# Jobqueue R package v. 1.0-4
# Bramblecloud UG, Bastian Laubner, 2015-04-22
# www.bramblecloud.com


### Internal Functions
Q.call = function(Q, fun, args, tag = NULL, tranche = NULL, mute = FALSE) {
  if (!is.null(tag)) tag = as.character(tag) # coerce tag to character string to avoid rack indexing problems
  if (mute) tag = "Q.mute"
  invisible(
    parallel:::sendCall(con=Q, fun=fun, args=args, tag=list(tag=tag,tranche=tranche)) # tryCatch? return value?
    #snow::sendCall(con=Q, fun=fun, args=args, tag=list(tag=tag,tranche=tranche)) # tryCatch? return value?
  )
}

Q.recv = function(Q, wait = FALSE) {
  if (Q.isready(Q, timeout = wait)) {
    return( parallel:::recvData(Q) )
    #return( snow::recvData.SOCKnode(Q) )
  }
  return(NULL)  # no result to retrieve
}

# guarantee uniform return type
Q.get_uniform_result = function(res) {
  isnull = is.null(res)
  if (!is.list(res)) res = list(value = res)
  res$has.result = !isnull
  if (is.list(res$tag)) {  # unpack tag and tranche
    res$tranche = res$tag$tranche
    res$tag = res$tag$tag
  }  
  return(res)
}

# convenience function to pop & return elements from rack
Q.rack_pop = function(Q, index) {
  elements = Q$data$rack[index]
  Q$data$rack[index] = NULL
  return(elements)
}



### Exported Functions

## generator function for queues
Q.make = function(...) {
  Q = parallel::makeCluster(1, "PSOCK", ...)[[1]]
  #Q = snow::makeCluster(1, "SOCK", ...)[[1]]
  Q$data = new.env()
  Q$data$mute = list("Q.mute")  # tagnames whose replies get muted
  Q$data$rack = list()  # storage for picked up results whose tag wasn't requested
  class(Q) = c("jobqueue", "SOCKnode")
  return(Q) 
}


## Test if queue has result to be read. 
#  Set write=TRUE to test if available for writing. Queue should always be available for writing.
Q.isready = function(Q, write = FALSE, timeout = 0) {
  return(socketSelect(list(Q$con), write = write,  timeout = timeout))
}


## Standard function to send job to queue
#  NOTE: This implementation uses "undefined" behavior of do.call applied to substitute. Possible workaround:  
#   e = new.env(hash=FALSE)
#   e$exp = substitute(...)
#   if (length(local)>0) list2env(local, e)
#   cmd = substitute(exp, e)
Q.push = function(Q, ..., local = list(), tag = NULL, tranche = NULL, mute = FALSE) {
  cmd = do.call(substitute, list(substitute(...), local))
  Q.call(Q, "eval", args = list(cmd, envir=globalenv()), tag=tag, tranche=tranche, mute=mute)
}


## Convenience function of a Q.push command followed by Q.pop. You should be sure that are no other
#  jobs in the queue that could prevent the timely pickup (otherwise use a unique tag and extended wait).
Q.do = function(Q, ..., local = list(), tag = NULL, tranche = NULL, mute = FALSE, wait = TRUE) {
  Q.push(Q, ..., local=local, tag=tag, tranche=tranche, mute=mute)
  Q.pop(Q, tag=tag, wait=wait)
}


## Assignment of remote variable var (given as quoted name) with local value.
#  The assignment is done to the global environment unless envir is specified
#  (given as an unquoted environment variable which is evaluated remotely).
#  The assignment operation is a normal (muted) task in the queue's pipeline 
#  and is executed only once all previous tasks were completed.
Q.assign = function(Q, var, value, envir = globalenv()) {
  Q.push(Q, assign(var, value, envir), 
         local = list(var=var, value=value, envir=substitute(envir)),
         mute = TRUE)
  return(value)
}


## Convenience function to copy variables to the queue's workspace. Values for
#  the specified variables (unquoted) are obtained as if the variable was used
#  at the prompt and then assigned under the same name to the queue's global
#  environment.
Q.sync = function(Q, ...) {
  args = list(...)
  argnames = lapply(substitute(list(...)), deparse)[-1]
  for (i in seq_along(args)) {
    Q.assign(Q, argnames[[i]], args[[i]])
  }
  invisible(argnames)
}


## Q.do.call
#  Executes remote function fun (given as quoted name) with local arguments args and assigns 
#  result to remote variable var (given as quoted name), if specified.
#  The evaluation result is also stored for pick-up as with push operation (unless muted).
#  Use quote(variable) in args-list for variables whose remote value should be used.
Q.do.call = function(Q, fun, args, var = NULL, envir = globalenv(), tag = NULL, tranche = NULL, mute = FALSE) {
  if (is.null(var)) {
    Q.push(Q, do.call(fun, args),
           local = list(fun=fun, args=args),
           tag=tag, tranche=tranche, mute=mute)
  } else {
    Q.push(Q, assign(var, do.call(fun, args), envir), 
           local = list(var=var, fun=fun, args=args, envir = substitute(envir)),
           tag=tag, tranche=tranche, mute=mute)
  }
}


## Collect result from queue. Returns a list containing the result at entry $value. 
#  The return value always contains a boolean entry $has.result which is FALSE if 
#  there was no result to be read (either because queue has not been tasked with anything or 
#  no result is ready for pick-up yet), TRUE otherwise. 
#  If a result could be read from the socket, then the return value contains the entry $success 
#  which is FALSE if the computation produced an error. Furthermore, if the job was sent with 
#  values for tag and tranche, then the result contains these values at entries $tag and $tranche.
#  The function discards muted results and returns the first available non-muted result.
#  Specifying a number for wait makes the function wait for the first non-muted result 
#  for at most the specified number of seconds. Note that setting wait = TRUE causes the
#  function to wait for 1 second, because of coercion. Use wait = Inf to wait indefinitely
#  for the result (this will hang if no result ever becomes available).
#  Setting tag will cause Q.collect to return the first available result with the
#  corresponding tag. If no result with this tag becomes available within the waiting time,
#  then the result's has.result attribute is FALSE. Results picked up with the wrong tag
#  get stored for later retrieval. If you set a tag, make sure wait is not set to 0/FALSE to
#  give the queue time to sieve through the available results.
Q.collect = function(Q, tag = NULL, wait = TRUE) {
  starttime = Sys.time()
  # check rack if result is present there
  if (length(Q$data$rack)) {
    if (is.null(tag)) {
      res = Q.rack_pop(Q, 1)[[1]]
      return(Q.get_uniform_result(res))
    } else {
      tag = as.character(tag)
      if (tag %in% names(Q$data$rack)) {
        res = Q.rack_pop(Q, tag)[[1]]
        return(Q.get_uniform_result(res))
      }
    }
  }
  # nothing on the rack, need to pick up from queue
  first = TRUE 
  remtime = wait
  while( first ||  # guarantee at least one pick-up
           (remtime = wait - as.numeric(difftime(Sys.time(), starttime, units="secs"))) > 0 ) {
    first = FALSE
    res = Q.recv(Q, wait=remtime)
    try({if (res$tag$tag %in% Q$data$mute) {res = NULL; next}}, silent = TRUE)  # drop all replies to muted calls - "try" patches through NULL and non-std. results
    try({if (is.null(tag) || is.null(res) || (res$tag$tag == as.character(tag))) break}, silent = TRUE)  # found result - NULL results mean waiting time ran out
    try({Q$data$rack = c(Q$data$rack, setNames(list(res), res$tag$tag)); res = NULL; next}, silent = TRUE)  # since tag didn't match store item on rack for later retrieval
    Q$data$rack[[length(Q$data$rack)+1]] = res  # fallback if res$tag$tag is invalid (this never happens if queue is operated through standard frontend)
    res = NULL
  }
  return(Q.get_uniform_result(res))  
}


## Simple version of Q.collect that only returns the result (without tag and tranche)
#  Note: a NULL return value may either mean that the return value was NULL or that there
#  was no result to collect at this time. Use Q.collect if you need to tell the difference.
Q.pop = function(Q, tag = NULL, wait = TRUE) {
  return(Q.collect(Q, tag=tag, wait=wait)$value)
}


Q.collect.all = function(Q, tag = NULL) {
  if (is.null(tag)) rackindices = rep(TRUE, length(Q$data$rack))
  else rackindices = (names(Q$data$rack) == tag)
  reslist = Q.rack_pop(Q, rackindices)
  while (Q.isready(Q)) {
    res = Q.collect(Q, tag=tag, wait=FALSE)
    if (res$has.result) reslist[[length(reslist)+1]] = res
  }
  return(reslist)
}


Q.pop.all = function(Q, tag = NULL) {
  reslist = Q.collect.all(Q, tag)
  return(lapply(reslist, "[[", "value"))
}


## Stop queue. Cleanup ensures that resources are freed, even if closing R-session hangs.
Q.close = function(Q, cleanup = TRUE) {
  if (cleanup) {
    # delete all variables assigned with Q.assign
    Q.push(Q, rm(list=ls(envir=globalenv()), envir=globalenv()), mute=TRUE) 
    Q.push(Q, gc(), mute=TRUE)
    Q.collect.all(Q)  # empty queue and remove all elements from rack
  }
  parallel:::stopNode(Q)
  #snow::stopNode(Q)
}


print.jobqueue = function(x, ...) {
  cat("Jobqueue based on a local socket node (status: ")
  tryCatch(cat(if (Q.isready(x, TRUE)) "ready/" else "not ready/", 
               if (Q.isready(x)) "results available" else "no results available",
               ")", sep=""),
           error = function(e) cat("closed/unavailable)"))
}
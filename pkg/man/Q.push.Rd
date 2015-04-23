\name{Q.push}
\alias{Q.push}
\alias{Q.do}
\alias{Q.assign}
\alias{Q.sync}
\alias{Q.do.call}

\title{
Functions for sending jobs to a job queue
}
\description{
\code{Q.push} is the standard function for enqueuing jobs.
\code{Q.do} is a convenience function that enqueues a job and immediately tries to pick up its result.
\code{Q.assign} is used for assigning local values to variables in the queue's workspace.
\code{Q.sync} is a convenience function for copying local variables 1-to-1 to the queue's workspace.
\code{Q.do.call} is a convenience function for executing functions in the queue and storing their result in the queue's workspace.
}

\usage{
Q.push(Q, ..., local = list(), tag = NULL, tranche = NULL, mute = FALSE)
Q.do(Q, ..., local = list(), tag = NULL, tranche = NULL, mute = FALSE, wait = TRUE)
Q.assign(Q, var, value, envir = globalenv())
Q.sync(Q, ...)
Q.do.call(Q, fun, args, var = NULL, envir = globalenv(), 
          tag = NULL, tranche = NULL, mute = FALSE)
}

\arguments{
  \item{Q}{
A job queue as created by \code{Q.make}.
}
  \item{\dots}{
\code{Q.push} and \code{Q.do} an R expression which is executed in the queue's workspace as it is, after substituting the local values of the elements specified in \code{local}. Use {} to enclose multiple commands/lines.
For \code{Q.sync} unquoted variable names.
}
  \item{local}{
A named list of the form \code{list(var1=value1, var2=value2, ...)}. Variables \code{var1, var2, ...} in the expression supplied to \code{Q.push} will be replaced with \code{value1, value2, ...}, respectively (evaluated in the local workspace), before sending the expression for evaluation to the queue.
}
  \item{tag}{
A tag for the job that can be used for later retrieval. Values will be coerced to string using \code{as.character}.
}
  \item{tranche}{
Another job tag that makes it convenient to subdivide a job with one tag into several parts. Can be an arbitrary value.
}
  \item{mute}{
If set to \code{TRUE}, the queue does not return the result of the computation.
}

  \item{wait}{
Maximum total time to wait until a result becomes available (in seconds). See \code{\link{Q.pop}} for more.
}

  \item{var}{
Variable to remotely assign in the queue's workspace (given as quoted name).
}
  \item{value}{
Value to assign (evaluated locally). 
}
  \item{envir}{
Environment to assign to in the queue's workspace (evaluated remotely).
}


  \item{fun}{
Function from the queue's workspace to execute (given as quoted name).
}
  \item{args}{
Function arguments given as a list (evaluated locally).
}

}
\details{
\code{Q.push} is the standard function used to send jobs to the queue. As the queue is running in a separate thread (via Rscript), it also has a workspace which is different from the local session (and which is practically blank in the beginning). The expression given to \code{Q.push} is evaluated remotely in the queue's global environment, so \code{Q.push(Q, a+1)} adds 1 to the value of \code{a} from the queue's workspace. If \code{a} cannot be found there, an error is thrown. 

Values from the local workspace can be injected into the expression using \code{local}. For example, \code{Q.push(Q, a+1, local=list(a=b))} uses the value of local variable \code{b} in place of \code{a}. Here, \code{b} can also be any other expression which is evaluated locally.

\code{Q.do} performs a \code{Q.push} command, immediately followed by a \code{\link{Q.pop}}. Its primary use is as a convenience function in interactive sessions for quickly evaluated jobs. If the return value is irrelevant, it is better to use \code{Q.push} with \code{mute=TRUE}. You should be sure there are no other jobs in the queue that could prevent the timely pickup (otherwise use a unique tag as in the example below, and consider increasing \code{wait}).

\code{Q.assign} is a convenience function for assigning a local value to a remote variable. The assignment is done to the global environment unless envir is specified (given as an unquoted environment variable which is evaluated remotely). The queue's reply for this assignment operation is muted. To check if the assignment was successful check the value returned for \code{Q.push(queue, var)} (here var is without quotes). The assignment operation is a normal task in the queue's pipeline and is executed only once all previous tasks were completed. \code{Q.assign(Q, "var", value)} is equivalent to \code{Q.push(Q, var <- value, local=list(value=value))}. 

\code{Q.sync} is another simplification of \code{Q.assign}. The specified variables (unquoted) are assigned under the same name to the queue's global environment. Local variable values are obtained as if the variable was used at the prompt.

\code{Q.do.call} executes the remote function fun (given as quoted name) with local arguments args and assigns result to remote variable var (given as quoted name), if specified. The evaluation result is also stored for retrieval as with \code{Q.push} (unless \code{mute=TRUE}). Use quote(variable) in args-list for variables or expressions whose remote value should be used. NOTE: unlike \code{Q.do}, this function does not attempt to pick up the computed result immediately (the name \code{Q.do.call} imitates the base function \code{\link{do.call}}).
}
\value{
\code{Q.push} and \code{Q.do.call} return NULL invisibly. 

\code{Q.do} has the same return value as \code{\link{Q.pop}}.

\code{Q.assign} returns the (locally evaluated) value which was sent to the queue for assignment.

\code{Q.sync} invisibly returns the character vector of variable names sent for assignment.
}
%\references{
%www.bramblecloud.com
%}
\author{
Bastian Laubner
}
\note{
The string \code{Q.mute} is reserved by the queue to tag jobs whose result should be muted. The list \code{Q$data$mute} can be extended to include further tags that should be muted.
}

\seealso{
\code{\link{Q.make}}, \code{\link{Q.collect}}
}
\examples{
Q = Q.make()

Q.push(Q, sum(1:1e4))
Q.push(Q, {a = 1})  # braces needed for assignment with =, not needed for a <- 1
Q.assign(Q, "b", 2)
c = 3
Q.sync(Q,c)
Q.do.call(Q, "sum", list(1:3), "d")
Q.do(Q, a+b+c == d, tag="test")  # TRUE - note: have to use a unique tag here
Q.pop.all(Q)

# use tags so that jobs can be retrieved selectively
for (i in 1:10) Q.push(Q, paste("Result:", i), local=list(i=i), tag=i);
Q.pop(Q, tag=5)  # Result: 5
Q.pop(Q, tag=2)  # Result: 2
Q.pop(Q, tag=10)  # Result: 10
Q.pop.all(Q)

Q.close(Q)
}

%\keyword{ programming }
%\keyword{ environment }
%\keyword{ utilities }

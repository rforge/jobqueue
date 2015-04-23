\name{Q.collect}
\alias{Q.collect}
\alias{Q.pop}
\alias{Q.collect.all}
\alias{Q.pop.all}
\alias{Q.isready}
\title{
Functions for retrieving results from a job queue
}
\description{
\code{Q.collect} returns the queue's first available result in a standardized format.
\code{Q.pop} is a simplified version of Q.collect that returns the pure result without any further information.
\code{Q.collect.all} and \code{Q.pop.all} return all results that are currently available in the queue.
\code{Q.isready} returns \code{TRUE} if there is a result available in the queue, \code{FALSE} otherwise.
}
\usage{
Q.collect(Q, tag = NULL, wait = TRUE)
Q.pop(Q, tag = NULL, wait = TRUE)

Q.collect.all(Q, tag = NULL)
Q.pop.all(Q, tag = NULL)

Q.isready(Q, write = FALSE, timeout = 0)
}
\arguments{
  \item{Q}{
A job queue as created by \code{Q.make}.
}
  \item{tag}{
Setting \code{tag} will cause \code{Q.collect} or \code{Q.pop} to return the first available result with the corresponding tag. Setting \code{tag} for \code{Q.collect.all} or \code{Q.pop.all} will return all available results with that tag.
}
  \item{wait}{
Maximum total time to wait until a result becomes available (in seconds). Logical values \code{TRUE/FALSE} are coerced to \code{1/0}, respectively. Setting \code{wait=Inf} will hang if no result ever becomes available.
}

  \item{write}{
Set \code{write=TRUE} to test if available for writing. Queue should always be available for writing. \code{write=FALSE} tests if there is a result available in the queue.
}
  \item{timeout}{
Time to wait (in seconds) for the socket to respond.
}
}
\details{
\code{Q.collect} returns a list containing the result at entry \code{$value}. The return value always contains a boolean entry \code{$has.result} which is \code{FALSE} if there was no result to be read (either because queue has not been tasked with anything or no result is ready for pick-up yet), \code{TRUE} otherwise. If a result could be read from the socket, then the return value contains the entry \code{$success} which is \code{FALSE} if the computation produced an error. Furthermore, if the job was sent with values for tag and tranche, then the result contains these values at entries \code{$tag} and \code{$tranche}. 

\code{Q.collect} discards muted results and returns the first available non-muted result. Setting \code{tag} will cause \code{Q.collect} to return the first available result with the corresponding tag. If no result with this tag becomes available within the waiting time, then the result's \code{has.result} field is \code{FALSE}. If you set a tag, make sure wait is not set to \code{0/FALSE} to give the queue time to sieve through the available results.

\code{Q.pop} is a simple version of \code{Q.collect} that only returns the result (without \code{has.result}, \code{tag}, \code{tranche}, etc.). Note: a \code{NULL} return value may either mean that the return value was \code{NULL} or that there was no result available at this time. Use \code{Q.collect} if you need to tell the difference.

\code{Q.collect.all} and \code{Q.pop.all} return all results that are currently available in the queue. There is no \code{wait} parameter as this would be practically equivalent to a construction like \code{Sys.sleep(wait); Q.collect.all(Q)}.

There is usually no need to use \code{Q.isready} since \code{Q.collect}'s \code{has.result} field indicates whether the queue was ready.

}
\value{
\code{Q.collect} returns a list which is guaranteed to have a logical field \code{has.result}. If \code{has.result=TRUE}, then the result also has a logical field \code{success} indicating whether or not an error occurred, and a field \code{value} containing the actual job result.

\code{Q.pop} simply returns the \code{value} field of \code{Q.collect}.

\code{Q.collect.all} and \code{Q.pop.all} return lists of elements in the respective formats.

\code{Q.isready} returns logical.
}


%\references{
%www.bramblecloud.com
%}
\author{
Bastian Laubner
}
\note{
If tag is specified for any of the retrieval functions, then available results with different tags will still be retrieved from the socket but stored in \code{Q$data$rack} for later retrieval from the queue. This is handled automatically by the queue.
}


\seealso{
\code{\link{Q.make}}, as well as \code{\link{Q.push}} and \code{\link[jobqueue:jobqueue-package]{jobqueue}} for further examples.
}
\examples{
Q = Q.make()
Q.push(Q, "Some job")

# safe way to check if the job returned a value
job = Q.collect(Q)
if (job$has.result) {
  # do something with the result
  print(job$value)
}

# safe way with error checking
if (job$has.result) {
  if (job$success) {
    # do something with the job result
    print(job$value)
  } else {
    # an error occurred during processing, error message in job$value
    stop(job$value)
  }
}

Q.close(Q)
}

%\keyword{ programming }
%\keyword{ environment }
%\keyword{ utilities }

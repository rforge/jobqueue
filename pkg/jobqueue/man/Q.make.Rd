\name{Q.make}
\alias{Q.make}
\alias{Q.close}
\title{
Functions for creating and closing a job queue
}
\description{
\code{Q.make} creates a 1-node socket cluster to be used with all the other jobqueue functions. 
\code{Q.close} destroys the jobqueue and frees its resources, deleting all data which it may still contain.
}
\usage{
Q.make(...)
Q.close(Q, cleanup = TRUE)
}
\arguments{
  \item{\dots}{
\code{Q.make} passes all supplied arguments through to \code{parallel::makeCluster(1, "PSOCK", ...)}. Usually, no such options need to be specified. Setting \code{methods=FALSE} reduces the memory usage of the queue, but can only be used if the methods package and S4 classes are not needed. 
}
  \item{Q}{
A job queue as created by \code{Q.make}.
}
  \item{cleanup}{
If \code{TRUE}, the queue's temporary data and all variables assigned with \code{Q.assign} are deleted before closing the socket. Otherwise, only the socket is closed (potentially not freeing all resources).
}
}

\value{
\code{Q.make} returns an S3 jobqueue object to be used with the other jobqueue functions.

\code{Q.close} returns NULL invisibly.
}
%\references{
%www.bramblecloud.com
%}
\author{
Bastian Laubner
}

\seealso{
\code{\link{Q.push}}, \code{\link{Q.collect}}
}
\examples{
Q = Q.make()
Q.close(Q)
}

%\keyword{ programming }
%\keyword{ environment }
%\keyword{ utilities }

\name{jobqueue-package}
\alias{jobqueue-package}
\alias{jobqueue}
\docType{package}
\title{
Job queue for computations in a separate thread
}
\description{
A generic implementation of an asynchronous job queue based on a 1-node-SOCKcluster from the parallel package.
}
\details{
%\tabular{ll}{
%Package: \tab jobqueue\cr
%Type: \tab Package\cr
%Version: \tab 1.0-1\cr
%Date: \tab 2015-04-09\cr
%License: \tab MIT\cr
%}
This package provides a queue-like interface that allows background computations while the calling R session remains responsive. The focus of the jobqueue package is on providing a simple and intuitive user interface.

Job results are available for pick-up in the order that the jobs were sent. Alternatively, jobs can be tagged and results can be retrieved based on their tag. 

Job queues are created using \code{\link{Q.make}}. Jobs are typically pushed to the queue using \code{\link{Q.push}} and their results collected with \code{\link{Q.collect}} or \code{\link{Q.pop}}.

Note that queues have their own workspace which is separate from your current workspace. That means that you have to load any packages and set all variables that you need for your computations in the queue (see examples below).
}
\author{
Bastian Laubner <bastian.laubner@bramblecloud.com>
}
\references{
\href{https://www.bramblecloud.com}{www.bramblecloud.com} uses the jobqueue package for basic threading.
}

\keyword{ package }
\keyword{ programming }
\keyword{ environment }
\keyword{ utilities }
\seealso{
\code{\link{Q.make}}, \code{\link{Q.push}}, \code{\link{Q.collect}}%, as well as the \code{\link[parallel:parallel-package]{parallel package}}
}
\examples{
# create job queue
Q = Q.make()

# push computation job to queue
Q.push(Q, sum(1:1e4) )

# perform other computations here while the job is computed 
# in the background

# retrieve result from job queue
Q.pop(Q)

# load package in the queue
Q.push(Q, library(stats4), mute=TRUE)

# set variables in the queue - you can also use Q.push or Q.sync
Q.assign(Q, "a", 5)

# close the queue and free its resources
Q.close(Q)
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lazytensor_preprocess.R
\name{identifier}
\alias{identifier}
\title{Identifier.}
\usage{
identifier(arg)
}
\arguments{
\item{arg}{A \code{string} corresponding to an element of the attribute \code{args} of
a \code{LazyTensor}.}
}
\value{
A \code{string}.
}
\description{
Returns the identifier/label of a \code{LazyTensor} which is contained in \code{arg}.
}
\details{
\code{identifier(arg)} will extract a unique identifier of the form
\code{"A0x.*"} from the argument \code{arg} which has the form \code{"A0x.*=Vi(3)"}.
}
\examples{
\dontrun{
x <- matrix(runif(150 * 3), 150, 3) # arbitrary R matrix, 150 rows, 3 columns
x_i <- LazyTensor(x, index = 'i')   # creating LazyTensor from matrix x, 
                                    # indexed by 'i'
arg <- x_i$args[1]                  # argument of the form "A0x.*=Vi(3)"
id <- identifier(arg)               # extracts "A0x.*"
}
}
\author{
Chloe Serre-Combe, Amelie Vernay
}
\keyword{internal}

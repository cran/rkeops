% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lazytensor_operations.R
\name{atan2}
\alias{atan2}
\title{Element-wise 2-argument arc-tangent operation.}
\usage{
atan2(x, y)
}
\arguments{
\item{x, y}{input for \code{\link[=atan2.default]{atan2.default()}} or
\code{\link[=atan2.LazyTensor]{atan2.LazyTensor()}}.}
}
\value{
See value of \code{\link[=atan2.default]{atan2.default()}} or
\code{\link[=atan2.LazyTensor]{atan2.LazyTensor()}}.
}
\description{
Symbolic element-wise 2-argument arc-tangent operation for \code{LazyTensor}
objects or standard element-wise 2-argument arc-tangent operation
otherwise.
}
\details{
If \code{x} is a \code{LazyTensor}, see \code{\link[=atan2.LazyTensor]{atan2.LazyTensor()}}, else
see \code{\link[=atan2.default]{atan2.default()}}.

\strong{Note}: the arc-tangent of two arguments \code{atan2(y, x)} returns the angle
between the x-axis and the vector from the origin to (x, y), i.e.,
for positive arguments \code{atan2(y, x) == atan(y/x)}.
}
\examples{
\dontrun{
# R base operation
atan2(0, 1)
atan2(1, 0)
# LazyTensor symbolic element-wise 2-argument arc-tangent
x <- matrix(runif(150 * 3), 150, 3) # arbitrary R matrix, 150 rows, 3 columns
y <- matrix(runif(250 * 3), 250, 3) # arbitrary R matrix, 250 rows, 3 columns
x_i <- LazyTensor(x, index = 'i')   # creating LazyTensor from matrix x, 
                                    # indexed by 'i'
y_j <- LazyTensor(y, index = 'j')   # creating LazyTensor from matrix y, 
                                    # indexed by 'j'
Atan2_xy <- atan2(x_i, y_j)         # symbolic matrix
}
}
\seealso{
\code{\link[=atan2.default]{atan2.default()}}, \code{\link[=atan2.LazyTensor]{atan2.LazyTensor()}}
}
\author{
Chloe Serre-Combe, Amelie Vernay
}

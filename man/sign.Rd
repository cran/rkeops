% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lazytensor_operations.R
\name{sign}
\alias{sign}
\title{Element-wise sign operation}
\usage{
sign(x)
}
\arguments{
\item{x}{input for \code{\link[=sign.default]{sign.default()}} or \code{\link[=sign.LazyTensor]{sign.LazyTensor()}}.}
}
\value{
See value of \code{\link[=sign.default]{sign.default()}} or \code{\link[=sign.LazyTensor]{sign.LazyTensor()}}.
}
\description{
Symbolic element-wise sign operation for \code{LazyTensor} objects or
default element-wise sign operation otherwise.
}
\details{
If \code{x} is a \code{LazyTensor}, see \code{\link[=sign.LazyTensor]{sign.LazyTensor()}}, else
see \code{\link[=sign.default]{sign.default()}}.

The sign function is defined as follows:
\deqn{\text{sign}(x) = \left\{
\begin{array}{rcl}
0 & \text{if } & x = 0\\
-1 & \text{if } & x < 0\\
1 & \text{if } & x > 0 
\end{array}\right.}
}
\examples{
\dontrun{
# R base operation
sign(5)
sign(-5)
sign(-10:10)
# LazyTensor symbolic element-wise sign
x <- matrix(runif(150 * 3), 150, 3) # arbitrary R matrix, 150 rows, 3 columns
x_i <- LazyTensor(x, index = 'i')   # creating LazyTensor from matrix x, 
                                    # indexed by 'i'
Sign_x <- sign(x_i)                 # symbolic matrix, 150 rows and 3 columns
}
}
\seealso{
\code{\link[=sign.default]{sign.default()}}, \code{\link[=sign.LazyTensor]{sign.LazyTensor()}}
}
\author{
Chloe Serre-Combe, Amelie Vernay
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lazytensor_preprocess.R
\name{get_inner_dim}
\alias{get_inner_dim}
\title{Get inner dimension.}
\usage{
get_inner_dim(x)
}
\arguments{
\item{x}{A \code{LazyTensor}.}
}
\value{
An integer corresponding to the inner dimension of \code{x}.
}
\description{
Returns the inner dimension of a given \code{LazyTensor}.
}
\details{
If \code{x} is a \code{LazyTensor}, \code{get_inner_dim(x)} returns an integer
corresponding to the inner dimension of \code{x}.
}
\examples{
\dontrun{
# basic example
D <- 3
M <- 100
s <- 0.25
x <- matrix(runif(M * D), M, D)

# create LazyTensor
x_i <- LazyTensor(x, index = 'i')
Pm_s <- LazyTensor(s, index = NA)

# call get_inner_dim
get_inner_dim(x_i) # returns 3
get_inner_dim(Pm_s) # returns 1
}
}
\author{
Chloe Serre-Combe, Amelie Vernay
}
\keyword{internal}

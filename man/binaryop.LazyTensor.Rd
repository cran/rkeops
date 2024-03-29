% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lazytensor_preprocess.R
\name{binaryop.LazyTensor}
\alias{binaryop.LazyTensor}
\title{Build a binary operation}
\usage{
binaryop.LazyTensor(
  x,
  y,
  opstr,
  is_operator = FALSE,
  dim_check_type = "sameor1",
  res_type = NA,
  dim_res = NA,
  opt_arg = NA
)
}
\arguments{
\item{x}{A \code{LazyTensor}, a \code{ComplexLazyTensor}, a vector of numeric values,
or a scalar value.}

\item{y}{A \code{LazyTensor}, a \code{ComplexLazyTensor}, a vector of numeric values,
or a scalar value.}

\item{opstr}{A text string corresponding to an operation.}

\item{is_operator}{A boolean used to specify if \code{opstr} is an operator like
\code{+}, \code{-} or a "genuine" function.}

\item{dim_check_type}{A string to specify if, and how, we should check input
dimensions. Supported values are:
\itemize{
\item \code{"same"}: \code{x} and \code{y} should have the same inner dimension;
\item \code{"sameor1"} (default): \code{x} and \code{y} should have the same
inner dimension or at least one of them should be of dimension 1;
\item \code{NA}: no dimension restriction.
}}

\item{res_type}{NA (default) or a character string among "LazyTensor" and
"ComplexLazyTensor", to specify if a change of class is required for the
result. (Useful especially when dealing with complex-to-real or
real-to-complex functions).}

\item{dim_res}{NA (default) or an integer corresponding to the inner
dimension of the output \code{LazyTensor}. If NA, \code{dim_res} is set to the
maximum between the inner dimensions of the two input \code{LazyTensor}s.}

\item{opt_arg}{NA (default) or list of optional arguments for the formula
encoding the binary operation on input LazyTensors.}
}
\value{
An object of class "LazyTensor".
}
\description{
Symbolically applies \code{opstr} operation to \code{x} and \code{y}.
}
\examples{
\dontrun{
x <- matrix(runif(150 * 3), 150, 3) # arbitrary R matrix, 150 rows, 3 columns
y <- matrix(runif(150 * 3), 150, 3) # arbitrary R matrix, 150 rows, 3 columns
x_i <- LazyTensor(x, index = 'i')   # LazyTensor from matrix x, indexed by 'i'
y_j <- LazyTensor(y, index = 'j')   # LazyTensor from matrix y, indexed by 'j'
# symbolic matrix:
bin_xy <- binaryop.LazyTensor(x_i, y_j, "+", is_operator = TRUE)
}
}
\author{
Chloe Serre-Combe, Amelie Vernay
}

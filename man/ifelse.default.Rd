% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lazytensor_operations.R
\name{ifelse.default}
\alias{ifelse.default}
\title{Conditional Element Selection}
\usage{
\method{ifelse}{default}(test, yes, no)
}
\arguments{
\item{test}{an object which can be coerced to logical mode.}

\item{yes}{return values for true elements of \code{test}.}

\item{no}{return values for false elements of \code{test}.}
}
\value{
A vector of the same length and attributes (including dimensions and
  \code{"class"}) as \code{test} and data values from the values of
  \code{yes} or \code{no}.  The mode of the answer will be coerced from
  logical to accommodate first any values taken from \code{yes} and then
  any values taken from \code{no}.
}
\description{
\code{ifelse} returns a value with the same shape as
  \code{test} which is filled with elements selected
  from either \code{yes} or \code{no}
  depending on whether the element of \code{test}
  is \code{TRUE} or \code{FALSE}.
}
\details{
If \code{yes} or \code{no} are too short, their elements are recycled.
  \code{yes} will be evaluated if and only if any element of \code{test}
  is true, and analogously for \code{no}.

  Missing values in \code{test} give missing values in the result.
}
\examples{
x <- c(6:-4)
sqrt(x)  #- gives warning
sqrt(ifelse(x >= 0, x, NA))  # no warning

## Note: the following also gives the warning !
ifelse(x >= 0, sqrt(x), NA)


## ifelse() strips attributes
## This is important when working with Dates and factors
x <- seq(as.Date("2000-02-29"), as.Date("2004-10-04"), by = "1 month")
## has many "yyyy-mm-29", but a few "yyyy-03-01" in the non-leap years
y <- ifelse(as.POSIXlt(x)$mday == 29, x, NA)
head(y) # not what you expected ... ==> need restore the class attribute:
class(y) <- class(x)
y
## This is a (not atypical) case where it is better *not* to use ifelse(),
## but rather the more efficient and still clear:
y2 <- x
y2[as.POSIXlt(x)$mday != 29] <- NA
## which gives the same as ifelse()+class() hack:
stopifnot(identical(y2, y))


## example of different return modes (and 'test' alone determining length):
yes <- 1:3
no  <- pi^(1:4)
utils::str( ifelse(NA,    yes, no) ) # logical, length 1
utils::str( ifelse(TRUE,  yes, no) ) # integer, length 1
utils::str( ifelse(FALSE, yes, no) ) # double,  length 1
}
\seealso{
\code{\link[base:ifelse]{base::ifelse()}}
}
\author{
R core team and contributors
}

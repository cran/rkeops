% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/common-set_options.R
\name{set_rkeops_options}
\alias{set_rkeops_options}
\title{Initialize or update \code{rkeops} options in \code{R} global options scope}
\usage{
set_rkeops_options(
  custom_compile_options = NULL,
  custom_runtime_options = NULL
)
}
\arguments{
\item{custom_compile_options}{a list (of class \code{rkeops_compile_options}).
See \code{\link[=compile_options]{compile_options()}} for a detailled description. Default value
is \code{NULL} and default compile options are set up (see
\code{\link[=default_compile_options]{default_compile_options()}}).}

\item{custom_runtime_options}{a list (of class \code{rkeops_runtime_options}).
See \code{\link[=runtime_options]{runtime_options()}} for a detailled description. Default
value is \code{NULL} and default runtime options are set up
(see \code{\link[=default_runtime_options]{default_runtime_options()}}).}
}
\value{
None
}
\description{
\code{rkeops} uses two sets of options: compile options (see
\code{\link[=compile_options]{compile_options()}}) and runtime options (see
\code{\link[=runtime_options]{runtime_options()}}). These options define the behavior of \code{rkeops}
when compiling or when calling user-defined operators.

If no input is provided, the functions \code{set_rkeops_options} initializes the
\code{rkeops} options in the \code{R} global options scope (i.e. options available
by calling \code{options()} or \verb{getOptions(<option_name>)}) with default values.

If some input is provided, i.e. objects defining compile options and/or
runtime options (see Details), \code{rkeops} global options are updated
accordingly.
}
\details{
\code{rkeops} global options includes two lists defining options used at
compilation of user-defined operators or at runtime. These two list
contains specific informations (see \code{\link[=compile_options]{compile_options()}} and
\code{\link[=runtime_options]{runtime_options()}} respectively, in particular for default values).

In order to update, the corresponding options, user should provide objects
returned by the functions \code{\link[=compile_options]{compile_options()}} and/or
\code{\link[=runtime_options]{runtime_options()}} respectively, being lists of class
\code{rkeops_compile_options} and \code{rkeops_runtime_options} respectively, with
specific attributes.
}
\examples{
set_rkeops_options()
}
\seealso{
\code{\link[=set_rkeops_option]{set_rkeops_option()}}, \code{\link[=compile_options]{compile_options()}},
\code{\link[=runtime_options]{runtime_options()}}, \code{\link[=default_compile_options]{default_compile_options()}},
\code{\link[=default_runtime_options]{default_runtime_options()}}, \code{\link[=use_gpu]{use_gpu()}},
\code{\link[=compile4gpu]{compile4gpu()}}, \code{\link[=get_rkeops_options]{get_rkeops_options()}}
}
\author{
Ghislain Durif
}

## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  progress = TRUE,
  warning = FALSE
)

## ----formula, eval=FALSE------------------------------------------------------
#  formula = "Sum_Reduction(Exp(-s * SqNorm2(x - y)) * b, 0)"

## ----args, eval=FALSE---------------------------------------------------------
#  args = c("x = Vi(3)",      # vector indexed by i (of dim 3)
#           "y = Vj(3)",      # vector indexed by j (of dim 3)
#           "b = Vj(6)",      # vector indexed by j (of dim 6)
#           "s = Pm(1)")      # parameter (scalar)

## ----compile, eval=FALSE------------------------------------------------------
#  # compilation
#  op <- keops_kernel(formula, args)
#  # data and parameter values
#  nx <- 100
#  ny <- 150
#  X <- matrix(runif(nx*3), nrow=nx)   # matrix 100 x 3
#  Y <- matrix(runif(ny*3), nrow=ny)   # matrix 150 x 3
#  B <- matrix(runif(ny*6), nrow=ny)   # matrix 150 x 6
#  s <- 0.2
#  # computation (order of the input arguments should be similar to `args`)
#  res <- op(list(X, Y, B, s))


## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  progress = TRUE,
  warning = FALSE
)

## ----install, eval=FALSE------------------------------------------------------
#  install.packages("rkeops")

## ----install_github, eval=FALSE-----------------------------------------------
#  devtools::install_git("https://github.com/getkeops/keops",
#                        subdir = "rkeops",
#                        args="--recursive")
#  # not possible to use `devtools::intall_github()` because of the required submodule

## ----install_src, eval=FALSE--------------------------------------------------
#  devtools::install("rkeops")

## ----setup--------------------------------------------------------------------
library(rkeops)

## ----full_example, eval=FALSE-------------------------------------------------
#  # implementation of a convolution with a Gaussian kernel
#  formula = "Sum_Reduction(Exp(-s * SqNorm2(x - y)) * b, 0)"
#  # input arguments
#  args = c("x = Vi(3)",      # vector indexed by i (of dim 3)
#           "y = Vj(3)",      # vector indexed by j (of dim 3)
#           "b = Vj(6)",      # vector indexed by j (of dim 6)
#           "s = Pm(1)")      # parameter (scalar)
#  # compilation
#  op <- keops_kernel(formula, args)
#  # data and parameter values
#  nx <- 100
#  ny <- 150
#  X <- matrix(runif(nx*3), nrow=nx)   # matrix 100 x 3
#  Y <- matrix(runif(ny*3), nrow=ny)   # matrix 150 x 3
#  B <- matrix(runif(ny*6), nrow=ny)   # matrix 150 x 6
#  s <- 0.2
#  
#  # to run computation on CPU (default mode)
#  use_cpu()
#  # to run computations on GPU (to be used only if relevant)
#  use_gpu()
#  
#  # computation (order of the input arguments should be similar to `args`)
#  res <- op(list(X, Y, B, s))

## ----formula, eval=FALSE------------------------------------------------------
#  formula = "Sum_Reduction(Exp(-s * SqNorm2(x - y)) * b, 0)"

## ----template_args, eval=FALSE------------------------------------------------
#  args = c("<name1>=<type1>(dim1)", "<name2>=<type2>(dim2)", "<nameX>=<typeX>(dimX)")

## ----args, eval=FALSE---------------------------------------------------------
#  args = c("x = Vi(3)",      # vector indexed by i (of dim 3)
#           "y = Vj(3)",      # vector indexed by j (of dim 3)
#           "b = Vj(6)",      # vector indexed by j (of dim 6)
#           "s = Pm(1)")      # parameter (scalar)

## ----compile, eval=FALSE------------------------------------------------------
#  # compilation
#  op <- keops_kernel(formula, args)

## ----run, eval=FALSE----------------------------------------------------------
#  # data and parameter values
#  nx <- 100
#  ny <- 150
#  X <- matrix(runif(nx*3), nrow=nx)   # matrix 100 x 3
#  Y <- matrix(runif(ny*3), nrow=ny)   # matrix 150 x 3
#  B <- matrix(runif(ny*6), nrow=ny)   # matrix 150 x 6
#  s <- 0.2
#  
#  # to run computation on CPU (default mode)
#  use_cpu()
#  # to run computations on GPU (to be used only if relevant)
#  use_gpu()
#  
#  # computation (order of the input arguments should be similar to `args`)
#  res <- op(list(x, y, beta, s))

## ----grad, eval=FALSE---------------------------------------------------------
#  # defining a formula with a Gradient
#  formula <- "Grad(Sum_Reduction(SqNorm2(x-y), 0), x, eta)"
#  args <- c("x=Vi(0,3)", "y=Vj(1,3)", "eta=Vi(2,1)")
#  # compiling the corresponding operator
#  op <- keops_kernel(formula, args)
#  
#  # data
#  nx <- 100
#  ny <- 150
#  x <- matrix(runif(nx*3), nrow=nx, ncol=3)     # matrix 100 x 3
#  y <- matrix(runif(ny*3), nrow=ny, ncol=3)     # matrix 150 x 3
#  eta <- matrix(runif(nx*1), nrow=nx, ncol=1)   # matrix 100 x 1
#  
#  # computation
#  input <- list(x, y, eta)
#  res <- op(input)

## ----keops_grad, eval=FALSE---------------------------------------------------
#  # defining an operator (reduction on squared distance)
#  formula <- "Sum_Reduction(SqNorm2(x-y), 0)"
#  args <- c("x=Vi(0,3)", "y=Vj(1,3)")
#  op <- keops_kernel(formula, args)
#  # defining its gradient regarding x
#  grad_op <- keops_grad(op, var="x")
#  
#  # data
#  nx <- 100
#  ny <- 150
#  x <- matrix(runif(nx*3), nrow=nx, ncol=3)     # matrix 100 x 3
#  y <- matrix(runif(ny*3), nrow=ny, ncol=3)     # matrix 150 x 3
#  eta <- matrix(runif(nx*1), nrow=nx, ncol=1)   # matrix 100 x 1
#  
#  # computation
#  input <- list(x, y, eta)
#  res <- grad_op(input)

## ----get_options, eval=FALSE--------------------------------------------------
#  get_rkeops_options()

## ----reset_options, eval=FALSE------------------------------------------------
#  set_rkeops_options()

## ----set_option, eval=FALSE---------------------------------------------------
#  set_rkeops_option(option, value)
#  # `option` = text string, name of the option to set up
#  # `value` = whatever value to assign to the chosen option

## ----set_cuda, eval=FALSE-----------------------------------------------------
#  # enable compiling for GPU if available (not necessary if using default options)
#  compile4gpu()
#  # or equivalently
#  set_rkeops_option("use_cuda_if_possible", 1)
#  # disable compiling for GPU
#  set_rkeops_option("use_cuda_if_possible", 0)

## ----set_precision, eval=FALSE------------------------------------------------
#  set_rkeops_option("precision", "float")    # float 32bits (default)
#  set_rkeops_option("precision", "double")   # float 64bits

## ----use_gpu, eval=FALSE------------------------------------------------------
#  use_gpu()
#  # see `?runtime_options` for a more advanced use of GPU inside RKeOps

## ----set_device_id, eval=FALSE------------------------------------------------
#  set_rkeops_option("device_id", 0)

## ----storage_order, eval=FALSE------------------------------------------------
#  # standard column reduction of a matrix product
#  op <- keops_kernel(formula = "Sum_Reduction((x|y), 1)",
#                     args = c("x=Vi(3)", "y=Vj(3)"))
#  
#  # data (inner dimension = columns)
#  nx <- 10
#  ny <- 15
#  # x_i = rows of the matrix X
#  X <- matrix(runif(nx*3), nrow=nx, ncol=3)
#  # y_j = rows of the matrix Y
#  Y <- matrix(runif(ny*3), nrow=ny, ncol=3)
#  # computing the result (here, by default `inner_dim=1` and columns corresponds
#  # to the inner dimension)
#  res <- op(list(X,Y))
#  
#  # data (inner dimension = rows)
#  nx <- 10
#  ny <- 15
#  # x_i = columns of the matrix X
#  X <- matrix(runif(nx*3), nrow=3, ncol=nx)
#  # y_j = columns of the matrix Y
#  Y <- matrix(runif(ny*3), nrow=3, ncol=ny)
#  # computing the result (we specify `inner_dim=0` to indicate that rows
#  # corresponds to the inner dimension)
#  res <- op(list(X,Y), inner_dim=0)


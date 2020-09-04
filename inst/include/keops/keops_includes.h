
#if USE_HALF
  #include <cuda_fp16.h>
#endif

// import constant
#include "core/formulas/constants/IntConst.h"
#include "core/formulas/constants/Zero.h"


// import all math implementations
#include "core/formulas/maths/Minus.h"
#include "core/formulas/maths/Sum.h"
#include "core/formulas/maths/Min.h"
#include "core/formulas/maths/Max.h"
#include "core/formulas/maths/ArgMin.h"
#include "core/formulas/maths/ArgMax.h"
#include "core/formulas/maths/Add.h"
#include "core/formulas/maths/Concat.h"
#include "core/formulas/maths/Scal.h"
#include "core/formulas/maths/Mult.h"
#include "core/formulas/maths/ScalOrMult.h"
#include "core/formulas/maths/Subtract.h"
#include "core/formulas/maths/Exp.h"
#include "core/formulas/maths/Sin.h"
#include "core/formulas/maths/Cos.h"
#include "core/formulas/maths/Pow.h"
#include "core/formulas/maths/Square.h"
#include "core/formulas/maths/Inv.h"
#include "core/formulas/maths/IntInv.h"
#include "core/formulas/maths/Divide.h"
#include "core/formulas/maths/Log.h"
#include "core/formulas/maths/XLogX.h"
#include "core/formulas/maths/Sign.h"
#include "core/formulas/maths/Abs.h"
#include "core/formulas/maths/Step.h"
#include "core/formulas/maths/ReLu.h"
#include "core/formulas/maths/Powf.h"
#include "core/formulas/maths/Sqrt.h"
#include "core/formulas/maths/Rsqrt.h"
#include "core/formulas/maths/MatVecMult.h"
#include "core/formulas/maths/GradMatrix.h"
#include "core/formulas/maths/TensorDot.h"
#include "core/formulas/maths/TensorProd.h"
#include "core/formulas/maths/VecMatMult.h"
#include "core/formulas/maths/OneHot.h"


// import all operations on vector implementations
#include "core/formulas/norms/Norm2.h"
#include "core/formulas/norms/Normalize.h"
#include "core/formulas/norms/Scalprod.h"
#include "core/formulas/norms/SqDist.h"
#include "core/formulas/norms/SqNorm2.h"
#include "core/formulas/norms/SqNormDiag.h"
#include "core/formulas/norms/SqNormIso.h"
#include "core/formulas/norms/WeightedSqDist.h"
#include "core/formulas/norms/WeightedSqNorm.h"


// import all reductions
#include "core/reductions/Sum_Reduction.h"
#include "core/reductions/Max_SumShiftExp_Reduction.h"
#include "core/reductions/Min_Reduction.h"
#include "core/reductions/Max_Reduction.h"
#include "core/reductions/KMin_Reduction.h"


// import all Kernels
#include "core/formulas/kernels/CauchyKernel.h"
#include "core/formulas/kernels/CurlFreeGaussKernel.h"
#include "core/formulas/kernels/DivFreeGaussKernel.h"
#include "core/formulas/kernels/GaussKernel.h"
#include "core/formulas/kernels/InverseMultiquadricKernel.h"
#include "core/formulas/kernels/LaplaceKernel.h"
#include "core/formulas/kernels/ScalarRadialKernels.h"
#include "core/formulas/kernels/SumGaussKernel.h"
#include "core/formulas/kernels/TRI_Kernel.h"
#include "core/formulas/kernels/TRIGaussKernel.h"

#include "core/formulas/Factorize.h"
#include "core/formulas/PrintFormula.h"

// special options for accuracy
#ifndef __TYPEACC__
  #define __TYPEACC__ __TYPE__
#endif
#define DIRECT_SUM 0
#define BLOCK_SUM 1
#define KAHAN_SCHEME 2
#ifndef SUM_SCHEME
  #define SUM_SCHEME DIRECT_SUM
#endif

// special computation scheme for dim>100
#ifndef ENABLECHUNK
  #define ENABLECHUNK 0
#endif
#ifndef DIMCHUNK
  #define DIMCHUNK 64
#endif
#ifndef CUDA_BLOCK_SIZE_CHUNKS
  #define CUDA_BLOCK_SIZE_CHUNKS 192
#endif
#ifndef DIM_TRESHOLD_CHUNK
  #define DIM_TRESHOLD_CHUNK 110
#endif

// float16 support
#if !USE_HALF
#include "core/mapreduce/CpuConv.cpp"
#endif

#ifdef __CUDACC__
  #include <cuda_fp16.h>
  #include "core/mapreduce/GpuConv1D.cu"
  #include "core/mapreduce/GpuConv2D.cu"
#endif


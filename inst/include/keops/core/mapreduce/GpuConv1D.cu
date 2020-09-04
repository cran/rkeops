#pragma once

#include <stdio.h>
#include <iostream>
#include <assert.h>
#include <cuda.h>

#include "core/pack/Pack.h"
#include "core/pack/GetInds.h"
#include "core/pack/GetDims.h"
#include "core/utils/CudaErrorCheck.cu"
#include "core/utils/CudaSizes.h"
#include "core/utils/TypesUtils.h"

namespace keops {
	

template<typename TYPE, class FUN>
__global__ void GpuConv1DOnDevice_Chunks(FUN fun, int nx, int ny, TYPE **px, TYPE **py, TYPE **pp) 
{

	// get the index of the current thread
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	
	// declare shared mem
	extern __shared__ TYPE yj[];
	
	// get templated dimensions :
	typedef typename FUN::DIMSX DIMSX;  // DIMSX is a "vector" of templates giving dimensions of xi variables
	typedef typename FUN::DIMSY DIMSY;  // DIMSY is a "vector" of templates giving dimensions of yj variables
	typedef typename FUN::DIMSP DIMSP;  // DIMSP is a "vector" of templates giving dimensions of parameters variables
	const int DIMY = DIMSY::SUM;        // DIMY  is sum of dimensions for yj variables
	const int DIMP = DIMSP::SUM;        // DIMP  is sum of dimensions for parameters variables
	const int DIMOUT = FUN::DIM; // dimension of output variable
	const int DIMRED = FUN::DIMRED; // dimension of reduction operation
	const int DIMFOUT = DIMSX::FIRST;     // DIMFOUT is dimension of output variable of inner function
	
	static_assert(DIMFOUT == 1, "implemented only for dim 1.");
	
	const int NCHUNKS = 1 + (DIMY-1) / DIMCHUNK;
	const int DIMLASTCHUNK = DIMY - (NCHUNKS-1)*DIMCHUNK;
	
	using F0 = typename FUN::F::template ReplaceVars2 < Var<0,DIMY,0>, Var<0,DIMCHUNK,0>, Var<1,DIMY,1>, Var<1,DIMCHUNK,1> >;
	using FUN_CHUNK = typename F0::template ReplaceVars2 < Var<1,DIMY,0>, Var<1,DIMCHUNK,0>, Var<0,DIMY,1>, Var<0,DIMCHUNK,1> >;
	
	using F1 = typename FUN::F::template ReplaceVars2 < Var<0,DIMY,0>, Var<0,DIMLASTCHUNK,0>, Var<1,DIMY,1>, Var<1,DIMLASTCHUNK,1> >;
	using FUN_LASTCHUNK = typename F1::template ReplaceVars2 < Var<1,DIMY,0>, Var<1,DIMLASTCHUNK,0>, Var<0,DIMY,1>, Var<0,DIMLASTCHUNK,1> >;
	
	// load parameter(s)
	TYPE param_loc[DIMP < 1 ? 1 : DIMP];
	load<DIMSP>(0, param_loc, pp); // load parameters variables from global memory to local thread memory
	
	// get the value of variable (index with i)
	TYPE xi[1+DIMCHUNK];
	TYPE fout[CUDA_BLOCK_SIZE_CHUNKS];
	
	__TYPEACC__ acc[DIMRED];

	if (i < nx) 
	{
		typename FUN::template InitializeReduction<__TYPEACC__, TYPE >()(acc); // acc = 0
	}
	__syncthreads();

	for (int jstart = 0, tile = 0; jstart < ny; jstart += blockDim.x, tile++) 
	{
		// get the current column
		int j = tile * blockDim.x + threadIdx.x;
	
		if (i < nx) 
		{ // we compute x1i only if needed
			for (int jrel = 0; (jrel < blockDim.x) && (jrel < ny - jstart); jrel++) 
			{
				fout[jrel] = 0;
			}
		}
		__syncthreads();
	
		// looping on chunks (except the last)
		#pragma unroll
		for (int chunk=0; chunk<NCHUNKS-1; chunk++) 
		{
			if (i < nx) 
			{
				#pragma unroll
				for (int k=0; k<DIMCHUNK; k++) 
					xi[k+1] = px[1][i*DIMSX::NEXT::FIRST+chunk*DIMCHUNK+k];  // load xi variable from global memory to local thread memory
			}
			__syncthreads();
	
			if (j < ny) 
			{ // we load yj from device global memory only if j<ny
				#pragma unroll
				for (int k=0; k<DIMCHUNK; k++) 
					yj[threadIdx.x * DIMCHUNK+k] = py[0][j*DIMSY::FIRST+chunk*DIMCHUNK+k];
			}
			__syncthreads();
	
			if (i < nx) 
			{ // we compute x1i only if needed
				TYPE * yjrel = yj; // Loop on the columns of the current block.
				for (int jrel = 0; (jrel < blockDim.x) && (jrel < ny - jstart); jrel++, yjrel += DIMCHUNK) 
				{
					call<pack<DIMFOUT,DIMCHUNK>, pack<DIMCHUNK>, DIMSP>(FUN_CHUNK::template EvalFun<FUN::INDS>(),
	                                  xi,
	                                  yjrel,
	                                  param_loc); // Call the function, which outputs results in xi[0:DIMX1]
					fout[jrel] += xi[0];
				}
			}
			__syncthreads();
		}
	
		// last chunk
		{
			if (i < nx) 
			{
				#pragma unroll
				for (int k=0; k<DIMLASTCHUNK; k++) 
					xi[k+1] = px[1][i*DIMSX::NEXT::FIRST+(NCHUNKS-1)*DIMCHUNK+k];  // load xi variable from global memory to local thread memory
			}
			__syncthreads();
	
			if (j < ny) 
			{ // we load yj from device global memory only if j<ny
				#pragma unroll
				for (int k=0; k<DIMLASTCHUNK; k++) 
					yj[threadIdx.x * DIMCHUNK+k] = py[0][j*DIMSY::FIRST+(NCHUNKS-1)*DIMCHUNK+k];
			}
			__syncthreads();
	
			if (i < nx) 
			{ // we compute x1i only if needed
				TYPE * yjrel = yj; // Loop on the columns of the current block.
				for (int jrel = 0; (jrel < blockDim.x) && (jrel < ny - jstart); jrel++, yjrel += DIMCHUNK) 
				{
					call<pack<DIMFOUT,DIMLASTCHUNK>, pack<DIMLASTCHUNK>, DIMSP>(FUN_LASTCHUNK::template EvalFun<FUN::INDS>(),
								  xi,
								  yjrel,
								  param_loc); // Call the function, which outputs results in xi[0:DIMX1]
					fout[jrel] += xi[0];
					typename FUN::template ReducePairShort<__TYPEACC__,TYPE>()(acc, fout+jrel, jrel + tile * blockDim.x);     // acc += xi
				}
			}
			__syncthreads();
		}

	}

	if (i < nx) {
		typename FUN::template FinalizeOutput<__TYPEACC__,TYPE>()(acc, px[0] + i * DIMOUT, px, i);
	}
	__syncthreads();
}


template<typename TYPE, class FUN>
__global__ void GpuConv1DOnDevice(FUN fun, int nx, int ny, TYPE **px, TYPE **py, TYPE **pp) {

  // get the index of the current thread
  int i = blockIdx.x * blockDim.x + threadIdx.x;

  // declare shared mem
  extern __shared__ TYPE yj[];

  // get templated dimensions :
  typedef typename FUN::DIMSX DIMSX;  // DIMSX is a "vector" of templates giving dimensions of xi variables
  typedef typename FUN::DIMSY DIMSY;  // DIMSY is a "vector" of templates giving dimensions of yj variables
  typedef typename FUN::DIMSP DIMSP;  // DIMSP is a "vector" of templates giving dimensions of parameters variables
  const int DIMX = DIMSX::SUM;        // DIMX  is sum of dimensions for xi variables
  const int DIMY = DIMSY::SUM;        // DIMY  is sum of dimensions for yj variables
  const int DIMP = DIMSP::SUM;        // DIMP  is sum of dimensions for parameters variables
  const int DIMOUT = FUN::DIM; // dimension of output variable
  const int DIMRED = FUN::DIMRED; // dimension of reduction operation
  const int DIMFOUT = DIMSX::FIRST;     // DIMFOUT is dimension of output variable of inner function

  // load parameter(s)
  TYPE param_loc[DIMP < 1 ? 1 : DIMP];
  load<DIMSP>(0, param_loc, pp); // load parameters variables from global memory to local thread memory

  // get the value of variable (index with i)
  TYPE xi[DIMX < 1 ? 1 : DIMX];
  __TYPEACC__ acc[DIMRED];
#if SUM_SCHEME == BLOCK_SUM
    // additional tmp vector to store intermediate results from each block
    TYPE tmp[DIMRED];
#elif SUM_SCHEME == KAHAN_SCHEME
    // additional tmp vector to accumulate errors
    const int DIM_KAHAN = FUN::template KahanScheme<__TYPEACC__,TYPE>::DIMACC;
    TYPE tmp[DIM_KAHAN];
#endif
  if (i < nx) {
    typename FUN::template InitializeReduction<__TYPEACC__, TYPE >()(acc); // acc = 0
#if SUM_SCHEME == KAHAN_SCHEME
    VectAssign<DIM_KAHAN>(tmp,0.0f);
#endif
    load<typename DIMSX::NEXT>(i, xi + DIMFOUT, px + 1); // load xi variables from global memory to local thread memory
  }

  for (int jstart = 0, tile = 0; jstart < ny; jstart += blockDim.x, tile++) {

    // get the current column
    int j = tile * blockDim.x + threadIdx.x;

    if (j < ny) { // we load yj from device global memory only if j<ny
      load<DIMSY>(j, yj + threadIdx.x * DIMY, py); // load yj variables from global memory to shared memory
    }
    __syncthreads();

    if (i < nx) { // we compute x1i only if needed
      TYPE * yjrel = yj; // Loop on the columns of the current block.
#if SUM_SCHEME == BLOCK_SUM
      typename FUN::template InitializeReduction<TYPE,TYPE>()(tmp); // tmp = 0
#endif
      for (int jrel = 0; (jrel < blockDim.x) && (jrel < ny - jstart); jrel++, yjrel += DIMY) {
        call<DIMSX, DIMSY, DIMSP>(fun,
                                  xi,
                                  yjrel,
                                  param_loc); // Call the function, which outputs results in xi[0:DIMX1]
#if SUM_SCHEME == BLOCK_SUM
#if USE_HALF
        int ind = jrel + tile * blockDim.x;
        typename FUN::template ReducePairShort<TYPE,TYPE>()(tmp, xi, __floats2half2_rn(2*ind,2*ind+1));     // tmp += xi
#else
        typename FUN::template ReducePairShort<TYPE,TYPE>()(tmp, xi, jrel + tile * blockDim.x);     // tmp += xi
#endif
#elif SUM_SCHEME == KAHAN_SCHEME
        typename FUN::template KahanScheme<__TYPEACC__,TYPE>()(acc, xi, tmp);     
#else
#if USE_HALF
        int ind = jrel + tile * blockDim.x;
        typename FUN::template ReducePairShort<__TYPEACC__,TYPE>()(acc, xi, __floats2half2_rn(2*ind,2*ind+1));     // acc += xi
#else
	typename FUN::template ReducePairShort<__TYPEACC__,TYPE>()(acc, xi, jrel + tile * blockDim.x);     // acc += xi
#endif
#endif
      }
#if SUM_SCHEME == BLOCK_SUM
      typename FUN::template ReducePair<__TYPEACC__,TYPE>()(acc, tmp);     // acc += tmp
#endif
    }
    __syncthreads();
  }
  if (i < nx) {
    typename FUN::template FinalizeOutput<__TYPEACC__,TYPE>()(acc, px[0] + i * DIMOUT, px, i);
  }

}


struct GpuConv1D_FromHost {

  template<typename TYPE, class FUN>
  static int Eval_(FUN fun, int nx, int ny, TYPE **px_h, TYPE **py_h, TYPE **pp_h) {

    typedef typename FUN::DIMSX DIMSX;
    typedef typename FUN::DIMSY DIMSY;
    typedef typename FUN::DIMSP DIMSP;
    const int DIMX = DIMSX::SUM;
    const int DIMY = DIMSY::SUM;
    const int DIMP = DIMSP::SUM;
    const int DIMOUT = FUN::DIM; // dimension of output variable
    const int DIMFOUT = DIMSX::FIRST;     // DIMFOUT is dimension of output variable of inner function
    const int SIZEI = DIMSX::SIZE;
    const int SIZEJ = DIMSY::SIZE;
    const int SIZEP = DIMSP::SIZE;

    // pointers to device data
    TYPE *x_d, *y_d, *param_d;

    // device arrays of pointers to device data
    TYPE **px_d, **py_d, **pp_d;

    // single cudaMalloc
    void **p_data;
    CudaSafeCall(cudaMalloc((void **) &p_data,
                            sizeof(TYPE *) * (SIZEI + SIZEJ + SIZEP)
                                + sizeof(TYPE) * (DIMP + nx * (DIMX - DIMFOUT + DIMOUT) + ny * DIMY)));

    TYPE **p_data_a = (TYPE **) p_data;
    px_d = p_data_a;
    p_data_a += SIZEI;
    py_d = p_data_a;
    p_data_a += SIZEJ;
    pp_d = p_data_a;
    p_data_a += SIZEP;
    TYPE *p_data_b = (TYPE *) p_data_a;
    param_d = p_data_b;
    p_data_b += DIMP;
    x_d = p_data_b;
    p_data_b += nx * (DIMX - DIMFOUT + DIMOUT);
    y_d = p_data_b;

    // host arrays of pointers to device data
    TYPE *phx_d[SIZEI];
    TYPE *phy_d[SIZEJ];
    TYPE *php_d[SIZEP];

    int nvals;
    // if DIMSP is empty (i.e. no parameter), nvals = -1 which could result in a segfault
    if (SIZEP > 0) {
      php_d[0] = param_d;
      nvals = DIMSP::VAL(0);
      CudaSafeCall(cudaMemcpy(php_d[0], pp_h[0], sizeof(TYPE) * nvals, cudaMemcpyHostToDevice));

      for (int k = 1; k < SIZEP; k++) {
        php_d[k] = php_d[k - 1] + nvals;
        nvals = DIMSP::VAL(k);
        CudaSafeCall(cudaMemcpy(php_d[k], pp_h[k], sizeof(TYPE) * nvals, cudaMemcpyHostToDevice));
      }
    }

    phx_d[0] = x_d;
    nvals = nx * DIMOUT;
    for (int k = 1; k < SIZEI; k++) {
      phx_d[k] = phx_d[k - 1] + nvals;
      nvals = nx * DIMSX::VAL(k);
      CudaSafeCall(cudaMemcpy(phx_d[k], px_h[k], sizeof(TYPE) * nvals, cudaMemcpyHostToDevice));
    }

    // if DIMSY is empty (i.e. no Vj variable), nvals = -1 which could result in a segfault
    if (SIZEJ > 0) {
      phy_d[0] = y_d;
      nvals = ny * DIMSY::VAL(0);
      CudaSafeCall(cudaMemcpy(phy_d[0], py_h[0], sizeof(TYPE) * nvals, cudaMemcpyHostToDevice));

      for (int k = 1; k < SIZEJ; k++) {
        phy_d[k] = phy_d[k - 1] + nvals;
        nvals = ny * (int) DIMSY::VAL(k);
        CudaSafeCall(cudaMemcpy(phy_d[k], py_h[k], sizeof(TYPE) * nvals, cudaMemcpyHostToDevice));
      }
    }

    // copy arrays of pointers
    CudaSafeCall(cudaMemcpy(pp_d, php_d, SIZEP * sizeof(TYPE *), cudaMemcpyHostToDevice));
    CudaSafeCall(cudaMemcpy(px_d, phx_d, SIZEI * sizeof(TYPE *), cudaMemcpyHostToDevice));
    CudaSafeCall(cudaMemcpy(py_d, phy_d, SIZEJ * sizeof(TYPE *), cudaMemcpyHostToDevice));

    // Compute on device : grid and block are both 1d
    int dev = -1;
    CudaSafeCall(cudaGetDevice(&dev));

    dim3 blockSize;

    SetGpuProps(dev);

#if ENABLECHUNK // register pressure case...
      blockSize.x = CUDA_BLOCK_SIZE_CHUNKS;
#else
	  // warning : blockSize.x was previously set to CUDA_BLOCK_SIZE; currently CUDA_BLOCK_SIZE value is used as a bound.
      blockSize.x = ::std::min(CUDA_BLOCK_SIZE,
                             ::std::min(maxThreadsPerBlock,
                                        (int) (sharedMemPerBlock / ::std::max(1,
                                                                              (int) (  DIMY
                                                                                  * sizeof(TYPE)))))); // number of threads in each block
#endif
    dim3 gridSize;
    gridSize.x = nx / blockSize.x + (nx % blockSize.x == 0 ? 0 : 1);

#if ENABLECHUNK
      GpuConv1DOnDevice_Chunks<TYPE> 
		  <<< gridSize, blockSize, blockSize.x * DIMCHUNK * sizeof(TYPE) >>> 
			  (fun, nx, ny, px_d, py_d, pp_d);
#else
      GpuConv1DOnDevice<TYPE> 
		  <<< gridSize, blockSize, blockSize.x * DIMY * sizeof(TYPE) >>> 
			  (fun, nx, ny, px_d, py_d, pp_d);
#endif

    // block until the device has completed
    CudaSafeCall(cudaDeviceSynchronize());
    CudaCheckError();

    // Send data from device to host.
    CudaSafeCall(cudaMemcpy(*px_h, x_d, sizeof(TYPE) * (nx * DIMOUT), cudaMemcpyDeviceToHost));

    // Free memory.
    CudaSafeCall(cudaFree(p_data));

    return 0;
  }

// and use getlist to enroll them into "pointers arrays" px and py.
  template<typename TYPE, class FUN, typename... Args>
  static int Eval(FUN fun, int nx, int ny, int device_id, TYPE *x1_h, Args... args) {

    if (device_id != -1)
      CudaSafeCall(cudaSetDevice(device_id));

    typedef typename FUN::VARSI VARSI;
    typedef typename FUN::VARSJ VARSJ;
    typedef typename FUN::VARSP VARSP;

    const int SIZEI = VARSI::SIZE + 1;
    const int SIZEJ = VARSJ::SIZE;
    const int SIZEP = VARSP::SIZE;

    using DIMSX = GetDims<VARSI>;
    using DIMSY = GetDims<VARSJ>;
    using DIMSP = GetDims<VARSP>;

    using INDSI = GetInds<VARSI>;
    using INDSJ = GetInds<VARSJ>;
    using INDSP = GetInds<VARSP>;

    TYPE *px_h[SIZEI];
    TYPE *py_h[SIZEJ];
    TYPE *pp_h[SIZEP];

    px_h[0] = x1_h;
    getlist<INDSI>(px_h + 1, args...);
    getlist<INDSJ>(py_h, args...);
    getlist<INDSP>(pp_h, args...);

    return Eval_(fun, nx, ny, px_h, py_h, pp_h);

  }

// same without the device_id argument
  template<typename TYPE, class FUN, typename... Args>
  static int Eval(FUN fun, int nx, int ny, TYPE *x1_h, Args... args) {
    return Eval(fun, nx, ny, -1, x1_h, args...);
  }

// Idem, but with args given as an array of arrays, instead of an explicit list of arrays
  template<typename TYPE, class FUN>
  static int Eval(FUN fun, int nx, int ny, TYPE *x1_h, TYPE **args, int device_id = -1) {

    // We set the GPU device on which computations will be performed
    if (device_id != -1)
      CudaSafeCall(cudaSetDevice(device_id));

    typedef typename FUN::VARSI VARSI;
    typedef typename FUN::VARSJ VARSJ;
    typedef typename FUN::VARSP VARSP;

    const int SIZEI = VARSI::SIZE + 1;
    const int SIZEJ = VARSJ::SIZE;
    const int SIZEP = VARSP::SIZE;

    using DIMSX = GetDims<VARSI>;
    using DIMSY = GetDims<VARSJ>;
    using DIMSP = GetDims<VARSP>;

    using INDSI = GetInds<VARSI>;
    using INDSJ = GetInds<VARSJ>;
    using INDSP = GetInds<VARSP>;

    TYPE *px_h[SIZEI];
    TYPE *py_h[SIZEJ];
    TYPE *pp_h[SIZEP];

    px_h[0] = x1_h;
    for (int i = 1; i < SIZEI; i++)
      px_h[i] = args[INDSI::VAL(i - 1)];
    for (int i = 0; i < SIZEJ; i++)
      py_h[i] = args[INDSJ::VAL(i)];
    for (int i = 0; i < SIZEP; i++)
      pp_h[i] = args[INDSP::VAL(i)];

    return Eval_(fun, nx, ny, px_h, py_h, pp_h);

  }

};

struct GpuConv1D_FromDevice {
  template<typename TYPE, class FUN>
  static int Eval_(FUN fun, int nx, int ny, TYPE **phx_d, TYPE **phy_d, TYPE **php_d) {

    typedef typename FUN::DIMSX DIMSX;
    typedef typename FUN::DIMSY DIMSY;
    typedef typename FUN::DIMSP DIMSP;
    const int SIZEI = DIMSX::SIZE;
    const int SIZEJ = DIMSY::SIZE;
    const int SIZEP = DIMSP::SIZE;

    // device arrays of pointers to device data
    TYPE **px_d, **py_d, **pp_d;

    // single cudaMalloc
    void **p_data;
    CudaSafeCall(cudaMalloc((void **) &p_data, sizeof(TYPE *) * (SIZEI + SIZEJ + SIZEP)));

    TYPE **p_data_a = (TYPE **) p_data;
    px_d = p_data_a;
    p_data_a += SIZEI;
    py_d = p_data_a;
    p_data_a += SIZEJ;
    pp_d = p_data_a;

    CudaSafeCall(cudaMemcpy(px_d, phx_d, SIZEI * sizeof(TYPE *), cudaMemcpyHostToDevice));
    CudaSafeCall(cudaMemcpy(py_d, phy_d, SIZEJ * sizeof(TYPE *), cudaMemcpyHostToDevice));
    CudaSafeCall(cudaMemcpy(pp_d, php_d, SIZEP * sizeof(TYPE *), cudaMemcpyHostToDevice));

    // Compute on device : grid and block are both 1d

    int dev = -1;
    CudaSafeCall(cudaGetDevice(&dev));

    SetGpuProps(dev);

    dim3 blockSize;
#if ENABLECHUNK  // register pressure case...
      blockSize.x = CUDA_BLOCK_SIZE_CHUNKS;
#else
      const int DIMY = DIMSY::SUM;
	  // warning : blockSize.x was previously set to CUDA_BLOCK_SIZE; currently CUDA_BLOCK_SIZE value is used as a bound.
      blockSize.x = ::std::min(CUDA_BLOCK_SIZE,
                             ::std::min(maxThreadsPerBlock,
                                        (int) (sharedMemPerBlock / ::std::max(1,
                                                                              (int) (  DIMY
                                                                                  * sizeof(TYPE)))))); // number of threads in each block
#endif
	
    dim3 gridSize;
    gridSize.x = nx / blockSize.x + (nx % blockSize.x == 0 ? 0 : 1);

#if ENABLECHUNK
      GpuConv1DOnDevice_Chunks<TYPE> 
		  <<< gridSize, blockSize, blockSize.x * DIMCHUNK * sizeof(TYPE) >>> 
			  (fun, nx, ny, px_d, py_d, pp_d);
#else
      GpuConv1DOnDevice<TYPE> <<< gridSize, blockSize, blockSize.x * DIMY * sizeof(TYPE) >>> 
		  (fun, nx, ny, px_d, py_d, pp_d);
#endif

    // block until the device has completed
    CudaSafeCall(cudaDeviceSynchronize());

    CudaCheckError();

    CudaSafeCall(cudaFree(p_data));

    return 0;
  }

// Same wrappers, but for data located on the device
  template<typename TYPE, class FUN, typename... Args>
  static int Eval(FUN fun, int nx, int ny, int device_id, TYPE *x1_d, Args... args) {

    // device_id is provided, so we set the GPU device accordingly
    // Warning : is has to be consistent with location of data
    CudaSafeCall(cudaSetDevice(device_id));

    typedef typename FUN::VARSI VARSI;
    typedef typename FUN::VARSJ VARSJ;
    typedef typename FUN::VARSP VARSP;

    const int SIZEI = VARSI::SIZE + 1;
    const int SIZEJ = VARSJ::SIZE;
    const int SIZEP = VARSP::SIZE;

    using DIMSX = GetDims<VARSI>;
    using DIMSY = GetDims<VARSJ>;
    using DIMSP = GetDims<VARSP>;

    using INDSI = GetInds<VARSI>;
    using INDSJ = GetInds<VARSJ>;
    using INDSP = GetInds<VARSP>;

    TYPE *phx_d[SIZEI];
    TYPE *phy_d[SIZEJ];
    TYPE *php_d[SIZEP];

    phx_d[0] = x1_d;

    getlist<INDSI>(phx_d + 1, args...);
    getlist<INDSJ>(phy_d, args...);
    getlist<INDSP>(php_d, args...);

    return Eval_(fun, nx, ny, phx_d, phy_d, php_d);

  }

// same without the device_id argument
  template<typename TYPE, class FUN, typename... Args>
  static int Eval(FUN fun, int nx, int ny, TYPE *x1_d, Args... args) {
    // We set the GPU device on which computations will be performed
    // to be the GPU on which data is located.
    // NB. we only check location of x1_d which is the output vector
    // so we assume that input data is on the same GPU
    // note : cudaPointerGetAttributes has a strange behaviour:
    // it looks like it makes a copy of the vector on the default GPU device (0) !!! 
    // So we prefer to avoid this and provide directly the device_id as input (first function above)
    cudaPointerAttributes attributes;
    CudaSafeCall(cudaPointerGetAttributes(&attributes, x1_d));
    return Eval(fun, nx, ny, attributes.device, x1_d, args...);
  }

  template<typename TYPE, class FUN>
  static int Eval(FUN fun, int nx, int ny, TYPE *x1_d, TYPE **args, int device_id = -1) {

    if (device_id == -1) {
      // We set the GPU device on which computations will be performed
      // to be the GPU on which data is located.
      // NB. we only check location of x1_d which is the output vector
      // so we assume that input data is on the same GPU
      // note : cudaPointerGetAttributes has a strange behaviour:
      // it looks like it makes a copy of the vector on the default GPU device (0) !!!
      // So we prefer to avoid this and provide directly the device_id as input (else statement below)
      cudaPointerAttributes attributes;
      CudaSafeCall(cudaPointerGetAttributes(&attributes, x1_d));
      CudaSafeCall(cudaSetDevice(attributes.device));
    } else // device_id is provided, so we use it. Warning : is has to be consistent with location of data
      CudaSafeCall(cudaSetDevice(device_id));

    typedef typename FUN::VARSI VARSI;
    typedef typename FUN::VARSJ VARSJ;
    typedef typename FUN::VARSP VARSP;

    const int SIZEI = VARSI::SIZE + 1;
    const int SIZEJ = VARSJ::SIZE;
    const int SIZEP = VARSP::SIZE;

    using DIMSX = GetDims<VARSI>;
    using DIMSY = GetDims<VARSJ>;
    using DIMSP = GetDims<VARSP>;

    using INDSI = GetInds<VARSI>;
    using INDSJ = GetInds<VARSJ>;
    using INDSP = GetInds<VARSP>;

    TYPE *px_d[SIZEI];
    TYPE *py_d[SIZEJ];
    TYPE *pp_d[SIZEP];

    px_d[0] = x1_d;
    for (int i = 1; i < SIZEI; i++)
      px_d[i] = args[INDSI::VAL(i - 1)];
    for (int i = 0; i < SIZEJ; i++)
      py_d[i] = args[INDSJ::VAL(i)];
    for (int i = 0; i < SIZEP; i++)
      pp_d[i] = args[INDSP::VAL(i)];

    return Eval_(fun, nx, ny, px_d, py_d, pp_d);

  }

};

}

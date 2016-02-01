#include <stdio.h>
#include <assert.h>

#include <cuda.h>
#include <cuda_runtime.h>

cudaDeviceProp deviceProps;

bool cuInit()
{
    bool    res     = true;
    int     device  = 0;

    cudaError_t err = cudaGetDevice( &device );

    if( err != cudaSuccess )
    {
        printf("%s\n", cudaGetErrorString(err));

        res = false;

        return res;
    }

    printf("  Device Count: %d\n", device+1 );

    for(int i = 0; i <= device; i++)
    {
        cudaGetDeviceProperties(&deviceProps, device);

        printf("  Device Number: %d\n", i);
        printf("  Device name: %s\n", deviceProps.name);

        printf("  Memory Clock Rate (KHz): %d\n", deviceProps.memoryClockRate);
        printf("  Memory Bus Width (bits): %d\n", deviceProps.memoryBusWidth );

        printf("  Peak Memory Bandwidth (GB/s): %f\n\n",
               2.0*deviceProps.memoryClockRate*(deviceProps.memoryBusWidth/8)/1.0e6);


        printf("  Max Threads per Block: %d\n", deviceProps.maxThreadsPerBlock );
    }

    // Select CUDA device
    cudaSetDevice(0);

    return res;
}

//******************************************************************************************************

// !!! Exemple DO NOT TOCH !!!!!
//__global__ void findMean(unsigned int dataForBlock, float *inputData, float *results)
//{
//    int index = blockIdx.x * blockDim.x + threadIdx.x;
//    float result = 0;

//    for (int i = 0; i < dataForBlock; i++)
//    {
//        result += inputData[index * dataForBlock + i];
//    }

//    result /= dataForBlock;
//    results[index] = result;
//}

//void processWithGPU(float *blocks, float *results, unsigned int blockSize, unsigned int blocksCount)
//{
//    unsigned int realDataCount = blockSize * blocksCount;

//    cudaSetDevice(0);

//    float   *deviceInputData,
//            *deviceResults;
//    cudaMalloc( (void**)&deviceInputData,  realDataCount * sizeof(float)   );
//    cudaMalloc( (void**)&deviceResults,    realDataCount * sizeof(float)   );

//    cudaMemcpy( deviceInputData, blocks, realDataCount * sizeof(float), cudaMemcpyHostToDevice );

//    findMean<<<1, blocksCount>>>( blockSize, deviceInputData, deviceResults );

//    cudaMemcpy( (void*)results, deviceResults, blocksCount * sizeof(float), cudaMemcpyDeviceToHost );

//    cudaFree(deviceInputData);
//    cudaFree(deviceResults  );
//}
//********************************************************************************************************
// Build Image
__global__ void cuBuildImageKernel( float* source, float* dest )
{
    int x       = blockIdx.x;
    int y       = blockIdx.y;

    int offset  = x + y * gridDim.x;

    float* s = source + ( y * (gridDim.x * 2 ) * 2 + x * 2);

	float t_[4], t_sume, t_result;
	// Save temp values
	t_[0] = s[0];
	t_[1] = s[1];
	t_[2] = s[	gridDim.x * 2];
	t_[3] = s[1+gridDim.x * 2];

	// Calculate sum
	t_sume = t_[0] + t_[1] + t_[2] + t_[3];

	// Calculate result
	t_result = t_sume * 0.25;


    dest[offset] = (	s[ 0 ] +
              			s[ 1 ] +
                     	s[ gridDim.x * 2 ]   +
                     	s[ gridDim.x * 2 + 1]   ) * 0.25f;
}

void cuBuildImage(  const float* source,    int sourceWidth,    int sourceHeight,
                    const float* dest,      int destWidth,      int destHeight      )
{

    int sourceBuffLength    = sourceWidth   * sourceHeight;
    int destBuffLength      = destWidth     * destHeight;

    // Reserving memory on GPU
    float   *sourceBuff,
            *destBuff;

    cudaMalloc( (void**)&sourceBuff,    sourceBuffLength  * sizeof(float)   );
    cudaMalloc( (void**)&destBuff,      destBuffLength    * sizeof(float)   );

    // Copy input buffer
    cudaMemcpy( sourceBuff, source,     sourceBuffLength  * sizeof(float), cudaMemcpyHostToDevice );

    dim3 grid( destWidth, destHeight );
    cuBuildImageKernel<<<grid, 1>>>( sourceBuff,  destBuff );

    cudaMemcpy( (void*)dest, destBuff,  destBuffLength * sizeof(float), cudaMemcpyDeviceToHost );

    cudaFree( sourceBuff );
    cudaFree( destBuff   );
}

//********************************************************************************************************
// Build Gradient
//__global__ void cuBuildGradientsKernel()
//{

//}

//void cuBuildGradients(const float* )
//{
//    const float*    img_pt      = data.image[level]     + width;
//    const float*    img_pt_max  = data.image[level]     + width * (height-1);
//    float*          gradxyii_pt = data.gradients[level] + width;

//    // in each iteration i need -1,0,p1,mw,pw
//    float val_m1 = *(img_pt-1);
//    float val_00 = * img_pt;
//    float val_p1;

//    for(; img_pt < img_pt_max; img_pt++, gradxyii_pt++)
//    {
//        val_p1 = *(img_pt+1);

//        *( (float*)gradxyii_pt +0)  = 0.5f*(val_p1 - val_m1);
//        *(((float*)gradxyii_pt)+1)  = 0.5f*(*(img_pt+width) - *(img_pt-width));
//        *(((float*)gradxyii_pt)+2)  = val_00;

//        val_m1 = val_00;
//        val_00 = val_p1;
//    }
//}

//********************************************************************************************************
// Build MaxGradient
//__global__ void cuBuildMaxGradientsKernel()
//{

//}

//void buildMaxGradients(int level)
//{

//    float* maxGradTemp = FrameMemory::getInstance().getFloatBuffer(width * height);

//    // 1. write abs gradients in real data.
//    Eigen::Vector4f* gradxyii_pt = data.gradients[level] + width;

//    float* maxgrad_pt       = data.maxGradients[level] + width;
//    float* maxgrad_pt_max   = data.maxGradients[level] + width*(height-1);

//    for(; maxgrad_pt < maxgrad_pt_max; maxgrad_pt++, gradxyii_pt++ )
//    {
//        float dx = *(  (float*)gradxyii_pt);
//        float dy = *(1+(float*)gradxyii_pt);
//        *maxgrad_pt = sqrtf(dx*dx + dy*dy);
//    }

//    // 2. smear up/down direction into temp buffer
//    maxgrad_pt      = data.maxGradients[level] + width+1;
//    maxgrad_pt_max  = data.maxGradients[level] + width*(height-1)-1;

//    float* maxgrad_t_pt = maxGradTemp + width+1;
//    for(;maxgrad_pt<maxgrad_pt_max; maxgrad_pt++, maxgrad_t_pt++ )
//    {
//        float g1 = maxgrad_pt[-width];
//        float g2 = maxgrad_pt[0];

//        if(g1 < g2)
//            g1 = g2;

//        float g3 = maxgrad_pt[width];

//        if(g1 < g3)
//            *maxgrad_t_pt = g3;
//        else
//            *maxgrad_t_pt = g1;
//    }

//    float numMappablePixels = 0;

//    // 2. smear left/right direction into real data
//    maxgrad_pt      = data.maxGradients[level] + width+1;
//    maxgrad_pt_max  = data.maxGradients[level] + width*(height-1)-1;
//    maxgrad_t_pt    = maxGradTemp + width+1;
//    for(;maxgrad_pt<maxgrad_pt_max; maxgrad_pt++, maxgrad_t_pt++ )
//    {
//        float g1 = maxgrad_t_pt[-1];
//        float g2 = maxgrad_t_pt[0];

//        if(g1 < g2)
//            g1 = g2;

//        float g3 = maxgrad_t_pt[1];
//        if(g1 < g3)
//        {
//            *maxgrad_pt = g3;
//            if(g3 >= MIN_ABS_GRAD_CREATE)
//                numMappablePixels++;
//        }
//        else
//        {
//            *maxgrad_pt = g1;
//            if(g1 >= MIN_ABS_GRAD_CREATE)
//                numMappablePixels++;
//        }
//    }

//    if(level==0)
//        this->numMappablePixels = numMappablePixels;

//    FrameMemory::getInstance().returnBuffer(maxGradTemp);
//}
//********************************************************************************************************
//__global__ void cuBuildIDepthAndIDepthVarKernel()
//{

//}

//// Build IDepth And IDepth Var
//void buildIDepthAndIDepthVar( int level )
//{
//    int sw = data.width[level - 1];

//    const float* idepthSource       = data.idepth   [level - 1];
//    const float* idepthVarSource    = data.idepthVar[level - 1];

//    float* idepthDest       = data.idepth   [level];
//    float* idepthVarDest    = data.idepthVar[level];

//    for( int y = 0; y < height; y++ )
//    {
//        for( int x = 0; x < width; x++ )
//        {
//            int idx     = 2 * ( x + y * sw  );
//            int idxDest = ( x + y * width   );

//            float idepthSumsSum = 0;
//            float ivarSumsSum   = 0;
//            int   num           = 0;

//            // build sums
//            float ivar;
//            float var = idepthVarSource[idx];
//            if( var > 0 )
//            {
//                ivar             = 1.0f / var;
//                ivarSumsSum     += ivar;
//                idepthSumsSum   += ivar * idepthSource[idx];
//                num++;
//            }

//            var = idepthVarSource[ idx + 1 ];
//            if( var > 0 )
//            {
//                ivar             = 1.0f / var;
//                ivarSumsSum     += ivar;
//                idepthSumsSum   += ivar * idepthSource[ idx + 1 ];
//                num++;
//            }

//            var = idepthVarSource[ idx + sw ];
//            if( var > 0 )
//            {
//                ivar             = 1.0f / var;
//                ivarSumsSum     += ivar;
//                idepthSumsSum   += ivar * idepthSource[ idx + sw ];
//                num++;
//            }

//            var = idepthVarSource[ idx + sw + 1 ];
//            if( var > 0 )
//            {
//                ivar             = 1.0f / var;
//                ivarSumsSum     += ivar;
//                idepthSumsSum   += ivar * idepthSource[ idx + sw + 1 ];
//                num++;
//            }

//            if(num > 0)
//            {
//                float depth = ivarSumsSum / idepthSumsSum;

//                idepthDest   [ idxDest ] = 1.0f / depth;
//                idepthVarDest[ idxDest ] = num  / ivarSumsSum;
//            }
//            else
//            {
//                idepthDest   [ idxDest ] = -1;
//                idepthVarDest[ idxDest ] = -1;
//            }
//        }
//    }
//}

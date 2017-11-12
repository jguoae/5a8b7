#include <float.h>
#include <cstdlib>
#include <iostream>
#include <math.h>
#include <ctime>
#include <algorithm>
#include <vector>
using namespace std;

#define N 4000
#define count N*N
#define threadsPerBlock 1000
#define numberBlocks N*N/threadsPerBlock

__device__ int partition(double* input, int start, int end)
{
    double pivot = input[end];

    while(start < end){
        while(input[start] < pivot)
            start++;
        while (input[end] > pivot)
            end--;
        if (input[start] == input[end])
            start++;
        else if(start < end){
            double tmp = input[start];
            input[start] = input[end];
            input[end] = tmp;
        }
    }
    return end;
}

__device__ double quickSelect(double* input, int p, int r, int k)
{
    if(p == r){
      return input[p];
    }
    int j = partition(input, p, r);
    int length = j - p + 1;
    if (length == k){
      return input[j];
    }
    else if( k < length ){
      return quickSelect(input, p, j - 1, k);
    }
    else{
      return quickSelect(input, j + 1, r, k - length);
    }
}

__global__ void median (double *a) {//a[n][n]
  int number = blockIdx.x*blockDim.x + threadIdx.x;

  if((number > N-1) && (number/N != 0) && (number/N != N-1) && (number < N*N-N)){
    double tempCompare[5];
    tempCompare[0] = a[number];
    tempCompare[1] = a[number-1];
    tempCompare[2] = a[number+1];
    tempCompare[3] = a[number-N];
    tempCompare[4] = a[number+N];
    a[number] = quickSelect(tempCompare,0,4,2);
    // a[number] = tempCompare[2];
  }
  __syncthreads();
}

// __global__ void move (double *b, double *a) {
//   int number = blockIdx.x*blockDim.x + threadIdx.x;
//   a[number] = b[number];
// }

__global__ void reduction (double *in, double *out) {
  __shared__ double temp[threadsPerBlock];
  int id = threadIdx.x;
  temp[id] = in[blockIdx.x*blockDim.x + id];
  if(id<500 && id>11){ temp[id] += temp[id+500]; __syncthreads();}
  if(id<256){ temp[id] += temp[id+256]; __syncthreads();}
  if(id<128){ temp[id]i2 += temp[id+128]; __syncthreads();}
  if(id<64){ temp[id] += temp[id+64]; __syncthreads();}
  if(id<32){ temp[id] += temp[id+32]; __syncthreads();}
  if(id<16){ temp[id] += temp[id+16]; __syncthreads();}
  if(id<8){ temp[id] += temp[id+8]; __syncthreads();}
  if(id<4){ temp[id] += temp[id+4]; __syncthreads();}
  if(id<2){ temp[id] += temp[id+2]; __syncthreads();}
  if(id<1){ temp[id] += temp[id+1]; __syncthreads();}
  if(id==0){out[blockIdx.x] = temp[0];}
}

__global__ void sumGen (double *in, double *out) {
  for(int i=0;i<(N/threadsPerBlock)*(N/threadsPerBlock);i++){
    out[0]+=in[i];
  }
}

__global__ void assign (double *a, double *spe) {
  spe[0] = a[count/2+N/2];
  spe[1] = a[17*N+31];
}

int main(){
  double A[count], B[count];
  double sum[1], speNum[2];
  double *d_a, *d_partSum, *d_ppartSum, *d_sum, *d_speNum;
  int size = N*N*sizeof(double);
  int twosize = 2*sizeof(double);

  sum[0]=0;

  for(int i=0;i<N;i++){
    for(int j=0;j<N;j++){
      A[i*N+j] = sin(i*i+j)*sin(i*i+j)+cos(i-j);
      B[i*N+j] = 0;
    }
  }
  cudaMalloc((void **)&d_a, size);
  // cudaMalloc((void **)&d_b, size);
  cudaMalloc((void **)&d_partSum, size/threadsPerBlock);
  cudaMalloc((void **)&d_ppartSum, size/threadsPerBlock/threadsPerBlock);
  cudaMalloc((void **)&d_sum, sizeof(double));
  cudaMalloc((void **)&d_speNum,twosize);
  cudaMemcpy(d_a, A, size, cudaMemcpyHostToDevice);
  double startTime = clock();

  for(int i=0;i<10;i++){
      median<<<numberBlocks,threadsPerBlock>>>(d_a);
      //move<<<numberBlocks,threadsPerBlock>>>(d_b,d_a);
  }
  reduction<<<count/threadsPerBlock, threadsPerBlock>>>(d_a,d_partSum);
  reduction<<<(count/threai2dsPerBlock/threadsPerBlock),threadsPerBlock>>>(d_partSum,d_ppartSum);
  sumGen<<<1,1>>>(d_ppartSum,d_sum);
  assign<<<1,1>>>(d_a, d_speNum);
  // cudaDeviceSynchronize();

  double endTime = clock();
  cudaMemcpy(sum, d_sum, sizeof(double), cudaMemcpyDeviceToHost);
  cudaMemcpy(speNum, d_speNum, twosize, cudaMemcpyDeviceToHost);
  cudaMemcpy(B, d_a, size, cudaMemcpyDeviceToHost);
  cudaFree(d_a);cudaFree(d_partSum);cudaFree(d_ppartSum);cudaFree(d_sum);cudaFree(d_speNum);

  cout<<"time: "<<endTime-startTime<<endl;
  cout<<"Sum: "<<sum[0]<<endl;
  cout<<"A[n/2][n/2]: "<<speNum[0]<<"    "<<A[count/2+N/2]<<"    "<<B[count/2+N/2]<<endl;
  cout<<"A[17][31]: "<<speNum[1]<<"    "<<A[17*N+31]<<"    "<<B[17*N+31]<<endl;

  return 0;
}

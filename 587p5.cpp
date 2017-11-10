#include <float.h>
#include <cstdlib>
#include <iostream>
#include <math.h>
#include <ctime>
#include <algorithm>
using namespace std;

int static N = 1000;
int static threadsPerBlock = 1000;
int static numberBlocks = N^2/threadsPerBlock;

__global__ void median (double *a) {
  __shared__ double temp[N][N/numberBlocks+2];
  int gindexx = threadIdx.x;
  int gindexy = threadIdx.y + blockIdx.x * blockDim.y;
  int lindexx = threadIdx.x;
  int lindexy = threadIdx.y + 1;
  temp[lindexx][lindexy] = a[gindexx][gindexy];
  if(threadIdx.y==0){
    temp[lindexx][lindexy-1] = a[gindexx][gindexy-1];
    temp[lindexx][lindexy+N/numberBlocks] = [gindexx][gindexy+N/numberBlocks];
  }
  if(gindexx!=0&&gindexx!=N-1&&gindexy!=0&&gindexy!=N-1){
    double tempCompare[5];
    tempCompare[0] = temp[lindexx][lindexy];
    tempCompare[1] = temp[lindexx-1][lindexy];
    tempCompare[2] = temp[lindexx+1][lindexy];
    tempCompare[3] = temp[lindexx][lindexy-1];
    tempCompare[4] = temp[lindexx][lindexy+1];
    sort(begin(tempCompare),end(tempCompare));
    a[gindexx][gindexy] == tempCompare[2];
  };
  __syncthreads();
}

__global__ void partsum (double *a, double *partSum) {
  for (int i=0;i<N;i++){
    partSum[blockIdx.x]+=a[blockIdx.x][i];
  }
}

__global__ void sum (double *sum, double *partSum) {
  for (int i=0;i<N;i++){
    sum+=partSum[i];
  }
}

__global__ void numassign (double *a, double *mid, double *spe) {
    mid = a[N/2][N/2];
    spe = a[17][31];
}

int main{
  double A[N][N];
  double partSum[N];
  double *d_a, *d_partSum, *d_sum, *d_midNum, *d_speNum;
  double sum, midNum, speNum;
  int size = N*N*sizeof(double);
  int partSize = N*sizeof(double);
  dim3 dimBlock(N, threadsPerBlock/N);

  for(int i=0;i<n;i++){
    for(int j=0;j<n;j++){
      A[i][j] = sin(i^2+j)^2+cos(i-j);
    }
  }

  cudaMalloc((void **)&d_a, size);
  cudaMalloc((void **)&d_partSum, partSize);
  cudaMalloc((void **)&d_sum, sizeof(double));
  cudaMalloc((void **)&d_speNum, sizeof(double));
  cudaMalloc((void **)&d_midNum, sizeof(double));
  cudaMemcpy(d_a, &A, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_partSum, &partSum, partSize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_sum, &sum, sizeof(double), cudaMemcpyHostToDevice);
  cudaMemcpy(d_speNum, &speNum, sizeof(double), cudaMemcpyHostToDevice);
  cudaMemcpy(d_midNum, &midNum, sizeof(double), cudaMemcpyHostToDevice);
  double startTime = clock();

  for(int i=0;i<10;i++){
      median<<<numberBlocks,dimBlock>>>(d_a);
  }
  partsum<<<N,1>>>(d_a,d_partSum);
  sum<<<1,1>>>(d_sum,d_partsum);
  numassign<<<1,1>>>(d_a,d_midNum,d_speNum);

  double endTime = clock();
  cudaMemcpy(&A, d_a, size, cudaMemcpyDeviceToHost);
  cudaMemcpy(&partSum, d_partSum, partSize, cudaMemcpyDeviceToHost);
  cudaMemcpy(&sum, d_sum, sizeof(double), cudaMemcpyDeviceToHost);
  cudaMemcpy(&midNum, d_midNum, sizeof(double), cudaMemcpyDeviceToHost);
  cudaMemcpy(&speNum, d_speNum, sizeof(double), cudaMemcpyDeviceToHost);
  cudaFree(d_a);cudaFree(d_sum);cudaFree(d_speNum);cudaFree(d_midNum);cudaFree(d_partSum);
  cout<<"time: "<<endTime-startTime<<endl;
  cout<<"Sum: "<<sum<<endl;
  cout<<"A[n/2][n/2]: "<<midNum<<endl;
  cout<<"A[17][31]: "<<speNum<<endl;

  return 0;
}

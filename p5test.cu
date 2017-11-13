#include <cstdlib>
#include <iostream>
#include <math.h>
#include <ctime>
#include <vector>
using namespace std;

#define N 2000
#define count N*N
#define threadsPerBlock 1000
#define numberBlocks N*N/threadsPerBlock

// __device__ int partition(double* input, int start, int end)
// {
//     double pivot = input[end];
//
//     while(start < end){
//         while(input[start] < pivot)
//             start++;
//         while (input[end] > pivot)
//             end--;
//         if (input[start] == inpucout<<"time: "<<endTime<<"   "<<startTime<<"   "<<CLOCKS_PER_SEC<<endl;t[end])
//             start++;
//         else if(start < end){
//             double tmp = input[start];
//             input[start] = input[end];
//             input[end] = tmp;
//         }
//     }
//     return end;
// }
//
// __device__ double quickSelect(double* input, int p, int r, int k){
//     if(p == r){
//       return input[p];
//     }
//     int j = partition(input, p, r);
//     int length = j - p + 1;
//     if (length == k){
//       return input[j];
//     }cout<<"time: "<<endTime<<"   "<<startTime<<"   "<<CLOCKS_PER_SEC<<endl;
//     else if( k < length ){
//       return quickSelect(input, p, j - 1, k);
//     }
//     else{
//       return quickSelect(input, j + 1, r, k - length);
//     }
// }

__device__ void sort(double* input){
  for(int i=0;i<5;i++){
    for(int j=i;j<5;j++){
      if(input[j]<input[i]){
        double new_temp = input[i];
        input[i] = input[j];
        input[j] = new_temp;
      }
    }
  }
}

__global__ void median (double *a, double *b) {
  int number = blockIdx.x*blockDim.x + threadIdx.x;
  // if((number <N) || (number>=N*N-N)||(number/N==0)||(number/N==N-1)){
  //   b[number]=a[number];
  // }
  // if((number > N-1) && (threadIdx.x > 0) && (threadIdx.x < N-1) && (number < N*N-N)){
  if((number > N-1) && (number%N > 0) && (number%N < N-1) && (number < N*N-N)){
    double tempCompare[5];
    tempCompare[0] = a[number];
    tempCompare[1] = a[number-1];
    tempCompare[2] = a[number+1];
    tempCompare[3] = a[number-N];
    tempCompare[4] = a[number+N];
    // b[number] = quickSelect(tempCompare,0,4,2);
    // a[number] = tempCompare[2];
    sort(tempCompare);
    b[number]=tempCompare[2];
  }
  else if(number < N*N){
    b[number]=a[number];
  }
  __syncthreads();
}

__global__ void move (double *b, double *a) {
  int number = blockIdx.x*blockDim.x + threadIdx.x;
  a[number] = b[number];
}

__global__ void reduction (double *in, double *out) {
  __shared__ double temp[threadsPerBlock];
  int id = threadIdx.x;
  temp[id] = in[blockIdx.x*blockDim.x + id];
  __syncthreads();
  if(id<500 && id>11){
    temp[id] += temp[id+500]; __syncthreads();
  }
  __syncthreads();
  if(id<256){
    temp[id] += temp[id+256]; __syncthreads();
  }
  if(id<128){
    temp[id] += temp[id+128]; __syncthreads();
  }
  if(id<64){
    temp[id] += temp[id+64]; __syncthreads();
  }
  if(id<32){
    temp[id] += temp[id+32]; __syncthreads();
  }
  if(id<16){
    temp[id] += temp[id+16]; __syncthreads();
  }
  if(id<8){
    temp[id] += temp[id+8]; __syncthreads();
  }
  if(id<4){
    temp[id] += temp[id+4]; __syncthreads();
  }
  if(id<2){
    temp[id] += temp[id+2]; __syncthreads();
  }
  if(id<1){
    temp[id] += temp[id+1]; __syncthreads();
  }
  if(id<1){out[blockIdx.x] = temp[id];}
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
  double *d_a, *d_b, *d_partSum, *d_ppartSum, *d_sum, *d_speNum;
  int size = N*N*sizeof(double);
  int twosize = 2*sizeof(double);

  sum[0]=0;

  for(int i=0;i<N;i++){
    for(int j=0;j<N;j++){
      A[i*N+j] = sin(i*i+j)*sin(i*i+j)+cos(i-j);
      // A[i*N+j] = j;
      B[i*N+j] = 0;
    }
  }
  cudaMalloc((void **)&d_a, size);
  cudaMalloc((void **)&d_b, size);
  cudaMalloc((void **)&d_partSum, size/threadsPerBlock);
  cudaMalloc((void **)&d_ppartSum, size/threadsPerBlock/threadsPerBlock);
  cudaMalloc((void **)&d_sum, sizeof(double));
  cudaMalloc((void **)&d_speNum,twosize);
  cudaMemcpy(d_a, A, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_sum, sum, sizeof(double), cudaMemcpyHostToDevice);
  // clock_t startaaa = clock();
  cudaEvent_t startTime=0, endTime=0;
  cudaEventCreate(&startTime);
  cudaEventCreate(&endTime);
  // auto start = std::chrono::system_clock::now();
  cudaEventRecord(startTime, 0);
  for(int i=0;i<10;i++){
      median<<<numberBlocks,threadsPerBlock>>>(d_a,d_b);
      cudaDeviceSynchronize();
      move<<<numberBlocks,threadsPerBlock>>>(d_b,d_a);
      cudaDeviceSynchronize();
  }
  reduction<<<count/threadsPerBlock, threadsPerBlock>>>(d_a,d_partSum);
  reduction<<<(count/threadsPerBlock/threadsPerBlock),threadsPerBlock>>>(d_partSum,d_ppartSum);
  sumGen<<<1,1>>>(d_ppartSum,d_sum);
  assign<<<1,1>>>(d_a, d_speNum);
  cudaDeviceSynchronize();
  // clock_t endbbb = clock();
  cudaEventRecord(endTime, 0);
  cudaEventSynchronize(endTime) ;
  float time;
  cudaEventElapsedTime(&time,startTime,endTime);
  // auto end = std::chrono::system_clock::now();
  // std::chrono::duration<double> elapsed_seconds = end-start;

  cudaMemcpy(sum, d_sum, sizeof(double), cudaMemcpyDeviceToHost);
  cudaMemcpy(speNum, d_speNum, twosize, cudaMemcpyDeviceToHost);
  cudaMemcpy(B, d_a, size, cudaMemcpyDeviceToHost);
  cudaFree(d_a);cudaFree(d_b);cudaFree(d_partSum);cudaFree(d_ppartSum);cudaFree(d_sum);cudaFree(d_speNum);


  cout.precision(8);

  // cout<<"time: "<<endbbb<<"   "<<startaaa<<"   "<<CLOCKS_PER_SEC<<endl;
  // cout<<"time: "<<(endTime-startTime)/CLOCKS_PER_SEC<<endl;
  cout<<"time: "<<time<<endl;
  cout<<"Sum: "<<sum[0]<<endl;
  cout<<"A[n/2][n/2]: "<<speNum[0]<<"    "<<A[count/2+N/2]<<"    "<<B[count/2+N/2]<<endl;
  cout<<"A[17][31]: "<<speNum[1]<<"    "<<A[17*N+31]<<"    "<<B[17*N+31]<<endl;
  cout<<"A[999][999]: "<<A[999*N+999]<<"    "<<B[999*N+999]<<endl;
  cout<<"A[999][500]: "<<A[999*N+500]<<"    "<<B[999*N+500]<<endl;
  cout<<"A[500][999]: "<<A[500*N+999]<<"    "<<B[500*N+999]<<endl;
  cout<<"A[500][0]: "<<A[500*N]<<"    "<<B[500*N]<<endl;
  cout<<"A[501][0]: "<<A[501*N]<<"    "<<B[501*N]<<endl;

  return 0;
}

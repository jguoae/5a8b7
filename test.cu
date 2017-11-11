#include <math.h>
#include <cstdlib>
#include <iostream>
using namespace std;


#define N 512

__global__ void add(int *a, int *b, int *c) {

c[blockIdx.x] = a[blockIdx.x] + b[blockIdx.x];

}


int main(void) {

int a[N], b[N], c[N]; // host copies of a, b, c
int *d_a, *d_b, *d_c; // device copies of a, b, c
int size = N * sizeof(int);
for(int i=0;i<N;i++){
  a[i]=1;
  b[i]=1;
}

// Alloc space for device copies of a, b, c
cudaMalloc((void **)&d_a, size);
cudaMalloc((void **)&d_b, size);
cudaMalloc((void **)&d_c, size);
// Alloc space for host copies of a, b, c and setup input values


cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);
cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice);
// Launch add() kernel on GPU with N blocks
add<<<N,1>>>(d_a, d_b, d_c);
// Copy result back to host
cudaMemcpy(c, d_c, size, cudaMemcpyDeviceToHost);
// Cleanup
cudaFree(d_a); cudaFree(d_b); cudaFree(d_c);
cout<<c[0]<<endl;
return 0;

}

#include <mpi.h>
#include <iomanip>
#include <cstdlib>
#include <iostream>
#include <math.h>
#include "f.h"
using namespace std;

main (int argc, char **argv)
{
  if(argc != 2){
    cout << "Error, please specify the size of the matrix"<< argc << endl;
    exit(1);
  }

  MPI_Status status;
  MPI_Init (&argc, &argv);
  int rank,p,row,column,temp,side;
  bool mark;
  long long sum,middle_value;
  int n = atoi(argv[1]);

  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &p);
  temp = sqrt(p);
  row = rank/temp;
  column = rank%temp;
  side = n/temp;
  long long A [side][side];
  long long B [side];
  long long C [side];
  for(int i, i<side-1, i++){
      for(int j, j<side-1, j++){
        A[i][j] = row*side+i+(column*side+j)*n;
      }
  } //init

  MPI_Barrier(MPI_COMM_WORLD);
  int start_time = MPI_Wtime();

  for(int m, m<9, m++){
    for(int p, p<side-1, p++){
      B[p] = A[p][0];
    }
    if(column != 0){
      MPI_SEND(&B,side,long long,rank-1,1,MPI_COMM_WORLD);
    }
    if(column != temp-1){
      MPI_RECEIVE(&C,side,long long,rank+1,1,MPI_COMM_WORLD);
      for(int q=0, q<side-1, q++){
        A[q][side] = C[q];
      }
    }
    if(row != 0){
      MPI_SEND(&A[0],side,long long,rank-temp,1,MPI_COMM_WORLD);
    }
    if(row != temp-1){
      MPI_RECEIVE(&A[side],side,long long,rank+temp,1,MPI_COMM_WORLD);
    }
    if(row != 0 && column != 0){
      MPI_SEND(&A[0][0],1,long long,rank-temp,1,MPI_COMM_WORLD);
    }
    if(row != temp-1 && column != temp-1){
      MPI_RECEIVE(&A[side][side],1,long long,rank-temp,1,MPI_COMM_WORLD);
    }
    for(int x, x<side-1, x++){
      for(int y, y<side-1, y++){
        if(row==0 && x==0){}
        else if(column==0 && y==0){}
        else if(row==side-1 && x>=n-side*row){}
        else if(column==side-1 && y>=n-side*row){}
        else{
          A[x][y] = f(A[x][y],A[x+1][y],A[x][y+1],A[x+1][y+1]);
        }
      }
    }
  }//itearationsmessage

  for(int i, i<side-1, i++){
    for(int j, j<side-1, j++){
      sum += A[i][j];
      if(row*side+i==n/2 && column*side+j==n/2 ){
        mark=1;
        middle_value = A[i][j];
      }
    }
  }
  if(rank!=0){
    MPI_SEND(&sum,1,long long,0,1,MPI_COMM_WORLD);
    if(mark){
      MPI_SEND(&middle_value,1,long long,0,1,MPI_COMM_WORLD);
    }
  }
  else{
    long long sum_received;
    int mid_proc;
    mid_proc=(!n/temp)?(p+temp)/2,(p-temp)/2-1;
    MPI_RECEIVE(&middle_value,1,long long,mid_proc,1,MPI_COMM_WORLD);
    for(int i=1, i<p, i++){
      MPI_RECEIVE(&sum_received,1,long long,i,1,MPI_COMM_WORLD);
      sum+=sum_received;
    }
  }
  MPI_Barrier(MPI_COMM_WORLD);
  if(rank==0){
    int end_time = MPI_WTime();
    std::cout << "/*Time*/" << end_time-start_time << std::endl;
    std::cout << "/* Sum */" << sum << std::endl;
    std::cout << "/* Middle value */" << middle_value << std::endl;
  }

  MPI_Finalize();
  return 0;
}

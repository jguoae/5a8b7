#include <float.h>
#include <cstdlib>
#include <iostream>
#include <math.h>
#include <omp.h>
#include <stack>
#include <queue>
#include "g.h"
using namespace std;

//parameters
double a = 1;
double b = 100;
double epi = 0.000001;
int s = 12;


int main(){
  //initialize
  double M=max(g(a),g(b));
  double start, end, time_consumed;
  double c,d,N;
  int count = 0;
  queue <pair<double, double> > bfs;
  omp_lock_t lock;

  bfs.push(make_pair(a,b));
  start = omp_get_wtime();
  omp_init_lock(&lock);

  #pragma omp parallel private(c,d,N)
  {
    for(;;){
      omp_set_lock(&lock);
      if(bfs.empty()&&count==0){
        omp_unset_lock(&lock);
        break;
      }
      if(!bfs.empty()){
        // cout<<count<<dfs.size()<<"\n";
        c = bfs.front().first;
        d = bfs.front().second;
        N=M;
        count++;
        bfs.pop();
        omp_unset_lock(&lock);
        double result_c = g(c);
        double result_d = g(d);
        double mid_value = (c+d)/2.0;
        N = max(N,result_c);
        N = max(N,result_d);
        double result = (result_c + result_d + s*(d - c))/2.0;
        if(result <= N+epi){
          omp_set_lock(&lock);
          count--;
          M=N;
          omp_unset_lock(&lock);
        }
        else{
          omp_set_lock(&lock);
          M=N;
          bfs.push(make_pair(c,mid_value));
          bfs.push(make_pair(mid_value,d));
          count--;
          omp_unset_lock(&lock);
        }
      }
      else{
        omp_unset_lock(&lock);
      }
    }
  }
  end = omp_get_wtime();
  time_consumed = end - start;
  cout<< "Time: " << time_consumed <<endl;
  cout<< "Max :" << M <<endl;
  return 0;
}

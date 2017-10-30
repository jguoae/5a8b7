#include <float.h>
#include <cstdlib>
#include <iostream>
#include <math.h>
#include <omp.h>
#include <stack>
#include "g.h"
using namespace std;

//parameters
double a = 1;
double b = 100;
double epi = 0.000001;
int s = 12;

class node {
public:
  double firstvalue;
  double secondvalue;
  double g_f;
  double g_s;

  void setvalue(double,double,double,double);
};

void node::setvalue(double x, double y, double gx, double gy){
  firstvalue=x;
  secondvalue=y;
  g_f=gx;
  g_s=gy;
}

node new_node(double x, double y, double gx, double gy){
  node temp;
  temp.setvalue(x,y,gx,gy);
  return temp;
}

int main(){
  //initialize
  double M=max(g(a),g(b));
  double start, end, time_consumed;
  double c,d,N;
  int count = 0;
  stack < node > dfs;
  omp_lock_t lock;

  dfs.push(new_node(a,b,g(a),g(b)));
  start = omp_get_wtime();
  omp_init_lock(&lock);

  #pragma omp parallel private(c,d,N)
  {
    for(;;){
      omp_set_lock(&lock);
      if(dfs.empty()&&count==0){
        omp_unset_lock(&lock);
        break;
      }
      if(!dfs.empty()){
        // cout<<count<<dfs.size()<<"\n";
        c = dfs.top().firstvalue;
        d = dfs.top().secondvalue;
        double gc = dfs.top().g_f;
        double gd = dfs.top().g_s;
        N=M;
        count++;
        dfs.pop();
        omp_unset_lock(&lock);
        double result_c,result_d;
        if(gc!=100) {
          result_c = gc;
        } else{
          result_c = g(c);
        }
        if(gd!=100) {
          result_d = gd;
        } else{
          result_d = g(d);
        }
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
          dfs.push(new_node(c,mid_value,result_c,100));
          dfs.push(new_node(mid_value,d,100,result_d));
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

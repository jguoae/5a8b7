#!/bin/bash
#SBATCH -N 2 
#SBATCH -p RM
#SBATCH --ntasks-per-node 28
#SBATCH -t 00:05:00
# echo commands to stdout•set -x
# run OpenMP program
export OMP_NUM_THREADS=56
./587p4.out

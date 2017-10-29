#!/bin/bash
#SBATCH -N 1
#SBATCH -p RM
#SBATCH --ntasks-per-node 2
#SBATCH -t 00:05:00
# echo commands to stdout•set -x
# run OpenMP program
export OMP_NUM_THREADS=2
./587p4.out

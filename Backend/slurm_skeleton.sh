#!/bin/bash
#SBATCH --job-name="JOB_NAME"
#SBATCH --output="JOB_NAME.%j.%N.out"
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --export=ALL
#SBATCH -t 01:30:00


#!/usr/bin/env python3

import netCDF4, os, sys, numpy as np, argparse
################################################################################
################################################################################
# nccmp.py: A simple python-based NetCDF comparison tool that assumes the two 
# filesbeing compared have the same variables and dimensions. It computes the 
# relative 2-norm, relative infinity-norm, and maximum value of the absolute 
# difference b/t the two files for every variables that is of float type.
# 
# To create a conda environment for this script:
# conda create --name crm_test_env --channel conda-forge netcdf4 numpy
#
# Usage:
# python nccmp.py file1.nc file2.nc
#
################################################################################
################################################################################

parser = argparse.ArgumentParser('NetCDF Norm Comparison')

parser.add_argument('--source', '-s', type=str, help='Source file for comparison')
parser.add_argument('--target', '-t', type=str, help='Target file for comparison')
parser.add_argument('--linf', '-li', type=float, default=1e-10, help='Normalized L-infinity tolerance')
parser.add_argument('--l2', '-l2', type=float, default=1e-10, help='Normalized L2 tolerance')

arguments = parser.parse_args()

source = arguments.source
target = arguments.target
linf_tol = arguments.linf
l2_tol = arguments.l2

# Complain if there aren't two arguments
if not os.path.exists(source):
  print(f"Error: Unable to find file {source}")
  sys.exit(1)

if not os.path.exists(target):
  print(f"Error: Unable to find file {target}")
  sys.exit(1)

# Open the two files
nc1 = netCDF4.Dataset(source)
nc2 = netCDF4.Dataset(target)

# Print column header
print(f"{'Var Name':<20}:  {'rel 2-norm':<20}  {'rel inf-norm':<20}  {'avg abs':<20}  {'max abs':<20}")

error = False
error_msg = f'All variables within relative 2-norm limit of {l2_tol}, and relative infinity-norm limit of {linf_tol}'

################################################################################
#Loop through all variables
################################################################################
print(nc1.variables.keys())

for v in nc1.variables.keys() :

  # Only compare floats
  if (nc2.variables[v].dtype == np.float64 or nc2.variables[v].dtype == np.float32) :
    
    # Grab the variables
    a1 = nc1.variables[v][:]
    a2 = nc2.variables[v][:]
    
    # Compute the absolute difference vector
    adiff = abs(a2-a1)

    # Compute the 2-norm and a normalization term (Only apply if non-zero)
    norm2 = np.sum( adiff**2 )
    norm2_denom = np.sum( a1**2 )
    if (norm2_denom != 0) : norm2 = norm2 / norm2_denom

    # Compute the inf-norm and a normalization term (Only apply if non-zero)
    normi = np.amax( adiff )
    normi_denom = np.amax(a1) - np.amin(a1)
    if (normi_denom != 0) : normi = normi / normi_denom

    # Compute the maximum absolute difference
    max_abs_err = np.amax( adiff )
    avg_abs_err = np.mean( adiff )

    # if 'state' not in v: continue # only compare state vriables
    # if 'rad'   not in v: continue # only compare radiation variables

    # skip lines that are all zeros
    #if norm2==0 and normi==0 and avg_abs_err==0 and max_abs_err==0: continue

    # Print to terminal
    print(f'{v:<20}:  {norm2:20.10e}  {normi:20.10e}  {avg_abs_err:20.10e}  {max_abs_err:20.10e}')

    if norm2 > l2_tol:
        error = True
        error_msg = f'Error: Variable {v} relative 2-norm {norm2} > {l2_tol}'

    if normi > linf_tol:
        error = True
        error_msg = f'Error: Variable {v} relative infinity-norm {normi} > {linf_tol}'


print(error_msg)
print('Failed' if error else 'Passed')
sys.exit(1 if error else 0)

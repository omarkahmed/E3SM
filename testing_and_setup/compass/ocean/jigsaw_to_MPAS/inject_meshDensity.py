#!/usr/bin/env python
# Simple script to inject mesh density onto a mesh
# example usage:
#   ./inject_meshDensity.py cellWidthVsLatLon.mat base_mesh.nc
# where:
#   cellWidthVsLatLon.mat is a matlab workspace file with cell width
#   base_mesh.nc is the mpas netcdf file where meshDensity is added
# Mark Petersen, 7/24/2018

from __future__ import absolute_import, division, print_function, \
    unicode_literals

import numpy as np
from scipy import interpolate
import netCDF4 as nc4
import scipy.io as sio
import sys


def inject_meshDensity(mat_filename, mesh_filename):
    print('Read cell width field from Matlab regular grid...')
    matData = sio.loadmat(mat_filename)
    # Add extra column in longitude to interpolate over the Date Line
    cellWidth = np.concatenate(
        (matData['cellWidth'], matData['cellWidth'][:, 0:1]), axis=1)
    LonPos = np.deg2rad(np.concatenate(
        (matData['lon'].T, matData['lon'].T[0:1] + 360)))
    LatPos = np.deg2rad(matData['lat'].T)
    # set max lat position to be exactly at North Pole to avoid interpolation
    # errors
    LatPos[np.argmax(LatPos)] = np.pi / 2.0
    minCellWidth = cellWidth.min()
    meshDensityVsLatLon = (minCellWidth / cellWidth)**4
    print('  minimum cell width in grid definition:', minCellWidth)
    print('  maximum cell width in grid definition:', cellWidth.max())

    LON, LAT = np.meshgrid(LonPos, LatPos)

    print('Open unstructured MPAS mesh file...')
    ds = nc4.Dataset(mesh_filename, 'r+')
    meshDensity = ds.variables['meshDensity']

    print('Preparing interpolation of meshDensity from lat/lon to mesh...')
    meshDensityInterp = interpolate.LinearNDInterpolator(
        np.vstack((LAT.ravel(), LON.ravel())).T, meshDensityVsLatLon.ravel())

    print('Interpolating and writing meshDensity...')
    meshDensity[:] = meshDensityInterp(
        np.vstack(
            (ds.variables['latCell'][:],
             np.mod(
                ds.variables['lonCell'][:] +
                np.pi,
                2 *
                np.pi) -
                np.pi)).T)

    ds.close()


if __name__ == "__main__":

    inject_meshDensity(mat_filename=sys.argv[1], mesh_filename=sys.argv[2])

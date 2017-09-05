#!/bin/bash

# enable debug verbose
# set -x

# print configurations for the build
spack config get compilers
spack config get config
spack config get packages

# the list of packages that we want to install
dev_packages=(
    	'openmpi'
	'mpich'
	'mvapich2'
	'spark'
	'armadillo'
	'boost'
	'darshan-runtime'
	'darshan-utils'
	'isl'
	'hadoop'
	'hdf5'
	'highfive'
	'hpctoolkit'
	'hpx5'
	'ior'
	'iozone'
	'netcdf'
	'octave'
	'ompss'
	'cuba'
	'qt'
	'qt-creator'
	'r'
	'raja'
	'random123'
	'zeromq'
	'swig'
	'llvm@4'
	'pgi'
	'intel-parallel-studio'
	'intel-mpi'
	'intel-tbb'
	'py-cython'
	'py-h5py'
	'py-ipython'
	'py-jupyter'
	'py-mpi4py'
	'py-nose'
	'py-numpy'
	'py-scipy'
	'py-setuptools'
	'py-six'
	'py-theano'
	'py-wheel'
	'singularity'
	#'allinea-forge'
	#'likwid'
)


# compilers on the viz cluster
compilers=(
"gcc"
#"intel"
# "pgi"
)


extra_opt="-v"

# for every compiler in the platform
for compiler in "${compilers[@]}"
do

    # build each package
    for package in "${dev_packages[@]}"
    do
        # spec is show just for information purpose
        spack spec $package %$compiler

        # install package
        spack install $extra_opt $package %$compiler

    done

done

# just list the packages at the end
spack find -v

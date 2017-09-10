#!/bin/bash

# enable debug verbose
set -x
set -e


################################ CLEANUP ################################
cd $WORKSPACE
rm -rf $WORKSPACE/* $HOME/.spack


########################## CLONE REPOSITORIES ############################
mkdir -p $WORKSPACE/SPACK_HOME
cd $WORKSPACE/SPACK_HOME
git clone https://github.com/pramodskumbhar/spack.git
git clone https://github.com/pramodskumbhar/spack-configs.git

export SPACK_ROOT=$WORKSPACE/SPACK_HOME/spack
export PATH=$SPACK_ROOT/bin:$PATH
source $SPACK_ROOT/share/spack/setup-env.sh


########################## USE STABLE BRANCHES ############################
cd $WORKSPACE/SPACK_HOME/spack
git checkout bbprh69

cd $WORKSPACE/SPACK_HOME/spack-configs
git checkout bbprh69

git clone ssh://bbpcode.epfl.ch/user/kumbhar/spack-licenses licenses
cp -r licenses $SPACK_ROOT/etc/spack/


######################### ARCH & DEFAULT COMPILERS ##########################
spack arch
spack compiler find


################################ MIRROR DIRECTORIES ################################
export COMPILERS_HOME=/gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/JENKINS_SPACK_HOME/compilers
mkdir -p $COMPILERS_HOME/extra/mirror
spack mirror add compiler_filesystem $COMPILERS_HOME/extra/mirror


################################ MIRROR COMPILERS ################################
packages_to_mirror=(
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@7.2.0'
    'llvm@4.0.1'
    'intel-parallel-studio@professional.2017.4'
)

for package in "${packages_to_mirror[@]}"
do
    spack mirror create -d $COMPILERS_HOME/extra/mirror --dependencies $package
done


############################## PGI COMPILER TARBALL #############################
mkdir -p  $COMPILERS_HOME/extra/mirror/pgi
cp /gpfs/bbp.cscs.ch/scratch/gss/bgq/kumbhar-adm/pgilinux-2017-174-x86_64.tar.gz $COMPILERS_HOME/extra/mirror/pgi/pgi-17.4.tar.gz


################################ SET COMPILERS CONFIG ################################
mkdir -p  $SPACK_ROOT/etc/spack/defaults/linux/
cp $WORKSPACE/SPACK_HOME/spack-configs/bbprh69/compilers.config.yaml $SPACK_ROOT/etc/spack/defaults/linux/config.yaml


################################ START COMPILERS INSTALLATION ################################
compilers=(
    'intel-parallel-studio@professional.2017.4'
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@7.2.0'
    'pgi+network+nvidia'
)

core_compiler='gcc@4'

for compiler in "${compilers[@]}"
do
    spack spec $compiler %$core_compiler
    spack install $compiler %$core_compiler
done

####################### LLVM NEEDS NEWER GCC ################################
spack compiler find `spack location --install-dir gcc@4.9.3`
spack install llvm@4.0.1 %gcc@4.9.3


################################ PERMISSIONS ################################
setfacl -R -m u:kumbhar-adm:rwx $COMPILERS_HOME/extra/mirror

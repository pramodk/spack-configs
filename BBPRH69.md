# Deploying Spack stack on BBP RH 6.9 #

These are brief instructions to deploy entire software stack on RH6.9 at BBP.


#### Clone Repositories

clone below repositories for Spack and Spack configurations:

```
mkdir -p $HOME/SPACK_HOME
cd $HOME/SPACK_HOME
git clone https://github.com/pramodskumbhar/spack.git
git clone https://github.com/pramodskumbhar/spack-configs.git
```

Add following to `.bashrc`

```
export SPACK_ROOT=$HOME/SPACK_HOME/spack
export PATH=$SPACK_ROOT/bin:$PATH
source $SPACK_ROOT/share/spack/setup-env.sh
```

Use stable branches that we continiously test for deploying entire stack:

```
cd $HOME/SPACK_HOME/spack
git checkout bbprh69

cd $HOME/SPACK_HOME/spack-configs.git
git checkout bbprh69
```

#### Software Licenses

Commercial softwares like `Intel`, `PGI` and `Allinea` need licenses. These are usually simple text files with license key or license server details. In Spack we can copy those licenses in following directory:

```
cp -r licenses $HOME/SPACK_HOME/spack/spack/etc/spack/
```

> Actual path on BBP IV : /gpfs/bbp.cscs.ch/home/kumbhar-adm/SPACK_HOME/licenses and the directory looks like

```
	$ tree
	.
	├── allinea-forge
	│   └── Licence
	├── intel
	│   └── license.lic
	└── pgi
		└── license.dat
```

Note that this is required only if you are installing licensed software components.

#### Adding Mirror [Optional]

Some software tarballs are very large and often time consuming to download (e.g. Intel Parallel Studio is about ~3 GB). In order to avoid download on every new installation we can create a mirror where softwares could be stored. You can check [spack mirror]() documentation for details and extra options. There are options to provide text file but we are simply adding softwares one-by-one:

```
mkdir -p $HOME/SPACK_HOME/install_home/mirror

packages_to_mirror=(
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@7.2.0'
    'llvm@4.0.1'
    'intel@17.0.0.1'
    'intel@16.0.0.1'
)

for package in "${packages_to_mirror[@]}"
do
    spack mirror create -d $HOME/SPACK_HOME/install_home/mirror --dependencies $package
done
```

Some softwares do need manual download from registered account (e.g. PGI compilers). Once you download them you can manually copy them to mirror directory as:

```
mkdir -p $HOME/SPACK_HOME/install_home/mirror/pgi
cp /gpfs/bbp.cscs.ch/apps/viz/tools/pgi/pgilinux-2017-177-x86_64.tar.gz $HOME/SPACK_HOME/install_home/mirror/pgi/pgi-17.7.tar.gz
```
> Note : For PGI compiler you can keep tarball in some local directory and invoke `spack install` from that same directory.

### Installing Compilers
By default Spack will find compilers available in `$PATH`. We can see available compilers using :

```
$ spack compilers
==> Available compilers
-- clang rhel6-x86_64 -------------------------------------------
clang@3.4.2

-- gcc rhel6-x86_64 ---------------------------------------------
gcc@4.4.7  gcc@3.4.6
```

These are default compilers installed on system. For software development we often need to install multiple compilers to meet requirements of different users. Also, compilers are expensive to install considering long build time. Often we don't need to reinstall compilers from scratch if there are other system/network related updates. One can delete entire software stack using `spack uninstall --all`. But in practive we want to preserve compiler installations and re-compile all other software stack. In this case it is good practice to install compilers in separate directory.

We can achieve this by using sample `config.yaml` with below settings:

```
config:
  install_tree: ~/SPACK_HOME/install_home/externals/install
```

We will copy the provided `config.yaml` for compilers installation:

```
rm -rf $HOME/.spack/linux/*
cp $HOME/SPACK_HOME/spack-configs/bbprh69/compilers.config.yaml ~/.spack/linux/config.yaml
```

We can now install all required compilers using Spack. Some compilers like `llvm` can't be compiled with old version of gcc (e.g. `llvm` required gcc version `>=4.8`). In this case we will first install newer `gcc` and then use it for `llvm` installation.

Here is sample script to achieve this:

```
compilers=(
    'pgi@17.7'
    'intel@17.0.0.1'
    'intel@16.0.0.1'
    'gcc@4.9.3'
    'gcc@5.3.0'
    'gcc@7.2.0'
)

core_compiler='gcc@4.4.7'

for compiler in "${compilers[@]}"
do
    spack spec $compiler %$core_compiler
    spack install -v $compiler %$core_compiler
done

# tell spack the location of new compiler
spack compiler find `spack location --install-dir gcc@4.9.3`

# install llvm with newer version of gcc
spack install llvm@4.0.1 %gcc@4.9.3
```

> Note : We are not using `packages.yaml` with system installed packages here. Some compilers do need latest `autoconf`, `automake` etc. and better to install those all dependencies from scratch. (e.g. for `gmp-6.1.2` we saw errors while installing with system packages).

Once all compilers are installed we want to generate `user-friendly` modules and not default ones like below:

```
----------------------------------------- /gpfs/bbp.cscs.ch/home/kumbhar-adm/SPACK_HOME/install_home/externals/tcl/linux-rhel6-x86_64 -----------------------------------------
autoconf-2.63-gcc-4.4.7-3nydg2s        gmp-6.1.2-gcc-4.4.7-qbnerqz            mpfr-3.1.5-gcc-4.4.7-qqtt2et           py-six-1.10.0-gcc-4.4.7-dviyzq5
autoconf-2.69-gcc-4.4.7-faqgymq        help2man-1.47.4-gcc-4.4.7-jrwlm4p      ncurses-6.0-gcc-4.4.7-4wkexyz          py-six-1.10.0-gcc-4.9.3-4o4hqmk
```

Copy below settings file and `re-generate` modules as:

```
cp $HOME/SPACK_HOME/spack-configs/bbprh69/compilers.modules.yaml ~/.spack/linux/modules.yaml
spack module refresh --yes-to-all --delete-tree --module-type tcl --yes-to-all
```

And now generated modules for compiler should be avaialble:

```
$ echo $MODULEPATH
/gpfs/bbp.cscs.ch/home/kumbhar-adm/SPACK_HOME/install_home/externals/tcl/linux-rhel6-x86_64

$ module avail

----------------------------------------- /gpfs/bbp.cscs.ch/home/kumbhar-adm/SPACK_HOME/install_home/externals/tcl/linux-rhel6-x86_64 -----------------------------------------
gcc-4.4.7/gcc-4.9.3      gcc-4.4.7/gcc-7.2.0      gcc-4.4.7/intel-17.0.0.1 gcc-4.9.3/llvm-4.0.1
gcc-4.4.7/gcc-5.3.0      gcc-4.4.7/intel-16.0.0.1 gcc-4.4.7/pgi-17.7
```
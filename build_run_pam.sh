#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#default=${SCRIPT_DIR}/../..
#REPO_HOME=${REPO_HOME:-${default}}
E3SM=${SCRIPT_DIR}/E3SM

export http_proxy=http://proxy-dmz.intel.com:912

export https_proxy=http://proxy-dmz.intel.com:912

GPU=1
MPI_RANKS=-1
OMP_THREADS=-1
HARDWARE=pvc
MPI_LIB=mpich
JOB=build
export E3SM_HOME=${PWD}
#export LIBHOME=/hpc-wl-automation/e3sm/libs/ubuntu-22.04/oneapi_2023.2_classic
#export LIBHOME=/nfs/site/home/omarahme/git-repos/applications.hpc.workloads.e3sm.pam/libs/oneapi-pnetcdf-ifort_mpich/20230917
export DATA_HOME=/hpc-wl-automation/e3sm/mmf/input

if [[ $1 == '-h' || $1 == '--help' || $1 == '-help' ]]; then
  echo "Run as follows:"
  echo "./build.sh [options]"
  echo
  echo "    -j <build|run|build_run>"
  echo "        job to execute (default: ${JOB})"
  echo
  echo "    -c <h100|a100|pvc|ats|spr|sprhbm>"
  echo "        hardware configuration to build for (default: ${HARDWARE})"
  echo
  echo "    -n <MPI ranks>"
  echo "        space delimited NCRMS to build for (default specific to hardware, i.e. 2 for PVC})"
  echo
  echo "    -o <OMP ranks>"
  echo "        space delimited NCRMS to build for (default is machine threads / MPI ranks)"
  echo
  echo "    -m <impi|mpich>"
  echo "        mpi configuration to use (default: ${MPI_LIB})"
  echo
  echo "    -b <build directory>"
  echo "        directory where program is built and run (default: ${E3SM_HOME})"
  echo
  echo "    -l <library directory>"
  echo "        directory for required library files (default: ${LIBHOME}"
  echo
  echo "    -i <input directory>"
  echo "        directory for required input files (default: ${DATA_HOME})"
  echo
  echo "    -d "
  echo "        Disable gpu (default: off)"
  echo
  echo
  exit 0
fi

# fetch input arguments, if any
while getopts "j:c:n:o:m:b:l:i:d" flag
do
  case "${flag}" in
    j) export JOB=${OPTARG};;
    c) export HARDWARE=${OPTARG};;
    n) export MPI_RANKS=${OPTARG};;
    o) export OMP_THREADS=${OPTARG};;
    m) export MPI_LIB=${OPTARG};;
    b) export E3SM_HOME=${OPTARG};;
    l) export LIBHOME=${OPTARG};;
    i) export DATA_HOME=${OPTARG};;
    d) export GPU=0;;
  esac
done

#echo "source ${SCRIPT_DIR}/config/${HARDWARE}_${MPI_LIB}.sh"
#source ${SCRIPT_DIR}/config/${HARDWARE}_${MPI_LIB}.sh

module purge
#module load cmake intel/oneapi/nightly intel-comp-rt intel/mpi-utils  -f intel/mpich
module load cmake intel/oneapi intel/dpl intel-nightly/20230615 intel-nightly/dpct/20230615 intel/mkl-nda/xmain-nightly/20230619 intel-comp-rt intel/mpi-utils  -f intel/mpich

#E3SM=${REPO_HOME}
RES=ne4pg2_ne4pg2
MACH=ortce
COMPSET=F2010-MMF2
COMPILER=oneapi-ifx
MAX_THREADS=112
if [[ ${GPU} == 1 ]]; then
  if [[ ${HARDWARE} =~ "100" ]]; then
    COMPILER="${COMPILER}-cuda"
    if [[ ${HARDWARE} =~ "a100" ]]; then
      MACH=ortce
      #-a100
    elif [[ ${HARDWARE} =~ "h100" ]]; then
      MACH=ortce
      #-h100
    fi
    if [[ ${MPI_RANKS} < 1 ]]; then
      MPI_RANKS=1
    fi
  elif [[ ${HARDWARE} =~ "pvc" || ${HARDWARE} =~ "ats" ]]; then
    #OMP_THREADS=1
    COMPILER="${COMPILER}gpu"
    if [[ ${MPI_RANKS} < 1 ]]; then
      MPI_RANKS=2
    fi
  else
    echo "Hardware has no GPU, disabling GPU in compile"
  fi
fi

if  [[ ${HARDWARE} =~ "icx" ]]; then
  if [[ ${MPI_RANKS} < 1 ]]; then
    MPI_RANKS=72
  fi
  MAX_THREADS=72
elif [[ ${HARDWARE} =~ "spr" ]]; then
  if [[ ${MPI_RANKS} < 1 ]]; then
    MPI_RANKS=112
  fi
  MAX_THREADS=112
elif [[ ${HARDWARE} =~ "milanx" ]]; then
  if [[ ${MPI_RANKS} < 1 ]]; then
    MPI_RANKS=128
  fi
  MAX_THREADS=128
fi

if [[ ${OMP_THREADS} < 1 ]]; then
  OMP_THREADS=$(( ${MAX_THREADS} / ${MPI_RANKS} ))
  OMP_THREADS=$(( ${OMP_THREADS} < 1 ? 1 : ${OMP_THREADS} ))
fi

PROJ=cli115
OUTPUT=${PWD}
export CASE=${COMPSET}_${MACH}_${HARDWARE}_${MPI_LIB}_${RES}_${COMPILER}_${MPI_RANKS}x${OMP_THREADS}

if [[ ${JOB} =~ "build" ]]; then
  newcase_command="${E3SM}/cime/scripts/create_newcase -case ${CASE} -compset ${COMPSET} -res ${RES} -mach ${MACH} -mpilib ${MPI_LIB} -compiler ${COMPILER} -project ${PROJ} --output-root ${OUTPUT} -pecount ${MPI_RANKS}x${OMP_THREADS} --handle-preexisting-dirs r"
  #ewcase_command="${E3SM}/cime/scripts/create_newcase -case ${CASE} -compset ${COMPSET} -res ${RES} -mach ${MACH} -mpilib ${MPI_LIB} -compiler ${COMPILER} -project ${PROJ} --output-root ${OUTPUT} --handle-preexisting-dirs r"
  echo "Executing: ${newcase_command}"
  ${newcase_command}
  cd $CASE
  ./xmlchange --append -id CAM_CONFIG_OPTS -val " -crm_dt 10 "
  ./xmlchange STOP_OPTION=ndays
  ./xmlchange STOP_N=1
  ./xmlchange REST_OPTION=never
  ./xmlchange REST_N=1
  ./xmlchange RESUBMIT=0
  ./xmlchange DEBUG=false
  ./xmlchange JOB_WALLCLOCK_TIME=02:00:00
  ./xmlchange CONTINUE_RUN=FALSE

  #cat > user_nl_eam << 'eof'
  # dt_tracer_factor=1
  # transport_alg=0
  # hypervis_subcycle_q=1
  #eof
  
  ./case.setup
  ./case.build
else
  cd ${CASE}
fi

if [[ ${JOB} =~ "run" ]]; then
  ./case.submit
fi

echo
echo ${CASE}

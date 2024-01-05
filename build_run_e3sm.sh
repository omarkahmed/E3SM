#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
E3SM_DIR=${SCRIPT_DIR}


GPU=1
MPI_RANKS=-1
OMP_THREADS=-1
HARDWARE=pvc
MPI_LIB=mpich
JOB=build_run
RUN=01
FORTRAN_COMPILER=ifx

if [[ $1 == '-h' || $1 == '--help' || $1 == '-help' ]]; then
  echo "Run as follows:"
  echo "./build.sh [options]"
  echo
  echo "    -j <build|run|build_run>"
  echo "        job to execute (default: ${JOB})"
  echo
  echo "    -c <pvc|spr>"
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
  echo "    -r <run label>"
  echo "        run label suffix (default: ${RUN})"
  echo
  echo "    -d "
  echo "        Disable gpu (default: off)"
  echo
  echo "    -f "
  echo "        Fortran compiler (default: ${FORTRAN_COMPILER}"
  echo
  echo
  exit 0
fi

# fetch input arguments, if any
while getopts "j:c:n:o:m:b:l:i:e:r:f:d" flag
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
    e) export E3SM_DIR=${OPTARG};;
    r) export RUN=${OPTARG};;
    f) export FORTRAN_COMPILER=${OPTARG};;
    d) export GPU=0;;
  esac
done


E3SM=${E3SM_DIR}
RES=ne4pg2_ne4pg2
MACH=sunspot
COMPSET=F2010-MMF2
COMPILER=oneapi-${FORTRAN_COMPILER}
MAX_THREADS=104
if [[ ${GPU} == 1 ]]; then
  if [[ ${HARDWARE} =~ "pvc" ]]; then
    #OMP_THREADS=1
    COMPILER="${COMPILER}gpu"
    if [[ ${MPI_RANKS} < 1 ]]; then
      MPI_RANKS=1
    fi
  else
    echo "Hardware has no GPU, disabling GPU in compile"
  fi
fi

if [[ ${HARDWARE} =~ "spr" ]]; then
  if [[ ${MPI_RANKS} < 1 ]]; then
    MPI_RANKS=104
  fi
  MAX_THREADS=104
fi

if [[ ${OMP_THREADS} < 1 ]]; then
  OMP_THREADS=$(( ${MAX_THREADS} / ${MPI_RANKS} ))
  OMP_THREADS=$(( ${OMP_THREADS} < 1 ? 1 : ${OMP_THREADS} ))
fi


PROJ=cli115
OUTPUT=${PWD}
export CASE=${COMPSET}_${MACH}_${HARDWARE}_${MPI_LIB}_${RES}_${COMPILER}_${MPI_RANKS}x${OMP_THREADS}.${RUN}

if [[ ${JOB} =~ "build" ]]; then
newcase_command="${E3SM}/cime/scripts/create_newcase -case ${CASE} -compset ${COMPSET} -res ${RES} -mach ${MACH} -mpilib ${MPI_LIB} -compiler ${COMPILER} -project ${PROJ} --output-root ${OUTPUT} -pecount ${MPI_RANKS}x${OMP_THREADS} --handle-preexisting-dirs r"
echo "Executing: ${newcase_command}"
${newcase_command}
cd $CASE
#./xmlchange --append -file env_build.xml -id CAM_CONFIG_OPTS -val " -cppdefs '-D_OPENMP' "
./xmlchange --append -id CAM_CONFIG_OPTS -val " -crm_dt 10 "
./xmlchange STOP_OPTION=ndays
./xmlchange STOP_N=1
#./xmlchange REST_OPTION=never
#./xmlchange REST_N=1
#./xmlchange RESUBMIT=0
#./xmlchange DEBUG=false
#./xmlchange JOB_WALLCLOCK_TIME=02:00:00
#./xmlchange CONTINUE_RUN=FALSE

cat > user_nl_eam << 'eof'
 dt_tracer_factor=1
 transport_alg=0
 hypervis_subcycle_q=1
eof
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

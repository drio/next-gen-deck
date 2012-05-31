#!/bin/bash
#
set -e

full_path()
{
  local BAM=$1
  local b_dir=`dirname $BAM`
  local fn=`basename $BAM`
  local f_dir=`cd $b_dir; pwd`
  BAM="$f_dir/$fn"
  echo $BAM
}

usage()
{
  local msg=$1
  [ ".$msg" != "." ] && echo "ERROR: $1" >&2
(
  cat <<EOF
Usage: $0 -b <input_bam> -n <n_of_bams_to_generate> [ -p <n_of_pairs_per_bam> -h]
  -n <int  : number of bams to generate
  -p <int> : number of read pairs to put on each bam. ($DEF_N_PAIRS)
  -h       : help
EOF
) >&2
  exit 1
}

# Defaults
N_OF_PAIRS=10000
while getopts "b:n:p:h" opt
do
  case $opt in
    b)
      BAM=$(full_path $OPTARG)
      [ ".$BAM" == "." ] && usage "I need an input bam"
      ;;
    n)
      NUM=$OPTARG
      ;;
    p)
      N_OF_PAIRS=$OPTARG
      ;;
    h)
      usage
      ;;
    \?)
      usage "Invalid option: -$OPTARG"
      ;;
  esac
done

[ ! -f $BAM ] && usage "I cannot read the input bam: $BAM"
[ ".$NUM" == "." ] && usage "How many bams do you want me to generate?"

mkdir -p bams; cd bams
../../backend/rb/bin/simu_data $N_OF_PAIRS $BAM $NUM | bash

stats_bin=$(full_path ../../backend/c/ngd-stats)
for b in `find . -name "*.bam"`
do
  dir=`dirname $b`
  fn=`basename $b`
  seed=${fn%.*}
  cd $dir
  $stats_bin $seed $fn
  cd - >/dev/null
done

../../backend/rb/bin/load2redis

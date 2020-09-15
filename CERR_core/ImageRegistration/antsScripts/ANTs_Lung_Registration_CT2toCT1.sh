#!/bin/bash

VERSION="0.0.0 test"

# trap keyboard interrupt (control-c)
trap control_c SIGINT

function setPath {
    cat <<SETPATH

--------------------------------------------------------------------------------------
Error locating ANTS
--------------------------------------------------------------------------------------
It seems that the ANTSPATH environment variable is not set. Please add the ANTSPATH
variable. This can be achieved by editing the .bash_profile in the home directory.
Add:

ANTSPATH=/cygdrive/c/Sadegh/Jacobians/ANTs_Release

Or the correct location of the ANTS binaries.

Alternatively, edit this script ( `basename $0` ) to set up this parameter correctly.

SETPATH
    exit 1
}

# Uncomment the line below in case you have not set the ANTSPATH variable in your environment.
 export ANTSPATH=${ANTSPATH:="/cygdrive/c/Sadegh/Esophagus_art/ANTs_Release"} # EDIT THIS

#ANTSPATH=YOURANTSPATH
if [[ ${#ANTSPATH} -le 3 ]];
  then
    setPath >&2
  fi

ANTS=${ANTSPATH}/antsRegistration

if [[ ! -s ${ANTS} ]];
  then
    echo "antsRegistration program can't be found. Please (re)define \$ANTSPATH in your environment."
    exit
  fi

function Usage {
    cat <<USAGE

Usage:

`basename $0` -d ImageDimension -f FixedImage -m MovingImage -o OutputPrefix

Compulsory arguments:

     -d:  ImageDimension: 2 or 3 (for 2 or 3 dimensional registration of single volume)

     -f:  Fixed image(s) or source image(s) or reference image(s)

     -m:  Moving image(s) or target image(s)

     -o:  OutputPrefix: A prefix that is prepended to all output files.

Optional arguments:

     -n:  Number of threads (default = 1)

     -i:  initial transform(s) --- order specified on the command line matters

     -t:  transform type (default = 's')
        t: translation (1 stage)
        r: rigid (1 stage)
        a: rigid + affine (2 stages)
        s: rigid + affine + deformable syn (3 stages)
        sr: rigid + deformable syn (2 stages)
        so: deformable syn only (1 stage)
        b: rigid + affine + deformable b-spline syn (3 stages)
        br: rigid + deformable b-spline syn (2 stages)
        bo: deformable b-spline syn only (1 stage)

     -r:  histogram bins for mutual information in SyN stage (default = 32)

     -s:  spline distance for deformable B-spline SyN transform (default = 26)

     -x:  mask(s) for the fixed image space.  Should specify either a single image to be used for
          all stages or one should specify a mask image for each "stage" (cf -t option).  If
          no mask is to be used for a particular stage, the keyword 'NULL' should be used
          in place of a file name.

     -p:  precision type (default = 'd')
        f: float
        d: double

     -j:  use histogram matching (default = 0)
        0: false
        1: true

     -z:  collapse output transforms (default = 1)

     NB:  Multiple image pairs can be specified for registration during the SyN stage.
          Specify additional images using the '-m' and '-f' options.  Note that image
          pair correspondence is given by the order specified on the command line.
          Only the first fixed and moving image pair is used for the linear resgitration
          stages.

Example:

`basename $0` -d 3 -f fixedImage.nii.gz -m movingImage.nii.gz -o output

USAGE
    exit 1
}

function Help {
    cat <<HELP

Usage:

`basename $0` -d ImageDimension -f FixedImage -m MovingImage -o OutputPrefix

Example Case:

`basename $0` -d 3 -f fixedImage.nii.gz -m movingImage.nii.gz -o output

Compulsory arguments:

     -d:  ImageDimension: 2 or 3 (for 2 or 3 dimensional registration of single volume)

     -f:  Fixed image(s) or source image(s) or reference image(s)

     -m:  Moving image(s) or target image(s)

     -o:  OutputPrefix: A prefix that is prepended to all output files.

Optional arguments:

     -n:  Number of threads (default = 1)

     -i:  initial transform(s) --- order specified on the command line matters

     -t:  transform type (default = 's')
        t: translation (1 stage)
        r: rigid (1 stage)
        a: rigid + affine (2 stages)
        s: rigid + affine + deformable syn (3 stages)
        sr: rigid + deformable syn (2 stages)
        so: deformable syn only (1 stage)
        b: rigid + affine + deformable b-spline syn (3 stages)
        br: rigid + deformable b-spline syn (2 stages)
        bo: deformable b-spline syn only (1 stage)

     -r:  histogram bins for mutual information in SyN stage (default = 32)

     -s:  spline distance for deformable B-spline SyN transform (default = 26)

     -x:  mask(s) for the fixed image space.  Should specify either a single image to be used for
          all stages or one should specify a mask image for each "stage" (cf -t option).  If
          no mask is to be used for a particular stage, the keyword 'NULL' should be used
          in place of a file name.

     -p:  precision type (default = 'd')
        f: float
        d: double

     -j:  use histogram matching (default = 0)
        0: false
        1: true

     -z:  collapse output transforms (default = 1)

     NB:  Multiple image pairs can be specified for registration during the SyN stage.
          Specify additional images using the '-m' and '-f' options.  Note that image
          pair correspondence is given by the order specified on the command line.
          Only the first fixed and moving image pair is used for the linear resgitration
          stages.

HELP
    exit 1
}

function reportMappingParameters {
    cat <<REPORTMAPPINGPARAMETERS

--------------------------------------------------------------------------------------
 Mapping parameters
--------------------------------------------------------------------------------------
 ANTSPATH is $ANTSPATH

 Dimensionality:           $DIM
 Output name prefix:       $OUTPUTNAME
 Fixed images:             ${FIXEDIMAGES[@]}
 Moving images:            ${MOVINGIMAGES[@]}
 Mask images:              ${MASKIMAGES[@]}
 Initial transforms:       ${INITIALTRANSFORMS[@]}
 Number of threads:        $NUMBEROFTHREADS
 Spline distance:          $SPLINEDISTANCE
 Transform type:           $TRANSFORMTYPE
 MI histogram bins:        $NUMBEROFBINS
 Precision:                $PRECISIONTYPE
 Use histogram matching    $USEHISTOGRAMMATCHING
 ======================================================================================
REPORTMAPPINGPARAMETERS
}

cleanup()
{
  echo "\n*** Performing cleanup, please wait ***\n"

  runningANTSpids=$( ps --ppid $$ -o pid= )

  for thePID in $runningANTSpids
  do
      echo "killing:  ${thePID}"
      kill ${thePID}
  done

  return $?
}

control_c()
# run if user hits control-c
{
  echo -en "\n*** User pressed CTRL + C ***\n"
  cleanup
  exit $?
  echo -en "\n*** Script cancelled by user ***\n"
}

# Provide output for Help
if [[ "$1" == "-h" || $# -eq 0 ]];
  then
    Help >&2
  fi

#################
#
# default values
#
#################

DIM=3
FIXEDIMAGES=()
MOVINGIMAGES=()
FIXEDIMAGESLABEL=()
MOVINGIMAGESLABEL=()
INITIALTRANSFORMS=()
OUTPUTNAME=output
NUMBEROFTHREADS=1
SPLINEDISTANCE=26
TRANSFORMTYPE='s'
PRECISIONTYPE='d'
NUMBEROFBINS=32
MASKIMAGES=()
USEHISTOGRAMMATCHING=0
COLLAPSEOUTPUTTRANSFORMS=1
# reading command line arguments
while getopts "d:f:h:i:m:j:n:o:p:r:s:t:x:z:" OPT
  do
  case $OPT in
      h) #help
   Help
   exit 0
   ;;
      d)  # dimensions
   DIM=$OPTARG
   ;;
      x)  # inclusive mask
   MASKIMAGES[${#MASKIMAGES[@]}]=$OPTARG
   ;;
      f)  # fixed image
   FIXEDIMAGES[${#FIXEDIMAGES[@]}]=$OPTARG
   ;;
      j)  # histogram matching
   USEHISTOGRAMMATCHING=$OPTARG
   ;;
      m)  # moving image
   MOVINGIMAGES[${#MOVINGIMAGES[@]}]=$OPTARG
   ;;
      i)  # initial transform
   INITIALTRANSFORMS[${#INITIALTRANSFORMS[@]}]=$OPTARG
   ;;
      n)  # number of threads
   NUMBEROFTHREADS=$OPTARG
   ;;
      o) #output name prefix
   OUTPUTNAME=$OPTARG
   ;;
      p)  # precision type
   PRECISIONTYPE=$OPTARG
   ;;
      r)  # cc radius
   NUMBEROFBINS=$OPTARG
   ;;
      s)  # spline distance
   SPLINEDISTANCE=$OPTARG
   ;;
      t)  # transform type
   TRANSFORMTYPE=$OPTARG
   ;;
      z)  # collapse output transforms
   COLLAPSEOUTPUTTRANSFORMS=$OPTARG
   ;;
     \?) # getopts issues an error message
   echo "$USAGE" >&2
   exit 1
   ;;
  esac
done

###############################
#
# Check inputs
#
###############################
if [[ ${#FIXEDIMAGES[@]} -ne ${#MOVINGIMAGES[@]} ]];
  then
    echo "Number of fixed images is not equal to the number of moving images."
    exit 1
  fi

for(( i=0; i<${#FIXEDIMAGES[@]}; i++ ))
  do
    if [[ ! -f "${FIXEDIMAGES[$i]}" ]];
      then
        echo "Fixed image '${FIXEDIMAGES[$i]}' does not exist.  See usage: '$0 -h 1'"
        exit 1
      fi
    if [[ ! -f "${MOVINGIMAGES[$i]}" ]];
      then
        echo "Moving image '${MOVINGIMAGES[$i]}' does not exist.  See usage: '$0 -h 1'"
        exit 1
      fi
  done

##############################
#
# Mask stuff
#
##############################

NUMBEROFMASKIMAGES=${#MASKIMAGES[@]}

MASKCALL=""
if [[ ${#MASKIMAGES[@]} -gt 0 ]];
  then
    for (( i = 0; i < ${#MASKIMAGES[@]}; i++ ))
      do
        MASKCALL="${MASKCALL} -x [${MASKIMAGES[$i]}, NULL]"
      done
  fi

###############################
#
# Set number of threads
#
###############################

ORIGINALNUMBEROFTHREADS=${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS}
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NUMBEROFTHREADS
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

##############################
#
# Print out options
#
##############################

reportMappingParameters

##############################
#
# Infer the number of levels based on
# the size of the input fixed image.
#
##############################

ISLARGEIMAGE=0

SIZESTRING=$( ${ANTSPATH}/PrintHeader ${FIXEDIMAGES[0]} 2 )
SIZESTRING="${SIZESTRING%\\n}"
SIZE=( `echo $SIZESTRING | tr 'x' ' '` )

for (( i=0; i<${#SIZE[@]}; i++ ))
  do
    if [[ ${SIZE[$i]} -gt 256 ]];
      then
        ISLARGEIMAGE=0
        break
      fi
  done

##############################
#
# Construct mapping stages
#
##############################
#This is where you set no. of iterations, subsamplig resolution (shrinking factor) and subsequent smoothing sigma (can be vox or mm)
#1-e6 is minimum change in step size and 10 is the optimization max window size. (stopping criteria:if metric change was smaller than 1-e6 in 10 iterations, it stops)
#so setting smaller value for min change and larger value for max window size, supports more deformations but most of time this is enough. you can log the metric to see what is the best for this.

RIGIDCONVERGENCE="[500x400x250x0,1e-6,10]"
RIGIDSHRINKFACTORS="8x4x2x1"
RIGIDSMOOTHINGSIGMAS="3x2x1x0vox"

AFFINECONVERGENCE="[500x400x250x0,1e-6,10]"
AFFINESHRINKFACTORS="8x4x2x1"
AFFINESMOOTHINGSIGMAS="3x2x1x0vox"

# SYNCONVERGENCE="[100x70x40x0,1e-6,10]"
# SYNSHRINKFACTORS="8x4x2x1"
# SYNSMOOTHINGSIGMAS="3x2x1x0vox"
SYNCONVERGENCE="[400x200x100x50x0,1e-6,10]"
#SYNCONVERGENCE="[60x30x10x0,1e-6,10]"
#SYNSHRINKFACTORS="8x4x2x1"
SYNSHRINKFACTORS="8x6x4x2x1"
SYNSMOOTHINGSIGMAS="5x3x2x1x0vox"

if [[ $ISLARGEIMAGE -eq 1 ]];
  then
    RIGIDCONVERGENCE="[1000x500x250x0,1e-6,10]"
    RIGIDSHRINKFACTORS="12x8x4x2"
    RIGIDSMOOTHINGSIGMAS="4x3x2x1vox"

    AFFINECONVERGENCE="[1000x500x250x0,1e-6,10]"
    AFFINESHRINKFACTORS="12x8x4x2"
    AFFINESMOOTHINGSIGMAS="4x3x2x1vox"

    SYNCONVERGENCE="[100x100x70x50x0,1e-6,10]"
    SYNSHRINKFACTORS="10x6x4x2x1"
    SYNSMOOTHINGSIGMAS="5x3x2x1x0vox"
  fi

INITIALSTAGE="--initial-moving-transform [${FIXEDIMAGES[0]},${MOVINGIMAGES[0]},0]"

if [[ ${#INITIALTRANSFORMS[@]} -gt 0 ]];
  then
    INITIALSTAGE=""
    for(( i=0; i<${#INITIALTRANSFORMS[@]}; i++ ))
      do
        INITIALSTAGE="$INITIALSTAGE --initial-moving-transform ${INITIALTRANSFORMS[$i]}"
      done
  fi

tx=Rigid
if [[ $TRANSFORMTYPE == 't' ]] ; then
  tx=Translation
fi

RIGIDSTAGE="--transform ${tx}[0.1] \
            --metric MI[${FIXEDIMAGES[0]},${MOVINGIMAGES[0]},1,32,Regular,0.25] \
            --convergence $RIGIDCONVERGENCE \
            --shrink-factors $RIGIDSHRINKFACTORS \
            --smoothing-sigmas $RIGIDSMOOTHINGSIGMAS"

AFFINESTAGE="--transform Affine[0.5] \
             --metric CC[${FIXEDIMAGES[0]},${MOVINGIMAGES[0]},1,4,Regular,0.30] \
             --convergence $AFFINECONVERGENCE \
             --shrink-factors $AFFINESHRINKFACTORS \
             --smoothing-sigmas $AFFINESMOOTHINGSIGMAS"

SYNMETRICS=''

#Below is where you define the metrics. Please also try other metrics e.g. demons, TimeVaryingVelocityField etc.
#after Moving image, 1 is weight for the defiend metric in cost function, 4 is CC kernel size (the smaller more local), Regular is type od sampling to choose and 0.25 means pick 25% of the whole sampling.
#You can pick more sampling but computaiton time increases. If you are using masks then better to set to 1, because of smaller region.
for(( i=0; i<${#FIXEDIMAGES[@]}; i++ ))
  do
    #SYNMETRICS="$SYNMETRICS --metric MeanSquares[${FIXEDIMAGES[$i]},${MOVINGIMAGES[$i]},1,6,Regular,0.25]"
    SYNMETRICS="$SYNMETRICS --metric CC[${FIXEDIMAGES[$i]},${MOVINGIMAGES[$i]},1,4,Regular,0.25]"
    #SYNMETRICS="$SYNMETRICS --metric Mattes[${FIXEDIMAGES[$i]},${MOVINGIMAGES[$i]},1,${NUMBEROFBINS},Regular,0.25]"
  done
  
SYNSTAGE="${SYNMETRICS} \
          --convergence $SYNCONVERGENCE \
          --shrink-factors $SYNSHRINKFACTORS \
          --smoothing-sigmas $SYNSMOOTHINGSIGMAS"
          
if [[ $TRANSFORMTYPE == 'so' ]] || [[ $TRANSFORMTYPE == 'br' ]];
  then
    SYNCONVERGENCE="[80x70x20x0,1e-6,10]"
    SYNSHRINKFACTORS="8x4x2x1"
    SYNSMOOTHINGSIGMAS="3x2x1x0vox"
          SYNSTAGE="${SYNMETRICS} \
          --convergence $SYNCONVERGENCE \
          --shrink-factors $SYNSHRINKFACTORS \
          --smoothing-sigmas $SYNSMOOTHINGSIGMAS"
  fi

if [[ $TRANSFORMTYPE == 'b' ]] || [[ $TRANSFORMTYPE == 'br' ]] || [[ $TRANSFORMTYPE == 'bo' ]];
  then
    #0.3 is gradient step and the larger it is, it supports larger deformation, but too much could distort the image, specially the borders. 
    #Second parameter is implicit regularizer mesh size. I usually set it to 32 and it reduced by factor of 2 at each iteration. the larger it is
    #more global deformations are supported. But it also correlated to number of resolutions. if you have 4/5 resolutions, then 32 is too small, better use 64 or larger.
    #third and fourth parameters are total mesh size and bsplie order and don't need to be changed mostly.
    SYNSTAGE="--transform BSplineSyN[0.3,${SPLINEDISTANCE},0,3] \
             $SYNSTAGE"
  fi

if [[ $TRANSFORMTYPE == 's' ]] || [[ $TRANSFORMTYPE == 'sr' ]] || [[ $TRANSFORMTYPE == 'so' ]];
  then
    SYNSTAGE="--transform SyN[0.85,3,0] \
             $SYNSTAGE"
  fi

NUMBEROFREGISTRATIONSTAGES=0
STAGES=''
case "$TRANSFORMTYPE" in
"r" | "t")
  STAGES="$INITIALSTAGE $RIGIDSTAGE"
  NUMBEROFREGISTRATIONSTAGES=1
  ;;
"a")
  STAGES="$INITIALSTAGE $RIGIDSTAGE $AFFINESTAGE"
  NUMBEROFREGISTRATIONSTAGES=2
  ;;
"b" | "s")
  STAGES="$AFFINESTAGE $SYNSTAGE"
  NUMBEROFREGISTRATIONSTAGES=2
  ;;
"br" | "sr")
  STAGES="$INITIALSTAGE $RIGIDSTAGE $SYNSTAGE"
  NUMBEROFREGISTRATIONSTAGES=2
  ;;
"bo" | "so")
  STAGES="$SYNSTAGE" #$INITIALSTAGE
  NUMBEROFREGISTRATIONSTAGES=1
  ;;
*)
  echo "Transform type '$TRANSFORMTYPE' is not an option.  See usage: '$0 -h 1'"
  exit
  ;;
esac

if [[ $NUMBEROFMASKIMAGES -ne 0 && $NUMBEROFMASKIMAGES -ne 1 && $NUMBEROFMASKIMAGES -ne $NUMBEROFREGISTRATIONSTAGES ]];
  then
    echo "The specified number of mask images is not correct.  Please see help menu."
    exit
  fi

PRECISION=''
case "$PRECISIONTYPE" in
"f")
  PRECISION="--float 1"
  ;;
"d")
  PRECISION="--float 0"
  ;;
*)
  echo "Precision type '$PRECISIONTYPE' is not an option.  See usage: '$0 -h 1'"
  exit
  ;;
esac

COMMAND="${ANTS} --verbose 1 \
                 --dimensionality $DIM $PRECISION \
                 --collapse-output-transforms $COLLAPSEOUTPUTTRANSFORMS \
                 --output [$OUTPUTNAME,${OUTPUTNAME}Warped.nii.gz,${OUTPUTNAME}InverseWarped.nii.gz] \
                 --interpolation BSpline[3] \
                 --use-histogram-matching ${USEHISTOGRAMMATCHING} \
                 $MASKCALL \
                 $STAGES"
#BSpline[3]
echo " antsRegistration call:"
echo "--------------------------------------------------------------------------------------"
echo ${COMMAND}
echo "--------------------------------------------------------------------------------------"

$COMMAND

###############################
#
# Restore original number of threads
#
###############################

ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$ORIGINALNUMBEROFTHREADS
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

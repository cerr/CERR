!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! DPMgateway.f
! JC Implement the "subroutine init" of DPM.f
! Jun 13 2005
! Get all the parameters in dpm.in from a structure: DPMIN, defined in MATLAB.
! And read photon energy spectrum file. 
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!! JC July 25, 2005
!!! Use single precision instead of double precision for the dynamically allocated arrays.

!!! Define module DPMVOX to replace common /dpmvox/ and common /dpmesc/

!!! Dec 29 2006
!   Use conditional compilation directives to make one version of code work both on LINUX AMD64-bit
!   and WINDOWS Inte32-bit machine.

!!! JC Dec 26, 2006
!!! Add Debug Statements: 
!!! Parameter Debug = 1            ! in DPMSOURCE module
!!! if (Debug.eq.1) then
!!! WRITE(10,*) ######
!!! endif

!!! JC Apr. 09 2008
!!! Changed the variable "mat()" into Integer*2, and lasthi() into real*4.
!!! Found out Interge*2 only works for sparse matrix. Need to change to real*4 etc.
!!! According to JOD, switch gear. Work on FF sampling issue.
!!! 
!!!DEC$ DEFINE UseSingle

	MODULE COLLIMATOR

	implicit NONE
	SAVE

	real*8 :: A(3,3), Nsource(3), NAfilter(3)
	real*8 mid_x, mid_y, halfside_x, halfside_y
	real*8 cosmin, cosmax, max_phi, min_phi, Distance
	

	END MODULE COLLIMATOR
!!! End the definition of module Collimator


	MODULE DPMVOX

	implicit NONE
	SAVE

	integer*8 Unxvox,Unyvox,Unzvox, nxyz
	real*8 dx,dy,dz,xmid,ymid,zmid

!dec$ IF DEFINED (UseSingla)
	integer*2, allocatable :: mat(:)
	integer*4, allocatable :: lasthi(:)
	
!dec$ ENDIF
	real*4, allocatable :: dens(:)
	integer*8, allocatable :: mat(:)
	integer*8, allocatable :: lasthi(:)
	real*4, allocatable :: escore(:), escor2(:), etmp(:)

	END MODULE DPMVOX
!!! End the definition of module DPMVOX
!!!
!!! Add all the variables need to implement a point source
!!! Add four points, Must be in Counter-Clockwise Order.!!!
	MODULE DPMSOURCE

	implicit NONE
	SAVE

	integer*8 Typesource, Nslices, Debug
!!! Fix Nslices as 720, not necessary be visible to users.
!!! JC July 08 2005
!!! Increase the number of the samples of the circle
!!! around the collimator. If the 

	parameter (Debug = 0)            
	parameter (Nslices=3600)
	real*8 XYZsource(3),
     &	 Afilter(3), Bfilter(3), Cfilter(3), Diameter,
     &	 IsoVector(3), IsoDistance
	character*40 spectrum
      real*8, allocatable :: e(:), e_spectrum(:), pcum(:)
	integer*8, allocatable :: pcum_nhist(:)
	integer*8 ndata
	real*8 BinEnergy(2)
	real*8 Avg_Energy, ElecAvg, NormalizeElec
!!! JC Added parameters to model the 'horns' effects. 
	real*8 IncreaseFluence
	real*8, allocatable :: testAngle(:,:), testAnglePcum(:)
!     the "IncreaseFluence is a const. ranging between [0, 1] (or bigger), to "scale" the change of the horn.
!!! JC Mar 19 2007
!	Add variables of increase fluence, ie. horn curve
!     Now "testAngle" are read from DPMIN struct, which is a m by 2 array.
!	with columns as the [cos(off-axis-angle), increas_of_fluence -1]

      integer*8 numberAngle
	
!!! JC Added parameters for a secondary source, with a exponential distribution.
	integer*8 UseFlatFilter
!!!	The parameter a, b in the model for FlatFilter, and the distance from the 
!	source to the flattening filter
!!! JC Jan 2008
!	Make the length of the FlatFilterA and FlatFilterB 10, instead of 1.
!	Now it can accomodate more flexible spatial distributions.
!	When useFlatFilter == 2, A is the weights for each source, B is the sigma of the Gaussian.
!	When useFlatFilter == 1, A and B are the coefficients of the exponential distribution.
	real*8 FlatFilterA(10), FlatFilterB(10), FlatFilterDist
      real*8 FlatFilterR(50), FlatFilterPcum(50)
	integer*8 numberBinR, sampleParticles
	real*8 XYZFlatSource(3)

!!! JC Sept 27 2006
!   Add one more input in DPMIN, 'OnlyHorn', to only model the horn effect. No isotropic source.
!!! JC Feb 09 2007
!   Add one more input in DPMIN, 'DoseNormFlag'. if it's 2, use 'sampleParticles" to normalize,
!	otherwise, default, use "nhist" to normalize dose.
      integer*8 OnlyHorn, DoseNormFlag, OpenField, Softening
!!! JC Mar 19 2007
!	Add maxSampleAngle in (rad), it's 0.245rad == 14deg, as the primary collimator defines.
!	However, for Flattening filter source, this value have to be bigger, since it's an extended source, not a point source.
!       to get the correct output factor
	real*8 maxSampleAngle, maxSampleAngleFF
!	parameter (maxSampleAngle = 0.245)
!	parameter (maxSampleAngleFF = 0.36)
! JC	Apr. 10, 2008	Do not make DPM stop, instead, return the zero dose back to MATLAB
!	Thus this flag to return zeros dose.
!	Add the flag to return from subroutine when the 
	logical*1  stopFlag

	END MODULE DPMSOURCE 	 
!!! All above variables need to be initialized in (init).
	
	
	MODULE rayBox
	IMPLICIT NONE
	save
	real*8 rayOrgV(3), rayDeltaV(3), minBoxV(3), maxBoxV(3)
	END MODULE rayBox
	
	
C     The gateway routine
      subroutine mexFunction(nlhs, plhs, nrhs, prhs)
!!! How to install?
!   mex -g DPMgateway.f revord.f xtimesy.f

!!! How to run?
!DPMIN_struct; input.x = 3.5;
!input.y = rand(3,4);
![a b c d] = DPMgateway(DPMIN, input)

! where DPMIN is the sturct for DPM input; x := a scalar; y := m*n matrix
! out1 :=x*y, out2 :=revord of z, out3 :=1*ndata vector(e), out4:=1*ndata vector(pcum). 


! On a WIN32 machine, comment out the following line.
!dec$ DEFINE AMD64

! JC Use the library provided by Intel Fortran Compile, 'IFPORT', to use 'getpid'
!dec$ IF DEFINED (AMD64)
      USE IFPORT
!dec$ ENDIF

      USE DPMVOX
      USE DPMSOURCE
      USE rayBox
!!! Test how long the program takes to run.
	!use DFPORT
	!character*8 char_time
	IMPLICIT NONE
    

!dec$ IF DEFINED (AMD64)
      integer*8 m, n, mxGetM, mxGetN, mxIsNumeric
      integer*8 mxCreateDoubleMatrix, mxIsStruct, mxGetPr
      integer*8 plhs(*), prhs(*)
      integer*8 output_pr
      integer*8 nlhs, nrhs

! Variable declerations for the revord subroutine.
      integer*8 mxIsChar
      integer*8 mxGetString
	integer*8 mxGetFieldByNumber
	integer*8 maxhis_pr, atime_pr, intype_pr, esrc_pr
	integer*8 param_pr, eabs_pr, eabsph_pr
	integer*8 BinEnergy_pr, UsePhotSpectrum_pr,UsePhotSpectrum
	integer*8 minBoxV_pr, maxBoxV_pr
	integer*8 XYZsource_pr, Afilter_pr, Bfilter_pr, Cfilter_pr
	integer*8 Diameter_pr, e_pr, OutputErr_pr, IsoVector_pr
!! Variables used to read the second input struct: CTscan
	integer*8 Unxvox_pr, Unyvox_pr, Unzvox_pr
	integer*8 dx_pr, dy_pr, dz_pr, dens_pr, mat_pr
! Jan 2008
! Add variable "tmp_pr", means the temporary pointer used to transfter the data from MATALB to Fortran environment. 
! BinEnergy_pr was used for this purpose, which was confusing.
	integer*8 tmp_pr



C-----------------------------------------------------------------------

!dec$ ELSE
C-----------------------------------------------------------------------
      integer m, n, mxGetM, mxGetN, mxIsNumeric
      integer mxCreateDoubleMatrix, mxIsStruct, mxGetPr
      integer plhs(*), prhs(*)
      integer output_pr
      integer nlhs, nrhs

! Variable declerations for the revord subroutine. 
      integer  mxIsChar
      integer mxGetString
	integer mxGetFieldByNumber
	integer maxhis_pr, atime_pr, intype_pr, esrc_pr
	integer param_pr, eabs_pr, eabsph_pr
	integer BinEnergy_pr, UsePhotSpectrum_pr,UsePhotSpectrum
	integer minBoxV_pr, maxBoxV_pr
	integer XYZsource_pr, Afilter_pr, Bfilter_pr, Cfilter_pr
	integer Diameter_pr, e_pr, OutputErr_pr, IsoVector_pr
!! Variables used to read the second input struct: CTscan
	integer Unxvox_pr, Unyvox_pr, Unzvox_pr
	integer dx_pr, dy_pr, dz_pr, dens_pr, mat_pr
! Jan 2008
! Add variable "tmp_pr", means the temporary pointer used to transfter the data from MATALB to Fortran environment. 
! BinEnergy_pr was used for this purpose, which was confusing.
	integer*8 tmp_pr


!dec$ ENDIF



!      character*100 input_buf, output_buf
      integer*8  status, strlen
      integer*8 len
      character*40 fname

! Variable declerations for the DPMIN struct. 
      integer*8 intype
      real*8 esrc,eabs,eabsph,param
      common /dpmsrc/ esrc,eabs,eabsph,param,intype
      integer*8 maxhis
      real*8 atime
      common /dpmsim/ atime,maxhis

	real*8 r_maxhis, r_intype, r_Typesource, r_seeds(2)
	real*8 r_UsePhotSpectrum
!	JC Add temporary real*8 variable for the conversion of the data from real to integer.
!	Because all the variables are real*8 when transfered from MATLAB to Fortran
!	r_UsePhotSpectrum was used for this purpose, previously.
	real*8 tmp_r

      character*40 prefix
	real*8  r_OutputErr
	integer*8 OutputErr

! Variable definition in main program of dpm.f
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype

      integer*8 scndry,loopbk
      real*8 time0,cputim,mc2,twomc2
      parameter (mc2=510.9991d3,twomc2=2.0d0*mc2)
!!!	
!!! Variables in 'subroutine init"
      integer*8 maxmat,nmat
      parameter (maxmat=5)
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat
      integer*8 sptype
      integer*8 maxns,nsec,sxvox,syvox,szvox,sabsvx
      real*8 swght,senerg,svx,svy,svz,sx,sy,sz
      parameter (maxns=2**7)
      common /dpmstck/ swght(maxns),senerg(maxns),
     & svx(maxns),svy(maxns),svz(maxns),sx(maxns),sy(maxns),sz(maxns),
     & sptype(maxns),sxvox(maxns),syvox(maxns),szvox(maxns),
     & sabsvx(maxns),nsec
      integer*8 nxini,nxfin,nyini,nyfin,nzini,nzfin
      common /dpmrpt/ nxini,nxfin,nyini,nyfin,nzini,nzfin

!      character*100 buffer
      integer*8 i,bytes,seed1,seed2
      real*8 kbytes,emin,emax,eminph,refz,refz2,refmas,refden
      real*8 stdspw,xini,xfin,yini,yfin,zini,zfin
      parameter (stdspw=2.0d6)

	real*8 prob,eps
      parameter (eps=1.0d-8)

! Variables used in the orginal subroutine report.
! Now "report" is a part of the gateway routine.
!       subroutine report(n,cputim)
c*******************************************************************
c*    Writes a report of the required quantities                   *
c*******************************************************************
      integer*8 j,k,getabs,nsig
      real*8 q,in,eff,sigma,voxvol,maxq,avesig
!! Add the variable "zero", to avoid divided by zero, when nsig = 0.      
	real*8 zero
      parameter (zero=1.0d-30)

!! Add the defination of the following arrays, for the output.
      real*8, allocatable :: output(:,:)
	integer*8 output_count

!! Variables used to read the second input struct: CTscan
	real*8 r_Unxvox, r_Unyvox, r_Unzvox
	real*8, allocatable :: r_mat(:), r_dens(:)

!!! JC July 13 2005, Uncomment the time function
!!! Need to check witch portion of the code takes most of CPU time.
	!!! Test how long the program takes to run.
	REAL*8 time_begin, time_end
	REAL*8 time_source, time_source_sum
	REAL*8 time_calculate, time_calculate_sum, time_report
	real*8 pi
      parameter (pi=3.1415926535897932d0)

!	 INTEGER(4) int_time
!	 character*8 char_time
!!! JC Jun 1 2006 Use getpid get the process ID, using it as part of the name of the output file,
!!! i.e. to replace ./local/dpm.out

        character*20 outputFNAME
        INTEGER*4 IUNIT
        INTEGER(4) istat


! Above from the main program.


! Start of the real commands for gateway routine

C     Check for proper number of arguments. 
!      if (nrhs .ne. 2) then
!         call mexErrMsgTxt('Two input required.')
!      elseif (nlhs .ne. 1) then
!         call mexErrMsgTxt('One output required Ha Ha Ha.')
!      endif

! Creat the output file
        outputFNAME = './local/00000000.out'

!dec$ IF DEFINED (AMD64)
        istat = GETPID()
        IUNIT = istat
!dec$ ENDIF

        WRITE(outputFNAME(9:16),'(i8)') IUNIT
        CALL mexprintf(outputFNAME)
        CALL mexprintf(CHAR(10))
	open(10, file=outputFNAME, status='REPLACE')
	 !int_time = TIME( )
	 !call TIME(char_time)
	 !write(10,*) 'Integer: ', int_time, 'time: ', char_time

! JC. July 6 2005
! Creat the dump file. unit = 6, since in files pengeom2.f, material.f
! and penelope.f, "write(6,*)". without open it.
	open(6, file='./local/dpm_dump.out', status='REPLACE')
 
! Check whether of the first input argument is a struct: DPMIN


	if (mxIsStruct(prhs(1))) then

! For the following commands, need to check the status of the success
! of the calling. Throw errors when nessary. Not Done. 

C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 1)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 1))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 1))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #1 of Input #1 is not a scalar.')
      endif
	maxhis_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 1))
	call mxCopyPtrToReal8(maxhis_pr, r_maxhis, 1)
	maxhis = idnint(r_maxhis)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 2)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 2))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 2))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #2 of Input #1 is not a scalar.')
      endif
	atime_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 2))
	call mxCopyPtrToReal8(atime_pr, atime, 1)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 3)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 3))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 3))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #3 of Input #1 is not a scalar.')
      endif
      intype_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 3))
	call mxCopyPtrToReal8(intype_pr, r_intype, 1)
	intype = idnint(r_intype)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 4)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 4))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 4))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #4 of Input #1 is not a scalar.')
      endif
      esrc_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 4))
	call mxCopyPtrToReal8(esrc_pr, esrc, 1)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 5)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 5))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 5))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #5 of Input #1 is not a scalar.')
      endif
	param_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 5))
	call mxCopyPtrToReal8(param_pr, param, 1)


      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 6)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 6))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 6))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #6 of Input #1 is not a scalar.')
      endif
	eabs_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 6))
	call mxCopyPtrToReal8(eabs_pr, eabs, 1)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 7)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 7))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 7))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #7 of Input #1 is not a scalar.')
      endif
	eabsph_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 7))
	call mxCopyPtrToReal8(eabsph_pr, eabsph, 1)

C	The input must be a string
	if(mxIsChar(mxGetFieldByNumber(prhs(1), 1, 8)) .ne. 1) then
		call mexErrMsgTxt('Input must be a string.')

C	The input must be a row vector.
	elseif (mxGetM(mxGetFieldByNumber(prhs(1), 1, 8)) .ne. 1) then
		call mexErrMsgTxt('Input must be a row vector.')
	endif

C     Get the length of the string: prefix
      strlen = mxGetM(mxGetFieldByNumber(prhs(1), 1, 8))
     & *mxGetN(mxGetFieldByNumber(prhs(1), 1, 8))

C     Get the string contents (dereference the input integer).
      status = mxGetString(mxGetFieldByNumber(prhs(1), 1, 8)
     & , prefix, strlen)

C     Check if mxGetString is successful.
      if (status .ne. 0) then 
         call mexErrMsgTxt('String length must be less than 40.')
      endif

!!! The following part is from "subroutine init"
c     *** Read material data
      len = strlen
	kbytes = 0.0d0
      fname= prefix(1:len)//'.matter'
      call rmater(fname,emin,eminph,emax,
     &            refz,refz2,refmas,refden)
      write(10,*) ' '
      write(10,*) ' '
      if (esrc.ge.emax.or.eabs.lt.emin.or.eabsph.lt.eminph) then
        write(10,*) 'init:error: Esrc or Eabs out of range.'
        stop
      endif
c     *** These restrictions save some 'if's in the e- transport routine:
      if (wcc.lt.eabs.or.wcb.lt.eabsph) then
        write(10,*) 'init:error: Cutoffs cannot be less than Eabs'
        stop
      endif
      fname= prefix(1:len)//'.step'
      call rstep(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.scpw'
      call rscpw(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.bw'
c     *** opt-qSingleMat ON: activate next line and deact next+1:
      call rbw(fname,bytes)
c     * call xrbw(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.q'
c     *** opt-qSingleMat ON: activate next line and deact next+1:
      call rqsurf(fname,bytes)
c     * call xrqsurf(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.lammo'
      call rlammo(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.lambre'
      call rlabre(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.rstpw'
      call rrstpw(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.brecon'
      call rbcon(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.lamph'
      call rlamph(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.compt'
      call rcompt(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.phote'
      call rphote(fname,bytes)
      kbytes = kbytes+bytes*1.d-3
      fname= prefix(1:len)//'.pairp'
      call rpairp(fname,bytes)
      kbytes = kbytes+bytes*1.d-3

!!!      call rvoxg(geometry)
!! The following block replace "subroutine rvoxg".
!! After write wroten & test, try to see wheter it can be moved
!! from here, to outside of the read in DPMIN struct block.
	if (mxIsStruct(prhs(2))) then

! For the following commands, need to check the status of the success
! of the calling. Throw errors when nessary. Not Done. 

C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(2), 1, 1)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(2), 1, 1))
	n = mxGetN(mxGetFieldByNumber(prhs(2), 1, 1))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #1 of Input #2 is not a scalar.')
      endif
	Unxvox_pr = mxGetPr(mxGetFieldByNumber(prhs(2), 1, 1))
	call mxCopyPtrToReal8(Unxvox_pr, r_Unxvox, 1)
	Unxvox = idnint(r_Unxvox)

C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(2), 1, 2)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(2), 1, 2))
	n = mxGetN(mxGetFieldByNumber(prhs(2), 1, 2))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #2 of Input #2 is not a scalar.')
      endif
	Unyvox_pr = mxGetPr(mxGetFieldByNumber(prhs(2), 1, 2))
	call mxCopyPtrToReal8(Unyvox_pr, r_Unyvox, 1)
	Unyvox = idnint(r_Unyvox)

C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(2), 1, 3)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(2), 1, 3))
	n = mxGetN(mxGetFieldByNumber(prhs(2), 1, 3))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #3 of Input #2 is not a scalar.')
      endif
	Unzvox_pr = mxGetPr(mxGetFieldByNumber(prhs(2), 1, 3))
	call mxCopyPtrToReal8(Unzvox_pr, r_Unzvox, 1)
	Unzvox = idnint(r_Unzvox)
	
C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(2), 1, 4)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(2), 1, 4))
	n = mxGetN(mxGetFieldByNumber(prhs(2), 1, 4))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #4 of Input #2 is not a scalar.')
      endif
      dx_pr = mxGetPr(mxGetFieldByNumber(prhs(2), 1, 4))
	call mxCopyPtrToReal8(dx_pr, dx, 1)

C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(2), 1, 5)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(2), 1, 5))
	n = mxGetN(mxGetFieldByNumber(prhs(2), 1, 5))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #5 of Input #2 is not a scalar.')
      endif
	dy_pr = mxGetPr(mxGetFieldByNumber(prhs(2), 1, 5))
	call mxCopyPtrToReal8(dy_pr, dy, 1)

C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(2), 1, 6)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(2), 1, 6))
	n = mxGetN(mxGetFieldByNumber(prhs(2), 1, 6))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #6 of Input #2 is not a scalar.')
      endif
	dz_pr = mxGetPr(mxGetFieldByNumber(prhs(2), 1, 6))
	call mxCopyPtrToReal8(dz_pr, dz, 1)
	
      xmid = dx*Unxvox/2.0
      ymid = dy*Unyvox/2.0
      zmid = dz*Unzvox/2.0
!!! Assign nxyz = Unxvox*Unyvox*Unzvox
!!! Allocate dens(nxyz) and mat(nxyz)
	nxyz = Unxvox*Unyvox*Unzvox
	allocate (dens(nxyz))
	allocate (r_dens(nxyz))
	allocate (mat(nxyz))

C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(2), 1, 7)) .eq. 0) then
         call mexErrMsgTxt('Input must be numberic.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(2), 1, 7))
	n = mxGetN(mxGetFieldByNumber(prhs(2), 1, 7))
	if (n .ne. 1) then
	 call mexErrMsgTxt('Field #7 of Input #2 is not a column vector.')
      endif
	if (m .ne. nxyz) then
		call mexErrMsgTxt('The number in Field #7 of Input #2
     &		 is not consistent with the number of the total voxels.')
      endif
	dens_pr = mxGetPr(mxGetFieldByNumber(prhs(2), 1, 7))
	call mxCopyPtrToReal8(dens_pr, r_dens, nxyz)
! JC, July 25, 2005 Use single precision for dens, need to convert from real*8
	do i = 1, nxyz
	dens(i) = SNGL(r_dens(i))
	enddo
	deallocate (r_dens)

C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(2), 1, 8)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(2), 1, 8))
	n = mxGetN(mxGetFieldByNumber(prhs(2), 1, 8))
	if (n .ne. 1) then
	 call mexErrMsgTxt('Field #8 of Input #2 is not a column vector.')
      endif
	if (m .ne. nxyz) then
		call mexErrMsgTxt('The number in Field #8 of Input #2
     &		 is not consistent with the number of the total voxels.')
      endif
	mat_pr = mxGetPr(mxGetFieldByNumber(prhs(2), 1, 8))


!dec$ IF DEFINED (UseSingle)
	call mxCopyPtrToInteger2(mat_pr, mat, nxyz)

!dec$ ELSE
	allocate (r_mat(nxyz))
	call mxCopyPtrToReal8(mat_pr, r_mat, nxyz)
	do i = 1, nxyz
!	mat(i) = idnint(r_mat(i))
	mat(i) = IIDNNT(r_mat(i))
	enddo
	deallocate (r_mat)

!dec$ ENDIF


! Still need to check whether the .vox/ CTscan info.
! is correctly allocated into the Fortran arrays.
! Still need to check whether the material #/ mat is less than 5.

c     *** Load material and density for each voxel:
!	do i=1,Unxvox
!        do j=1,Unyvox
!          do k=1,Unzvox
!                  read(1,*) mat(getabs(i,j,k)),dens(getabs(i,j,k))
!              write(10,*) mat(getabs(i,j,k)),dens(getabs(i,j,k))
!            if (mat(getabs(i,j,k)).gt.nmat) then
!              write(10,*) 'rvoxg:error: Mat# too large:'
!              write(10,'(1x,i6)') mat(absvox)
!              stop
!            endif
!		enddo
!	  enddo
!	enddo
!      close(1)
!      end

	endif 


      call iniion(refz,refmas,wcc)
      call inibre(refz2,refmas,wcb)
!      call inigeo(dx,dy,dz,nxvox,nyvox,nzvox)
      call inigeo(dx,dy,dz,Unxvox,Unyvox,Unzvox)
c     *** iniwck must be called after reading esrc & eabsph:
      call iniwck(eminph,emax,bytes)
      kbytes = kbytes+bytes*1.d-3
c     *** inisub called after eabs has been read:
      call inisub(refden)


C     Check to ensure the input is 3*1 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 9)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 9))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 9))
	if (m .ne. 1 .or. n .ne. 3) then
	 call mexErrMsgTxt('Field #9 of Input #1 is not a 1*3 vector.')
	endif
	minBoxV_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 9))
	call mxCopyPtrToReal8(minBoxV_pr, minBoxV, 3)
	
C     Check to ensure the input is 3*1 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 10)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 10))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 10))
	if (m .ne. 1 .or. n .ne. 3) then
	 call mexErrMsgTxt('Field #10 of Input #1 is not a 1*3 vector.')
	endif
	maxBoxV_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 10))
	call mxCopyPtrToReal8(maxBoxV_pr, maxBoxV, 3)


C     Check to ensure the input is 1*2 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 11)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 11))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 11))
	if (m .ne. 1 .or. n .ne. 2) then
	 call mexErrMsgTxt('Field #11 of Input #1 is not a 1*2 vector.')
	endif
	call mxCopyPtrToReal8
     & (mxGetPr(mxGetFieldByNumber(prhs(1), 1, 11)), r_seeds, 2)
!	JC: The output of idnint is integer*4
!   Want it to be kidnint, result type is integer*8
!    seed1 = idnint(r_seeds(1))
!	 seed2 = idnint(r_seeds(2))
      seed1 = int8(r_seeds(1))
	  seed2 = int8(r_seeds(2))
 
      call inirng(seed1)
      call seed2n(seed2)
c     *** One more call to force RNG to report:
      call inirng(int8(-666))

		
C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 12)) .eq. 0) then
         call mexErrMsgTxt('Input must be a number.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 12))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 12))
	if (n .ne. 1 .or. m .ne. 1) then
		call mexErrMsgTxt('Field #12 of Input #1 is not a scalar.')
      endif
	call mxCopyPtrToReal8
     & (mxGetPr(mxGetFieldByNumber(prhs(1), 1, 12)), r_Typesource, 1)
	Typesource = idnint(r_Typesource)
	
C     Check to ensure the input is 1*3 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 13)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 13))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 13))
	if (m .ne. 1 .or. n .ne. 3) then
	 call mexErrMsgTxt('Field #13 of Input #1 is not a 1*3 vector.')
	endif
	XYZsource_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 13))
	call mxCopyPtrToReal8(XYZsource_pr, XYZsource, 3)

C     Check to ensure the input is 1*3 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 14)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 14))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 14))
	if (m .ne. 1 .or. n .ne. 3) then
	 call mexErrMsgTxt('Field #14 of Input #1 is not a 1*3 vector.')
	endif
	Afilter_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 14))
	call mxCopyPtrToReal8(Afilter_pr, Afilter, 3)

C     Check to ensure the input is 1*3 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 15)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 15))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 15))
	if (m .ne. 1 .or. n .ne. 3) then
	 call mexErrMsgTxt('Field #15 of Input #1 is not a 1*3 vector.')
	endif
	Bfilter_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 15))
	call mxCopyPtrToReal8(Bfilter_pr, Bfilter, 3)

C     Check to ensure the input is 1*3 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 16)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 16))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 16))
	if (m .ne. 1 .or. n .ne. 3) then
	 call mexErrMsgTxt('Field #16 of Input #1 is not a 1*3 vector.')
	endif
	Cfilter_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 16))
	call mxCopyPtrToReal8(Cfilter_pr, Cfilter, 3)

!!!  JC On Jun 27 2005
! Cancel this parameter from the input
! which is the number of sampling points on the circle overset
! the rectangle of the collimator.
! Use default value 720 inside the code, since this info is not
! necessary to seen by the users. 

!C     Check to ensure the input is a number.
!      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 17)) .eq. 0) then
!         call mexErrMsgTxt('Input must be numeric.')
!	endif
!	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 17))
!	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 17))
!	if (m .ne. 1 .or. n .ne. 1) then
!	 call mexErrMsgTxt('Field #17 of Input #1 is not a scalar.')
!	endif
!	Nslices_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 17))
!	call mxCopyPtrToReal8(Nslices_pr, r_Nslices, 1)
!	Nslices = idnint(r_Nslices)


C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 17)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 17))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 17))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #17 of Input #1 is not a scalar.')
	endif
	Diameter_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 17))
	call mxCopyPtrToReal8(Diameter_pr, Diameter, 1)


!JC July 28, 2005
!Get this reading photon portion out of subroutine source,
!Instead, use the one in DPMIN struct.

C     input the photon energy spectrum.
!      if (intype.eq.0) then

	if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 18)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	ndata = mxGetM(mxGetFieldByNumber(prhs(1), 1, 18))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 18))
	if (n .ne. 2) then
		call mexErrMsgTxt('Field #18 of Input #1 is not
     & a 2 column vector.')
      endif
	
	allocate (e(ndata*2))
	allocate (e_spectrum(ndata+1))
	allocate (pcum(ndata+1))
	allocate (pcum_nhist(ndata+1))

	e_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 18))
	call mxCopyPtrToReal8(e_pr, e, 2*ndata)
      
!!! JC Dec. 05 2005
! Normalize pdf, ie. e(1+ndata: 2*ndata)
! Use pcum(1) temporarily
	pcum(1)=0
      do i=1,ndata
          pcum(1) = pcum(1)+e(i+ndata)
	enddo
      
	if (dabs(pcum(1)-1.0d0).gt.eps) then
		do i=1,ndata
			e(i+ndata)=e(i+ndata)/pcum(1)
		enddo
	endif

	write(10,*) 'e    pdf'
	write(10,'(1pe10.3,5x,1pe10.3)') 0, 0
!%	do i=2,ndata+1
!%	write(10,'(1pe10.3,5x,1pe10.3)')e(i-1), e(ndata+i-1)
!%	enddo

!! pcum(1+ndata : 2*ndata) are the number of history for each energy bin.

!        if (e(1).ne.0.0d0.or.pcum(1).ne.0.0d0) then
!          write(10,*) 'source:error: First spectrum data must be 0.'
!          stop
!        endif

	e_spectrum(1)=0
	pcum(1)=0
	pcum_nhist(1)=0

       do i=2,ndata+1
		prob = e(i+ndata-1)
 	    if (prob.lt.0.0d0) then
            write(10,*) 'source:error: Negative probability found @eV:'
            write(10,*) e(i-1)
            stop
          endif
		e_spectrum(i) = e(i-1)
          pcum(i) = pcum(i-1)+prob
!!! JC Dec. 05 2005
		pcum_nhist(i) = idnint(pcum(i)*maxhis)
	  enddo
	   write(10,*) 'DPMgateway: number of photon spectrum: ',ndata
!        if (e(ndata).gt.esrc) then
!          write(10,*) 'source:error: Spectrum energy is too high:'
!          write(10,'(1x,2(1pe10.3,1x))') e(ndata),esrc
!          stop
!        endif
        if (dabs(pcum(ndata+1)-1.0d0).gt.eps) then
          write(10,*) 'source: Spectrum PDF not normalized:'
          write(10,'(1pe10.3)') pcum(ndata)
          write(10,*) '        renormalizing to 1.'
          do 30 i=1,ndata+1
            pcum(i) = pcum(i)/pcum(ndata+1)
 30       continue
      
      endif
!        endif
c
!!!	JC Nov. 29, 2005, output pcum to check.
	do i=1,ndata+1
	write(10,'(1pe10.3,1x,1pe10.3,1x,1I10.1)')
     & e_spectrum(i),pcum(i),pcum_nhist(i)
	enddo


C     Check to ensure the input is a number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 19)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 19))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 19))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #19 of Input #1 is not a scalar.')
	endif
	OutputErr_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 19))
	call mxCopyPtrToReal8(OutputErr_pr, r_OutputErr, 1)
	OutputErr = idnint(r_OutputErr)
	endif


! JC Oct 12, 05. ADD the part, get IsoVector information from CERR.


C     Check to ensure the input is 3 numbers.
C     Check to ensure the input is 1*3 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 20)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 20))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 20))
	if (m .ne. 1 .or. n .ne. 3) then
	 call mexErrMsgTxt('Field #20 of Input #1 is not a 1*3 vector.')
	endif
	IsoVector_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 20))
	call mxCopyPtrToReal8(IsoVector_pr, IsoVector, 3)


!!! JC Nov. 02, 2005 Added BinEnergy Feature
C     Check to ensure the input is 2 number.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 21)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 21))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 21))
	if (m .ne. 1 .or. n .ne. 2) then
	 call mexErrMsgTxt('Field #21 of Input #1 is not a 1*2 vector.')
	endif
	BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 21))
	call mxCopyPtrToReal8(BinEnergy_pr, BinEnergy, 2)


      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 22)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 22))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 22))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #22 of Input #1 is not a scalar.')
	endif
	UsePhotSpectrum_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 22))
	call mxCopyPtrToReal8(UsePhotSpectrum_pr, r_UsePhotSpectrum, 1)
	UsePhotSpectrum = idnint(r_UsePhotSpectrum)


!!!	JC July 20 2006, 
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 23)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 23))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 23))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #23 of Input #1 is not a scalar.')
	endif
	UsePhotSpectrum_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 23))
	call mxCopyPtrToReal8(UsePhotSpectrum_pr, r_UsePhotSpectrum, 1)
	UseFlatFilter = idnint(r_UsePhotSpectrum)

      
	if (UseFlatFilter .eq. 0) then
!	No FF. i.e. Primary photon.
!	Doesent' matter FlatFilterA and FlatFilterB are.
         if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 24)) .eq. 0) then
		   call mexErrMsgTxt('Input must be numeric.')
		endif
		m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 24))
		n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 24))
		if (m .ne. 1 .or. (n .ne. 1 .and. n .ne. 3)) then
		 call mexErrMsgTxt('Field #24 of Input #1 is not a scalar.')
		endif
		BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 24))
		call mxCopyPtrToReal8(BinEnergy_pr, FlatFilterA(1), 1)


	   if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 25)) .eq. 0) then
		   call mexErrMsgTxt('Input must be numeric.')
		endif
		m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 25))
		n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 25))
		if (m .ne. 1 .or. (n .ne. 1 .and. n .ne. 3)) then
		 call mexErrMsgTxt('Field #25 of Input #1 is not a scalar.')
		endif
		BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 25))
		call mxCopyPtrToReal8(BinEnergy_pr, FlatFilterB, 1)

	elseif (UseFlatFilter .eq. 1) then
!	Use H H Liu (MP, 1997) model
         if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 24)) .eq. 0) then
		   call mexErrMsgTxt('Input must be numeric.')
		endif
		m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 24))
		n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 24))
		if (m .ne. 1 .or. n .ne. 1) then
		 call mexErrMsgTxt('Field #24 of Input #1 is not a scalar.')
		endif
		BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 24))
		call mxCopyPtrToReal8(BinEnergy_pr, FlatFilterA(1), 1)


	   if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 25)) .eq. 0) then
		   call mexErrMsgTxt('Input must be numeric.')
		endif
		m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 25))
		n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 25))
		if (m .ne. 1 .or. n .ne. 1) then
		 call mexErrMsgTxt('Field #25 of Input #1 is not a scalar.')
		endif
		BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 25))
		call mxCopyPtrToReal8(BinEnergy_pr, FlatFilterB, 1)


	elseif (UseFlatFilter  .eq. 2) then
!	Use Jiang(MP, 2001) model
	   if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 24)) .eq. 0) then
		   call mexErrMsgTxt('Input must be numeric.')
		endif
		m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 24))
		n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 24))
		if (m .ne. 1 .or. n .ne. 3) then
		 call mexErrMsgTxt('Field #24 of Input #1 is not
     & a 1x3 vector.')
		endif
		BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 24))
		call mxCopyPtrToReal8(BinEnergy_pr, FlatFilterA(1:3), 1)


	   if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 25)) .eq. 0) then
		   call mexErrMsgTxt('Input must be numeric.')
		endif
		m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 25))
		n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 25))
		if (m .ne. 1 .or. n .ne. 3) then
		 call mexErrMsgTxt('Field #25 of Input #1 is not 1x3 scalar.')
		endif
		BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 25))
		call mxCopyPtrToReal8(BinEnergy_pr, FlatFilterB(1:3), 1)

	else
		write(10,*) 'UseFlatFilter can only be 0, 1 or 2 \n'
		stop

	endif



      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 26)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 26))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 26))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #26 of Input #1 is not a scalar.')
	endif
	BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 26))
	call mxCopyPtrToReal8(BinEnergy_pr, FlatFilterDist, 1)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 27)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 27))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 27))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #27 of Input #1 is not a scalar.')
	endif
	BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 27))
	call mxCopyPtrToReal8(BinEnergy_pr, IsoDistance, 1)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 28)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 28))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 28))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #28 of Input #1 is not a scalar.')
	endif
	BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 28))
	call mxCopyPtrToReal8(BinEnergy_pr, IncreaseFluence, 1)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 29)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 29))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 29))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #29 of Input #1 is not a scalar.')
	endif
	 BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 29))
	   call mxCopyPtrToReal8(BinEnergy_pr, r_UsePhotSpectrum, 1)
       OnlyHorn = idnint(r_UsePhotSpectrum)

! Feb 09, 2007
! Default, use "nhist" to normalize dose.
! flag == 2, use "numberParticles" to normalize dose. 
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 30)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 30))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 30))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #30 of Input #1 is not a scalar.')
	endif
	 BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 30))
	   call mxCopyPtrToReal8(BinEnergy_pr, r_UsePhotSpectrum, 1)
       DoseNormFlag = idnint(r_UsePhotSpectrum)

C     Check to ensure the input is 1001*2 vector.
      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 31)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 31))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 31))
	if (m .ge. 1001 .or. n .ne. 2) then
	 call mexErrMsgTxt('Field #31 of Input #1 is not a m*2 vector.')
	endif
	BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 31))
	allocate (testAngle(m,2))
	allocate (testAnglePcum(m))
	numberAngle = m
	call mxCopyPtrToReal8(BinEnergy_pr, testAngle, m*2)

      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 32)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 32))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 32))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #32 of Input #1 is not a scalar.')
	endif
	 BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 32))
	   call mxCopyPtrToReal8(BinEnergy_pr, r_UsePhotSpectrum, 1)
       OpenField = idnint(r_UsePhotSpectrum)
!	If OpenField == 0; calculated by beamlet.
!	Thus 'Horn effect' will be incoporated outside DPM code, used as the PB weight based on the
!	off-axis-angle.


!!! JC Aug 06 2007
! Add flag to turn on/off off-axis-softening
       if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 33)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 33))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 33))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #33 of Input #1 is not a scalar.')
	endif
	 BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 33))
	   call mxCopyPtrToReal8(BinEnergy_pr, r_UsePhotSpectrum, 1)
       Softening = idnint(r_UsePhotSpectrum)



      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 34)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 34))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 34))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #34 of Input #1 is not a scalar.')
	endif
	 BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 34))
	   call mxCopyPtrToReal8(BinEnergy_pr, maxSampleAngle, 1)


      if(mxIsNumeric(mxGetFieldByNumber(prhs(1), 1, 35)) .eq. 0) then
         call mexErrMsgTxt('Input must be numeric.')
	endif
	m = mxGetM(mxGetFieldByNumber(prhs(1), 1, 35))
	n = mxGetN(mxGetFieldByNumber(prhs(1), 1, 35))
	if (m .ne. 1 .or. n .ne. 1) then
	 call mexErrMsgTxt('Field #35 of Input #1 is not a scalar.')
	endif
	 BinEnergy_pr = mxGetPr(mxGetFieldByNumber(prhs(1), 1, 35))
	   call mxCopyPtrToReal8(BinEnergy_pr, maxSampleAngleFF, 1)




!!! JC Jul. 26 2006
!Beginning of add the accumulated probablity for the secondary source.

	FlatFilterR(1) = 0
	FlatFilterPcum(1) = 0
	numberBinR = 50

	if (UseFlatFilter .eq. 1) then
	DO i = 2,numberBinR
	! Only calculate up to r = 5cm. resolution = 0.1cm
! JC. Apr. 9 2008.
! Set the FlatFilterR Maximum as 4 cm, instead of 5 cm.
! Thus, we'll still have 98% of the FF photons included in the simulation.
		FlatFilterR(i) = (i-1)*5/50.0
		FlatFilterR(i) = (i-1)*4.0/50.0
!	JC July 30, 2006
!	take out FlatFilterR when calculate FlatFilterPcum
!		FlatFilterPcum(i) = FlatFilterPcum(i-1) + FlatFilterR(i)*
!     &		exp(FlatFilterA*FlatFilterR(i)+
!     &			FlatFilterB*FlatFilterR(i)*FlatFilterR(i))*0.1
		FlatFilterPcum(i) = FlatFilterPcum(i-1) + 
     &		exp(FlatFilterA(1)*FlatFilterR(i)+
     &			FlatFilterB(1)*FlatFilterR(i)*FlatFilterR(i))
	ENDDO
	
	elseif (UseFlatFilter .eq. 2) then
!!!	Use Jiang's 3 Gaussian model
	DO i = 2,numberBinR
	! Only calculate up to r = 5cm. resolution = 0.1cm
		FlatFilterR(i) = (i-1)*5/50.0
		FlatFilterPcum(i) = FlatFilterPcum(i-1) + 
     &		0.5*FlatFilterA(1)/(pi*FlatFilterB(1)**2.0)*
     &		exp(-0.5*FlatFilterR(i)**2.0/FlatFilterB(1)**2)+
     &		0.5*FlatFilterA(2)/(pi*FlatFilterB(2)**2.0)*
     &		exp(-0.5*FlatFilterR(i)**2.0/FlatFilterB(2)**2)+
     &		0.5*FlatFilterA(3)/(pi*FlatFilterB(3)**2.0)*
     &		exp(-0.5*FlatFilterR(i)**2.0/FlatFilterB(3)**2)
	ENDDO

	endif
		

!	   write(10,*) 'DPMgateway: number of photon spectrum: ',ndata
!        if (e(ndata).gt.esrc) then
!          write(10,*) 'source:error: Spectrum energy is too high:'
!          write(10,'(1x,2(1pe10.3,1x))') e(ndata),esrc
!          stop
!        endif
        if (dabs(FlatFilterPcum(numberBinR)-1.0d0).gt.eps) then
          write(10,*) 'DPMgateway: Flat Filter PDF not normalized:'
          write(10,*) '        renormalizing to 1.'
          do i=1,numberBinR
          FlatFilterPcum(i)=FlatFilterPcum(i)/FlatFilterPcum(numberBinR)
		if(Debug .eq. 1) then
		   write(10, *) FlatFilterR(i), FlatFilterPcum(i)
		endif
		enddo      
        endif
!end of add the accumulated probablity for the secondary source.



!!! JC Jul. 30 2006
!Beginning of add the accumulated probablity for the secondary source.

!!! JC Sep 27 2006, Add 'OnlyHorn' parameter, can be either 0 or 1
      if (testAngle(1,1) .ne. 1.0) then
            call mexErrMsgTxt('DPMIN.HornCoef(1,1) have to be 1.0')
	stop
	endif

       if (OnlyHorn .eq. 0) then
	
	  testAnglePcum(1) = 0.
	 DO i = 2,numberAngle
	! Only calculate up to r = 0.14 rad, 0.14/100 = resolutoin.= 0.0014
	 testAnglePcum(i)=testAnglePcum(i-1)
     & +(testAngle(i-1,1)-testAngle(i,1))
     & *(1+IncreaseFluence*testAngle(i-1,2))
	!	above: previsouly use testAngle(i-1,2), now use testAngle(i,2)
	! Where, IncreaseFluence serves as a "ratio" to adjust the Horn.
	!	Default is 1.(?)
        ENDDO

        if (dabs(testAnglePcum(numberAngle)-1.0d0).gt.eps) then
          write(10,*) 'DPMgateway:Horn Effect PDF not normalized:'
          write(10,*) '        renormalizing to 1.'
         do i=1,numberAngle
         testAnglePcum(i)=testAnglePcum(i)/testAnglePcum(numberAngle)
		if(Debug .eq. 1) then
			write(10,*) testAngle(i,1), testAnglePcum(i)
	    endif
		enddo      
        endif
       elseif (OnlyHorn .eq. 1) then
! Only Horn effect.
	  testAnglePcum(1) = 0.
	 DO i = 2,numberAngle
	! Only calculate up to r = 0.07 rad, 0.07/200 = resolutoin.= 0.00035
!         write(10,*) testAngle(i)
	 testAnglePcum(i)=testAnglePcum(i-1)
     &	+(testAngle(i-1,1)-testAngle(i,1))
     &	*(1+testAngle(i-1,2))
       ENDDO
        if (dabs(testAnglePcum(numberAngle)-1.0d0).gt.eps) then
          write(10,*) 'DPMgateway:Horn Effect PDF not normalized:'
          write(10,*) '        renormalizing to 1.'
         do i=1,numberAngle
         testAnglePcum(i)=testAnglePcum(i)/testAnglePcum(numberAngle)
!         write(10,*) testAngle(i), testAnglePcum(i)
		enddo      
        endif
        else 
            call mexErrMsgTxt('DPMIN.OnlyHorn can only be 0 or 1.')
	    endif


! Output the contents of DPMIN struct in dpm.out
      write(10,*) 'The following is the parameters defined in DPMIN'
      write(10,'(1x,i10)') maxhis
      write(10,'(1x,1pe10.3)') atime
      write(10,'(1x,i2)') intype
      write(10,'(1x,1pe10.3)') esrc
      write(10,'(1x,1pe10.3)') param
      write(10,'(1x,1pe10.3)') eabs
      write(10,'(1x,1pe10.3)') eabsph
      write(10,*) prefix
!      write(10,*) geometry
      write(10,*) minBoxV(1), minBoxV(2), minBoxV(3)
      write(10,*) maxBoxV(1), maxBoxV(2), maxBoxV(3)
      write(10,'(1x,2(i10,1x))') seed1,seed2
	write(10,*) Typesource
	write(10,*) XYZsource(1), XYZsource(2), XYZsource(3)
	write(10,*) Afilter(1), Afilter(2), Afilter(3)
 	write(10,*) Bfilter(1), Bfilter(2), Bfilter(3) 
	write(10,*) Cfilter(1), Cfilter(2), Cfilter(3) 
	write(10,*) Nslices
	write(10,*) Diameter
	write(10,*) spectrum
	write(10,*) OutputErr
	write(10,*) IsoVector(1), IsoVector(2), IsoVector(3)
	write(10,*) BinEnergy(1), BinEnergy(2)
	write(10,*) UseFlatFilter, FlatFilterA, FlatFilterB
	write(10,*) IsoDistance
	write(10,*) IncreaseFluence

!	Initialize the count for the photons coming from FF
	sampleParticles = 0
	write(10,*) sampleParticles
      do i=1,numberAngle
	write(10,*) TestAngle(i,1), TestAngle(i,2), TestAnglePcum(i)
	enddo
	write(10,*) OpenField
      write(10,*) Softening
	write(10,*) maxSampleAngle
	write(10,*) maxSampleAngleFF


! Comment out the following time function call

!      call initim
c     *** Read the prefix with the name of the data files, truncate it:
!      read(*,'(a100)') buffer
!      write(10,*) buffer
!      call getnam(5,prefix,len)
!      write(10,*) prefix(1:len)



c     *** Read the rectangular RoI in cm and set voxel index values:
!      read(*,'(a100)') buffer
!      read(*,*) xini,xfin,yini,yfin,zini,zfin
! Imply xini,xfin,yini,yfin,zini,zfin are inside of the voxel file.
!!! The following part is changed based on the part of "subroutine init"
!!! Need to make sure it's correct. 

	 xini = minBoxV(1)
	 yini = minBoxV(2)
	 zini = minBoxV(3)
	 xfin = maxBoxV(1) 
	 yfin = maxBoxV(2)
	 zfin = maxBoxV(3)

      nxini = xini/dx+1
      if (nxini.lt.1) nxini = 1
      if (nxini.gt.Unxvox) nxini = Unxvox
      nxfin = xfin/dx+1
!! The nxfin = 36.4/0.2+1 = 182
!! Weird. Should be 183.


      if (nxfin.lt.1) nxfin = 1
      if (nxfin.gt.Unxvox) nxfin = Unxvox
      nyini = yini/dy+1
      if (nyini.lt.1) nyini = 1
      if (nyini.gt.Unyvox) nyini = Unyvox
      nyfin = yfin/dy+1
      if (nyfin.lt.1) nyfin = 1
      if (nyfin.gt.Unyvox) nyfin = Unyvox
      nzini = zini/dz+1
      if (nzini.lt.1) nzini = 1
      if (nzini.gt.Unzvox) nzini = Unzvox
      nzfin = zfin/dz+1
      if (nzfin.lt.1) nzfin = 1
      if (nzfin.gt.Unzvox) nzfin = Unzvox

!!! Allocate counters:
	allocate (lasthi(nxyz))
	allocate (escore(nxyz))
	allocate (escor2(nxyz))
	allocate (etmp(nxyz))

c     *** Cleaning counters:
      nsec = 0
      do 100 i=1,nxyz
        escore(i) = 0.e0
        escor2(i) = 0.e0
        etmp(i) = 0.e0
        lasthi(i) = 0
 100   continue

      write(10,*)
     &  'init: kB by interpolation arrays and secondary stack:'
      kbytes = kbytes+(8*8+1*4+5*2)*maxns*1.d-3
      write(10,'(1x,1pe8.1)') kbytes
      write(10,*) 'init: kB by 3D energy counters:'
      kbytes = (3*8+1*4)*nxyz*1.d-3
      write(10,'(1x,1pe8.1)') kbytes
      write(10,*) ' '
      write(10,*) ' '
      write(10,*) 'init: Done.'
	      nhist = 0

c     *** Loop for every history:
      time0 = cputim()
! JC July 13, 2005. Add time function to get profile of dpm
	time_source_sum = 0.0
	time_calculate_sum = 0.0

 10   nhist = nhist+1

!!! JC Dec. 05, 2005. Get the BinEnergy range, based on the pure pdf -->pcum(1+ndata: 2*ndata)
!!! JC Dec. 09, 2005 UsePhotSpectrum == 1; use DPMIN.PhotSpectrum.
	if (UsePhotSpectrum .eq. 1 .AND. intype .eq. 0) then
	 do i=1,ndata
		if(nhist.ge.pcum_nhist(i) .AND. nhist.lt.pcum_nhist(1+i)) then
			BinEnergy(1)=e_spectrum(i)
			BinEnergy(2)=e_spectrum(i+1)
			exit
		endif
	 enddo	
	endif

	if(intype .eq. -1 .and. nhist .lt. 2) then
! JC Dec. 10 2005 Based on Fippel, Medical Physics, Vol. 30, No.3
! Eq. (29).
		ElecAvg=0.13*esrc+0.55
		NormalizeElec=1.0/(ElecAvg*(1-exp(-esrc/ElecAvg)))
	endif


	  CALL CPU_TIME ( time_begin ) 

	  stopFlag = 0
	  	
        call source()

	  CALL CPU_TIME ( time_end )
	 time_source = time_end - time_begin
	 time_source_sum = time_source_sum + time_source

 	  CALL CPU_TIME ( time_begin ) 

!	If everything goes normally, do the usual stuff
!	If it does NOT, skip the dose calculation part, and only return zero dose.
	
	IF (stopFlag .eq. 0) THEN

c       *** Loop for every particle
20     continue
          if (ptype.eq.0) then
            call photon
          else
            call electr
            if(ptype.eq.1) call putann
          endif

        if (scndry().eq.1) goto 20
	  CALL CPU_TIME ( time_end )
	 time_calculate = time_end - time_begin
	 time_calculate_sum = time_calculate_sum + time_calculate

      call comand(nhist,10000)
      if (loopbk(nhist).eq.0) goto 10

!      call report(nhist,cputim()-time0)
! JC Jun 15 2005
! JC The below block is the original "subroutine report". 

	  CALL CPU_TIME ( time_begin ) 

	call dumpe()
      write(10,*) ' '
      write(10,*) ' '
      write(10,*) 'report: Dose in target voxels'
      write(10,*)
     & '        Voxel interval {nx,ny,nz} of the Region of Interest:'
      write(10,'(4x,3(2(i5,1x),3x))')
     &  nxini,nxfin,nyini,nyfin,nzini,nzfin

!!! JC July 13 2005
!!! The dose is been normalized by the number of history.
!!! So no matter how many particles per unit area(The intensity),
!!! dpm will always has same intensity.

!!! JC Feb 09, 2007
	if (DoseNormFlag .eq. 2) then
		in = 1.d0/sampleParticles
	else
		in = 1.d0/nhist
	endif

      voxvol = dx*dy*dz

	if (outputErr .eq. 1) then

c     *** Get the voxel at which the dose is maximum:
      maxq = 0.0d0
      do 75 k=nzini,nzfin
        do 85 j=nyini,nyfin
          do 95 i=nxini,nxfin
            absvox = getabs(i,j,k)
            if (escore(absvox).gt.maxq) maxq = escore(absvox)
 95       continue
 85     continue
 75   continue
c     *** And take half of the max as the reference value:
      maxq = maxq*0.5d0
      nsig = 0
      avesig = 0.0d0
	
	endif


      write(10,*) ' '
      write(10,*) ' Uncertainty (+-) at 2 sigma'
      write(10,*)
     &' x(cm)      y(cm)      z(cm)      dose(MeV/g)  +-'
      write(10,*)
     &'----------------------------------------------------'
!      real*8, allocatable :: output_x_cm(:), output_y_cm(:), 
!     &   output_z_cm(:), output_dose_MeV_per_g(:), output_two_sigma(:)

	nxyz = (nzfin-nzini+1)*(nyfin-nyini+1)*(nxfin-nxini+1)
!	allocate (output(nxyz, 5))
!!! JC Jun 30 2005
! Only output dose, nothing else, to save memory usage. 

	if (outputErr .eq. 0) then
		allocate (output(nxyz,1))
	elseif (outputErr .eq. 1) then
	allocate (output(nxyz, 2))
	else
	write(10,*) 'Input 1 for output Error; 0 does not.'
	endif

	do i = 1, nxyz
		output(nxyz,1) = 0
	if (outputErr .eq. 1)  output(nxyz,2) = 0
	enddo

	output_count = 1

      do 70 k=nzini,nzfin
        do 80 j=nyini,nyfin
          do 90 i=nxini,nxfin
            absvox = getabs(i,j,k)
            q = escore(absvox)*in

		  !JC Oct. 10 2005. 0/0 is not a number, fix dens
		  if (dens(absvox).eq.0.0) then
			dens(absvox) = dens(absvox)+zero
		  endif

	if (outputErr .eq. 1) then
            sigma = escor2(absvox)*in-q**2
            sigma = dsqrt(dmax1(sigma*in,0.0d0))
            sigma = sigma/(voxvol*dens(absvox)*1.0d6)
		  output(output_count, 2) = 2.d0*sigma
	endif

            q = q/(voxvol*dens(absvox)*1.0d6)
!		  output(output_count, 1) = (i-0.5d0)*dx
!		  output(output_count, 2) = (j-0.5d0)*dy
!		  output(output_count, 3) = (k-0.5d0)*dz

     	  output(output_count, 1) = q
		  output_count = output_count+1

!!! JC resume the write out part. Jun 29, 2005, to debug
!            write(10,'(1x,4(1pe10.3,1x),1pe8.1)')
!     &       (i-0.5d0)*dx,(j-0.5d0)*dy,(k-0.5d0)*dz,q,2.d0*sigma
c           *** Calculate mean rel. variance for voxels with dose > Dmax/2:
!            if (escore(absvox).gt.maxq) then
!              avesig = avesig+(sigma/q)**2
!              nsig = nsig+1
!            endif
 90       continue
 80     continue
 70   continue


! JC Apr. 10, 2008
!	i.e. if (stopFlag == 1)
!	return zero dose array, and report Warning/Error within MATLAB
	ELSE
	
	nxyz = (nzfin-nzini+1)*(nyfin-nyini+1)*(nxfin-nxini+1)

		if (outputErr .eq. 0) then
			allocate (output(nxyz,1))

		elseif (outputErr .eq. 1) then

		allocate (output(nxyz, 2))

		else
		write(10,*) 'Input 1 for output Error; 0 does not.'
		endif

		do i = 1, nxyz
			output(nxyz,1) = 0
			if (outputErr .eq. 1)  output(nxyz,2) = 0
		enddo
		    
	CALL mexprintf('Warning: beamlet dose NOT intercept patient.')
	CALL mexprintf('Warning: Check beamlet geometry Please.')
	CALL mexprintf(CHAR(10))


	ENDIF



!      avesig = dsqrt(avesig/nsig)
!      avesig = dsqrt(avesig/(nsig+zero))

c     *** Call to force RNG to report:
      write(10,*) ' '
      call inirng(int8(-666))
      write(10,*) ' '
      write(10,*) 'report: Performance statistics:'
      write(10,*) '  No of histories simulated:'
      write(10,'(4x,i12)') nhist
      if (cputim()-time0.gt.0.0d0) then
        write(10,*) '  CPU non-init and non-report time [t] (s):'
        write(10,'(4x,1pe10.3)') cputim()-time0
        write(10,*) '  Performance (ms/history):'
        write(10,'(4x,1pe10.3)') (cputim()-time0)/nhist*1.0d3
      else
        write(10,*) '  CPU non-init and non-report time [t] (s):'
        write(10,*) '     Sorry, time functions not available'
        write(10,*) '  Performance (ms/history):'
        write(10,*) '     Sorry, time functions not available'
      endif
      write(10,*) '  Average relative sigma from report above (%):'
      write(10,'(4x,1pe10.3)') avesig*100.0d0
      write(10,*) '  Intrinsic efficiency [N*sigma^2]^-1:'
      eff = nhist*avesig**2
      if (eff.gt.0.0d0) then
        write(10,'(4x,1pe10.3)') 1.0d0/eff
      else
        write(10,'(4x,1pe10.3)') 0.0d0
      endif
      write(10,*) '  Absolute efficiency [t*sigma^2]^-1 (s^-1):'
      eff = max((cputim()-time0)*avesig**2,1.0d-30)
      if (cputim()-time0.gt.0.0d0) then
        write(10,'(4x,1pe10.3)') 1.0d0/eff
      else
        write(10,*) '     Sorry, time functions not available'
      endif
      write(10,*) ' '
      write(10,*) ' '
      write(10,*) 'Have a nice day. '
      write(10,*) ' '
	
!!! JC July 13 2005
	CALL CPU_TIME ( time_end ) 
	time_report = time_end - time_begin
	write(10,*) 'Time in generating particles is ', time_source_sum
	write(10,*) 'Time in calculating is ', time_calculate_sum
	write(10,*) 'Time in reporting results is ', time_report
	write(10,*) 'nhist =', nhist
	write(10,*) 'sampleParticles=', sampleParticles
	
! JC Jun 15 2005
! JC The above block is the original "subroutine report". 

! Commented out the following time function call.
!      call endtim


!!! Test how long the program takes to run.
!	USE DFPORT
	 !INTEGER(4) int_time
	 !character*8 char_time
	 !int_time = TIME( )
!	 call TIME(char_time)
!	 print *, 'Integer: ', int_time, 'time: ', char_time
!
!      stop

C     Create matrix for the return argument.
! JC July 13, 2005, comment out, no output of sigma
C     Load the output into a MATLAB array.
	if(outputErr.eq.1) then
      plhs(1) = mxCreateDoubleMatrix(nxyz, 2, 0)
      output_pr = mxGetPr(plhs(1))
      call mxCopyReal8ToPtr(output, output_pr, nxyz*2)
	endif

	if(outputErr.eq.0) then
      plhs(1) = mxCreateDoubleMatrix(nxyz, 1, 0)
      output_pr = mxGetPr(plhs(1))
      call mxCopyReal8ToPtr(output, output_pr, nxyz*1)
	endif

!	JC Apr 27. 2007  Add 2nd output
      plhs(2) = mxCreateDoubleMatrix(1, 1, 0)
      output_pr = mxGetPr(plhs(2))
      call mxCopyReal8ToPtr(real(sampleParticles, 8), output_pr, 1)


	close(10)
	close(6)

      !!!	Deallocate all the dynamically allocated arrays. 
	deallocate (output)
	deallocate (dens)
	deallocate (mat)
	deallocate (lasthi)
	deallocate (escore)
	deallocate (escor2)
	deallocate (etmp)
	
!	if (intype.eq.0) then
	deallocate (e)
	deallocate (pcum)	
	deallocate (e_spectrum)
	deallocate (pcum_nhist)
	deallocate (testAngle)
	deallocate (testAnglePcum)

!	endif
     
!      return
      end

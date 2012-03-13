c*******************************************************************
c* DPM                                                             *
c* Short description                                               *
c*   Transpofrt of MeV electrons in a 3D voxel geometry             *
c*                                                                 *
c* Copyright (c) 2000,2001                                         *f
c* The University of Barcelona                                     *
c*                                                                 *
c* Permission to use, copy, modify, distribute and sell this       *
c* software and its documentation for any purpose is hereby granted*
c* without fee, provided that the above copyright notice appear in *
c* all copies and that both that copyright notice and this         *
c* permission notice appear in supporting documentation.  The      *
c* University of Barcelona makes no representations about the      *
c* suitability of this software for any purpose. It is provided    *
c* "as is" without express or implied warranty.                    *
c*                                                                 *
c* Copyright (c) 2000,2001                                         *
c* Polytechnical University of Catalonia                           *
c*                                                                 *
c* Permission to use, copy, modify, distribute and sell this       *
c* software and its documentation for any purpose is hereby granted*
c* without fee, provided that the above copyright notice appear in *
c* all copies and that both that copyright notice and this         *
c* permission notice appear in supporting documentation.  The      *
c* Polytechnical University of Catalonia makes no representations  *
c* about the suitability of this software for any purpose. It is   *
c* provided "as is" without express or implied warranty.           *
c*                                                                 *
c* Copyright (c) 2000,2001                                         *
c* The University of Michigan                                      *
c*                                                                 *
c* Permission to use, copy, modify, distribute and sell this       *
c* software and its documentation for any purpose is hereby granted*
c* without fee, provided that the above copyright notice appear in *
c* all copies and that both that copyright notice and this         *
c* permission notice appear in supporting documentation.  The      *
c* University of Michigan makes no representations about the       *
c* suitability of this software for any purpose. It is provided    *
c* "as is" without express or implied warranty.                    *
c*                                                                 *
c* Dependencies:                                                   *
c*   -> exports common /dpmpart/  to geometry routines             *
c*   -> imports /dpmvox/ from libgeom.f                            *
c*                                                                 *
c* Last updates                                                    *
c*   2001-02-09   JS  Fully Uncoupled Event Logic (FUEL) &         *
c*                    multi-material q(u;E) surface implemented.   *
c*   2000-11-29   SW  Modified for release.                        *
c*   2000-03-08   SW                                               *
c*   1999-02-26   JS  Created.                                     *
c*******************************************************************

! Remove the main program.
! Replace it with DPMgateway.f
! "DPMgateway.f" will also replace "subroutine init"


      subroutine source
c*******************************************************************
c*    Creates a new primary particle state                         *
c*                                                                 *
c*    Output:                                                      *
c*      ptype -> -1 if it is an electron, 0 when it is a photon    *
c*      energy -> kinetic energy                                   *
c*      {vx,vy,vz} -> direction of flight                          *
c*      {x,y,z} -> position                                        *
c*      vox -> voxel#                                              *
c*    Comments:                                                    *
c*      -> It is this routine's responsability to make sure that   *
c*         all dynamic variables are assigned valid values; in     *
c*         particular, kinetic energy must be in the interval      *
c*         (Emin,Emax) defined by the material data generated with *
c*         predpm.                                                 *
c*******************************************************************




! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX
	use DPMSOURCE
	use rayBox
	use COLLIMATOR

      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
      
	integer*8 intype, temp
      real*8 esrc,eabs,eabsph,param
      common /dpmsrc/ esrc,eabs,eabsph,param,intype

      real*8 rng,zeroc,zero
      parameter (zero=1.d-30)

!!!	The following declaration of variables are for SOURCE 1.
!!!   Disk collimator, perpendicular to z axis.
!!!	They have been moved since the variable declaration can't be put inside of 
!!!	select case block.
	real*8 costhe,sinthe, phi,s,pi,smin,smax, thet, hfside
      parameter (pi=3.1415926535897932d0)
      character*80 buffer
      integer*8 i,seeki
	real*8 s_square_max, s_square_min, s_square,d

!!!	The following declaration of variables are for SOURCE 2.
!!! Rectangular collimator

	real*8 l(3), m(3), n(3), llength, mlength, nlength
	real*8 NBfilter(3), NCfilter(3)
	real*8 xthe1, xthe2
	real*8 Endsource(3), NEndsource(3), Nv(3)
	real*8 Nx, Ny, Nz, Nnorm, DisBox, rayBoxIntersection
	integer*8 t
!!! JC July 13, 2005, Added the following variables to confine
!!1 angle phi, to make it sample the smaller region.
	real*8 NDfilter(3), cos_phi, phi_A, phi_B, phi_C, phi_D, temp_phi
	real*8 theta, s_theta 
!JC Added to account the off-axis softening Oct. 12 2005 JC
!JC Nov. 08 05, added to get the averaged energy from the sampling
      integer*8 maxhis
      real*8 atime
      common /dpmsim/ atime,maxhis

!JC Added for secondary source
	real*8 XYZisocenter(3), pointD(3), deltaAngle, deltaR
	real*8 detA, invA(3,3)
!JC Add XYZFlatSource(3) into DPMVOX module
!JC So the values will be kept, no need to update it everytime.
!	real*8 XYZFlatSource(3)
!JC Added eps, to correct the small offset of calculated (x,y,z) of the sampled particles.
        real*8 eps
        parameter (eps=1.d-10)
        real*8 temp_x, temp_y
!JC Apr. 09 2008
! Add New variable for FlatFilter
	real*8 EndXYZFlatSource(3)


c     *** SOURCE 0:
c     * Monoenergetic, normal, square parallel beam, side='param':
!!!	Make the selections of source can be controlled throught
!!	the input file: dpm.in

	select case (Typesource)
	case(0)
      
	ptype = intype
      energy = esrc
      vx = 0.d0
      vy = 0.d0
      vz = 1.d0
      x = xmid+param*(rng()-0.5d0)
      y = ymid+param*(rng()-0.5d0)
      z = +zero
      call where
	
!!!
cc     *** SOURCE 1: ICCR2000 benchmark
cc       * Centered square beam, side='param', point source @ z=-100 cm:
c
	case(1)
c
      ptype = intype	
	energy = esrc
c
	if (nhist.lt.2) then
cc       *** Init:
        hfside = 0.5d0*param
!!!        cosmin = -Zsource/dsqrt(Zsource**2+0.5d0*Diameter**2)
	
	thet = 0.0d0
	s_square_max = 
     &	(Afilter(1)+0.5*Diameter*dcos(thet)-XYZsource(1))**2
     &	+(Afilter(2)+0.5*Diameter*dsin(thet)-XYZsource(2))**2
     &	+(Afilter(3)-XYZsource(3))**2
	s_square_min = s_square_max

	DO I = 1, Nslices
	
	thet = I*2.0d0*pi/Nslices
	s_square = (Afilter(1)+0.50*Diameter*dcos(thet)-XYZsource(1))**2
     &	+(Afilter(2)+0.50*Diameter*dsin(thet)-XYZsource(2))**2
     &	+(Afilter(3)-XYZsource(3))**2
	if (s_square .gt. s_square_max) s_square_max = s_square
	if (s_square .lt. s_square_min) s_square_min = s_square
	
	END DO

	cosmin = (Afilter(3)-XYZsource(3))/sqrt(s_square_max)
	cosmax = (Afilter(3)-XYZsource(3))/sqrt(s_square_min)

      endif
cc     *** Sample direction in a cone and reject if not inside the disk:
 10   continue
!!        costhe = cosmin+(1.0d0-cosmin)*rng()
	costhe = cosmin+(1.0d0-cosmin)*rng()
        sinthe = dsqrt(1.0d0-costhe**2)
        phi = 2.0d0*pi*rng()
        vx = sinthe*dcos(phi)
        vy = sinthe*dsin(phi)
        vz = costhe
        x = XYZSource(1)
        y = XYZSource(2)
        z = XYZSource(3)
cc       *** Find intersection with z=Zfilter plane:
        s = (Afilter(3)-XYZsource(3))/vz
        x = x+s*vx
        y = y+s*vy
        z = Afilter(3)
	  d = ((x-Afilter(1))**2.0+(y-Afilter(2))**2.0)
      if (d .gt. ((0.5d0*Diameter)*(0.5d0*Diameter)))
     & goto 10

cc       *** Find intersection with z=0 side of the universe:
        s = -z/vz
        x = x+s*vx
        y = y+s*vy
        z = +zero
      if (x.lt.minBoxV(1).or.x.gt.maxBoxV(1).or.
     & y.lt.minBoxV(2).or.y.gt.maxBoxV(2)) goto 10
      call where
      if (absvox.eq.0) then
        write(10,*)
     &  'source:error: Particle not in universe! v{x,y,z}&vox{x,y,z}:'
        write(10,'(3(1x,1pe10.3),3(1x,i6))') vx,vy,vz,xvox,yvox,zvox
        write(10,*)
     &  '              check source() for errors.'
        stop
      endif

	case(2)
c
      ptype = intype	
	energy = esrc
! July 10, 2005 Debug, crash when nhist== 77656
!	if (nhist.eq.77677) then
!	write(10,*) 'debug'
!	endif

      if 
     & (XYZsource(1).ge.minBoxV(1).and.XYZsource(1).le.maxBoxV(1).and.
     & XYZsource(2).ge.minBoxV(2).and.XYZsource(2).le.maxBoxV(2).and.
     & XYZsource(3).ge.minBoxV(3).and.XYZsource(3).le.maxBoxV(3)) then
	write (10,*) 'Source is inside the CTscan. DPM stopped.'
	stop 'Source is inside the CTscan. DPM stopped.'
	endif


!!!	JC July 20 2006, Add Gaussian Source. Only Add the primary/1st Source for now.
!	Using the direct sampling method.
!	Base formula: x = sigma*sqrt(-2.0*log(rng()))) * cos(2.0*pi*rng())
!	First, get deltaX, deltaY, added to the XYZsource, where XYZsource(3), z, stays the same.
15	if (UseFlatFilter .ne. 0) then
!!!!	NEED TO IMPLEMENT THIS PART
!!!!  For nhist =1, need to find the transform of the coordinates system. Only need to do it once.
!!!!	However, need to perform the sampling of the source for each number of history
!step 1: Get the isocenter location, based on the isdistance and isovector
	Do i = 1, 3
	XYZisocenter(i) = XYZsource(i) + IsoDistance * IsoVector(i)
	XYZFlatSource(i) = XYZsource(i) + FlatFilterDist * IsoVector(i)
	EndDo

!Step 2: Pick an arbitrary point on the plane perpendicular to the IsoVector.
!	point D, assume xD = XYZisocenter(1) +10 cm, zD = XYZisocenter(3)+10 cm
	pointD(1)=XYZisocenter(1) + 10
	pointD(2)=XYZFlatSource(2)+((XYZFlatSource(1)-XYZisocenter(1))*10.0
     &	+(XYZFlatSource(3) - XYZisocenter(3))*10.0)
     &	/(XYZFlatSource(2)-XYZisocenter(2))
	pointD(3)=XYZisocenter(3) +10
	
	if(Debug .eq. 1) then
	write(10,*) pointD(1), pointD(2), pointD(3)
	write(10,*) XYZFlatSource(1), XYZFlatSource(2), XYZFlatSource(3)
	write(10,*) XYZisocenter(1), XYZisocenter(2), XYZisocenter(3)  
	endif 
	
!Step 3: Define the new coordinates system as:
!	source->ponitD is x axis
!	cross(isocent->source, source->pointD) is y axis
!	inverse of the isovector is z axis
	llength = dsqrt((pointD(1)-XYZFlatSource(1))**2.0
     &	+(pointD(2)-XYZFlatSource(2))**2.0
     &	+(pointD(3)-XYZFlatSource(3))**2.0)

		mlength = dsqrt((XYZFlatSource(1)-XYZisocenter(1))**2.0
     &	 +(XYZFlatSource(2)-XYZisocenter(2))**2.0
     &	 +(XYZFlatSource(3)-XYZisocenter(3))**2.0)

	Do i=1, 3
			l(i)=(pointD(i)-XYZFlatSource(i))/llength
			m(i)=(XYZFlatSource(i)-XYZisocenter(i))/mlength
	End do
	! l is the xAxis direction vector
	! n, i.e. cross(l, m) is yAxis direction vector
	    n(1) = l(2) * m(3) - l(3) * m(2);
	    n(2) = l(3) * m(1) - l(1) * m(3);
	    n(3) = l(1) * m(2) - l(2) * m(1);
		nlength = sqrt(n(1)**2.0 +n(2)**2.0+n(3)**2.0)
		n(1)=-n(1)/nlength
		n(2)=-n(2)/nlength
		n(3)=-n(3)/nlength
	! zAxis is in the inverse direction of IsoVector
	Do i = 1, 3
		m(i) = -IsoVector(i)
	End Do

	Do i = 1, 3
		A(1,i) = l(i)
		A(2,i) = n(i)
		A(3,i) = m(i)
	End Do

!	write(10, *) A(1,1), A(1,2), A(1,3)
!	write(10, *) A(2,1), A(2,2), A(2,3)
!	write(10, *) A(3,1), A(3,2), A(3,3)


	Do i = 1, 3
	Nsource(i)=A(i,1)*XYZFlatSource(1)+A(i,2)*XYZFlatSource(2)
     &	+A(i,3)*XYZFlatSource(3)
	End Do
	if(Debug .eq. 1) then
	write(10,*) Nsource(1), Nsource(2), Nsource(3)
	endif

!! JC. Oct 09, 2006
!! Add a uniform circular disk electron source, at the flattening filter location, z.

16        if (ptype == -1) then
33        temp_x = (rng()-0.5d0)*6.0d0
          temp_y = (rng()-0.5d0)*6.0d0
          if ((temp_x * temp_x + temp_y * temp_y).GT.3.0d0) then
          go to 33
!! If the radius is larger than the specified value: 3cm, re-sample
          else
             Nsource(1) = Nsource(1) + temp_x
             Nsource(2) = Nsource(2) + temp_y
          end if
         else
! For photons on the flattening filter
! Now find a point on the z = const. = Nsource(3) plane,
	i = seeki(FlatFilterPcum, rng(), numberBinR)
	deltaAngle = 2.0*pi*rng()

	deltaR = FlatFilterR(i)+(FlatFilterR(i+1)-FlatFilterR(i))*rng()
	
!	write(10,*) Nsource(1), Nsource(2), Nsource(3), deltaR
	Nsource(1) = Nsource(1) + dcos(deltaAngle)*deltaR
	Nsource(2) = Nsource(2) + dsin(deltaAngle)*deltaR
! JC. Oct 09, 2006    
        endif

!	write(10,*) Nsource(1), Nsource(2), Nsource(3), deltaR
! Transfer back the coordinates into the original coordinates system
! Need to calculate inverse of A
	detA = A(1,1)*(A(2,2)*A(3,3)-A(2,3)*A(3,2))
     &	-A(1,2)*(A(2,1)*A(3,3)-A(2,3)*A(3,1))
     &	+A(1,3)*(A(2,1)*A(3,2)-A(3,1)*A(2,2))

	invA(1,1) = (A(2,2)*A(3,3)-A(2,3)*A(3,2))/detA
	invA(2,1) = (A(1,3)*A(3,2)-A(1,2)*A(3,3))/detA
	invA(3,1) = (A(1,2)*A(2,3)-A(2,2)*A(1,3))/detA
	invA(1,2) = (A(2,3)*A(3,1)-A(3,3)*A(2,1))/detA
	invA(2,2) = (A(1,1)*A(3,3)-A(1,3)*A(3,1))/detA
	invA(3,2) = (A(1,3)*A(2,1)-A(2,3)*A(1,1))/detA
	invA(1,3) = (A(2,1)*A(3,2)-A(2,2)*A(3,1))/detA
	invA(2,3) = (A(1,2)*A(3,1)-A(1,1)*A(3,2))/detA
	invA(3,3) = (A(1,1)*A(2,2)-A(1,2)*A(2,1))/detA


	Do i = 1, 3
	EndXYZFlatSource(i)=invA(1,i)*Nsource(1)+invA(2,i)*Nsource(2)
     &	+invA(3,i)*Nsource(3)
	End Do

	else
	XYZFlatSource(1) = XYZsource(1)
	XYZFlatSource(2) = XYZsource(2)
	XYZFlatSource(3) = XYZsource(3)
	EndXYZFlatSource(1) = XYZFlatsource(1)
	EndXYZFlatSource(2) = XYZFlatsource(2)
	EndXYZFlatSource(3) = XYZFlatsource(3)

	endif
	
	if(Debug .eq. 1) then
      write(10,*) XYZFlatSource(1), XYZFlatSource(2), XYZFlatSource(3)
      write(10,*) EndXYZFlatSource(1), EndXYZFlatSource(2), 
     &	EndXYZFlatSource(3)
	endif


! A rectangle collimator
!	% Define direction of (corner2-corner1) as the new X axis
!	l = (corner2-corner1)/sqrt(dot((corner2-corner1),(corner2-corner1)));
!	% Define direction of (corner3-corner2) as the new Y axis
!	m = (corner3-corner2)/sqrt(dot((corner3-corner2),(corner3-corner2)));
!	% Define the nor+mal direction of the rectangule as the new Z axix
!	n = cross((corner2-corner1), (corner3-corner2));
!	n = n/sqrt(dot(n,n));
	
	if (nhist.lt.2 .OR. UseFlatFilter .ne. 0)then
	! Need to calculte the transformation matrix for each source point,
	! if the flat filter source is turned on.
!JC Nov. 08 05. Added Avg_Energy, to get the averaged energy of the spectrum/particles	
	Avg_Energy = 0.0

	llength = dsqrt((Bfilter(1)-Afilter(1))**2.0
     &	+(Bfilter(2)-Afilter(2))**2.0+(Bfilter(3)-Afilter(3))**2.0)
	mlength = dsqrt((Cfilter(1)-Bfilter(1))**2.0
     &	 +(Cfilter(2)-Bfilter(2))**2.0+(Cfilter(3)-Bfilter(3))**2.0)
		
		Do i=1, 3
			l(i)=(Bfilter(i)-Afilter(i))/llength
			m(i)=(Cfilter(i)-Bfilter(i))/mlength
		End do
 
! Calculate the CrossProduct of the 
	    n(1) = l(2) * m(3) - l(3) * m(2);
	    n(2) = l(3) * m(1) - l(1) * m(3);
	    n(3) = l(1) * m(2) - l(2) * m(1);
		nlength = sqrt(n(1)**2.0 +n(2)**2.0+n(3)**2.0)
		n(1)=n(1)/nlength
		n(2)=n(2)/nlength
		n(3)=n(3)/nlength

!	%Thus, in the new coordinates, the rectangule is in the plane z = const. 
!	%And its sides are parallel to the X and Y axis of the new coordinates respectively.
!	%the coordinates of four new corners are:
!	A = [l; m; n] 
! A = l(1) l(2) l(3) =   A(1,1) A(1,2) A(1,3)
!	m(1) m(2) m(3)     A(2,1) A(2,2) A(2,3)
!	n(1) n(2) n(3)     A(3,1) A(3,2) A(3,3)

	Do i = 1, 3
		A(1,i) = l(i)
		A(2,i) = m(i)
		A(3,i) = n(i)
	End Do

!	Ncorner1 = A*corner1'

!	Ncorner2 = A*corner2'
!	Ncorner3 = A*corner3'

	Do i = 1, 3
	NAfilter(i)=A(i,1)*Afilter(1)+A(i,2)*Afilter(2)+A(i,3)*Afilter(3)
	NBfilter(i)=A(i,1)*Bfilter(1)+A(i,2)*Bfilter(2)+A(i,3)*Bfilter(3)
	NCfilter(i)=A(i,1)*Cfilter(1)+A(i,2)*Cfilter(2)+A(i,3)*Cfilter(3)
	Nsource(i)=A(i,1)*EndXYZFlatSource(1)+A(i,2)*EndXYZFlatSource(2)
     &	+A(i,3)*EndXYZFlatSource(3)

	End Do

	mid_x = 0.5*(NAfilter(1)+NBfilter(1))
	mid_y = 0.5*(NCfilter(2)+NBfilter(2))
	halfside_x = 0.5*dabs(NBfilter(1)-NAfilter(1))
	halfside_y = 0.5*dabs(NCfilter(2)-NBfilter(2))

!!! The maximum length allowed to trace the ray from the source position
!!! to the box/CTscan

!!!	Distance = 2.0*max(norm(source-minBoxV),norm(source-maxBoxV))
	Distance = 2.0*max(dsqrt((EndXYZFlatSource(1)-minBoxV(1))**2.0
     &+(EndXYZFlatSource(2)-minBoxV(2))**2.0
     &+(EndXYZFlatSource(3)-minBoxV(3))**2.0),
     &	dsqrt((EndXYZFlatSource(1)-maxBoxV(1))**2.0
     &+(EndXYZFlatSource(2)-maxBoxV(2))**2.0
     &+(EndXYZFlatSource(3)-maxBoxV(3))**2.0))

cc    
!!! In order to sample the particle direction in a cone instead of on a sphere,
!!! Need to calculate the maximum thet from the source to the collimator.
! JC Mar 26, 2007
! Delete the codes calculating 'cosmax', 'cosmin'
	
! JC July 13, 2005
	NDfilter(1) = NAfilter(1)
	NDfilter(2) = NCfilter(2)
	NDfilter(3) = NAfilter(3)


	endif

! temp is the counter of the how many samples taken for one history/particle.
! Throw out an error message if it's a dead loop, i.e. too many samples taken
! 
! JC Mar 26, 2007
!	temp should start from 1 instead of 0, since it updates after one trial of sampling.
	temp = 1
cc     *** Sample direction in a cone and reject if not inside the rectangle:
 12   continue
	  if (temp.gt.1.0d1) then
	  write (10, *) 'Sampled 10 times, The ray from the point sour
     &ce / the collimatordoes does not intercept the Region of Interest'
	  write (10, *) 'Please check the source/collimator/geomtry.'
	  write (10, *) NAfilter(1), NAfilter(2), NAfilter(3)
	  write (10, *) NBfilter(1), NBfilter(2), NBfilter(3)
	  write (10, *) NCfilter(1), NCfilter(2), NCfilter(3)
	  write (10, *) 'nHist = ', nhist
! JC Sep 14, 2007
!	For FF, it is possible that one sampled particle from it, passing the beamlet(openning) will never hit the phantom,
!	Should give it more chance to try.
!	So instead of break the program, just go back to the very beginning of the case (2).
		if (UseFlatFilter .eq. 0) then
! JC Apr. 10, 2008
!	Instead of "stop" DPM code, set the flag, and return to the DPMgateway.f, and return to MATLAB
!			stop
			stopFlag = 1
			return;
		else 
			go to 15 
! JC Apr. 09, 2008; By adding one variable: EndXYZFlatSource, keep the same "XYZFlatSource".
!	Unfinished.
!	Thus no need to repeat the calculation between The line marked as "15" and "16".
!			go to 16 
!	A potential problem with this change is that it may end up with a dead loop.
!	Better to use a new variable to limit the number of loops this can go through.
		endif
	  	
	  endif

	  xthe1 = rng()
	  xthe2 = rng()

!!! JC July 30 2006 
!!! Incroprate the horns effect
!!! Do not use this horns effect for flattening filter. 
!       write(10,*) cosmax, cosmin
	 if (UseFlatFilter .eq. 0 .AND. OpenField .eq. 1) then
        i=seeki(testAnglePcum,xthe1,numberAngle)
        vz=testAngle(i,1)+(testAngle(i+1,1)-testAngle(i,1))*rng()
	  vx = dsqrt(1-vz*vz)*dcos(2*pi*xthe2)
	  vy = dsqrt(1-vz*vz)*dsin(2*pi*xthe2) 


cc       *** Find intersection with z=Zfilter plane:
        s = dabs((NAfilter(3)-NSource(3))/vz)
        NEndsource(1) = NSource(1)+s*vx
        NEndsource(2) = NSource(2)+s*vy
        NEndsource(3) = NAfilter(3)
!	  NEndsource(3) = z+s*vz
		if(Debug.eq.1) then
			open(11, file='./local/test.out', status='REPLACE')
			write(11,*) i, testAngle(i,1), vz
		endif

	 elseif (UseFlatFilter .ne. 0 .AND. OpenField .eq. 1) then
	  cosmin = dcos(maxSampleAngleFF)
	  cosmax = 1.0d0
	  vz = cosmin+(cosmax-cosmin)*xthe1
	  vx = dsqrt(1-vz*vz)*dcos(2*pi*xthe2)
	  vy = dsqrt(1-vz*vz)*dsin(2*pi*xthe2) 


cc       *** Find intersection with z=Zfilter plane:
        s = dabs((NAfilter(3)-NSource(3))/vz)
        NEndsource(1) = NSource(1)+s*vx
        NEndsource(2) = NSource(2)+s*vy
        NEndsource(3) = NAfilter(3)
!	  NEndsource(3) = z+s*vz

	 else 
! JC Mar 26, 2007
	! Not openField(??), use predetermined cosmin, cosmax
	! sample (x,y) 
		NEndsource(1) = NAfilter(1)+xthe1*(NBfilter(1)-NAfilter(1))
		NEndsource(2) = NBfilter(2)+xthe2*(NCfilter(2)-NBfilter(2))
		NEndsource(3) = NAfilter(3)

	 endif
			


	if(Debug.eq.1) then
		write(10,*) NEndsource(1), NEndsource(2), NEndsource(3)
		write(10, *) vx, vy, vz
	endif

   	    if ((dabs(NEndsource(1) - mid_x).gt.(halfside_x+eps)) 
     &	.or.(dabs(NEndsource(2) - mid_y).gt.(halfside_y+eps))) then
       	temp=temp+1
		go to 12
		else
	    t = 1;
	    ! Transform everything(point source (Knew); 
            ! particles' intecept with the rectangle)
	    ! back into the original coordinate system.
	! inv(A) = At == A transpose
	!	Oldxyz = inv(A)*[x y z]'
!!! JC July 13 2005, output to examine
!	write(6,*) NEndsource(1), NEndsource(2), NEndsource(3),
!     &	 vx, vy, vz

	Do i = 1, 3
	Endsource(i)=A(1,i)*NEndsource(1)+A(2,i)*NEndsource(2)
     &	+A(3,i)*NEndsource(3)
	End Do
 
	Nnorm = dsqrt((Endsource(1)-EndXYZFlatSource(1))**2.0
     &	 +(Endsource(2)-EndXYZFlatSource(2))**2.0
     &     +(Endsource(3)-EndXYZFlatSource(3))**2.0)
	
	vx = (Endsource(1)-EndXYZFlatSource(1))/Nnorm
	vy = (Endsource(2)-EndXYZFlatSource(2))/Nnorm
	vz = (Endsource(3)-EndXYZFlatSource(3))/Nnorm

!!! Need to calculate the directin vector in the old coordinate system.

	rayOrgV(1) = Endsource(1)
	rayOrgV(2) = Endsource(2)
	rayOrgV(3) = Endsource(3)
	rayDeltaV(1) = Distance * vx
	rayDeltaV(2) = Distance * vy
	rayDeltaV(3) = Distance * vz

	DisBox = rayBoxIntersection()		  
		  if (DisBox.lt.0) then
			temp=temp+1
			go to 12
		  else
				!Calculate the intecept of the ray with the surface of the box.
! Output data for examining.
!	write(10,*) Endsource(1), Endsource(2), Endsource(3), vx, vy, vz
! x, y, z may become negative, but very close to zero. Thus the index for this point will become zero,
! which is unacceptable. So get it inside the CTscan.
! The actual problem is that calculated (x, y, z) might be slightly outside of the CTscan.
! The offset is supposed to be very small. 
! JC July 13 2005, Previously, shift by 1.0d-2, now 2% of the grid size.
! JC Aug 17 2006, Try to use 'eps' as the correct factor.

		  x = Endsource(1)+DisBox*Distance*vx
		if (x.lt.minBoxV(1).and.x.gt.(minBoxV(1)-eps)) 
     &      x = minBoxV(1)+eps
		if (x.gt.maxBoxV(1).and.x.lt.(maxBoxV(1)+eps)) 
     &      x = maxBoxV(1)-eps

		  y = Endsource(2)+DisBox*Distance*vy
		if (y.lt.minBoxV(2).and.y.gt.(minBoxV(2)-eps)) 
     &      y = minBoxV(2)+eps
		if (y.gt.maxBoxV(2).and.y.lt.(maxBoxV(2)+eps)) 
     &      y = maxBoxV(2)-eps

		  z = Endsource(3)+DisBox*Distance*vz
		if (z.lt.minBoxV(3).and.z.gt.(minBoxV(3)-eps)) 
     &      z = minBoxV(3)+eps
		if (z.gt.maxBoxV(3).and.z.lt.(maxBoxV(3)+eps)) 
     &      z = maxBoxV(3)-eps
! Output data for examining.
		if(Debug .eq. 1) then
		write(10,*) x, y, z
		write(10,*) nhist
		write(10,*) vx, vy, vz
		endif 

		call where
	if (absvox.eq.0) then
	  write(10,*)
     &  'source:error: Particle not in universe! v{x,y,z}&vox{x,y,z}:'
	  write(10,'(3(1x,1pe10.3),3(1x,i6))') vx,vy,vz,xvox,yvox,zvox
	  write(10,*)
     &  '              check source() for errors.'
	  stop
	endif
	
		endif

	    endif
    
!	 endif


	CASE DEFAULT
	write(10,*) 'Please specify the source type 0, 1, or 2'
	!!!
	end select


cc     *** Sample photon E from spectrum; E is fixed for electrons:
!      if (ptype.eq.0) then
! 40     continue
!          i = seeki(pcum,rng(),ndata)
!          energy = e(i)+(e(i+1)-e(i))*rng()

!!! JC Oct. 25, 2005
!!! Make BinEnergy beam
	
	if (ptype .eq. 0) then 
		if (BinEnergy(1) .ge. 0) then
		 energy = BinEnergy(1)+rng()*(BinEnergy(2)-BinEnergy(1))
		 energy = 1000000.0*energy
		endif

!!! JC July 21, 2006 TURN on the off-axis-softening
!	Calculate the angle between the center ray(source -> isocenter) and the particle
!	Call it theta

!!! JC Aug 06 2007, add flag "Softening"
	if(Softening .eq. 1 .AND. UseFlatFilter .eq. 0 
     &	.AND. ptype .NE. -1)then
	  theta = dacos(IsoVector(1)*vx+IsoVector(2)*vy+IsoVector(3)*vz)
	  theta = theta*180.0/pi
	  s_theta=(1.0/(1+.00181*theta+.00202*theta**2-.0000942*theta**3))
     &  ** (1.0/0.45)
	  energy = s_theta*energy
	endif

	
	else if (ptype .eq. -1) then
	  energy = -ElecAvg*dlog(1.0-rng()/(NormalizeElec*ElecAvg))
	  energy = 1000000.0*energy
	  if (energy.lt.eabs) energy = eabs		
!	  write(10,*) nhist, energy

	else 
	  write(10, *) 'DPMIN.ParticleType has to be 0 or 1'
        CALL mexprintf('DPMIN.ParticleType has to be 0 or 1')
	  stop
	end if


	Avg_Energy = Avg_Energy+energy/maxhis

!!! JC Dec 07,2005, output theta & energy
	if(Debug .eq. 1) then
	write(10,*) nhist, theta, energy
	endif

	if (nhist .eq. maxhis) then
	write(10, *) 'nhist = ', nhist, 'Avg_Energy =', Avg_Energy
	endif
!!!
!!!	write(10, *),  'energy = ', energy
!!! JC July 10, 2005 Output sample times for every history.
!		  if (temp.gt.1.0d6) then

	if (temp.gt.1.0d4) then
	write(10, *) 'nhist = ', nhist, '   Num of Samples = ', temp
      endif

! JC Add sampleParticles
	sampleParticles = sampleParticles + temp
	end


  	real*8 function rayBoxIntersection ()
!     & (rayOrgV,rayDeltaV,minBoxV,maxBoxV)

!"rayBoxIntersection"
!   Parametric intersection with a ray.  Returns parametric point of
!   intersection in range 0...1 or -1 if no intersection.  A ray whose
!   origin is located inside the box returns a 0.  Rays are represented by
!   an origin, direction, and length, i.e., pV = p0V + t * deltaV.  For the
!   intersecto to be found, the line segment from rayOrgV to
!   rayOrgV+rayDeltaV must intersect the box.
!
!   To find the intersect point, assuming t is not -1, use rayOrgV +
!   rayDeltaV * t.
!
!   rayOrgV     is [x,y,z] of coordinate of ray's origin.
!   rayDeltaV   is [dx,dy,dz] of the ray.
!   minBoxV     is [x,y,z] of the minimum corner of the box.
!   maxBoxV     is [x,y,z] of the maximum corner of the box.
!
!   The output parameter t has a value between 0 and 1 and is the fraction
!   of the ray to the nearest intersection point.
!
!Code by JOD 10/??/03
!Reorg.  JRA 04/01/05 - Removed references to scan and other planC specific
!                       values.  Reorganized code and comments.
!!! Reformatted by JC 05/18/05 - Now in Fortran instead of in MATLAB.
!!! Use module instead of passing parameters by dummy arguments.
!
!Usage:
!   function rayBoxIntersection(rayOrgV,rayDeltaV,minBoxV,maxBoxV)

!The algorithm is based on "Fast Ray-Box Intersection" by Woo in "Graphics Gems I",
!page 395 & cpp implementation by Dun and Parberry "3D Math Primer for Graphics and Games Development",
!Adapted to Matlab code by JOD, Oct 03.

! Check for point inside box, trivial reject, and determine parametric
! distance to each front face
	
	use rayBox
	implicit none
	integer*8  true, false, inside, which
	real*8 x, y, z, xt, yt, zt, t, noIntersection
	
!Return negative number if no intersection:
	noIntersection = -1;
	true = 1;
	false = 0;
	inside = true;
	rayBoxIntersection = 0;

	if (rayOrgV(1) .lt. minBoxV(1)) then
	xt = minBoxV(1) - rayOrgV(1);
		if (xt .gt. rayDeltaV(1)) then
		  rayBoxIntersection = noIntersection;
		  return
		endif
	    xt = xt / rayDeltaV(1);
	    inside = false;
	elseif (rayOrgV(1) .gt. maxBoxV(1)) then
	    xt = maxBoxV(1) - rayOrgV(1);
	    if (xt .lt. rayDeltaV(1)) then
		  rayBoxIntersection = noIntersection;
		  return
	    endif
	    xt = xt / rayDeltaV(1);
	    inside = false;
	else
	    xt = -1.0;
	endif

	if (rayOrgV(2) .lt. minBoxV(2)) then
	    yt = minBoxV(2) - rayOrgV(2);
	    if (yt .gt. rayDeltaV(2)) then
		  rayBoxIntersection = noIntersection;
		  return
	    endif
	    yt = yt / rayDeltaV(2);
	    inside = false;
	else if (rayOrgV(2) .gt. maxBoxV(2)) then 
	    yt = maxBoxV(2) - rayOrgV(2);
	    if (yt < rayDeltaV(2)) then
		  rayBoxIntersection = noIntersection;
		  return
	    endif
	    yt = yt / rayDeltaV(2);
	    inside = false;
	else
	    yt = -1.0;
	endif

	if (rayOrgV(3) .lt. minBoxV(3)) then
	    zt = minBoxV(3) - rayOrgV(3);
	    if (zt .gt. rayDeltaV(3)) then
		  rayBoxIntersection = noIntersection;
		  return
	    endif
	    zt = zt / rayDeltaV(3);
	    inside = false;
	else if (rayOrgV(3) .gt. maxBoxV(3)) then
	    zt = maxBoxV(3) - rayOrgV(3);
	    if (zt .lt. rayDeltaV(3)) then
		  rayBoxIntersection = noIntersection;
		  return
	    endif
	    zt = zt / rayDeltaV(3);
	    inside = false;
	else
	    zt = -1.0;
	endif

! Inside box?
	if (inside) then
	    t= 0.0;
	    return
	endif

	! Select farthest plane - this is
	! the plane of intersection.

	which = 0;
	rayBoxIntersection = xt;
	if (yt .gt. rayBoxIntersection) then
	    which = 1;
	    rayBoxIntersection = yt;
	endif

	if (zt .gt. rayBoxIntersection) then
	    which = 2;
	    rayBoxIntersection = zt;
	endif

   	select case (which)
 
	    case (0) ! intersect with yz plane
        
		  y = rayOrgV(2) + rayDeltaV(2)*rayBoxIntersection;
		  if (y .lt. minBoxV(2) .or. y .gt. maxBoxV(2)) then
			  rayBoxIntersection = noIntersection;
			  return
		  endif
		  z = rayOrgV(3) + rayDeltaV(3)*rayBoxIntersection;
		  if (z .lt. minBoxV(3) .or. z .gt. maxBoxV(3)) then
			  rayBoxIntersection = noIntersection;
			  return
		  endif
        
		  return
        
	    case (1) ! intersect with xz plane
        
		  x = rayOrgV(1) + rayDeltaV(1)*rayBoxIntersection;
		  if (x .lt. minBoxV(1) .or. x .gt. maxBoxV(1)) then
			  rayBoxIntersection = noIntersection;
			  return
		  endif
		  z = rayOrgV(3) + rayDeltaV(3)*rayBoxIntersection;
		  if (z .lt. minBoxV(3) .or. z .gt. maxBoxV(3)) then
			  rayBoxIntersection = noIntersection;
			  return
		  endif
        
		  return
        
	    case (2) ! intersect with xy plane
        
		  x = rayOrgV(1) + rayDeltaV(1)*rayBoxIntersection;
		  if (x .lt. minBoxV(1) .or. x .gt. maxBoxV(1)) then
			  rayBoxIntersection = noIntersection;
			  return
		  endif
		  y = rayOrgV(2) + rayDeltaV(2)*rayBoxIntersection;
		  if (y .lt. minBoxV(2) .or. y .gt. maxBoxV(2)) then
			  rayBoxIntersection = noIntersection;
			  return
		  endif
        
		  return
        
	   case default
        
		  write(10,*) 'error: Failure in rayBoxIntersection.'
      
	end select  
	
	end
	
	
	    subroutine score(edep)
c*******************************************************************
c*    Deposites energy in the corresponding counters               *
c*                                                                 *
c*    Input:                                                       *
c*      edep -> energy being deposited (eV)                        *
c*    Comments:                                                    *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      real*8 edep
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 lasthi
!      real*8 escore,escor2,etmp
!      common /dpmesc/ escore(nxyz),escor2(nxyz),etmp(nxyz),
!     &                lasthi(nxyz)
      integer*8 nxini,nxfin,nyini,nyfin,nzini,nzfin
      common /dpmrpt/ nxini,nxfin,nyini,nyfin,nzini,nzfin

c     *** Do not score if outside the RoI:
      if (xvox.lt.nxini.or.xvox.gt.nxfin.or.yvox.lt.nyini.or.
     &    yvox.gt.nyfin.or.zvox.lt.nzini.or.zvox.gt.nzfin) return

      if (lasthi(absvox).ne.nhist) then
c       *** Transfer energy to final counters:
        escore(absvox) = escore(absvox)+etmp(absvox)
        escor2(absvox) = escor2(absvox)+etmp(absvox)**2
        etmp(absvox) = edep
        lasthi(absvox) = nhist
      else
        etmp(absvox) = etmp(absvox)+edep
      endif
      end


      subroutine dumpe
c*******************************************************************
c*    Dumps all tmp counters into the corresponding final counters *
c*                                                                 *
c*    Input:                                                       *
c*    Comments:                                                    *
c*      -> must be called prior to printing any report when        *
c*         exact-variance is in use                                *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 lasthi
!      real*8 escore,escor2,etmp
!      common /dpmesc/ escore(nxyz),escor2(nxyz),etmp(nxyz),
!     &                lasthi(nxyz)
      integer*8 i

      do 10 i=1,nxyz
        escore(i) = escore(i)+etmp(i)
        escor2(i) = escor2(i)+etmp(i)**2
        etmp(i) = 0.d0
 10   continue
      end


! JC remove subroutine report.
! Use DPM gateway to return vriables back to MATLAB,
! instead of writing into the disk.


      integer*8 function loopbk(n)
c*******************************************************************
c*    Determines whether the simulation is done or not             *
c*                                                                 *
c*    Input:                                                       *
c*      n -> current no. of histories completed                    *
c*    Output:                                                      *
c*      -> 1 if done, 0 else                                       *
c*    Comments:                                                    *
c*******************************************************************
      implicit none
      integer*8 n

      integer*8 maxhis
      real*8 atime
      common /dpmsim/ atime,maxhis

      real*8 elaps,cputim

      loopbk = 0
      if (atime.gt.0.d0) then
        if (elaps().gt.atime) loopbk = 1
      else
        if (cputim().gt.-atime) loopbk = 1
      endif
      if (n.ge.maxhis) loopbk = 1
      end


      subroutine comand(n,nscan)
c*******************************************************************
c*    Reads and executes commands from an external file, allowing  *
c*    in-flight steering of the simulation.                        *
c*                                                                 *
c*    Input:                                                       *
c*      n -> current no. of histories already simulated.           *
c*      nscan -> command file is read every 'nscan' histories.     *
c*      -> From file command.in.  Possible codes are:              *
c*          0     -> Stop reading and get back to work             *
c*          1     -> Write report to file progress.out             *
c*          2 <N> -> Reset No of histories                         *
c*          3 <T> -> Reset simulation time, in s (if defined)      *
c*          4 <string> -> write <string> to stdout                 *
c*          5 <k> -> Following commands apply only to processor #k *
c*    Output:                                                      *
c*      -> Command is executed, command.in  reset to 0             *
c*    Comments:                                                    *
c*      -> Commands are read sequentially until command 0 is found;*
c*         all command arguments (such as <N>) must be preceded    *
c*         by a line feed (as in '2 <return> 200000')              *
c*      -> <string> must not exceed 80 chars.                      *
c*      -> Command 5 is intended for parallel processing; if not   *
c*         given, actions are assumed to refer to all processors;  *
c*         when monoprocessing, all messages are passed to the     *
c*         CPU in use.
c*      -> Note that the simulation may be stopped immediately by  *
c*         resetting <N> to 0.                                     *
c*      -> Be extremely careful before saving file command.in ;    *
c*         a syntax error is likely to cause the program to abort. *
c*******************************************************************
      implicit none
      integer*8 n,nscan

      integer*8 maxhis
      real*8 atime
      common /dpmsim/ atime,maxhis

      integer*8 nlast
      common /comlst/ nlast
      character*80 buffer
      integer*8 iscom(5),i,com,comsum,cpuid,xnp
      real*8 xatime

c     *** Scan for commands once every nscan histories:
      if (n.lt.10) nlast = 0
      if (n-nlast.lt.nscan) return
      nlast = n

c     *** Clear iscom() array:
      do 5 i=1,5
        iscom(i) = 0
 5    continue
      comsum = 0

c     *** Parse command file:
      open(1,file='command.in',err=20)
 10   continue
        read(1,*,err=20) com
        if (com.le.0) then
          goto 20
        else if (com.eq.1) then
          call progre(n)
        else if (com.eq.2) then
          read(1,*,err=20) xnp
          maxhis = xnp
        else if (com.eq.3) then
          read(1,*,err=20) xatime
          atime = xatime
        else if (com.eq.4) then
          read(1,'(a80)',err=20) buffer
        else if (com.eq.5) then
          read(1,*,err=20) cpuid
        else
          write(10,*) 'comand:WARNING: invalid command code; ignored:'
          write(10,*) com
        endif
        if (com.le.5) iscom(com)=1
        comsum = comsum+com
      goto 10
 20   continue
      close(1)

      if (comsum.eq.0) return
c     *** Reset command file:
      open(1,file='command.in')
      write(1,*) ' 0'
      write(1,*) '  '
      write(1,*) '*** Codes:  '
      write(1,*)
     & '0               -> Stop reading and get back to work'
      write(1,*)
     & '1               -> Write report to progress.out'
      write(1,*)
     & '2 <CR> <N>      -> Reset No of histories to N'
      write(1,*)
     & '3 <CR> <T>      -> Reset simulation time to T'
      write(1,*)
     & '4 <CR> <string> -> Write <string> (80 chars max) to stdout'
      write(1,*)
     & '5 <CR> <n>      -> Next commands only for processor #n'
      write(1,*) ' '
      write(1,*) '<CR> stands for carriage return'
      write(1,*) ' '
      close(1)

      write(10,*) 'comand: Command received when Nhist was:'
      write(10,'(1x,i12)') n
      write(10,*) '  Command description:'
      if (iscom(1).eq.1) then
        write(10,*) '  Report written to progress.out'
      endif
      if (iscom(2).eq.1) then
        write(10,*) '  Max Nhist reset to:'
        write(10,'(1x,i12)') maxhis
      endif
      if (iscom(3).eq.1) then
        write(10,*) '  Max time reset to:'
        write(10,'(1x,1pe10.3)') atime
      endif
      if (iscom(4).eq.1) then
        write(10,*) '*** Message from command.in  follows:'
        write(10,'(1x,a80)') buffer
      endif
      if (iscom(5).eq.1) then
        write(10,*)
     &      'comand:WARNING: Parallel processing inquiry; ignored.'
      endif
      write(10,*) '  '
      end


      subroutine progre(n)
c*******************************************************************
c*    This progress report will be printed out when requested by   *
c*    command().                                                   *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      integer*8 n

!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     &          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
!      integer*8 lasthi
!      real*8 escore,escor2,etmp
!      common /dpmesc/ escore(nxyz),escor2(nxyz),etmp(nxyz),
!     &                lasthi(nxyz)

      integer*8 seed1,seed2,getabs,absvox,nxmid,nymid,nzmid
      real*8 q,sigma,in

      in = 1.0d0/n
      nxmid = Unxvox/2+1
      nymid = Unyvox/2+1
      nzmid = Unzvox/2+1
      absvox = getabs(nxmid,nymid,nzmid)
      q = escore(absvox)*in
      sigma = escor2(absvox)*in-q**2
      sigma = dsqrt(max(sigma*in,0.0d0))
      if (q.gt.0.0d0) then
        sigma = 100.0d0*sigma/q
      else
        sigma = 0.0d0
      endif

      open(2,file='progress.out')
      write(2,*) 'Relative uncertainty in central voxel so far (%):'
      write(2,'(1x,f7.2)') sigma
      write(2,*) 'No of histories simulated so far:'
      write(2,'(1x,i12)') n
      seed1 = -1.0d0
      call inirng(seed1)
      seed2 = -1.0d0
      call seed2n(seed2)
      write(2,*) 'Random seeds at this point:'
      write(2,'(1x,2(i12,1x))') seed1,seed2
      write(2,*) ' '
      close(2)
      end


      subroutine electr
c*******************************************************************
c*    Transports an electron until it either escapes from the      *
c*    universe or its energy drops below Eabs                      *
c*                                                                 *
c*    Input:                                                       *
c*      electron initial state                                     *
c*    Output:                                                      *
c*      deposits energy in counters and updates secondary stack    *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      integer*8 ptype
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      integer*8 maxmat,nmat
      parameter (maxmat=5)
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat
      integer*8 matid,event,modeel
      real*8 fuelel,fuelmo,fuelbr,burnel,burnmo,burnbr
      real*8 smax,voxden,ebefor,fuelxt
      common /dpmjmp/ fuelel,fuelmo,fuelbr,fuelxt,
     &                burnel,burnmo,burnbr,smax,voxden,
     &                ebefor,matid,event,modeel
      integer*8 intype
      real*8 esrc,eabs,eabsph,param
      common /dpmsrc/ esrc,eabs,eabsph,param,intype
      real*8 subden,subfac,substp
      common /dpmsub/ subden,subfac,substp
      integer*8 maxhis
      real*8 atime
      common /dpmsim/ atime,maxhis

      real*8 costhe,de,inve
      real*8 pi,twopi,rng,lamoip,sammo,stepip,sbrems
      parameter (pi=3.1415926535897932d0,twopi=2.0d0*pi)

c     *** Loading fuel before take off:
      ebefor = energy
      fuelel = stepip(energy)
      fuelxt = fuelel*rng()
      fuelel = fuelel-fuelxt
      inve = -1.d0/energy
      fuelmo = -lamoip(inve)*dlog(rng())
      fuelbr = -dlog(rng())

c     *** Set switches to steer the flight:
      modeel = 1
      event = -1

c     *** Repeat for every flight stop:
 20   continue
        call flight

        if (event.eq.2) then
c         *** Elastic stop for refueling:
          if (modeel.eq.0) then
c           *** End of second scattering substep, no real interaction:
            ebefor = energy
            fuelel = stepip(energy)
            fuelxt = fuelel*rng()
            fuelel = fuelel-fuelxt
            modeel = 1
            event = 20
          else
c           *** Elastic scattering event:
c           *** opt-qSingleMat ON: activate next line and deact next+1:
            call samsca(ebefor,costhe)
c           * call xsamsca(mat(absvox),ebefor,costhe)
            call rotate(vx,vy,vz,costhe,twopi*rng())
            fuelel = fuelxt
            modeel = 0
          endif

        else if (event.eq.3) then
c         *** Moller stop for refueling; note that:
c           *  no Moller is simulated below energy=2*cutoff;
c           *  energy/2 > de > cutoff(moller) >= Eabs  holds, then
c           *  EnergyFinal = energy-de can never be below Eabs;
c           *  sammo() can also return de=0.
          de = energy*sammo(energy)
          if (de.gt.0.d0) then
            call putmol(de)
            energy = energy-de
          endif
          fuelmo = -lamoip(-1.d0/energy)*dlog(rng())

        else if (event.eq.4) then
c         *** Bremsstrahlung stop for refueling; note that
c           * de > cutoff(brem) >= Eabsph  OR  de=0 --see sambre():
          de = sbrems(energy,mat(absvox))
          if (de.gt.0.d0) then
            call putbre(de)
            energy = energy-de
          endif
          if (energy.lt.eabs) then
c           *** Determine if subEabs transport is needed:
            if (voxden.gt.subden) then
              call score(energy)
            else
              call subabs
            endif
            return
          endif
          fuelbr = -dlog(rng())

        else
c         *** Other event values indicate that history ended:
          return
        endif

      goto 20
      end


      subroutine flight
c*******************************************************************
c*    Transports the particle following a rectiliniar trajectory,  *
c*    taking care of interface crossings and keeping track of      *
c*    energy losses in the corresponding counters (using CSDA)     *
c*                                                                 *
c*    Input:                                                       *
c*      e- initial state                                           *
c*      Fuel variables affecting the flight                        *
c*      event -> event that stopped flight last time; in addition  *
c*                to the output codes,                             *
c*                -1 new particle                                  *
c*                20 end of elastic step                           *
c*    Output:                                                      *
c*      e- final state                                             *
c*      Remaining fuel vars                                        *
c*      event -> kind of event that causes flight to stop:         *
c*                1 run out of energy; absorbed                    *
c*                2 run out of elastic fuel                        *
c*                3 run out of Moller fuel                         *
c*                4 run out of bremsstrahlung fuel                 *
c*               99 escaped from universe                          *
c*    Comments:                                                    *
c*      -> this routine does NOT transport correctly e- below Eabs *
c*      -> internally, 'event' can also have the value 0 to        *
c*         indicate that the particle hit a voxel boundary; the    *
c*         flight is resumed without a stop.                       *
c*      -> the 'fuel vars' are contained in /dpmjmp/.              *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
      integer*8 maxmat,nmat
      parameter (maxmat=5)
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat
      integer*8 matid,event,modeel
      real*8 fuelel,fuelmo,fuelbr,burnel,burnmo,burnbr
      real*8 smax,voxden,ebefor,fuelxt
      common /dpmjmp/ fuelel,fuelmo,fuelbr,fuelxt,
     &                burnel,burnmo,burnbr,smax,voxden,
     &                ebefor,matid,event,modeel
      integer*8 intype
      real*8 esrc,eabs,eabsph,param
      common /dpmsrc/ esrc,eabs,eabsph,param,intype
      real*8 subden,subfac,substp
      common /dpmsub/ subden,subfac,substp

      real*8 inters,scpwip,sback,s,rstpip,ilabip,dedx,newe,news
      real*8 de,infuel

c     *** Init according to the dynamic vars changed:
      if (event.eq.2.or.event.eq.-1) then
        call setv
        smax = inters()
      endif
      event = 0

c     *** Loop until it runs out of fuel:
 10   continue
        s = smax

c       *** Calculate fuel burn rate in the current voxel:
        matid = mat(absvox)
        voxden = dens(absvox)
        dedx = rstpip(matid,energy)*voxden
        newe = max(energy-0.5d0*dedx*s,eabs)
        burnel = scpwip(matid,newe)*voxden
        burnmo = zmass(matid)*voxden
        burnbr = voxden*ilabip(matid,-1.0d0/newe)

c       *** Burn Moller fuel:
        fuelmo = fuelmo-s*burnmo
        if (fuelmo.lt.0.d0) then
          sback = -fuelmo/burnmo
          s = s-sback
          fuelmo = 0.d0
          event = 3
        endif

c       *** Burn bremss fuel:
        fuelbr = fuelbr-s*burnbr
        if (fuelbr.lt.0.d0) then
          sback = -fuelbr/burnbr
          s = s-sback
          fuelmo = fuelmo+sback*burnmo
          fuelbr = 0.d0
          event = 4
        endif

c       *** Burn elastic fuel:
        infuel = fuelel
        fuelel = fuelel-s*burnel
        if (fuelel.lt.0.d0) then
c         *** Refine calculation of scattering 1st MFP:
          news = infuel/(scpwip(matid,energy)*voxden)
          newe = max(energy-0.5d0*dedx*news,eabs)
          news = infuel/(scpwip(matid,newe)*voxden)
          if (news.gt.s) news = s
          sback = s-news
          s = news
          fuelmo = fuelmo+sback*burnmo
          fuelbr = fuelbr+sback*burnbr
          fuelel = 0.d0
          event = 2
        endif

c       *** Accounting for continous energy loss:
        newe = max(energy-0.5d0*dedx*s,eabs)
        de = s*rstpip(matid,newe)*voxden
        energy = energy-de
        call score(de)
        if (energy.lt.eabs) then
c         *** Determine if subEabs transport is needed:
          if (voxden.gt.subden) then
            call score(energy)
          else
            call subabs()
          endif
          event = 1
          return
        endif

c       *** Move the electron:
        x = x+s*vx
        y = y+s*vy
        z = z+s*vz
        smax = smax-s

c       *** Check whether an interaction has not ocurred:
        if (event.eq.0) then
          call chvox()
          if (absvox.eq.0) then
            event = 99
            return
          endif
          smax = inters()
          goto 10
        endif

c       *** Otherwise, run out of fuel so return:
      end


      subroutine subabs
c*******************************************************************
c*    Transport of e- below the nominal Eabs until absorption      *
c*                                                                 *
c*    Input:                                                       *
c*      {x,y,z} -> take off location                               *
c*      {vx,vy,vz} -> direction of flight                          *
c*      energy -> initial kinetic energy                           *
c*    Output:                                                      *
c*      escore -> energy deposited by CSDA                         *
c*    Comments:                                                    *
c*      -> the particle flies following a straight path.           *
c*      -> uses a constant StopPow extracted from reference mat.   *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
      real*8 subden,subfac,substp
      common /dpmsub/ subden,subfac,substp

      real*8 de,s,inters,voxden

 10   continue
        voxden = dens(absvox)
c       *** Determine if further transport is needed:
        if (voxden.gt.energy*subfac) then
          call score(energy)
          return
        endif
        s = inters()
        de = substp*voxden*s
        energy = energy-de
        call score(de)
        call chvox()
        if (absvox.eq.0) then
          return
        endif
        x = x+s*vx
        y = y+s*vy
        z = z+s*vz
      goto 10
      end


      subroutine samsca(e,mu)
c*******************************************************************
c*    Samples cos(theta) according to the G&S distribution.        *
c*    Uses interpolated data for bw and the q surface and this     *
c*    latter quantity to perform a rejection procedure.            *
c*                                                                 *
c*    Input:                                                       *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      mu -> polar angle -cos(theta)-                             *
c*******************************************************************
      implicit none
      real*8 e,mu

      real*8 bw,onebw,u,rng,xbwip,xq2Dip,ie

      ie = -1.d0/e
      bw = xbwip(ie)
      onebw = 1.d0+bw
 10   continue
      u = rng()
      mu = (onebw-u*(onebw+bw))/(onebw-u)
      if (rng().gt.xq2Dip(u,ie)) goto 10
      end


      subroutine xsamsca(matid,e,mu)
c*******************************************************************
c*    Samples cos(theta) according to the G&S distribution.        *
c*    Uses interpolated data for bw and the q surface and this     *
c*    latter quantity to perform a rejection procedure.            *
c*    Multi-material version.                                      *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      mu -> polar angle -cos(theta)-                             *
c*    Comments:                                                    *
c*      -> Identical to samsca() but uses a q surface for each mat.*
c*******************************************************************
      implicit none
      integer*8 matid
      real*8 e,mu

      real*8 bw,onebw,u,rng,bwip,q2Dip,ie

      ie = -1.d0/e
      bw = bwip(matid,ie)
      onebw = 1.d0+bw
 10   continue
      u = rng()
      mu = (onebw-u*(onebw+bw))/(onebw-u)
      if (rng().gt.q2Dip(matid,u,ie)) goto 10
      end


      subroutine putmol(elost)
c*******************************************************************
c*    Creates a new secondary electron from a Moller interaction   *
c*    and stores its state in the secondary stack                  *
c*                                                                 *
c*    Input:                                                       *
c*      elost -> kinetic energy of the secondary electron (eV)     *
c*******************************************************************
      implicit none
      real*8 elost
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      integer*8 sptype
      integer*8 maxns,nsec,sxvox,syvox,szvox,sabsvx
      real*8 swght,senerg,svx,svy,svz,sx,sy,sz
      parameter (maxns=2**7)
      common /dpmstck/ swght(maxns),senerg(maxns),
     & svx(maxns),svy(maxns),svz(maxns),sx(maxns),sy(maxns),sz(maxns),
     & sptype(maxns),sxvox(maxns),syvox(maxns),szvox(maxns),
     & sabsvx(maxns),nsec
      real*8 rng,twopi,pi,secmo
      parameter (pi=3.1415926535897932d0,twopi=2.d0*pi)

      if (nsec.ge.maxns) then
        write(10,*)
     &   'putmol:error: Stack is full, enlarge cutoffs or maxns'
        stop
      endif
      nsec = nsec+1
      sptype(nsec) = -1
      senerg(nsec) = elost
      svx(nsec) = vx
      svy(nsec) = vy
      svz(nsec) = vz
      sx(nsec) = x
      sy(nsec) = y
      sz(nsec) = z
      sxvox(nsec) = xvox
      syvox(nsec) = yvox
      szvox(nsec) = zvox
      sabsvx(nsec) = absvox
      call rotate(svx(nsec),svy(nsec),svz(nsec),
     &            secmo(elost,energy),rng()*twopi)
      end


      subroutine putbre(elost)
c*******************************************************************
c*    Creates a new secondary bremsstrahlung photon and stores its *
c*    state in the secondary stack                                 *
c*                                                                 *
c*    Input:                                                       *
c*      elost -> energy of the secondary photon (eV)               *
c*******************************************************************
      implicit none
      real*8 elost
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      integer*8 sptype
      integer*8 maxns,nsec,sxvox,syvox,szvox,sabsvx
      real*8 swght,senerg,svx,svy,svz,sx,sy,sz
      parameter (maxns=2**7)
      common /dpmstck/ swght(maxns),senerg(maxns),
     & svx(maxns),svy(maxns),svz(maxns),sx(maxns),sy(maxns),sz(maxns),
     & sptype(maxns),sxvox(maxns),syvox(maxns),szvox(maxns),
     & sabsvx(maxns),nsec
      real*8 rng,twopi,pi,mc2,mc2sq2,angsq2
      parameter (pi=3.1415926535897932d0,twopi=2.d0*pi)
      parameter (mc2=510.9991d3,mc2sq2=7.07106781d-1*mc2)

      nsec = nsec+1
      if (nsec.gt.maxns) then
        write(10,*)
     &   'putbre:error: Stack is full, enlarge cutoffs or maxns'
        stop
      endif
      sptype(nsec) = 0
      senerg(nsec) = elost
      svx(nsec) = vx
      svy(nsec) = vy
      svz(nsec) = vz
      sx(nsec) = x
      sy(nsec) = y
      sz(nsec) = z
      sxvox(nsec) = xvox
      syvox(nsec) = yvox
      szvox(nsec) = zvox
      sabsvx(nsec) = absvox

c     *** Polar angle set to mean value, i.e. no angular distribution used,
c       * besides, small angle approx is used for cosine:
      angsq2 = mc2sq2/(energy+mc2)
      call rotate(svx(nsec),svy(nsec),svz(nsec),
     &            1.d0-angsq2*angsq2,rng()*twopi)
      end


      subroutine photon()
c*******************************************************************
c*    Transports a photon until it either escapes from the         *
c*    universe or its energy drops below EabsPhoton                *
c*                                                                 *
c*    Input:                                                       *
c*      photon initial state                                       *
c*    Output:                                                      *
c*      deposits energy in counters and updates secondary stack    *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      integer*8 sptype
      integer*8 maxns,nsec,sxvox,syvox,szvox,sabsvx
      real*8 swght,senerg,svx,svy,svz,sx,sy,sz
      parameter (maxns=2**7)
      common /dpmstck/ swght(maxns),senerg(maxns),
     & svx(maxns),svy(maxns),svz(maxns),sx(maxns),sy(maxns),sz(maxns),
     & sptype(maxns),sxvox(maxns),syvox(maxns),szvox(maxns),
     & sabsvx(maxns),nsec
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
      integer*8 intype
      real*8 esrc,eabs,eabsph,param
      common /dpmsrc/ esrc,eabs,eabsph,param,intype
!      integer*8 lasthi
!      real*8 escore,escor2,etmp
!      common /dpmesc/ escore(nxyz),escor2(nxyz),etmp(nxyz),
!     &                lasthi(nxyz)

      integer*8 j
      real*8 itphip,icptip,ipapip,lamwck,lamden,prob,randno
      real*8 s,rng,efrac,costhe,de,twopi,pi,phi,lammin,mc2,twomc2
      real*8 epair(2)
      parameter (pi=3.1415926535897932d0,twopi=2.d0*pi)
      parameter (mc2=510.9991d3,twomc2=2.d0*mc2)


c     *** Loop until it either escapes or is absorbed:
 10   continue
c       *** Get lambda from the minimum lambda at the current energy:
        lammin = lamwck(energy)
        s = -lammin*dlog(rng())
        x = x+s*vx
        y = y+s*vy
        z = z+s*vz
        call where
        if (absvox.eq.0) then
          return
        endif
c       *** Apply Woodcock trick:
        lamden = lammin*dens(absvox)
        prob = 1.d0-lamden*itphip(mat(absvox),energy)
        randno = rng()

c       *** No real event; continue jumping:
        if (randno.lt.prob) goto 10

c       *** Compton:
        prob = prob+lamden*icptip(mat(absvox),energy)
        if (randno.lt.prob) then
c         *** opt-IncohScat-ON ->  Activate sincoh() and deact comsam():
c         * call sincoh(mat(absvox),energy,efrac,costhe)
          call comsam(energy,efrac,costhe)
          de = energy*(1.d0-efrac)
          phi = twopi*rng()
          if (de.lt.eabs) then
            call score(de)
          else
c           *** Create a secondary electron in the stack:
            call putcom(de,efrac,phi+pi,costhe)
          endif
          energy = energy-de
          if (energy.lt.eabsph) then
            call score(energy)
            return
          endif
          call rotate(vx,vy,vz,costhe,phi)
          goto 10
        endif

c       *** Pair production:
        prob = prob+lamden*ipapip(mat(absvox),energy)
        if (randno.lt.prob) then
          epair(1) = rng()*(energy-twomc2)
          epair(2) = energy-twomc2-epair(1)
          do 20 j=1,2
            if(epair(j).gt.eabs) then
              nsec=nsec+1
              if (nsec.gt.maxns) then
                write(10,*)
     &            'photon:error: Stack is full, enlarge maxns.'
                stop
              endif
              senerg(nsec) = epair(j)
              svx(nsec) = vx
              svy(nsec) = vy
              svz(nsec) = vz
              sx(nsec) = x
              sy(nsec) = y
              sz(nsec) = z
              sxvox(nsec) = xvox
              syvox(nsec) = yvox
              szvox(nsec) = zvox
              sabsvx(nsec) = absvox
              if(j.eq.1) then
                sptype(nsec) = -1
              else
                sptype(nsec) = +1
              endif
            else
              call score(epair(j))
              if(j.eq.2) call putann
            endif
 20       continue
          return
        endif

c     *** In any other case, photoelectric absorption occurs:
      call score(energy)
      end


      subroutine putcom(elost,efrac,phi,costhe)
c*******************************************************************
c*    Creates a secondary electron from a Compton interaction and  *
c*    stores its state in the secondary stack                      *
c*                                                                 *
c*    Input:                                                       *
c*      elost -> energy of the secondary electron being created    *
c*      efrac -> fraction of initial energy kept by 2nd photon     *
c*      phi -> athimutal angle                                     *
c*      costhe -> photon scattering angle
c*******************************************************************
      implicit none
      real*8 elost,efrac,phi,costhe
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      integer*8 sptype
      integer*8 maxns,nsec,sxvox,syvox,szvox,sabsvx
      real*8 swght,senerg,svx,svy,svz,sx,sy,sz
      parameter (maxns=2**7)
      common /dpmstck/ swght(maxns),senerg(maxns),
     & svx(maxns),svy(maxns),svz(maxns),sx(maxns),sy(maxns),sz(maxns),
     & sptype(maxns),sxvox(maxns),syvox(maxns),szvox(maxns),
     & sabsvx(maxns),nsec
      real*8 comele

      nsec = nsec+1
      if (nsec.gt.maxns) then
        write(10,*)
     &   'putcom:error: Stack is full, enlarge cutoffs or maxns.'
        stop
      endif
      sptype(nsec) = -1
      senerg(nsec) = elost
      svx(nsec) = vx
      svy(nsec) = vy
      svz(nsec) = vz
      sx(nsec) = x
      sy(nsec) = y
      sz(nsec) = z
      sxvox(nsec) = xvox
      syvox(nsec) = yvox
      szvox(nsec) = zvox
      sabsvx(nsec) = absvox
      call rotate(svx(nsec),svy(nsec),svz(nsec),
     &               comele(energy,efrac,costhe),phi)
      end


      integer*8 function scndry()
c*******************************************************************
c*    Retrieves a particle from the secondary stack and fills up   *
c*    the current particle common with its state                   *
c*                                                                 *
c*    Output:                                                      *
c*      -> 0 if there was no particle in the stack, 1 else         *
c*******************************************************************
      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      integer*8 sptype
      integer*8 maxns,nsec,sxvox,syvox,szvox,sabsvx
      real*8 swght,senerg,svx,svy,svz,sx,sy,sz
      parameter (maxns=2**7)
      common /dpmstck/ swght(maxns),senerg(maxns),
     & svx(maxns),svy(maxns),svz(maxns),sx(maxns),sy(maxns),sz(maxns),
     & sptype(maxns),sxvox(maxns),syvox(maxns),szvox(maxns),
     & sabsvx(maxns),nsec

      if (nsec.eq.0) then
        scndry = 0
        return
      endif
      scndry = 1
      energy = senerg(nsec)
      vx = svx(nsec)
      vy = svy(nsec)
      vz = svz(nsec)
      x = sx(nsec)
      y = sy(nsec)
      z = sz(nsec)
      xvox = sxvox(nsec)
      yvox = syvox(nsec)
      zvox = szvox(nsec)
      absvox = sabsvx(nsec)
      ptype = sptype(nsec)
      nsec = nsec-1
      end


      real*8 function stepip(e)
c*******************************************************************
c*    3spline interpolation for scattering strength as a function  *
c*    of kinetic energy; this quantity is related to the step      *
c*    length                                                       *
c*                                                                 *
c*    Input:                                                       *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      K = scattering strength = integ{ds/lambda1(s)}             *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
      real*8 e
      integer*8 nscsr
      parameter (nscsr=2**9)
      real*8 escsr,scssp,scsspa,scsspb,scsspc,scsspd,idless
      common /dpmscsr/ escsr(nscsr),scssp(nscsr),
     &                 scsspa(nscsr),scsspb(nscsr),
     &                 scsspc(nscsr),scsspd(nscsr),idless
      integer*8 i

      i = idless*(e-escsr(1))+1
      stepip = scsspa(i)+e*(scsspb(i)+e*(scsspc(i)+e*scsspd(i)))
      end


      real*8 function scpwip(matid,e)
c*******************************************************************
c*    Inverse 1st transport MFP --linear interpolation             *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      -> lambda_1^{-1} in cm^2/g                                 *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
      integer*8 matid
      real*8 e
      integer*8 maxmat,nscp
      parameter (maxmat=5,nscp=2**11)
      real*8 escp,scpsp,scpspa,scpspb,idlesc
      common /dpmscpw/ escp(nscp),scpsp(nscp),
     &       scpspa(maxmat,nscp),scpspb(maxmat,nscp),idlesc
      integer*8 i

      i = idlesc*(e-escp(1))+1
      scpwip = scpspa(matid,i)+e*scpspb(matid,i)
      end


      real*8 function bwip(matid,ie)
c*******************************************************************
c*    3spline interpolation for bw as a function of mat & energy   *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      ie -> -1/energy in eV^-1  --kinetic energy--               *
c*    Output:                                                      *
c*      bw, broad screening parameter that gets flattest q surf    *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
      integer*8 matid
      real*8 ie

      integer*8 maxmat
      parameter (maxmat=5)
      integer*8 nbw
      parameter (nbw=2**9)
      real*8 ebw,bwsp,bwspa,bwspb,bwspc,bwspd,idlebw
      common /dpmbw/ ebw(nbw),bwsp(nbw),
     &       bwspa(maxmat,nbw),bwspb(maxmat,nbw),
     &       bwspc(maxmat,nbw),bwspd(maxmat,nbw),idlebw

      integer*8 i

      i = idlebw*(ie-ebw(1))+1
      bwip = bwspa(matid,i)+ie*(bwspb(matid,i)+ie*(bwspc(matid,i)+
     &       ie*bwspd(matid,i)))
      end


      real*8 function xbwip(ie)
c*******************************************************************
c*    3spline interpolation for bw as a function energy            *
c*                                                                 *
c*    Input:                                                       *
c*      ie -> -1/energy in eV^-1  --kinetic energy--               *
c*    Output:                                                      *
c*      bw, broad screening parameter that gets flattest q surf    *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*    Comments:                                                    *
c*      -> Identical to bwip() but uses only the reference mat.    *
c*******************************************************************
      implicit none
      real*8 ie

      integer*8 nbw
      parameter (nbw=2**9)
      real*8 ebw,bwsp,bwspa,bwspb,bwspc,bwspd,idlebw
      common /xdpmbw/ ebw(nbw),bwsp(nbw),
     &       bwspa(nbw),bwspb(nbw),
     &       bwspc(nbw),bwspd(nbw),idlebw

      integer*8 i

      i = idlebw*(ie-ebw(1))+1
      xbwip = bwspa(i)+ie*(bwspb(i)+ie*(bwspc(i)+ie*bwspd(i)))
      end


      real*8 function q2Dip(matid,u,ie)
c*******************************************************************
c*    Linearly interpolated q(u;energy) surface                    *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      u -> angular variable                                      *
c*      ie -> -1/energy in eV^-1  --kinetic energy--               *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
      integer*8 matid
      real*8 u,ie

      integer*8 maxmat
      parameter (maxmat=5)
      integer*8 nuq,neq
      parameter (nuq=2**7,neq=2**8)
      real*8 q,le0q,idleq,iduq
      common /dpmq2D/ q(maxmat,nuq,neq),le0q,idleq,iduq

      integer*8 i,j
      real*8 ru,ou,rle,ole,ouole

      ru = u*iduq
      i = ru
      ou = ru-i
      i = i+1
      rle = idleq*(ie-le0q)
      j = rle
      ole = rle-j
      j = j+1
      ouole = ou*ole
      q2Dip = q(matid,i,j)*(1.d0-ou-ole+ouole)+
     &        q(matid,i+1,j)*(ou-ouole)+q(matid,i,j+1)*(ole-ouole)+
     &        q(matid,i+1,j+1)*ouole
      end


      real*8 function xq2Dip(u,ie)
c*******************************************************************
c*    Linearly interpolated q(u;energy) surface                    *
c*                                                                 *
c*    Input:                                                       *
c*      u -> angular variable                                      *
c*      ie -> -1/energy in eV^-1  --kinetic energy--               *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*    Comments:                                                    *
c*      -> Identical to q2Dip() but uses only the reference mat.   *
c*******************************************************************
      implicit none
      real*8 u,ie

      integer*8 nuq,neq
      parameter (nuq=2**7,neq=2**8)
      real*8 q,le0q,idleq,iduq
      common /xdpmq2D/ q(nuq,neq),le0q,idleq,iduq

      integer*8 i,j
      real*8 ru,ou,rle,ole,ouole

      ru = u*iduq
      i = ru
      ou = ru-i
      i = i+1
      rle = idleq*(ie-le0q)
      j = rle
      ole = rle-j
      j = j+1
      ouole = ou*ole
      xq2Dip = q(i,j)*(1.d0-ou-ole+ouole)+
     &         q(i+1,j)*(ou-ouole)+q(i,j+1)*(ole-ouole)+
     &         q(i+1,j+1)*ouole
      end


      real*8 function lamoip(ie)
c*******************************************************************
c*    Moller mean free path, 3-spline interpolation                *
c*                                                                 *
c*    Input:                                                       *
c*      ie -> -1/energy in eV^-1  --kinetic energy--               *
c*    Output:                                                      *
c*      mean free path in g/cm^2                                   *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
      real*8 ie
      integer*8 nlam
      parameter (nlam=2**8)
      real*8 elam,lamsp,lamspa,lamspb,lamspc,lamspd,idlela
      common /dpmlam/ elam(nlam),lamsp(nlam),
     &  lamspa(nlam),lamspb(nlam),lamspc(nlam),lamspd(nlam),idlela
      integer*8 i
      real*8 inf,de
      parameter (inf=1.d30)

      de = ie-elam(1)
      if (de.gt.0.d0) then
        i = idlela*de+1
        lamoip = 1.d0/
     &    (lamspa(i)+ie*(lamspb(i)+ie*(lamspc(i)+ie*lamspd(i))))
      else
        lamoip = +inf
      endif
      end


      real*8 function ilabip(matid,ie)
c*******************************************************************
c*    Bremsstrahlung inverse MFP --linear interpolation            *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id number                                *
c*      ie -> -1/energy in eV^-1  --kinetic energy--               *
c*    Output:                                                      *
c*      inverse mean free path in cm^2/g                           *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
      integer*8 matid
      real*8 ie

      integer*8 nlra,maxmat
      parameter (nlra=2**9,maxmat=5)
      real*8 elra,lrasp,lraspa,lraspb,idlelr
      common /dpmlbr/ elra(nlra),lrasp(nlra),
     &                lraspa(maxmat,nlra),lraspb(maxmat,nlra),
     &                idlelr
      integer*8 i
      real*8 de,zero
      parameter (zero=1.0d-30)

      de = ie-elra(1)
      if (de.gt.0.d0) then
        i = idlelr*de+1
        ilabip = lraspa(matid,i)+ie*lraspb(matid,i)
      else
        ilabip = zero
      endif
      end


      real*8 function rstpip(matid,e)
c*******************************************************************
c*    Restricted stopping power --linear interpolation             *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      e -> energy in eV  --kinetic energy--                      *
c*    Output:                                                      *
c*      StopPow in eV*cm^2/g                                       *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
      integer*8 matid
      real*8 e
      integer*8 maxmat,nst
      parameter (maxmat=5,nst=2**10)
      real*8 est,stsp,stspa,stspb,idlest
      common /dpmstpw/ est(nst),stsp(nst),
     &       stspa(maxmat,nst),stspb(maxmat,nst),idlest
      integer*8 i

      i = idlest*(e-est(1))+1
      rstpip = stspa(matid,i)+e*stspb(matid,i)
      end


      real*8 function itphip(matid,e)
c*******************************************************************
c*    Photon total inverse mean free path --3spline interpolation  *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      Total inverse mean free path in cm^2/g                     *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
! JC July 25 2005
! Change integer*8 m into "interger*2 m"
! Since the type of mat() is integer*2, not integer*4.
      integer*8 matid
      real*8 e
      integer*8 maxmat,nlaph
      parameter (maxmat=5,nlaph=2**11)
      real*8 elaph,lamph,lampha,lamphb,lamphc,lamphd,idleph
      common /dpmlph/ elaph(nlaph),lamph(nlaph),
     &       lampha(maxmat,nlaph),lamphb(maxmat,nlaph),
     &       lamphc(maxmat,nlaph),lamphd(maxmat,nlaph),idleph
      integer*8 i

      i = idleph*(e-elaph(1))+1
      itphip = lampha(matid,i)+e*(lamphb(matid,i)+e*(lamphc(matid,i)+
     &         e*lamphd(matid,i)))
      end


      real*8 function icptip(matid,e)
c*******************************************************************
c*    Inverse Compton mean free path --3spline interpolation       *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      Inverse total mean free path in cm^2/g                     *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
! JC July 25 2005
! Change integer m into "interger*2 m"
! Since the type of mat() is integer*2, not integer*4.
      integer*8 matid
      real*8 e
      integer*8 maxmat,ncmpt
      parameter (maxmat=5,ncmpt=2**8)
      real*8 ecmpt,compt,compta,comptb,comptc,comptd,idlecp
      common /dpmcmp/ ecmpt(ncmpt),compt(ncmpt),
     &       compta(maxmat,ncmpt),comptb(maxmat,ncmpt),
     &       comptc(maxmat,ncmpt),comptd(maxmat,ncmpt),idlecp
      integer*8 i

      i = idlecp*(e-ecmpt(1))+1
      icptip = compta(matid,i)+e*(comptb(matid,i)+e*(comptc(matid,i)+
     &         e*comptd(matid,i)))
      end


      real*8 function ipheip(matid,e)
c*******************************************************************
c*    Inverse photoelectric mean free path --3spline interpol      *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      Inverse total mean free path in cm^2/g                     *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
      integer*8 matid
      real*8 e
      integer*8 maxmat,nphte
      parameter (maxmat=5,nphte=2**12)
      real*8 ephte,phote,photea,photeb,photec,photed,idlepe
      common /dpmpte/ ephte(nphte),phote(nphte),
     &       photea(maxmat,nphte),photeb(maxmat,nphte),
     &       photec(maxmat,nphte),photed(maxmat,nphte),idlepe
      integer*8 i

      i = idlepe*(e-ephte(1))+1
      ipheip = photea(matid,i)+e*(photeb(matid,i)+e*(photec(matid,i)+
     &         e*photed(matid,i)))
      end


      real*8 function ipapip(matid,e)
c*******************************************************************
c*    Inverse pair production mean free path --3spline interpol    *
c*                                                                 *
c*    Input:                                                       *
c*      matid -> material id#                                      *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      Inverse total mean free path in cm^2/g                     *
c*    Comments:                                                    *
c*      -> init() must be called before first call                 *
c*******************************************************************
      implicit none
! JC July 25 2005
! Change integer m into "interger*2 m"
! Since the type of mat() is integer*2, not integer*4.
      integer*8 matid
      real*8 e
      integer*8 maxmat,npair
      parameter (maxmat=5,npair=2**10)
      real*8 epair,pairp,pairpa,pairpb,pairpc,pairpd,idlepp
      common /dpmpap/ epair(npair),pairp(npair),
     &       pairpa(maxmat,npair),pairpb(maxmat,npair),
     &       pairpc(maxmat,npair),pairpd(maxmat,npair),idlepp
      integer*8 i

      if (e.gt.epair(1)) then
        i = idlepp*(e-epair(1))+1
        ipapip = pairpa(matid,i)+e*(pairpb(matid,i)+
     &           e*(pairpc(matid,i)+e*pairpd(matid,i)))
      else
        ipapip = 0.d0
        return
      endif
      end


      real*8 function lamwck(e)
c*******************************************************************
c*    Mean free path prepared to play the Woodcock trick           *
c*                                                                 *
c*    Input:                                                       *
c*      e -> kinetic energy in eV                                  *
c*    Output:                                                      *
c*      Minimum mean free path in cm                               *
c*    Comments:                                                    *
c*      -> iniwck() must be called before first call               *
c*******************************************************************
      implicit none
      real*8 e
      integer*8 nwck
      parameter (nwck=2**12)
      real*8 a0wck,a1wck,idlewk,wcke0
      common /dpmwck/ a0wck(nwck),a1wck(nwck),idlewk,wcke0
      integer*8 i

      i = (e-wcke0)*idlewk+1
      lamwck = a0wck(i)+a1wck(i)*e
      end

      subroutine rmater(fname,emin,eminph,emax,
     &                  refz,refz2,refmas,refden)
c*******************************************************************
c*    Reads material data from file                                *
c*                                                                 *
c*    Output:                                                      *
c*      fname -> input file name                                   *
c*      [Emin,Eminph,Emax] -> interval where data will be gen (eV) *
c*      refz -> total atomic no of the reference material          *
c*      refz2 -> atomic no^2 of the reference material             *
c*      refmas -> atomic weight of the reference material          *
c*      refden -> density of the reference material (g/cm^3)       *
c*******************************************************************
      implicit none
      character*40 fname
      real*8 emin,eminph,emax,refz,refz2,refmas,refden
      integer*8 maxmat
      parameter (maxmat=5)
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,nelem,len
      real*8 atno,atno2,mass,shigh,slow,ecross
      character*40 mname

      write(10,*) ' '
      write(10,*) ' '
      write(10,*) 'rmater: Reading ', fname
      write(10,*) '        information from this file follows:'
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      write(10,*) buffer
      read(1,'(a100)') buffer
      write(10,*) buffer
      read(1,*) eminph,emin,emax
      write(10,'(1x,3(1pe10.3,1x))') eminph,emin,emax
      read(1,'(a100)') buffer
      write(10,*) buffer
      read(1,*) wcc,wcb
      write(10,'(1x,2(1pe10.3,1x))') wcc,wcb
      read(1,'(a100)') buffer
      write(10,*) buffer
      read(1,*) shigh,slow,ecross
      write(10,'(1x,3(1pe10.3,1x))') shigh,slow,ecross

      read(1,'(a100)') buffer
      write(10,*) buffer
      read(1,*) nmat
      write(10,'(1x,1(i3,1x))') nmat
      if (nmat.gt.maxmat) then
        write(10,*) 'rmater:error: Too many materials.'
        stop
      endif

      do 10 i=1,nmat
        read(1,'(a100)') buffer
        write(10,*) buffer
c       *** Read name of material, remove trailing blanks:
        call getna2(1,mname,len)
        read(1,'(a100)') buffer
        write(10,*) 'MATERIAL: ',mname(1:len)
        read(1,*) matden(i)
        write(10,'(1x,1pe14.7)') matden(i)
        read(1,'(a100)') buffer
        write(10,*) buffer
        read(1,*) nelem
        write(10,'(1x,i3)') nelem
        do 20 j=1,nelem
          read(1,'(a100)') buffer
          write(10,*) buffer
 20     continue
        read(1,'(a100)') buffer
        write(10,*) buffer
        read(1,*) atno,atno2
        write(10,'(1x,2(1pe14.7,1x))') atno,atno2
        read(1,'(a100)') buffer
        write(10,*) buffer
        read(1,*) mass
        write(10,'(1x,1(1pe14.7,1x))') mass
c       *** Take mat# 1 as the reference material:
        if (i.eq.1) then
          refz = atno
          refz2 = atno2
          refmas = mass
        endif
        read(1,'(a100)') buffer
        write(10,*) buffer
        read(1,*) zmass(i),z2mass(i)
        write(10,'(1x,2(1pe14.7,1x))') zmass(i),z2mass(i)
c       *** opt-IncohScat-ON -> activate inscati():
c       * call inscati(mname,len,i)
 10   continue
      close(1)

c     *** Get reference density:
      refden = matden(1)

      write(10,*) ' '
      write(10,*) 'rmater: Done.'
      end


      subroutine rstep(fname,bytes)
c*******************************************************************
c*    Reads scattering strength data and sets up interpolation     *
c*    matrices                                                     *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 nscsr
      parameter (nscsr=2**9)
      real*8 escsr,scssp,scsspa,scsspb,scsspc,scsspd,idless
      common /dpmscsr/ escsr(nscsr),scssp(nscsr),
     &                 scsspa(nscsr),scsspb(nscsr),
     &                 scsspc(nscsr),scsspd(nscsr),idless

      character*100 buffer
      integer*8 i,ndata
      real*8 shigh,slow,ecross

      write(10,*) 'rstep: Reading ',fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      write(10,*) 'rstep: ',buffer
      read(1,*) shigh,slow,ecross
      write(10,'(1x,3(1pe10.3,1x))') shigh,slow,ecross
      read(1,'(a100)') buffer
      read(1,*) ndata
      if (ndata.ne.nscsr) then
        write(10,*) 'rstep:error: Array dim do not match:'
        write(10,'(1x,2(i5,1x))') ndata,nscsr
        stop
      endif
      read(1,'(a100)') buffer
c     *** Prepare interpolation:
      do 20 i=1,nscsr
        read(1,*) escsr(i),scssp(i)
 20   continue
      close(1)
      idless = (nscsr-1)/(escsr(nscsr)-escsr(1))
      call spline(escsr,scssp,scsspa,scsspb,scsspc,scsspd,
     &  0.d0,0.d0,nscsr)
      bytes = 8*(6*nscsr)
      end


      subroutine rscpw(fname,bytes)
c*******************************************************************
c*    Reads 1st TMFP from file and sets up interpolation matrices  *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat,nscp
      parameter (maxmat=5,nscp=2**11)
      real*8 escp,scpsp,scpspa,scpspb,idlesc
      common /dpmscpw/ escp(nscp),scpsp(nscp),
     &       scpspa(maxmat,nscp),scpspb(maxmat,nscp),idlesc
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,ndata
      real*8 dummya(nscp),dummyb(nscp)

      write(10,*) 'rscpw: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer

      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) ndata
        if (ndata.ne.nscp) then
          write(10,*) 'rscpw:error: Array dim do not match:'
          write(10,'(1x,2(i5,1x))') ndata,nscp
          stop
        endif
        read(1,'(a100)') buffer
c       *** Prepare interpolation:
        do 10 i=1,nscp
          read(1,*) escp(i),scpsp(i)
 10     continue
        read(1,'(a100)') buffer
        do 30 i=1,nscp-1
          dummyb(i) = (scpsp(i+1)-scpsp(i))/(escp(i+1)-escp(i))
          dummya(i) = scpsp(i)-escp(i)*dummyb(i)
  30    continue
c       *** Loading dummy arrays into multimaterial sp matrices:
        do 15 i=1,nscp
          scpspa(j,i) = dummya(i)
          scpspb(j,i) = dummyb(i)
 15     continue
 20   continue
      close(1)
      idlesc = (nscp-1)/(escp(nscp)-escp(1))
      bytes = 8*(maxmat*nscp*2+nscp*2)
      end


      subroutine rbw(fname,bytes)
c*******************************************************************
c*    Reads screening parameter data from file and sets up         *
c*    interpolation matrices                                       *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat
      parameter (maxmat=5)
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat
      integer*8 nbw
      parameter (nbw=2**9)
      real*8 ebw,bwsp,bwspa,bwspb,bwspc,bwspd,idlebw
      common /xdpmbw/ ebw(nbw),bwsp(nbw),
     &       bwspa(nbw),bwspb(nbw),
     &       bwspc(nbw),bwspd(nbw),idlebw

      character*100 buffer
      integer*8 i,ndata
      real*8 dummya(nbw),dummyb(nbw),dummyc(nbw),dummyd(nbw)

      write(10,*) 'rbw: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      read(1,*) ndata
      read(1,'(a100)') buffer
      if (ndata.ne.nbw) then
        write(10,*) 'rbw:error: Array dim do not match:'
        write(10,'(1x,2(i5,1x))') ndata,nbw
        stop
      endif
c     *** Prepare interpolation:
      do 10 i=1,nbw
        read(1,*) ebw(i),bwsp(i)
        ebw(i) = -1.d0/ebw(i)
 10   continue
      read(1,'(a100)') buffer
      call spline(ebw,bwsp,dummya,dummyb,dummyc,dummyd,
     &              0.d0,0.d0,nbw)
      do 15 i=1,nbw
        bwspa(i) = dummya(i)
        bwspb(i) = dummyb(i)
        bwspc(i) = dummyc(i)
        bwspd(i) = dummyd(i)
 15   continue

      close(1)
      idlebw = (nbw-1)/(ebw(nbw)-ebw(1))
      bytes = 8*(nbw*6)
      end


      subroutine xrbw(fname,bytes)
c*******************************************************************
c*    Reads screening parameter data from file and sets up         *
c*    interpolation matrices. Multi-material version.              *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*    Comments:                                                    *
c*      -> This routine is identical to rbw() except that it loads *
c*         different data for different materials.                 *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat
      parameter (maxmat=5)
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat
      integer*8 nbw
      parameter (nbw=2**9)
      real*8 ebw,bwsp,bwspa,bwspb,bwspc,bwspd,idlebw
      common /dpmbw/ ebw(nbw),bwsp(nbw),
     &       bwspa(maxmat,nbw),bwspb(maxmat,nbw),
     &       bwspc(maxmat,nbw),bwspd(maxmat,nbw),idlebw

      character*100 buffer
      integer*8 i,j,ndata
      real*8 dummya(nbw),dummyb(nbw),dummyc(nbw),dummyd(nbw)

      write(10,*) 'xrbw: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) ndata
        read(1,'(a100)') buffer
        if (ndata.ne.nbw) then
          write(10,*) 'xrbw:error: Array dim do not match:'
          write(10,'(1x,2(i5,1x))') ndata,nbw
          stop
        endif
c       *** Prepare interpolation:
        do 10 i=1,nbw
          read(1,*) ebw(i),bwsp(i)
          ebw(i) = -1.d0/ebw(i)
 10     continue
        read(1,'(a100)') buffer
        call spline(ebw,bwsp,dummya,dummyb,dummyc,dummyd,
     &              0.d0,0.d0,nbw)
c       *** Loading dummy arrays into multimaterial matrices:
        do 15 i=1,nbw
          bwspa(j,i) = dummya(i)
          bwspb(j,i) = dummyb(i)
          bwspc(j,i) = dummyc(i)
          bwspd(j,i) = dummyd(i)
 15     continue
 20   continue
      close(1)
      idlebw = (nbw-1)/(ebw(nbw)-ebw(1))
      bytes = 8*(maxmat*nbw*4+nbw*2)
      end


      subroutine rqsurf(fname,bytes)
c*******************************************************************
c*    Reads q surface data data from file and sets up interpolation*
c*    matrices                                                     *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat
      parameter (maxmat=5)
      integer*8 nuq,neq
      parameter (nuq=2**7,neq=2**8)
      real*8 q,le0q,idleq,iduq
      common /xdpmq2D/ q(nuq,neq),le0q,idleq,iduq
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,nu,ne
      real*8 e0,e1,u,qmax,effic,qval

      write(10,*) 'rqsurf: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      read(1,*) nu,ne
      if ((nu.ne.nuq).or.(ne.ne.neq)) then
        write(10,*) 'rqsurf:error: Array dim do not match:'
        write(10,'(1x,4(i5,1x))') nu,nuq,ne,neq
        stop
      endif
      read(1,'(a100)') buffer
      read(1,*) qmax
      read(1,'(a100)') buffer
      effic = 1.d0/qmax
      write(10,*) 'rqsurf: q rejection efficiency(%):'
      write(10,'(1x,1pe8.1)') 100.0*effic
      do 10 i=1,neq
        read(1,*) e1
        if (i.eq.1) e0 = e1
        do 20 j=1,nuq
          read(1,*) u,qval
c         *** Incorporating the efficiency in the q function:
          q(j,i) = qval*effic
 20     continue
 10   continue
      read(1,'(a100)') buffer

      close(1)
      le0q = -1.d0/e0
      idleq = (neq-1)/(-1.d0/e1-le0q)
      iduq = nuq-1.d0
      bytes = 4*nuq*neq
      end


      subroutine xrqsurf(fname,bytes)
c*******************************************************************
c*    Reads q surface data data from file and sets up interpolation*
c*    matrices. Multi-material version.                            *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*    Comments:                                                    *
c*      -> This routine is identical to rqsurf() except that it    *
c*         loads different data for different materials.           *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat
      parameter (maxmat=5)
      integer*8 nuq,neq
      parameter (nuq=2**7,neq=2**8)
      real*8 q,le0q,idleq,iduq
      common /dpmq2D/ q(maxmat,nuq,neq),le0q,idleq,iduq
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,k,nu,ne
      real*8 e0,e1,u,qmax,effic,qval

      write(10,*) 'xrqsurf: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      do 30 k=1,nmat
        read(1,'(a100)') buffer
        read(1,*) nu,ne
        if ((nu.ne.nuq).or.(ne.ne.neq)) then
          write(10,*) 'xrqsurf:error: Array dim do not match:'
          write(10,'(1x,4(i5,1x))') nu,nuq,ne,neq
          stop
        endif
        read(1,'(a100)') buffer
        read(1,*) qmax
        read(1,'(a100)') buffer
        effic = 1.d0/qmax
        write(10,*) 'xrqsurf: Mat id & q rejection efficiency(%):'
        write(10,'(1x,i3,1x,1pe8.1)') k,100.0*effic
        do 10 i=1,neq
          read(1,*) e1
          if (i.eq.1) e0 = e1
          do 20 j=1,nuq
            read(1,*) u,qval
c           *** Incorporating the efficiency in the q function:
            q(k,j,i) = qval*effic
 20       continue
 10     continue
        read(1,'(a100)') buffer
 30   continue
      close(1)
      le0q = -1.d0/e0
      idleq = (neq-1)/(-1.d0/e1-le0q)
      iduq = nuq-1.d0
      bytes = 4*(maxmat*nuq*neq)
      end


      subroutine rlammo(fname,bytes)
c*******************************************************************
c*    Reads lambda for Moller interactions from file and sets up   *
c*    interpolation matrices                                       *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 nlam
      parameter (nlam=2**8)
      real*8 elam,lamsp,lamspa,lamspb,lamspc,lamspd,idlela
      common /dpmlam/ elam(nlam),lamsp(nlam),
     &  lamspa(nlam),lamspb(nlam),lamspc(nlam),lamspd(nlam),idlela

      character*100 buffer
      integer*8 i,ndata

      write(10,*) 'rlammo: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      read(1,*) ndata
      if (ndata.ne.nlam) then
        write(10,*) 'rlammo:error: Array dim do not match:'
        write(10,'(1x,2(i5,1x))') ndata,nlam
        stop
      endif
      read(1,'(a100)') buffer
c     *** Prepare interpolation:
      do 10 i=1,nlam
        read(1,*) elam(i),lamsp(i)
        elam(i) = -1.d0/elam(i)
        lamsp(i) = 1.d0/lamsp(i)
 10   continue
      read(1,'(a100)') buffer
      close(1)
      idlela = (nlam-1)/(elam(nlam)-elam(1))
      call spline(elam,lamsp,lamspa,lamspb,lamspc,lamspd,
     &  0.d0,0.d0,nlam)
      bytes = 8*6*nlam
      end


      subroutine rlabre(fname,bytes)
c*******************************************************************
c*    Reads lambda_radiative data from file and sets up            *
c*    interpolation matrices                                       *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*    Comments:                                                    *
c*      -> The array employed to interpolate the Bremss MFP is     *
c*         prepared to store multi-material data, even though this *
c*         is not needed if the mono-material Sel&Ber DCS option   *
c*         is active.                                              *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 nlra,maxmat
      parameter (nlra=2**9,maxmat=5)
      real*8 elra,lrasp,lraspa,lraspb,idlelr
      common /dpmlbr/ elra(nlra),lrasp(nlra),
     &                lraspa(maxmat,nlra),lraspb(maxmat,nlra),
     &                idlelr
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,ndata,j
      real*8 dummya(nlra),dummyb(nlra)

      write(10,*) 'rlabre: Reading ',fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) ndata
        if (ndata.ne.nlra) then
          write(10,*) 'rlabre:error: Array dim do not match:'
          write(10,'(1x,2(i5,1x))') ndata,nlra
          stop
        endif
        read(1,'(a100)') buffer
c       *** Prepare interpolation:
        do 10 i=1,nlra
          read(1,*) elra(i),lrasp(i)
          elra(i) = -1.d0/elra(i)
          lrasp(i) = 1.d0/lrasp(i)
 10     continue
        read(1,'(a100)') buffer
        do 30 i=1,nlra-1
          dummyb(i) = (lrasp(i+1)-lrasp(i))/(elra(i+1)-elra(i))
          dummya(i) = lrasp(i)-elra(i)*dummyb(i)
  30    continue
        do 15 i=1,nlra
          lraspa(j,i) = dummya(i)
          lraspb(j,i) = dummyb(i)
 15     continue
 20   continue
      close(1)
      idlelr = (nlra-1)/(elra(nlra)-elra(1))
      bytes = 8*(2*nlra*maxmat+2*nlra)
      end


      subroutine rbcon(fname,bytes)
c*******************************************************************
c*    Reads brems constants for sampling with PENELOPE routine     *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat
      parameter (maxmat=5)
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat
      real*8 f0,bcb
      COMMON/XBRE/F0(MAXMAT,3),BCB(MAXMAT)

      character*100 buffer
      integer*8 i,j

      write(10,*) 'rbcon: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) (f0(j,i),i=1,3),bcb(j)
 20   continue
      close(1)
      bytes = nmat*4
      end


      subroutine rrstpw(fname,bytes)
c*******************************************************************
c*    Reads StopPower_restr  data from file and sets up            *
c*    interpolation matrices                                       *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat,nst
      parameter (maxmat=5,nst=2**10)
      real*8 est,stsp,stspa,stspb,idlest
      common /dpmstpw/ est(nst),stsp(nst),
     &       stspa(maxmat,nst),stspb(maxmat,nst),idlest
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,ndata
      real*8 dummya(nst),dummyb(nst)

      write(10,*) 'rrstpw: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) ndata
        if (ndata.ne.nst) then
          write(10,*) 'rrstpw:error: Array dim do not match:'
          write(10,'(1x,2(i5,1x))') ndata,nst
          stop
        endif
        read(1,'(a100)') buffer
        do 10 i=1,nst
          read(1,*) est(i),stsp(i)
 10     continue
        read(1,'(a100)') buffer
        do 30 i=1,nst-1
          dummyb(i) = (stsp(i+1)-stsp(i))/(est(i+1)-est(i))
          dummya(i) = stsp(i)-est(i)*dummyb(i)
  30    continue
c       *** Loading dummy arrays into multimaterial sp matrices:
        do 15 i=1,nst
          stspa(j,i) = dummya(i)
          stspb(j,i) = dummyb(i)
 15     continue
 20   continue
      close(1)
      idlest = (nst-1)/(est(nst)-est(1))
      bytes = 8*(maxmat*nst*2+nst*2)
      end


      subroutine rlamph(fname,bytes)
c*******************************************************************
c*    Reads photon total inverse mean free path data from file and *
c*    sets up interpolation matrices                               *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat,nlaph
      parameter (maxmat=5,nlaph=2**11)
      real*8 elaph,lamph,lampha,lamphb,lamphc,lamphd,idleph
      common /dpmlph/ elaph(nlaph),lamph(nlaph),
     &       lampha(maxmat,nlaph),lamphb(maxmat,nlaph),
     &       lamphc(maxmat,nlaph),lamphd(maxmat,nlaph),idleph
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,ndata
      real*8 dummya(nlaph),dummyb(nlaph),dummyc(nlaph),dummyd(nlaph)

      write(10,*) 'rlamph: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) ndata
        if (ndata.ne.nlaph) then
          write(10,*) 'rlamph:error: Array dim do not match:'
          write(10,'(1x,2(i5,1x))') ndata,nlaph
          stop
        endif
        read(1,'(a100)') buffer
c       *** Preparing interpolation:
        do 10 i=1,nlaph
          read(1,*) elaph(i),lamph(i)
 10     continue
        read(1,'(a100)') buffer
        call spline(elaph,lamph,dummya,dummyb,dummyc,dummyd,
     &              0.d0,0.d0,nlaph)
c       *** Loading dummy arrays into multimaterial sp matrices:
        do 15 i=1,nlaph
          lampha(j,i) = dummya(i)
          lamphb(j,i) = dummyb(i)
          lamphc(j,i) = dummyc(i)
          lamphd(j,i) = dummyd(i)
 15     continue
 20   continue
      close(1)
      idleph = (nlaph-1)/(elaph(nlaph)-elaph(1))
      bytes = 8*(maxmat*nlaph*4+nlaph*2)
      end


      subroutine rcompt(fname,bytes)
c*******************************************************************
c*    Reads Compton inverse mean free path data from file and sets *
c*    up interpolation matrices                                    *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat,ncmpt
      parameter (maxmat=5,ncmpt=2**8)
      real*8 ecmpt,compt,compta,comptb,comptc,comptd,idlecp
      common /dpmcmp/ ecmpt(ncmpt),compt(ncmpt),
     &       compta(maxmat,ncmpt),comptb(maxmat,ncmpt),
     &       comptc(maxmat,ncmpt),comptd(maxmat,ncmpt),idlecp
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,ndata
      real*8 dummya(ncmpt),dummyb(ncmpt),dummyc(ncmpt),dummyd(ncmpt)

      write(10,*) 'rcompt: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) ndata
        if (ndata.ne.ncmpt) then
          write(10,*) 'rcompt:error: Array dim do not match:'
          write(10,'(1x,2(i5,1x))') ndata,ncmpt
          stop
        endif
        read(1,'(a100)') buffer
c       *** Preparing interpolation:
        do 10 i=1,ncmpt
          read(1,*) ecmpt(i),compt(i)
 10     continue
        read(1,'(a100)') buffer
        call spline(ecmpt,compt,dummya,dummyb,dummyc,dummyd,
     &              0.d0,0.d0,ncmpt)
c       *** Loading dummy arrays into multimaterial sp matrices:
        do 15 i=1,ncmpt
          compta(j,i) = dummya(i)
          comptb(j,i) = dummyb(i)
          comptc(j,i) = dummyc(i)
          comptd(j,i) = dummyd(i)
 15     continue
 20   continue
      close(1)
      idlecp = (ncmpt-1)/(ecmpt(ncmpt)-ecmpt(1))
      bytes = 8*(maxmat*ncmpt*4+ncmpt*2)
      end


      subroutine rphote(fname,bytes)
c*******************************************************************
c*    Reads photoelectric inverse mean free path data from file and*
c*    sets up interpolation matrices                               *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat,nphte
      parameter (maxmat=5,nphte=2**12)
      real*8 ephte,phote,photea,photeb,photec,photed,idlepe
      common /dpmpte/ ephte(nphte),phote(nphte),
     &       photea(maxmat,nphte),photeb(maxmat,nphte),
     &       photec(maxmat,nphte),photed(maxmat,nphte),idlepe
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,ndata
      real*8 dummya(nphte),dummyb(nphte),dummyc(nphte),dummyd(nphte)

      write(10,*) 'rphote: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer
      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) ndata
        if (ndata.ne.nphte) then
          write(10,*) 'rphote:error: Array dim do not match:'
          write(10,'(1x,2(i5,1x))') ndata,nphte
          stop
        endif
        read(1,'(a100)') buffer
c       *** Preparing interpolation
        do 10 i=1,nphte
          read(1,*) ephte(i),phote(i)
 10     continue
        read(1,'(a100)') buffer
        call spline(ephte,phote,dummya,dummyb,dummyc,dummyd,
     &              0.d0,0.d0,nphte)
c       *** Loading dummy arrays into multimaterial sp matrices:
        do 15 i=1,nphte
          photea(j,i) = dummya(i)
          photeb(j,i) = dummyb(i)
          photec(j,i) = dummyc(i)
          photed(j,i) = dummyd(i)
 15     continue
 20   continue
      close(1)
      idlepe = (nphte-1)/(ephte(nphte)-ephte(1))
      bytes = 8*(maxmat*nphte*4+nphte*2)
      end


      subroutine rpairp(fname,bytes)
c*******************************************************************
c*    Reads inverse pair production mean free path data from file  *
c*    and sets up interpolation matrices                           *
c*                                                                 *
c*    Input:                                                       *
c*      fname -> input file name                                   *
c*    Output:                                                      *
c*      bytes -> memory filled up by interpolation arrays          *
c*******************************************************************
      implicit none
      character*40 fname
      integer*8 bytes

      integer*8 maxmat,npair
      parameter (maxmat=5,npair=2**10)
      real*8 epair,pairp,pairpa,pairpb,pairpc,pairpd,idlepp
      common /dpmpap/ epair(npair),pairp(npair),
     &       pairpa(maxmat,npair),pairpb(maxmat,npair),
     &       pairpc(maxmat,npair),pairpd(maxmat,npair),idlepp
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

      character*100 buffer
      integer*8 i,j,ndata
      real*8 dummya(npair),dummyb(npair),dummyc(npair),dummyd(npair)

      write(10,*) 'rpairp: Reading ', fname
      open(1,file=fname)
      read(1,'(a100)') buffer
      read(1,'(a100)') buffer

      do 20 j=1,nmat
        read(1,'(a100)') buffer
        read(1,*) ndata
        if (ndata.ne.npair) then
          write(10,*) 'rpairp:error: Array dim do not match:'
          write(10,'(1x,2(i5,1x))') ndata,npair
          stop
        endif
        read(1,'(a100)') buffer
c       *** Preparing interpolation:
        do 10 i=1,npair
          read(1,*) epair(i),pairp(i)
 10     continue
        read(1,'(a100)') buffer
        call spline(epair,pairp,dummya,dummyb,dummyc,dummyd,
     &              0.d0,0.d0,npair)
c       *** Loading dummy arrays into multimaterial sp matrices:
        do 15 i=1,npair
          pairpa(j,i) = dummya(i)
          pairpb(j,i) = dummyb(i)
          pairpc(j,i) = dummyc(i)
          pairpd(j,i) = dummyd(i)
 15     continue
 20   continue
      close(1)
      idlepp = (npair-1)/(epair(npair)-epair(1))
      bytes = 8*(maxmat*npair*4+npair*2)
      end

! JC remove subroutine report.
! Use DPM gateway to return vriables back to MATLAB,
! instead of writing into the disk.


      subroutine iniwck(eminph,emax,bytes)
c*******************************************************************
c*    Finds information used to transport photons with the Woodcock*
c*    technique                                                    *
c*                                                                 *
c*    Input:                                                       *
c*      eminph -> minimum photon energy in data files (eV)         *
c*      emax -> maximum photon energy in data files (eV)           *
c*    Output                                                       *
c*      bytes -> space allocated for arrays                        *
c*    Comments:                                                    *
c*      -> common /dpmsrc/ must be loaded previously               *
c*      -> rlamph() must be called previously                      *
c*      -> rvoxg() must be called first                            *
c*      -> emax reduced to avoid reaching the end of interpol table*
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX
! JC July 25 2005
! Change integer m into "interger*2 m" in itphip
! Since the type of mat() is integer*2, not integer*4.
! Thus in 
! ycanbe = itphip(j,e)*maxden(j)
! j has to be integer*2

      implicit none
      integer*8 bytes
      real*8 eminph,emax

      integer*8 maxmat,nlaph
      parameter (maxmat=5,nlaph=2**11)
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
      integer*8 nwck
      parameter (nwck=2**12)
      real*8 a0wck,a1wck,idlewk,wcke0
      common /dpmwck/ a0wck(nwck),a1wck(nwck),idlewk,wcke0
      integer*8 intype
      real*8 esrc,eabs,eabsph,param
      common /dpmsrc/ esrc,eabs,eabsph,param,intype
      integer*8 nmat
      real*8 matden,zmass,z2mass,wcc,wcb
      common /dpmmat/ matden(maxmat),zmass(maxmat),z2mass(maxmat),
     &                wcc,wcb,nmat

!      integer i,j,granul,ke
      integer*8 i,j,granul,ke
      parameter (granul=3)
      integer*8 vox
      real*8 maxden(maxmat),de,e,ymax,ymin,ycanbe
      real*8 itphip,ylast,me,avedif,maxdif,gle,fip,freal,dif,eps
      parameter (eps=1.d-10)

      write(10,*) ' '
      write(10,*) ' '
      write(10,*) 'iniwck: Started.'
c     *** Find the largest density for each present material:
      do 10 i=1,maxmat
        maxden(i) = 0.d0
 10   continue
      do 20 vox=1,Unxvox*Unyvox*Unzvox
!      do 20 vox=1,nxyz
        if (dens(vox).gt.maxden(mat(vox))) maxden(mat(vox))=dens(vox)
 20   continue

c     *** Prepare linear interpolation:
      wcke0 = eminph
      de = (emax*(1.d0-eps)-wcke0)/nwck
      idlewk = 1.d0/de
      do 30 i=1,nwck+1
        e = wcke0+de*(i-1)
        ymax = 0.d0
        do 40 j=1,nmat
          ycanbe = itphip(j,e)*maxden(j)
          if (ycanbe.gt.ymax) ymax = ycanbe
 40     continue
        ymin = 1.d0/ymax
        if (i.eq.1) then
          ylast = ymin
          goto 30
        endif
        a1wck(i-1) = (ymin-ylast)*idlewk
        a0wck(i-1) = ylast-(e-de)*a1wck(i-1)
        ylast = ymin
 30   continue
      bytes = 8*2*nwck

c     *** Check accuracy inside mesh:
      me = wcke0
      avedif = 0.d0
      maxdif = 0.d0
      do 50 i=1,nwck
        e = wcke0+de*(i-1)
        do 60 ke=1,granul
          gle = e+ke*de/(granul+1)
          fip = a0wck(i)+a1wck(i)*gle
          ymax = 0.d0
          do 70 j=1,nmat
            ycanbe = itphip(j,gle)*maxden(j)
            if (ycanbe.gt.ymax) ymax = ycanbe
 70       continue
          freal = 1.d0/ymax
          dif = dabs(1.d0-fip/freal)
          if (maxdif.lt.dif) then
            maxdif = dif
            me = gle
          endif
          avedif = avedif+dif
 60     continue
 50   continue
      avedif = 100.d0*avedif/(nwck*granul)
      maxdif = 100.d0*maxdif

      write(10,*)
     &'iniwck: ndata,granularity,mean_dif(%),max_dif(%) at(eV):'
      write(10,'(1x,i5,1x,i3,1x,3(1pe10.3,1x))')
     &  nwck,granul,avedif,maxdif,me
      end


      subroutine inisub(refden)
c*******************************************************************
c*    Initializes data used when transporting electrons below      *
c*    Eabs and reads StopPower from file to set up interpolation   *
c*    matrices                                                     *
c*                                                                 *
c*    Input:                                                       *
c*      refden -> reference material density (g/cm^3)              *
c*    Comments:                                                    *
c*      -> must be called after reading common /dpmsrc/            *
c*******************************************************************
      implicit none
      real*8 refden

      integer*8 intype
      real*8 esrc,eabs,eabsph,param
      common /dpmsrc/ esrc,eabs,eabsph,param,intype
      real*8 subden,subfac,substp
      common /dpmsub/ subden,subfac,substp

c     *** Density and StopPower for SubEabs transport are set quite arbitrarily:
      subden = refden/10.0d0
      substp = 2.0d6
      subfac = subden/eabs
      write(10,*)
     &  'inisub: Minimum density for SubEabs motion (g/cm^3):'
      write(10,'(1x,1pe10.3)') subden
      write(10,*)
     &  'inisub: StopPower for SubEabs motion (eV*cm^2/g):'
      write(10,'(1x,1pe10.3)') substp
      end


      subroutine putann
c*******************************************************************
c*    Creates secondaries for annhilation photons,                 *
c*    stores states in the secondary stack                         *
c*******************************************************************
      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      integer*8 sptype
      integer*8 maxns,nsec,sxvox,syvox,szvox,sabsvx
      real*8 swght,senerg,svx,svy,svz,sx,sy,sz
      parameter (maxns=2**7)
      common /dpmstck/ swght(maxns),senerg(maxns),
     & svx(maxns),svy(maxns),svz(maxns),sx(maxns),sy(maxns),sz(maxns),
     & sptype(maxns),sxvox(maxns),syvox(maxns),szvox(maxns),
     & sabsvx(maxns),nsec
      integer*8 intype
      real*8 esrc,eabs,eabsph,param
      common /dpmsrc/ esrc,eabs,eabsph,param,intype

      integer*8 j
      real*8 rng,twopi,pi,mc2,sinthe,phi
      parameter (pi=3.1415926535897932d0,twopi=2.d0*pi)
      parameter (mc2=510.9991d3)

      vz = 2.d0*rng()-1.d0
      sinthe = dsqrt(1.d0-vz*vz)
      phi = twopi*rng()
      vy = sinthe*dsin(phi)
      vx = sinthe*dcos(phi)
      do 10 j=1,2
        nsec = nsec+1
        if (nsec.gt.maxns) then
          write(10,*) 'putann:error: stack is full, enlarge maxns.'
          stop
        endif
        sptype(nsec) = 0
        senerg(nsec) = mc2
        svx(nsec) = vx
        svy(nsec) = vy
        svz(nsec) = vz
        sx(nsec) = x
        sy(nsec) = y
        sz(nsec) = z
        sxvox(nsec) = xvox
        syvox(nsec) = yvox
        szvox(nsec) = zvox
        sabsvx(nsec) = absvox
   10 continue
      svx(nsec) = -svx(nsec)
      svy(nsec) = -svy(nsec)
      svz(nsec) = -svz(nsec)
      end


      real*8 function SBREMS(E,M)
c*******************************************************************
c*    New routine to replace sambre in dpm                         *
c*    for more accurate sampling of Bremsstrahlung energies.       *
c*    Canibalized from PENELOPE.                                   *
c*******************************************************************
! JC July 25 2005
! Change integer m into "interger*2 m"
! Since the type of mat() is integer*2, not integer*4.

      integer*8 m
      real*8 e
C
C     RANDOM SAMPLING OF HARD BREMSSTRAHLUNG EMISSION.
C
      integer*8 maxmat
      parameter (maxmat=5)
      real*8 pi,twopi,rev
      PARAMETER (PI=3.1415926535897932D0, TWOPI=2.0D0*PI)
      PARAMETER (REV=5.1099906D5)
C
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
C
      real*8 f0,bcb
      COMMON/XBRE/F0(MAXMAT,3),BCB(MAXMAT)
C
      real*8 rng
C
      integer*8 ic
      real*8 toten, gam, em, ed, ec, ec1, ec2, emecs, xx, f2le
      real*8 f00, f1, f2, f1c, f2c, f1d, f2d, ed1, bec, bed
      real*8 eps, eps1, pa, pa0, pa1, pa2, pb, pb2
C
      TOTEN=E+REV
      GAM=TOTEN/REV
      PA=BCB(M)*GAM
      EM=E/TOTEN
      IF(EM.GT.9.9999D-1) EM=9.9999D-1
C  ****  REJECTION FUNCTIONS.
      ED=(E-5.0D0*REV)/TOTEN
      EC=wcbre/TOTEN
      EC2=EC*EC
      EMECS=EM*EM-EC2
C  ****  LOW ENERGY CORRECTION.
      XX=E/REV
      F2LE=(4.650D0-F0(M,3)*(6.005D0-F0(M,3)*2.946D0))/XX
     1    -(3.242D1-F0(M,3)*(6.708D1+F0(M,3)*3.906D0))/(1+XX)**2
     2    +(2.033D1+F0(M,3)*(2.338D1-F0(M,3)*7.742D1))/(1+XX)**3
C
      IF(EC.LT.ED) THEN
        IC=2
      ELSE
        IC=1
      ENDIF
      F00=F0(M,IC)+F2LE
      EC1=1.0D0-EC
      BEC=EC/(PA*EC1)
      CALL SCHIFF(BEC,F1,F2)
      F1C=F1+F00
      F2C=(F2+F00)*EC1
      IF(EC.LT.ED) THEN
        F00=F0(M,1)+F2LE
        ED1=1.0D0-ED
        BED=ED/(PA*ED1)
        CALL SCHIFF(BED,F1,F2)
        F1D=F1+F00
        F2D=(F2+F00)*EC1
        IF(F1D.GT.F1C) F1C=F1D
        IF(F2D.GT.F2C) F2C=F2D
      ENDIF
      PA1=EMECS*F1C
      PA2=2.66666666666666D0*DLOG(EM/EC)*F2C
C
    1 CONTINUE
      IF(rng()*(PA1+PA2).GT.PA1) GO TO 2
      EPS=DSQRT(EC2+rng()*EMECS)
      PB=EPS/(PA*(1.0D0-EPS))
      F1=2.0D0-2.0D0*DLOG(1.0D0+PB*PB)
      IF(PB.LT.1.0D-8) THEN
        F1=F1-PB*TWOPI
      ELSE
        F1=F1-4.0D0*PB*DATAN2(1.0D0,PB)
      ENDIF
      IF(EPS.LT.ED) THEN
        F00=F0(M,2)+F2LE
      ELSE
        F00=F0(M,1)+F2LE
      ENDIF
      IF(rng()*F1C.GT.F1+F00) GO TO 1
      GO TO 3
    2 CONTINUE
      EPS=EC*(EM/EC)**rng()
      EPS1=1.0D0-EPS
      PB=EPS/(PA*EPS1)
      PB2=PB*PB
      F1=2.0D0-2.0D0*DLOG(1.0D0+PB2)
      F2=F1-6.666666666666666D-1
      IF(PB.LT.1.0D-8) THEN
        F1=F1-PB*TWOPI
      ELSE
        PA0=4.0D0*PB*DATAN2(1.0D0,PB)
        F1=F1-PA0
        F2=F2+2.0D0*PB2*(4.0D0-PA0-3.0D0*DLOG((1.0D0+PB2)/PB2))
      ENDIF
      F2=0.5D0*(3.0D0*F1-F2)
      IF(EPS.LT.ED) THEN
        F00=F0(M,2)+F2LE
      ELSE
        F00=F0(M,1)+F2LE
      ENDIF
      IF(rng()*F2C.GT.EPS1*(F2+F00)) GO TO 1
    3 sbrems=EPS*TOTEN
      RETURN
      END


      SUBROUTINE SCHIFF(B,F1,F2)
c*******************************************************************
c*    Canibalized from PENELOPE too.                               *
c*******************************************************************
C
C     SCREENING FUNCTIONS F1(B) AND F2(B) IN THE BETHE-HEITLER
C  DIFFERENTIAL CROSS SECTION FOR BREMSSTRAHLUNG EMISSION.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      implicit integer*8 (i-n)
      REAL*8 PI, TWOPI, B2, B, F1, F2, A0
      PARAMETER (PI=3.1415926535897932D0, TWOPI=2.0D0*PI)

      B2=B*B
      F1=2.0D0-2.0D0*DLOG(1.0D0+B2)
      F2=F1-6.666666666666666D-1
      IF(B.LT.1.0D-10) THEN
        F1=F1-TWOPI*B
      ELSE
        A0=4.0D0*B*DATAN2(1.0D0,B)
        F1=F1-A0
        F2=F2+2.0D0*B2*(4.0D0-A0-3.0D0*DLOG((1.0D0+B2)/B2))
      ENDIF
      F2=0.5D0*(3.0D0*F1-F2)
      RETURN
      END


c*** end of file *****************************************************


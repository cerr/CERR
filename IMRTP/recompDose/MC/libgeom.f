c*******************************************************************
c* Short description                                               *
c*   Library that handles the geometrical part of the transport    *
c*   process is a 3D voxel geometry                                *
c*                                                                 *
c* Dependencies:                                                   *
c*   -> imports common /dpmpart/                                   *
c* Last update                                                     *
c*   1998-08-21                                                    *
c*******************************************************************


      real*8 function inters()
c*******************************************************************
c*    Informs about interface crossings in a 3D voxel geometry and *
c*    prepares information to move to next voxel                   *
c*                                                                 *
c*    Input:                                                       *
c*      {x,y,z} -> position vector (cm)                            *
c*      {vx,vy,vz} -> normalized direction vector                  *
c*      vox -> voxel where the particle starts                     *
c*    Output:                                                      *
c*      -> distance to intersection with nearest voxel wall (cm)   *
c*      index -> {1,2,3} depending on which walls are intersected  *
c*      dvox -> {+1,-1} depending on whether part. goes forw-backw *
c*    Comments:                                                    *
c*      -> inigeo() must be called before 1st call                 *
c*      -> setv() must be called previously every time v changes   *
c*      -> this routine works in conjunction with chvox(),preparing*
c*         information used by the latter and transferred through  *
c*         a common block                                          *
c*      -> the returned value is never < 0                         *
c*******************************************************************
      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      real*8 dx,dy,dz,idx,idy,idz,ivx,ivy,ivz
      common /cgeom3/ dx,dy,dz,idx,idy,idz,ivx,ivy,ivz
      integer*8 index,dvox
      common /cgo/ index,dvox
! CJ. Jun 20 2005
! Comment out the following two lines, no need in this function.
!      integer*8 nxvox,nyvox,nzvox,nyzvox
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150,nyzvox=nyvox*nzvox)
      real*8 smaybe

com: Checking out all the voxel walls for the smallest distance...
      if (ivz.gt.0.d0) then
        inters = (zvox*dz-z)*ivz
        index = 3
        dvox = +1
      else
        inters = ((zvox-1)*dz-z)*ivz
        index = 3
        dvox = -1
      endif
      if (ivy.gt.0.d0) then
        smaybe = (yvox*dy-y)*ivy
        if (smaybe.lt.inters) then
          inters = smaybe
          index = 2
          dvox = +1
        endif
      else
        smaybe = ((yvox-1)*dy-y)*ivy
        if (smaybe.lt.inters) then
          inters = smaybe
          index = 2
          dvox = -1
        endif
      endif
      if (ivx.gt.0.d0) then
        smaybe = (xvox*dx-x)*ivx
        if (smaybe.lt.inters) then
          inters = smaybe
          index = 1
          dvox = +1
        endif
      else
        smaybe = ((xvox-1)*dx-x)*ivx
        if (smaybe.lt.inters) then
          inters = smaybe
          index = 1
          dvox = -1
        endif
      endif
com: Make sure we won't get neg value to avoid interpretation problems...
      if (inters.lt.0.d0) inters = 0.d0
      end


      subroutine chvox()
c*******************************************************************
c*    Changes voxel according to the information passed by inters()*
c*                                                                 *
c*    Input:                                                       *
c*      vox -> voxel where the particle starts                     *
c*      index -> {1,2,3} depending on which walls are intersected  *
c*      dvox -> {+1,-1} depending on whether part. goes forw-backw *
c*    Output:                                                      *
c*      vox -> voxel where the final position lies                 *
c*    Comments:                                                    *
c*      -> inters() must be called previously                      *
c*      -> if the particle leaves the universe, absvox is set to 0 *
c*      -> only voxel indexes are changed, spatial coordinates     *
c*         {x,y,z} are NOT changed (thus it must be done by the    *
c*         caller)                                                 *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      integer*8 index,dvox
      common /cgo/ index,dvox
C
!      integer*8 nxvox,nyvox,nzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)
!      parameter (nxyz=nxvox*nyvox*nzvox)
C
!      integer*8 mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
      if (index.eq.3) then
        zvox = zvox+dvox
        if (zvox.gt.0.and.zvox.le.Unzvox) then
          absvox = absvox+dvox
        else
          absvox = 0
        endif
      elseif (index.eq.2) then
        yvox = yvox+dvox
        if (yvox.gt.0.and.yvox.le.Unyvox) then
          absvox = absvox+dvox*Unzvox
        else
          absvox = 0
        endif
      else
        xvox = xvox+dvox
        if (xvox.gt.0.and.xvox.le.Unxvox) then
          absvox = absvox+dvox*Unzvox*Unyvox
        else
          absvox = 0
        endif
      endif
      end


      subroutine cango(s)
c*******************************************************************
c*    Transports the particle taking care of interface crossings   *
c*    in a 3D voxelwise geometry                                   *
c*                                                                 *
c*    Input:                                                       *
c*      s -> distance to travel (cm)                               *
c*      {x,y,z} -> position vector (cm)                            *
c*      {vx,vy,vz} -> normalized direction vector                  *
c*      vox -> voxel where the particle starts                     *
c*    Output:                                                      *
c*      s -> distance actually travelled (cm) (=input if vox unchg)*
c*      {x,y,z} -> position vector after the leap                  *
c*      vox -> voxel where the final position lies                 *
c*    Comments:                                                    *
c*      -> inigeo() must be called before 1st call                 *
c*      -> setv() must be called previously every time v changes   *
c*      -> the returned value of s is always >= 0                  *
c*      -> if the particle leaves the universe, absvox is set to 0 *
c*      -> cango does more or less what inters()+chvox() together  *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      real*8 s
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
!      integer*8 nxvox,nyvox,nzvox,nyzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150,nyzvox=nyvox*nzvox)
!      parameter (nxyz=nxvox*nyvox*nzvox)
C
!      real*8 ddx,ddy,ddz,xmid,ymid,zmid,dens
!      integer*8 Unxvox,Unyvox,Unzvox,mat
!      common /dpmvox/ ddx,ddy,ddz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
C
      real*8 ddx,ddy,ddz,idx,idy,idz,ivx,ivy,ivz
      common /cgeom3/ ddx,ddy,ddz,idx,idy,idz,ivx,ivy,ivz
      integer*8 index
      integer*8 dvox
      real*8 smin,smaybe

com: Checking out all the voxel walls for the smallest distance...
      if (ivz.gt.0.d0) then
        smin = (zvox*ddz-z)*ivz
        index = 3
        dvox = +1
      else
        smin = ((zvox-1)*ddz-z)*ivz
        index = 3
        dvox = -1
      endif
      if (ivy.gt.0.d0) then
        smaybe = (yvox*ddy-y)*ivy
        if (smaybe.lt.smin) then
          smin = smaybe
          index = 2
          dvox = +1
        endif
      else
        smaybe = ((yvox-1)*ddy-y)*ivy
        if (smaybe.lt.smin) then
          smin = smaybe
          index = 2
          dvox = -1
        endif
      endif
      if (ivx.gt.0.d0) then
        smaybe = (xvox*ddx-x)*ivx
        if (smaybe.lt.smin) then
          smin = smaybe
          index = 1
          dvox = +1
        endif
      else
        smaybe = ((xvox-1)*ddx-x)*ivx
        if (smaybe.lt.smin) then
          smin = smaybe
          index = 1
          dvox = -1
        endif
      endif

com: Find next voxel, if changed...
      if (smin.lt.s) then
        if (smin.gt.0.d0) then
          s = smin
        else
          s = 0.d0
        endif
        if (index.eq.3) then
          zvox = zvox+dvox
          if (zvox.gt.0.and.zvox.le.Unzvox) then
            absvox = absvox+dvox
          else
            absvox = 0
          endif
        elseif (index.eq.2) then
          yvox = yvox+dvox
          if (yvox.gt.0.and.yvox.le.Unyvox) then
            absvox = absvox+dvox*Unzvox
          else
            absvox = 0
          endif
        else
          xvox = xvox+dvox
          if (xvox.gt.0.and.xvox.le.Unxvox) then
            absvox = absvox+dvox*Unyvox*Unzvox
          else
            absvox = 0
          endif
        endif
      endif

com: Move the particle...
      x = x+s*vx
      y = y+s*vy
      z = z+s*vz
      end


      subroutine setv()
c*******************************************************************
c*    Stores the inverse of vz to save time while in cango(). It   *
c*    should be called every time {vx,vy,vz} changes.              *
c*******************************************************************
      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      real*8 dx,dy,dz,idx,idy,idz,ivx,ivy,ivz
      common /cgeom3/ dx,dy,dz,idx,idy,idz,ivx,ivy,ivz
      integer*8 nxvox,nyvox,nzvox,nyzvox
      parameter (nxvox=2**6,nyvox=2**6,nzvox=150,nyzvox=nyvox*nzvox)
      real*8 inf
      parameter (inf=1.0d30)

      if (vz.ne.0.d0) then
        ivz = 1.d0/vz
      else
        ivz = inf
      endif
      if (vy.ne.0.d0) then
        ivy = 1.d0/vy
      else
        ivy = inf
      endif
      if (vx.ne.0.d0) then
        ivx = 1.d0/vx
      else
        ivx = inf
      endif
      end


      subroutine where()
c*******************************************************************
c*    Locates the particle and sets vox in 3D                      *
c*                                                                 *
c*    Input:                                                       *
c*      -> particle position                                       *
c*    Output:                                                      *
c*      absvox -> absolute address of the current voxel            *
c*    Comments:                                                    *
c*      -> inigeo() must be called before 1st call                 *
c*      -> if the particle is out of universe, absvox is set to 0  *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      integer*8 ptype
      integer*8 xvox,yvox,zvox,absvox,nhist
      real*8 energy,vx,vy,vz,x,y,z
      common /dpmpart/ energy,vx,vy,vz,x,y,z,
     &                 xvox,yvox,zvox,absvox,nhist,ptype
      real*8 ddx,ddy,ddz,idx,idy,idz,ivx,ivy,ivz
      common /cgeom3/ ddx,ddy,ddz,idx,idy,idz,ivx,ivy,ivz
C
!      integer*8 nxvox,nyvox,nzvox,nyzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150,nyzvox=nyvox*nzvox)
!      parameter (nxyz=nxvox*nyvox*nzvox)
C
!      integer*8 mat
!      real*8 dens,ddx,ddy,ddz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ ddx,ddy,ddz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox
C
      zvox = z*idz+1
      if (zvox.lt.1.or.zvox.gt.Unzvox) then
        absvox = 0
        return
      endif
      yvox = y*idy+1
      if (yvox.lt.1.or.yvox.gt.Unyvox) then
        absvox = 0
        return
      endif
      xvox = x*idx+1
      if (xvox.lt.1.or.xvox.gt.Unxvox) then
        absvox = 0
        return
      endif
      absvox = zvox+(yvox-1)*Unzvox+(xvox-1)*Unzvox*Unyvox
      end


      subroutine inigeo(Udx,Udy,Udz,Unxvox,Unyvox,Unzvox)
c*******************************************************************
c*    Initializes the voxel-like geometry in 3D                    *
c*                                                                 *
c*    Input:                                                       *
c*      {dx,dy,dz} -> voxel dimensions in cm                       *
c*      nvox... -> no. of voxels in {x,y,z} directions             *
c*    Comments:                                                    *
c*      -> left,top,lower universe coordinates are assumed {0,0,0} *
c*******************************************************************
      implicit none
!!! comment out the unnecessary statements and check, since the 
!!! checking dimension is not necessary.
      integer*8 Unxvox,Unyvox,Unzvox
      real*8 Udx,Udy,Udz
      real*8 dx,dy,dz,idx,idy,idz,ivx,ivy,ivz
      common /cgeom3/ dx,dy,dz,idx,idy,idz,ivx,ivy,ivz
!      integer*8 nxvox,nyvox,nzvox
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150)

!      if (Unxvox.gt.nxvox.or.Unyvox.gt.nyvox.or.Unzvox.gt.nzvox) then
!        write(*,*) 'inigeo Error: voxel dimensions do not match'
!        stop
!      endif
      dx = Udx
      dy = Udy
      dz = Udz
      idx = 1.d0/dx
      idy = 1.d0/dy
      idz = 1.d0/dz
      end


      integer*8 function getabs(xvox,yvox,zvox)
c*******************************************************************
c*    Gets the absolute voxel # from the coordinate voxel #s       *
c*                                                                 *
c*    Input:                                                       *
c*      vox -> coordinate voxel #s                                 *
c*    Comments:                                                    *
c*      -> inigeo() must be called before 1st call                 *
c*      -> if the particle is out of universe, absvox is set to 0  *
c*******************************************************************
! module DPMVOX replaces common /dpmvox/ and common /dpmesc/	
	use DPMVOX

      implicit none
      integer*8 xvox,yvox,zvox
!      integer*8 nxvox,nyvox,nzvox,nyzvox,nxyz
!      parameter (nxvox=2**6,nyvox=2**6,nzvox=150,nyzvox=nyvox*nzvox)
!      parameter (nxyz=nxvox*nyvox*nzvox)
!      integer*8 mat
!      real*8 dens,dx,dy,dz,xmid,ymid,zmid
!      integer*8 Unxvox,Unyvox,Unzvox
!      common /dpmvox/ dx,dy,dz,xmid,ymid,zmid
!     +          ,dens(nxyz),mat(nxyz),Unxvox,Unyvox,Unzvox

      getabs = zvox+(yvox-1)*Unzvox+(xvox-1)*Unzvox*Unyvox
      end


c* end of file *****************************************************



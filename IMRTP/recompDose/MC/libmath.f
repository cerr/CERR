c*******************************************************************
c* Short description                                               *
c*   Library of numerical tools                                    *
c*                                                                 *
c* Last update                                                     *
c*   2000-06-14                                                    *
c*     rotate() improved; it now superseds rotafs().               *
c*   2000-03-01                                                    *
c*     Routines from PENELOPE gathered in a separate file.         *
c*   2000-02-15                                                    *
c*     linter(), xsplin() and seeki() included.                    *
c*   1998-03-24                                                    *
c*     Created.                                                    *
c*******************************************************************


      real*8 function OFF_rng()
c*******************************************************************
c*    A congruential RNG for a 32-bit machine with a period of some*
c*    2**30 = 1e9                                                  *
c*                                                                 *
c*    Output:                                                      *
c*      -> random in (0,1)                                         *
c*    Comments:                                                    *
c*      -> inirng() must be called before 1st call                 *
c*******************************************************************
      implicit none
      integer*8 iseed
      common /crng2/ iseed

      iseed = iseed*663608941
      OFF_rng = 0.5d0 + iseed*0.23283064d-09
      end


      subroutine OFF_inirng(seed)
c*******************************************************************
c*    Initializes the former rng                                   *
c*                                                                 *
c*    Input:                                                       *
c*      seed -> value to be loaded                                 *
c*              if seed = 0, seed set to the default value         *
c*              if seed < 0, the current value of seed is returned *
c*              if seed = -666 write seed to stdout                *
c*    Output:                                                      *
c*      seed -> if input is >=0, seed does not change              *
c*              if input is <0, the current seed is returned       *
c*******************************************************************
      implicit none
      integer*8 seed
      integer*8 iseed
      common /crng2/ iseed

      if (seed.eq.0) then
c     *** With seed that follows, the period is 1,073,741,824:
        iseed = 1234567
      else if (seed.gt.0) then
        iseed = seed
      else if (seed.eq.-666) then
        write(*,*) 'inirng:info: congruential RNG from libmath.f;'
        write(*,*) '             seed is:'
        write(*,'(1x,i11)') iseed
      else
        seed = iseed
      endif
      end


C  **************************************************************
      FUNCTION ROOTNR(F,DF,X0,BOUND1,BOUND2,PREC)
C FINDS A ROOT OF A FUNCTION USING THE NEWTON-RAPHSON METHOD.
C REF: "Numerical Recipes in C", W.H. Press et al., Cambridge 1992.
C
C INPUT:
C  F ....... FUNCTION WHOSE ROOT IS TO BE FOUND.
C  DF ...... FUNCTION DELIVERING THE DERIVATIVE OF 'FUNC'.
C  X0 ...... INITIAL GUESS FOR THE ROOT.
C  [BOUND1,BOUND2]
C        ... INTERVAL WHERE THE ROOT MUST BE FOUND.
C  PREC .... ITERATION STOPS WHEN RELATIVE CHANGES IN ROOT ARE LESS
C            THAN THIS VALUE.
C
C OUTPUT:
C  ROOTNR DELIVERS THE ROOT.
C
C NOTES:
C  DOUBLE PREC IS ASSUMED FOR ALL ARGUMENTS AND FUNCTIONS.

!!! JC Aug 5, 2005 explicitly declare the variable type 

      IMPLICIT REAL*8 (A-H,O-Z), INTEGER*8 (I-N)
      REAL*8 ZERO, B1, B2, BOUND1, BOUND2, PREC, ROOTNR, DX, DF, DFX, F,
     & X0
	INTEGER*8 MAXFA, MAXITR,NFAILS, ITER
	PARAMETER (ZERO=1.D-30)
      PARAMETER (MAXFA=3,MAXITR=200)

      B1 = BOUND1
      B2 = BOUND2
      ROOTNR  = X0
      NFAILS = 0
      ITER = 0
      IF ((ROOTNR-B1)*(ROOTNR-B2).GT.0.D0) THEN
        WRITE(*,*) 'ROOTNR ERROR: INCORRECT BOUNDS.'
        STOP
      ENDIF
      IF (PREC.LT.1.D-15) THEN
        WRITE(*,*) 'ROOTNR ERROR: PRECISION TOO HIGH.'
        STOP
      ENDIF

C     **** ITERATION LOOP
 10   ITER = ITER + 1
      IF (ITER.EQ.MAXITR) THEN
        WRITE(*,*) 'ROOTNR ERROR: ACCURACY NOT ACHIEVED AFTER',ITER
        WRITE(*,*) '              ITERATIONS PERFORMED. I GIVE UP.'
        STOP
      ENDIF
      DFX = DF(ROOTNR)
      IF (DABS(DFX).LT.ZERO) THEN
        WRITE(*,1000) ROOTNR
 1000   FORMAT (1X,'ROOTNR ERROR: DF(',1PE15.8,') IS ZERO.')
        STOP
      ENDIF
      DX = F(ROOTNR)/DFX
      ROOTNR = ROOTNR - DX
C     **** OUTSIDE THE BOUNDARIES?
      IF ((ROOTNR-B1)*(ROOTNR-B2).GT.0.D0) THEN
        WRITE(*,*) 'ROOTNR ERROR: GONE OUTSIDE BOUNDARIES.'
        STOP
      ENDIF

      IF (DABS(DX).LE.PREC*DABS(ROOTNR)) RETURN
      GO TO 10
      END


      subroutine rotate(u,v,w,costh,phi)
c*******************************************************************
c*    Rotates a vector; the rotation is specified by giving        *
c*    the polar and azimuthal angles in the "self-frame", as       *
c*    determined by the vector to be rotated.                      *
c*                                                                 *
c*    Input:                                                       *
c*      (u,v,w) -> input vector (=d) in the lab. frame             *
c*      costh -> cos(theta), angle between d before and after turn *
c*      phi -> azimuthal angle (rad) turned by d in its self-frame *
c*    Output:                                                      *
c*      (u,v,w) -> rotated vector components in the lab. frame     *
c*    Comments:                                                    *
c*      -> (u,v,w) should have norm=1 on input; if not, it is      *
c*         renormalized on output, provided norm>0.                *
c*      -> The algorithm is based on considering the turned vector *
c*         d' expressed in the self-frame S',                      *
c*           d' = (sin(th)cos(ph), sin(th)sin(ph), cos(th))        *
c*         and then apply a change of frame from S' to the lab     *
c*         frame. S' is defined as having its z' axis coincident   *
c*         with d, its y' axis perpendicular to z and z' and its   *
c*         x' axis equal to y'*z'. The matrix of the change is then*
c*                   / uv/rho    -v/rho    u \                     *
c*          S ->lab: | vw/rho     u/rho    v |  , rho=(u^2+v^2)^0.5*
c*                   \ -rho       0        w /                     *
c*      -> When rho=0 (w=1 or -1) z and z' are parallel and the y' *
c*         axis cannot be defined in this way. Instead y' is set to*
c*         y and therefore either x'=x (if w=1) or x'=-x (w=-1)    *
c*******************************************************************
      implicit none
      real*8 u,v,w,costh,phi
      real*8 rho2,sinphi,cosphi,sthrho,urho,vrho,sinth,norm
      real*8 SZERO,ZERO
      parameter (SZERO=1.0d-14,ZERO=1.0d-90)

      rho2 = u*u+v*v
      norm = rho2+w*w
c     *** Check normalization:
      if (dabs(norm-1.0d0).gt.SZERO) then
        if (norm.lt.ZERO) then
          write(*,*)
     &      'error:rotate:null vector cannot be renormalized'
          stop
        endif
c       *** Renormalize:
        norm = 1.d0/dsqrt(norm)
        u = u*norm
        v = v*norm
        w = w*norm
      endif

      sinphi = dsin(phi)
      cosphi = dcos(phi)
c     *** Case z' not= z:
      if (rho2.gt.ZERO) then
        sthrho = dsqrt((1.0d0-costh*costh)/rho2)
        urho =  u*sthrho
        vrho =  v*sthrho
        u = u*costh - vrho*sinphi +      w*urho*cosphi
        v = v*costh + urho*sinphi +      w*vrho*cosphi
        w = w*costh               - rho2*sthrho*cosphi
      else
c     *** 2 especial cases when z'=z or z'=-z:
        sinth = dsqrt(1.0d0-costh*costh)
        v = sinth*sinphi
        if (w.gt.0.d0) then
          u = sinth*cosphi
          w = costh
        else
          u = -sinth*cosphi
          w = -costh
        endif
      endif
      end


      subroutine rotafs(u,v,w,costh,phi)
c*******************************************************************
c*    Obsolete                                                     *
c*******************************************************************
      real*8 u,v,w,costh,phi

      write(*,*) 'error:rotafs: Please, call rotate instead.'
      stop
      end


      subroutine legsum(coef,sum,conv)
c*******************************************************************
c*    Sums a Legendre series taking its coefs as input data        *
c*                                                                 *
c*    Input:                                                       *
c*      coef -> next coefficient of the Legendre expansion         *
c*      sum -> series sum so far                                   *
c*      conv -> succesive convergent iterations performed so far   *
c*    Output:                                                      *
c*      sum -> series sum so far --after adding the new term--     *
c*      conv -> succesive conv iter so far, after the last one     *
c*    Comments:                                                    *
c*      -> inileg() must be called first                           *
c*      -> 1st coef entered must be the corresponding to P1        *
c*      -> the 1st call to legsum() must input conv=0              *
c*      -> convergence can be considered reached when conv=3       *
c*      -> values of the relevant quantities are stored between    *
c*         calls to this subroutine in a common block              *
c*******************************************************************
      implicit none
      integer*8 cn
      real*8 cmu,pn2,pn1
      common /legdat/ cmu,pn2,pn1,cn
      integer conv
      real*8 coef,sum,pn,toadd,invn,accu
      parameter (accu=1.d-10)

      invn = 1.d0/cn
      pn = (2.d0-invn)*cmu*pn1-(1.d0-invn)*pn2
      pn2 = pn1
      pn1 = pn
      toadd = (cn+0.5d0)*coef*pn
c***  convergence analysis
      if (dabs(toadd).lt.accu*dabs(sum)) then
        conv = conv+1
      else
        conv = 0
      endif
      sum = sum+toadd
      cn = cn+1
      end


      subroutine inileg(mu,coef0,sum)
c*******************************************************************
c*    Initializes data to be used by legsum()                      *
c*                                                                 *
c*    Input:                                                       *
c*      mu -> cos(theta)                                           *
c*      coef0 -> 1st coef of the Legendre series                   *
c*    Output:                                                      *
c*      sum -> 1st term added; use this var when calling legsum()  *
c*    Comments:                                                    *
c*      -> Data is stored in common block for later use            *
c*******************************************************************
      implicit none
      integer*8 cn
      real*8 cmu,pn2,pn1
      common /legdat/ cmu,pn2,pn1,cn
      real*8 mu,coef0,sum

      cmu = mu
      pn2 = 0.d0
      pn1 = 1.d0
      sum = 0.5d0*coef0
      cn = 1
      end


      real*8 function pleg3(k,l,n)
c*******************************************************************
c*    Calculates the integral of three Legendre polinomials        *
c*                                                                 *
c*    Input:                                                       *
c*      k,l,n -> indices of the three polinomials                  *
c*******************************************************************
      implicit none
      integer*8 k,l,n,i,null,ihalf
      real*8 pi,eps,fact,gam2
      parameter (pi=3.14159265358979d0,eps=1.d-3)

      i=k+l+n
      ihalf = i/2
c ***   check conditions for pleg3 not zero
      null=0
      if (ihalf*2.d0+eps.lt.dble(i)) null=1
      if (k+l.lt.n.or.l+n.lt.k.or.k+n.lt.l) null=1
      if (null.eq.1) then
        pleg3 = 0.d0
        return
      endif

      pleg3=1/pi*fact(ihalf)/gam2(ihalf+1)
      pleg3=pleg3*gam2(ihalf-k)/fact(ihalf-k)
      pleg3=pleg3*gam2(ihalf-l)/fact(ihalf-l)
      pleg3=pleg3*gam2(ihalf-n)/fact(ihalf-n)
      end


      real*8 function fact(n)
c*******************************************************************
c*    Calculates the factorial of a natural number                 *
c*******************************************************************
      implicit none
      integer*8 n,i

      if (n.lt.0) then
        write(*,*) 'Error: fact() called with neg argument'
        stop
      endif
      if (n.gt.100) then
        write(*,*) 'Error: sorry, fact(n) goes only up to n=100'
        stop
      endif
      if (n.eq.0) then
        fact = 1.d0
        return
      endif
      fact = 1.d0
      do 10 i=1,n
        fact = fact*i
 10   continue
      end


      real*8 function gam2(n)
c*******************************************************************
c*    Calculates Gamma(n+0.5d0) for n a natural number             *
c*******************************************************************
      implicit none
      integer*8 n,i
      real*8 sqrtpi
      parameter (sqrtpi=1.772453850905d0)

      if (n.lt.0) then
        write(*,*) 'Error: gam2(n) called with neg argument'
        stop
      endif
      if (n.gt.100) then
        write(*,*) 'Error: sorry, gam2(n) goes only up to n=100'
        stop
      endif
      gam2 = sqrtpi
      if (n.eq.0) return
      do 10 i=1,n
        gam2 = gam2*(i-0.5d0)
 10   continue
      end


      subroutine linter(x,y,n,a0,a1)
c*******************************************************************
c*    Prepares linear interpolation coefficients;                  *
c*    discontinuity-tolerant                                       *
c*                                                                 *
c*    Input:                                                       *
c*      x(1..n) -> abscissas                                       *
c*      y(1..n) -> corresponding function values                   *
c*    Output:                                                      *
c*      a0(1..n-1) -> zero-order coef of interpolating polynomial  *
c*      a1(1..n-1) -> first-order coef                             *
c*    Comments:                                                    *
c*      -> x values must be in increasing order.                   *
c*      -> Function discontinuities are accepted; their abscissas  *
c*         are identified by introducing two consecutive (x,y)     *
c*         entries with the same x values.                         *
c*      -> At the discontinuity, the interpolated function is      *
c*         defined continuous from the left.                       *
c*******************************************************************
      implicit none
      integer*8 n
      real*8 x(n),y(n),a0(n),a1(n)
      integer*8 i,iplus1

      if (n.lt.2) then
        write(*,*) 'linter error: too few data: ',n
        stop
      endif

      do 10 i=1,n-1
        iplus1 = i+1
        if (x(i).gt.x(iplus1)) then
          write(*,*) 'linter error: x not in increasing order, i,x:'
          write(*,*) i,x(i),x(iplus1)
          stop
        endif
        if (x(iplus1).gt.x(i)) then
          a1(i) = (y(iplus1)-y(i))/(x(iplus1)-x(i))
          a0(i) = y(i)-x(i)*a1(i)
        else
          a1(i) = 0.0d0
          a0(i) = y(i)
        endif
 10   continue
      end


      subroutine xsplin(x,y,xa,ya,b0,b1,b2,b3,n,a0,a1,a2,a3)
c*******************************************************************
c*    Prepares natural cubic spline interpolation coefficients;    *
c*    discontinuity-tolerant                                       *
c*                                                                 *
c*    Input:                                                       *
c*      x(1..n) -> abscissas                                       *
c*      y(1..n) -> corresponding function values                   *
c*      xa(n),ya(n),b0(n),b1(n),b2(n),b3(n) -> auxiliary mem space *
c*    Output:                                                      *
c*      a0(1..n-1) -> zero-order coef of interpolating polynomial  *
c*      a1(1..n-1) -> first-order coef                             *
c*      a2(1..n-1) -> 2nd-order coef                               *
c*      a3(1..n-1) -> 3rd-order coef                               *
c*    Comments:                                                    *
c*      -> Arrays a0 thru a3 are expected to be of dimension n at  *
c*         least (not n-1).                                        *
c*      -> x values must be in increasing order.                   *
c*      -> Function discontinuities are accepted; their abscissas  *
c*         are identified by introducing two consecutive (x,y)     *
c*         entries with the same x values.                         *
c*      -> At the discontinuity, the interpolated function is      *
c*         defined continuous from the left and the polynomial     *
c*         coefs for the null-width interval are defined as        *
c*         a0=y(left), a1=a2=a3=0.                                 *
c*      -> If less than 4 points are provided between 2            *
c*         discontinuities, spline(), and therefore this routine,  *
c*         aborts.                                                 *
c*******************************************************************
      implicit none
      integer*8 n
      real*8 x(n),y(n),a0(n),a1(n),a2(n),a3(n)
      real*8 xa(n),ya(n),b0(n),b1(n),b2(n),b3(n)
      integer*8 i,j,k,iplus1

      i = 1
      j = 1
 10   continue
        iplus1 = i+1
        if (i.eq.n) iplus1 = i
        if (x(i).gt.x(iplus1)) then
          write(*,*) 'xsplin error: x not in increasing order, i,x:'
          write(*,*) i,x(i),x(iplus1)
          stop
        endif
        if (x(iplus1).gt.x(i)) then
          xa(j) = x(i)
          ya(j) = y(i)
          j = j+1
        else
com:      *** discontinuity:
          xa(j) = x(i)
          ya(j) = y(i)
          call spline(xa,ya,b0,b1,b2,b3,0.0d0,0.0d0,j)
          do 20 k=1,j-1
            a0(i-j+k) = b0(k)
            a1(i-j+k) = b1(k)
            a2(i-j+k) = b2(k)
            a3(i-j+k) = b3(k)
 20       continue
          a0(i) = y(i)
          a1(i) = 0.0d0
          a2(i) = 0.0d0
          a3(i) = 0.0d0
          j = 1
        endif
        i = i+1
        if (i.le.n) goto 10
      end


      integer*8 function seeki(x,xc,n)
c*******************************************************************
c*    Finds the interval (x(i),x(i+1)] containing the value xc.    *
c*                                                                 *
c*    Input:                                                       *
c*      x(1..n) -> data array                                      *
c*      xc -> point to be located                                  *
c*      n -> no. of data points                                    *
c*    Output:                                                      *
c*      index i of the semiopen interval where xc lies             *
c*    Comments:                                                    *
c*      -> NOTICE: Use of this function instead of FINDI() is      *
c*         highly recommended.                                     *
c*      -> If xc is outside the closed interval [x(1),x(n)]  the   *
c*         execution is aborted.                                   *
c*      -> If xc=x(1) then i=1 is returned.                        *
c*******************************************************************
      implicit none
      integer*8 n
      real*8 xc,x(n)
      integer*8 itop,imid

      if(xc.gt.x(n)) then
        write(6,*) 'seeki error: value outside range, xc>x(n):'
        write(6,*) xc,x(n)
        stop
      endif
      if(xc.lt.x(1)) then
        write(6,*) 'seeki error: value outside range, xc<x(1):'
        write(6,*) xc,x(1)
        stop
      endif

      seeki = 1
      itop = n
 10   imid = (seeki+itop)/2
      if(xc.gt.x(imid)) then
        seeki = imid
      else
        itop = imid
      endif
      if(itop-seeki.gt.1) goto 10
      end


      REAL*8 FUNCTION BESK1(RX)
c*******************************************************************
c Bessel's function taken from the CERN Library
c*******************************************************************
CDECK  ID>, BESK1.
      REAL*8 RX
      LOGICAL LEX
      CHARACTER*6 ENAME
      DOUBLE PRECISION X,Y,R,A,A0,A1,A2,B,B0,B1,B2,T(12)
      DOUBLE PRECISION U0,U1,U2,U3,U4,U5,U6,U7,U8,U9
      DOUBLE PRECISION F,F1,F2,F3,C,C0,PI1,CE,EPS,H,ALFA,D
      DOUBLE PRECISION ZERO,ONE,TWO,THREE,FOUR,FIVE,SIX,EIGHT,HALF
      DOUBLE PRECISION C1(0:14),C2(0:14),C3(0:11)
      DOUBLE PRECISION DBESK1,DEBSK1,DX
!!! JC explicitly declare the variable type of 'ROUND', 'EBESK1', 'I'	
	REAL*8 ROUND, EBESK1 
	INTEGER*8 I

      DATA ZERO /0.0D0/, ONE /1.0D0/, TWO /2.0D0/, THREE /3.0D0/
      DATA FOUR /4.0D0/, FIVE /5.0D0/, SIX /6.0D0/, EIGHT /8.0D0/
      DATA HALF /0.5D0/

      DATA T /16.0D0,3.2D0,2.2D0,432.0D0,131.0D0,35.0D0,336.0D0,
     1        40.0D0,48.0D0,12.0D0,20.0D0,28.0D0/

      DATA PI1 /1.25331 41373 155D0/, CE /0.57721 56649 0153D0/
      DATA EPS /1.0D-14/

      DATA C1( 0) /0.22060 14269 2352D3/
      DATA C1( 1) /0.12535 42668 3715D3/
      DATA C1( 2) /0.42865 23409 3128D2/
      DATA C1( 3) /0.94530 05229 4349D1/
      DATA C1( 4) /0.14296 57709 0762D1/
      DATA C1( 5) /0.15592 42954 7626D0/
      DATA C1( 6) /0.01276 80490 8173D0/
      DATA C1( 7) /0.00081 08879 0069D0/
      DATA C1( 8) /0.00004 10104 6194D0/
      DATA C1( 9) /0.00000 16880 4220D0/
      DATA C1(10) /0.00000 00575 8695D0/
      DATA C1(11) /0.00000 00016 5345D0/
      DATA C1(12) /0.00000 00000 4048D0/
      DATA C1(13) /0.00000 00000 0085D0/
      DATA C1(14) /0.00000 00000 0002D0/

      DATA C2( 0) /0.41888 94461 6640D3/
      DATA C2( 1) /0.24989 55490 4287D3/
      DATA C2( 2) /0.91180 31933 8742D2/
      DATA C2( 3) /0.21444 99505 3962D2/
      DATA C2( 4) /0.34384 15392 8805D1/
      DATA C2( 5) /0.39484 60929 4094D0/
      DATA C2( 6) /0.03382 87455 2688D0/
      DATA C2( 7) /0.00223 57203 3417D0/
      DATA C2( 8) /0.00011 71310 2246D0/
      DATA C2( 9) /0.00000 49754 2712D0/
      DATA C2(10) /0.00000 01746 0493D0/
      DATA C2(11) /0.00000 00051 4329D0/
      DATA C2(12) /0.00000 00001 2890D0/
      DATA C2(13) /0.00000 00000 0278D0/
      DATA C2(14) /0.00000 00000 0005D0/

      DATA C3( 0) /+1.03595 08587 724D0/
      DATA C3( 1) /+0.03546 52912 433D0/
      DATA C3( 2) /-0.00046 84750 282D0/
      DATA C3( 3) /+0.00001 61850 638D0/
      DATA C3( 4) /-0.00000 08451 720D0/
      DATA C3( 5) /+0.00000 00571 322D0/
      DATA C3( 6) /-0.00000 00046 456D0/
      DATA C3( 7) /+0.00000 00004 354D0/
      DATA C3( 8) /-0.00000 00000 458D0/
      DATA C3( 9) /+0.00000 00000 053D0/
      DATA C3(10) /-0.00000 00000 007D0/
      DATA C3(11) /+0.00000 00000 001D0/
      ROUND(D)  =  SNGL(D+(D-DBLE(SNGL(D))))

      ENAME=' BESK1'
      X=RX
      LEX=.FALSE.
      GOTO 9

      ENTRY EBESK1(RX)
      ENAME='EBESK1'
      X=RX
      LEX=.TRUE.
      GO TO 9
      ENTRY DBESK1(DX)
      ENAME='DBESK1'
      X=DX
      LEX=.FALSE.
      GO TO 9
      ENTRY DEBSK1(DX)
      ENAME='DEBSK1'
      X=DX
      LEX=.TRUE.

 9    CONTINUE
      IF(X .LE. ZERO) THEN
        WRITE(*,*) ' BESEL: X < 0 ',X
        STOP
      ENDIF

      IF(X .LT. HALF) THEN
       Y=X/EIGHT
       H=TWO*Y**2-ONE
       ALFA=-TWO*H
       B1=ZERO
       B2=ZERO
       DO 1 I = 14,0,-1
       B0=C1(I)-ALFA*B1-B2
       B2=B1
    1  B1=B0
       R=Y*(B0-B2)
       B1=ZERO
       B2=ZERO
       DO 2 I = 14,0,-1
       B0=C2(I)-ALFA*B1-B2
       B2=B1
    2  B1=B0
       B1=(CE+LOG(HALF*X))*R+ONE/X-Y*(B0-B2)
       IF(LEX) B1=EXP(X)*B1
      ELSE IF(X .GT. FIVE) THEN
       R=ONE/X
       Y=FIVE*R
       H=TWO*Y-ONE
       ALFA=-TWO*H
       B1=ZERO
       B2=ZERO
       DO 3 I = 11,0,-1
       B0=C3(I)-ALFA*B1-B2
       B2=B1
    3  B1=B0
       B1=PI1*SQRT(R)*(B0-H*B2)
       IF(.NOT.LEX) B1=EXP(-X)*B1
      ELSE
       Y=(T(1)*X)**2
       A0=ONE
       A1=T(2)*X+T(3)
       A2=(Y+T(4)*X+T(5))/T(6)
       B0=ONE
       B1=T(2)*X+ONE
       B2=(Y+T(7)*X+T(6))/T(6)
       U1=ONE
       U4=T(8)
       U5=T(9)
       C=ZERO
       F=TWO
    4  C0=C
       F=F+ONE
       U0=T(10)*F**2+THREE
       U1=U1+TWO
       U2=U1+TWO
       U3=U1+FOUR
       U4=U4+T(11)
       U5=U5+T(12)
       U6=ONE/(U3**2-FOUR)
       U7=U2*U6
       U8=-U7/U1
       U9=T(1)*U7*X
       F1=U9-(U0-U4)*U8
       F2=U9-(U0-U5)*U6
       F3=U8*(FOUR-(U3-SIX)**2)
       A=F1*A2+F2*A1+F3*A0
       B=F1*B2+F2*B1+F3*B0
       C=A/B
       IF(ABS((C0-C)/C) .GE. EPS) THEN
        A0=A1
        A1=A2
        A2=A
        B0=B1
        B1=B2
        B2=B
        GO TO 4
       ENDIF
       B1=PI1*C/SQRT(X)
       IF(.NOT.LEX) B1=EXP(-X)*B1
      ENDIF
      IF(LEX)  THEN
         IF(ENAME .EQ. 'EBESK1')  THEN
            EBESK1=ROUND(B1)
         ELSE
            DEBSK1=B1
         ENDIF
      ELSE
         IF(ENAME .EQ. ' BESK1')  THEN
            BESK1=ROUND(B1)
         ELSE
            DBESK1=B1
         ENDIF
      ENDIF
      RETURN

  100 FORMAT(7X,A6,' ... NON-POSITIVE ARGUMENT X = ',E16.6)
      END


c* end of file *****************************************************



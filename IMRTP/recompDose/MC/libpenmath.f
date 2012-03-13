! JC Jun 13 2005
! Adapt the orginal FORTRAN file to be call by MATLAB.
! Replace write(*,*) with "CALL mexprintf('')
! since MATLAB has the control of display
c*******************************************************************
c* Short description                                               *
c*   Numerical tools from the PENELOPE project.                    *
c*******************************************************************

C  **************************************************************
C                         FUNCTION RAND
C  **************************************************************
      real*8 function rng()
C
C     THIS IS AN ADAPTED VERSION OF SUBROUTINE RANECU WRITTEN BY
C  F. JAMES (COMPUT. PHYS. COMMUN. 60 (1990) 329-344), WHICH HAS
C  BEEN MODIFIED TO GIVE A SINGLE RANDOM NUMBER AT EACH CALL.
C     THE 'SEEDS' ISEED1 AND ISEED2 MUST BE INITIALIZED IN THE
C  MAIN PROGRAM AND TRANSFERRED THROUGH THE NAMED COMMON BLOCK
C  /RSEED/.
c     Comments:
c       -> inirng() must be called before 1st call.

      IMPLICIT DOUBLE PRECISION (A-H,O-Z), integer*8 (I)
!!! JC AUG 5, 2005, EXPLICITLY DECLARE VARIABLE TYPES
	REAL*8 USCALE
	INTEGER*8 ISEED1, ISEED2, I1, I2, IZ

      PARAMETER (USCALE=1.0D0/2.0D0**31)
      COMMON/RSEED/ISEED1,ISEED2

      I1=ISEED1/53668
      ISEED1=40014*(ISEED1-I1*53668)-I1*12211
      IF(ISEED1.LT.0) ISEED1=ISEED1+2147483563

      I2=ISEED2/52774
      ISEED2=40692*(ISEED2-I2*52774)-I2*3791
      IF(ISEED2.LT.0) ISEED2=ISEED2+2147483399

      IZ=ISEED1-ISEED2
      IF(IZ.LT.1) IZ=IZ+2147483562
      rng = IZ*USCALE

      RETURN
      END


      subroutine inirng(seed)
c*******************************************************************
c*    Initializes the former rng                                   *
c*                                                                 *
c*    Input:                                                       *
c*      seed -> value to be loaded as seed1;                       *
c*              if seed = 0, seed1 and seed2 set to default values;*
c*              if seed < 0, the current value of seed1 is returned*
c*              if seed = -666 write seed1 and seed2 to stdout     *
c*    Output:                                                      *
c*      seed -> seed < 0, the current value of seed1 is returned   *
c*    Comments:                                                    *
c*      -> use seed2n() to set and query about seed2               *
c*******************************************************************
      implicit none
      integer*8 seed
      integer*8 iseed1,iseed2
      COMMON/RSEED/ISEED1,ISEED2
! ADDED by JC, to output ndata to MATLAB commond window.
	character*80 buffer 

      if (seed.eq.int8(0)) then
        iseed1 = 564737433
        call seed2n(0)
      else if (seed.gt.int8(0)) then
        iseed1 = seed
        call seed2n(0)
      else if (seed.eq.int8(-666)) then
        CALL mexprintf('inirng:info: 64-bit RNG from PENELOPE;')
        CALL mexprintf('   seeds 1 and 2 are:')
	  CALL mexprintf(CHAR(10))
	  WRITE(buffer,'(i20)') iseed1
	  CALL mexprintf(buffer)
	  WRITE(buffer,'(i20)') iseed2
      CALL mexprintf(buffer)
	  CALL mexprintf(CHAR(10))
      else
        seed = iseed1
      endif
      end


      subroutine seed2n(seed2)
c*******************************************************************
c*    Set and query about seed2 in the former rng                  *
c*                                                                 *
c*    Input:                                                       *
c*      seed2 -> value to be loaded as seed2                       *
c*              if input is =0, seed2 is set to the default        *
c*    Output:                                                      *
c*      seed -> if input is >=0, seed2 does not change             *
c*              if input is <0, the current seed2 is returned      *
c*******************************************************************
      implicit none
      integer*8 seed2
      integer*8 iseed1,iseed2
      COMMON/RSEED/ISEED1,ISEED2

      if (seed2.eq.0) then
        iseed2 = 65432133
      else if (seed2.gt.0) then
        iseed2 = seed2
      else
        seed2 = iseed2
      endif
      end


C  **************************************************************
C                       SUBROUTINE GABQ
C  **************************************************************
      SUBROUTINE GABQ(FCT,XL,XU,SUM,TOL,IER)
C
C     THIS INTEGRATION SUBROUTINE APPLIES THE GAUSS METHOD WITH
C  AN ADAPTIVE-BIPARTITION SCHEME.
C     FCT IS THE (EXTERNAL) FUNCTION BEING INTEGRATED OVER THE
C  INTERVAL (XL,XU). SUM IS THE RESULTANT VALUE OF THE INTEGRAL.
C     TOL IS THE TOLERANCE, I.E. MAXIMUM RELATIVE ERROR REQUIRED
C  ON THE COMPUTED VALUE (SUM). TOL SHOULD NOT EXCEED 1.0D-13.
C     IER IS AN ERROR CONTROL PARAMETER; ITS OUTPUT VALUE IS
C  IER=0 IF THE INTEGRATION ALGORITHM HAS BEEN ABLE TO GET THE
C  REQUIRED ACCURACY AND IER=1 OTHERWISE.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
!!! JC Aug 5 2005, explicitly declear the variable type
	INTEGER*8 IWR,NP,NP2,NP4,IER,I1,ICALL,LH,LHN,I,K,I2,I3
	REAL*8 FCT,HO,ASUM,SI,XA,XB,XC,S1,S2,S12
	REAL*8	X(10),W(10),S(128),SN(128),L(128),LN(128)
	REAL*8 CTOL, PTOL, ERR, H, XU, XL, SUM, TOL,A,B,C,D
C  ****  PRINTED OUTPUT OF PARTIAL RESULTS: SET IWR=1.
      DATA IWR/0/
C  ****  COEFFICIENTS FOR GAUSS 20-POINT INTEGRATION.
      DATA NP,NP2,NP4/10,20,40/
C  ****  ABSCISSAS.
      DATA X/7.6526521133497334D-02,2.2778585114164508D-01,
     1       3.7370608871541956D-01,5.1086700195082710D-01,
     2       6.3605368072651503D-01,7.4633190646015079D-01,
     3       8.3911697182221882D-01,9.1223442825132591D-01,
     4       9.6397192727791379D-01,9.9312859918509492D-01/
C  ****  WEIGHTS.
      DATA W/1.5275338713072585D-01,1.4917298647260375D-01,
     1       1.4209610931838205D-01,1.3168863844917663D-01,
     2       1.1819453196151842D-01,1.0193011981724044D-01,
     3       8.3276741576704749D-02,6.2672048334109064D-02,
     4       4.0601429800386941D-02,1.7614007139152118D-02/
C  ****  CORRECTED TOLERANCE.
      CTOL=DMAX1(TOL,1.0D-13)
      PTOL=0.01D0*CTOL
      ERR=1.0D35
      H=XU-XL
C
com: Info disabled...
c      IF(IWR.EQ.1) THEN
c      WRITE(6,10)
c   10 FORMAT(///5X,'GAUSS ADAPTIVE-BIPARTITION QUADRATURE')
c      WRITE(6,11) XL,XU,TOL
c   11 FORMAT(/5X,'XL = ',1P,E15.8,', XU = ',E15.8,', TOL = ',
c     1  E8.1)
c      ENDIF
      IER=0
C  ****  GAUSS INTEGRATION FROM XL TO XU.
      A=0.5D0*(XU-XL)
      B=0.5D0*(XL+XU)
      C=A*X(1)
      D=W(1)*(FCT(B+C)+FCT(B-C))
      DO 1 I1=2,NP
      C=A*X(I1)
    1 D=D+W(I1)*(FCT(B+C)+FCT(B-C))
      SUM=D*A
C  ****  ADAPTIVE BIPARTITION SCHEME.
      ICALL=NP2
      LH=1
      S(1)=SUM
      L(1)=1
    2 HO=H
      H=0.5D0*H
      ASUM=SUM
      LHN=0
      DO 5 I=1,LH
      K=L(I)
      SI=S(I)
      XA=XL+(K-1)*HO
      XB=XA+H
      XC=XA+HO
      A=0.5D0*(XB-XA)
      B=0.5D0*(XB+XA)
      C=A*X(1)
      D=W(1)*(FCT(B+C)+FCT(B-C))
      DO 3 I2=2,NP
      C=A*X(I2)
    3 D=D+W(I2)*(FCT(B+C)+FCT(B-C))
      S1=D*A
      A=0.5D0*(XC-XB)
      B=0.5D0*(XC+XB)
      C=A*X(1)
      D=W(1)*(FCT(B+C)+FCT(B-C))
      DO 4 I3=2,NP
      C=A*X(I3)
    4 D=D+W(I3)*(FCT(B+C)+FCT(B-C))
      S2=D*A
      ICALL=ICALL+NP4
      S12=S1+S2
      SUM=SUM+S12-SI
      IF(DABS(S12-SI).LT.DMAX1(PTOL*DABS(S12),1.0D-35)) GO TO 5
      LHN=LHN+2
      IF(LHN.GT.128.OR.ICALL.GT.9999) GO TO 8
      SN(LHN)=S2
      LN(LHN)=K+K
      SN(LHN-1)=S1
      LN(LHN-1)=LN(LHN)-1
    5 CONTINUE
      ERR=DABS(SUM-ASUM)/DMAX1(DABS(SUM),1.0D-35)
      IF(IWR.EQ.1) WRITE(6,12) ICALL,SUM,ERR,LHN
   12 FORMAT(5X,'N = ',I5,', SUM = ',1P,E19.12,', ERR = ',E8.1,
     1  ', LH = ',I3)
      IF(ERR.GT.CTOL.AND.LHN.GT.0) GO TO 6
      IF(IWR.EQ.1) WRITE(6,13)
   13 FORMAT(5X,'END OF GAUSS-BIPARTITION PROCEDURE'///)
      RETURN
    6 LH=LHN
      DO 7 I=1,LH
      S(I)=SN(I)
    7 L(I)=LN(I)
      GO TO 2
C  ****  WARNING (LOW ACCURACY) MESSAGE.
c*** Low accuracy warning printout disabled
 8    continue
c    8 WRITE(6,14)
c   14 FORMAT(/5X,'*** LOW ACCURACY IN SUBROUTINE GABQ.')
c      WRITE(6,11) XL,XU,TOL
c      WRITE(6,15) SUM,ERR
c   15 FORMAT(5X,'SUM = ',1P,E19.12,', ERR = ',E8.1//)
      IER=1
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE SPLINE
C  **************************************************************
      SUBROUTINE SPLINE(X,Y,A,B,C,D,S1,SN,N)
C
C     CUBIC SPLINE INTERPOLATION BETWEEN TABULATED DATA.
C
C  INPUT:
C     X(I) (I=1, ...,N) ........ GRID POINTS.
C                     (THE X VALUES MUST BE IN INCREASING ORDER).
C     Y(I) (I=1, ...,N) ........ CORRESPONDING FUNCTION VALUES.
C     S1,SN ..... SECOND DERIVATIVES AT X(1) AND X(N).
C             (THE NATURAL SPLINE CORRESPONDS TO TAKING S1=SN=0).
C     N ........................ NUMBER OF GRID POINTS.
C
C     THE INTERPOLATING POLYNOMIAL IN THE I-TH INTERVAL, FROM
C  X(I) TO X(I+1), IS PI(X)=A(I)+X*(B(I)+X*(C(I)+X*D(I))).
C
C  OUTPUT:
C     A(I),B(I),C(I),D(I) ...... SPLINE COEFFICIENTS.
C
C     REF.: M.J. MARON, 'NUMERICAL ANALYSIS: A PRACTICAL
C           APPROACH', MACMILLAN PUBL. CO., NEW YORK 1982.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
!!! JC AUG 05, 2005 explicitly declear variable types
!dec$ IF DEFINED (AMD64)
	INTEGER*8 N,N1,N2,I,K
!dec$ ELSE
	INTEGER N,N1,N2,I,K
!dec$ ENDIF

	REAL*8 R,SI1,SI,S1,SN,H,HI
      REAL*8 X(N),Y(N),A(N),B(N),C(N),D(N)
      IF(N.LT.4) THEN
      WRITE(6,10) N
   10 FORMAT(5X,'SPLINE INTERPOLATION CANNOT BE PERFORMED WITH',
     1  I4,' POINTS. STOP.')
      STOP
      ENDIF
      N1=N-1
      N2=N-2
C  ****  AUXILIARY ARRAYS H(=A) AND DELTA(=D).
      DO 1 I=1,N1
      IF(X(I+1)-X(I).LT.1.0D-10) THEN
      WRITE(6,11)
   11 FORMAT(5X,'SPLINE X VALUES NOT IN INCREASING ORDER. STOP.')
      STOP
      ENDIF
      A(I)=X(I+1)-X(I)
    1 D(I)=(Y(I+1)-Y(I))/A(I)
C  ****  SYMMETRIC COEFFICIENT MATRIX (AUGMENTED).
      DO 2 I=1,N2
      B(I)=2.0D0*(A(I)+A(I+1))
      K=N1-I+1
    2 D(K)=6.0D0*(D(K)-D(K-1))
      D(2)=D(2)-A(1)*S1
      D(N1)=D(N1)-A(N1)*SN
C  ****  GAUSS SOLUTION OF THE TRIDIAGONAL SYSTEM.
      DO 3 I=2,N2
      R=A(I)/B(I-1)
      B(I)=B(I)-R*A(I)
    3 D(I+1)=D(I+1)-R*D(I)
C  ****  THE SIGMA COEFFICIENTS ARE STORED IN ARRAY D.
      D(N1)=D(N1)/B(N2)
      DO 4 I=2,N2
      K=N1-I+1
    4 D(K)=(D(K)-A(K)*D(K+1))/B(K-1)
      D(N)=SN
C  ****  SPLINE COEFFICIENTS.
      SI1=S1
      DO 5 I=1,N1
      SI=SI1
      SI1=D(I+1)
      H=A(I)
      HI=1.0D0/H
      A(I)=(HI/6.0D0)*(SI*X(I+1)**3-SI1*X(I)**3)
     1    +HI*(Y(I)*X(I+1)-Y(I+1)*X(I))
     2    +(H/6.0D0)*(SI1*X(I)-SI*X(I+1))
      B(I)=(HI/2.0D0)*(SI1*X(I)**2-SI*X(I+1)**2)
     1    +HI*(Y(I+1)-Y(I))+(H/6.0D0)*(SI-SI1)
      C(I)=(HI/2.0D0)*(SI*X(I+1)-SI1*X(I))
    5 D(I)=(HI/6.0D0)*(SI1-SI)
      RETURN
      END

C  **************************************************************
C                       SUBROUTINE R4SPLN
C  **************************************************************
      SUBROUTINE R4SPLN(X,Y,A,B,C,D,S1,SN,N)
c *** Same as spline() but input vars are real, not real*8.
!!! JC Aug 5 2005 explicitly declare the variable types
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
	INTEGER*8 I, N, N1, N2, K
	REAL*8 SI, SI1, H, HI, R, S1, SN
      real*8 X(N),Y(N),A(N),B(N),C(N),D(N)
      IF(N.LT.4) THEN
      WRITE(6,10) N
   10 FORMAT(5X,'SPLINE INTERPOLATION CANNOT BE PERFORMED WITH',
     1  I8,' POINTS. STOP.')
      STOP
      ENDIF
      N1=N-1
      N2=N-2
C  ****  AUXILIARY ARRAYS H(=A) AND DELTA(=D).
      DO 1 I=1,N1
      IF(X(I+1)-X(I).LT.1.0D-10) THEN
      WRITE(6,11)
   11 FORMAT(5X,'SPLINE X VALUES NOT IN INCREASING ORDER. STOP.')
      STOP
      ENDIF
      A(I)=X(I+1)-X(I)
    1 D(I)=(Y(I+1)-Y(I))/A(I)
C  ****  SYMMETRIC COEFFICIENT MATRIX (AUGMENTED).
      DO 2 I=1,N2
      B(I)=2.0D0*(A(I)+A(I+1))
      K=N1-I+1
    2 D(K)=6.0D0*(D(K)-D(K-1))
      D(2)=D(2)-A(1)*S1
      D(N1)=D(N1)-A(N1)*SN
C  ****  GAUSS SOLUTION OF THE TRIDIAGONAL SYSTEM.
      DO 3 I=2,N2
      R=A(I)/B(I-1)
      B(I)=B(I)-R*A(I)
    3 D(I+1)=D(I+1)-R*D(I)
C  ****  THE SIGMA COEFFICIENTS ARE STORED IN ARRAY D.
      D(N1)=D(N1)/B(N2)
      DO 4 I=2,N2
      K=N1-I+1
    4 D(K)=(D(K)-A(K)*D(K+1))/B(K-1)
      D(N)=SN
C  ****  SPLINE COEFFICIENTS.
      SI1=S1
      DO 5 I=1,N1
      SI=SI1
      SI1=D(I+1)
      H=A(I)
      HI=1.0D0/H
      A(I)=(HI/6.0D0)*(SI*X(I+1)**3-SI1*X(I)**3)
     1    +HI*(Y(I)*X(I+1)-Y(I+1)*X(I))
     2    +(H/6.0D0)*(SI1*X(I)-SI*X(I+1))
      B(I)=(HI/2.0D0)*(SI1*X(I)**2-SI*X(I+1)**2)
     1    +HI*(Y(I+1)-Y(I))+(H/6.0D0)*(SI-SI1)
      C(I)=(HI/2.0D0)*(SI*X(I+1)-SI1*X(I))
    5 D(I)=(HI/6.0D0)*(SI1-SI)
      RETURN
      END

C  **************************************************************
C                       SUBROUTINE INTEG
C  **************************************************************
      SUBROUTINE INTEG(X,A,B,C,D,XL,XU,SUM,N)
C
C     INTEGRAL OF A CUBIC SPLINE FUNCTION.
C
C  INPUT:
C     X(I) (I=1, ...,N) ........ GRID POINTS.
C                     (THE X VALUES MUST BE IN INCREASING ORDER).
C     A(I),B(I),C(I),D(I) ...... SPLINE COEFFICIENTS.
C     N ........................ NUMBER OF GRID POINTS.
C     XL ....................... LOWER LIMIT IN THE INTEGRAL.
C     XU ....................... UPPER LIMIT IN THE INTEGRAL.
C
C  OUTPUT:
C     SUM ...................... VALUE OF THE INTEGRAL.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
!!! JC AUG 5 2005 EXPLICITLY DECLARE VARIABLE TYPES
	INTEGER*8 N,IWR,IL,IU,I
      REAL*8 X(N),A(N),B(N),C(N),D(N)
	REAL*8 XU,XL,SIGN,SUM,X1,X2, SUMP
C  ****  SET INTEGRATION LIMITS IN INCREASING ORDER.
      SIGN=1.0D0
      IF(XU.LT.XL) THEN
      SUM=XL
      XL=XU
      XU=SUM
      SIGN=-1.0D0
      ENDIF
C  ****  CHECK INTEGRAL LIMITS.
      IWR=0
      IF(XL.LT.X(1).OR.XU.GT.X(N)) IWR=1
C  ****  FIND INVOLVED INTERVALS.
      SUM=0.0D0
      CALL FINDI(X,XL,N,IL)
      CALL FINDI(X,XU,N,IU)
C  ****  ONLY A SINGLE INTERVAL INVOLVED.
      IF(IL.EQ.IU) THEN
      X1=XL
      X2=XU
      SUM=X2*(A(IL)+X2*((B(IL)/2)+X2*((C(IL)/3)+X2*D(IL)/4)))
     1   -X1*(A(IL)+X1*((B(IL)/2)+X1*((C(IL)/3)+X1*D(IL)/4)))
      GO TO 2
      ENDIF
C  ****  CONTRIBUTIONS FROM DIFFERENT INTERVALS.
      X1=XL
      X2=X(IL+1)
      SUM=X2*(A(IL)+X2*((B(IL)/2)+X2*((C(IL)/3)+X2*D(IL)/4)))
     1   -X1*(A(IL)+X1*((B(IL)/2)+X1*((C(IL)/3)+X1*D(IL)/4)))
      IL=IL+1
      DO 1 I=IL,IU
      X1=X(I)
      X2=X(I+1)
      IF(I.EQ.IU) X2=XU
      SUMP=X2*(A(I)+X2*((B(I)/2)+X2*((C(I)/3)+X2*D(I)/4)))
     1    -X1*(A(I)+X1*((B(I)/2)+X1*((C(I)/3)+X1*D(I)/4)))
    1 SUM=SUM+SUMP
    2 SUM=SIGN*SUM
C  ****  INTEGRAL LIMITS OUT OF RANGE.
      IF(IWR.EQ.1) WRITE(6,10)
   10 FORMAT(/'*** WARNING: INTEGRAL LIMITS OUT OF RANGE. ***')
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE FINDI
C  **************************************************************
      SUBROUTINE FINDI(X,XC,N,I)
C
C     FINDS THE INTERVAL (X(I),X(I+1)) CONTAINING THE VALUE XC.
C
C  INPUT:
C     X(I) (I=1, ...,N) ........ GRID POINTS.
C                     (THE X VALUES MUST BE IN INCREASING ORDER).
C     XC ....................... POINT TO BE LOCATED.
C     N ........................ NUMBER OF GRID POINTS.
C
C  OUTPUT:
C     I ........................ INTERVAL INDEX.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
!!! JC AUG 5 2005, explicitly declare the variable types
      INTEGER*8 N, I, IT, I1
	REAL*8 X(N),XC
      IF(XC.GT.X(N)) THEN
      I=N-1
      RETURN
      ENDIF
      IF(XC.LT.X(1)) THEN
      I=1
      RETURN
      ENDIF
      I=1
      I1=N
    1 IT=(I+I1)/2
      IF(XC.GT.X(IT)) THEN
        I=IT
      ELSE
        I1=IT
      ENDIF
      IF(I1-I.GT.1) GO TO 1
      RETURN
      END
C  **************************************************************
C                         FUNCTION RAND
C  **************************************************************
      FUNCTION RAND(DUMMY)
C
C     THIS IS AN ADAPTED VERSION OF SUBROUTINE RANECU WRITTEN BY
C  F. JAMES (COMPUT. PHYS. COMMUN. 60 (1990) 329-344), WHICH HAS
C  BEEN MODIFIED TO GIVE A SINGLE RANDOM NUMBER AT EACH CALL.
C     THE 'SEEDS' ISEED1 AND ISEED2 MUST BE INITIALIZED IN THE
C  MAIN PROGRAM AND TRANSFERRED THROUGH THE NAMED COMMON BLOCK
C  /RSEED/.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*8 (I)
!!! JC Aug 5 2005 declear varialbles explicitly
	REAL*8 USCALE, RAND, DUMMY
	INTEGER*8 ISEED1, ISEED2, I1, I2, IZ

      PARAMETER (USCALE=1.0D0/2.0D0**31)
      COMMON/RSEED/ISEED1,ISEED2
C
      I1=ISEED1/53668
      ISEED1=40014*(ISEED1-I1*53668)-I1*12211
      IF(ISEED1.LT.0) ISEED1=ISEED1+2147483563
C
      I2=ISEED2/52774
      ISEED2=40692*(ISEED2-I2*52774)-I2*3791
      IF(ISEED2.LT.0) ISEED2=ISEED2+2147483399
C
      IZ=ISEED1-ISEED2
      IF(IZ.LT.1) IZ=IZ+2147483562
      RAND=IZ*USCALE
C
      RETURN
      END


c*** Next stuff added on 24-03-2000
C  **************************************************************
C                       SUBROUTINE GAULEG
C  **************************************************************
      SUBROUTINE GAULEG(X,W,N)
C
C     This subroutine returns the abscissas X(1:N) and weights
C  W(1:N) of the Gauss-Legendre N-point quadrature formula.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
!!! JC AUG 05 2005, explicitly declare variable types
	INTEGER*8 N,M,I,J
      REAL*8 X(N),W(N),EPS,XM,XL,P1,P2,P3,PP,Z,Z1
      PARAMETER (EPS=1.0D-15)
      M=(N+1)/2
      XM=0.0d0
      XL=1.0d0
      DO 3 I=1,M
        Z=DCOS(3.141592654D0*(I-0.25D0)/(N+0.5D0))
    1   CONTINUE
          P1=1.0D0
          P2=0.0D0
          DO 2 J=1,N
            P3=P2
            P2=P1
            P1=((2.0D0*J-1.0D0)*Z*P2-(J-1.0D0)*P3)/J
    2     CONTINUE
          PP=N*(Z*P1-P2)/(Z*Z-1.0D0)
          Z1=Z
          Z=Z1-P1/PP
        IF(DABS(Z-Z1).GT.EPS*DABS(Z)+EPS) GO TO 1
        X(I)=XM-XL*Z
        X(N+1-I)=XM+XL*Z
        W(I)=2.0D0*XL/((1.0D0-Z*Z)*PP*PP)
        W(N+1-I)=W(I)
    3 CONTINUE
      RETURN
      END


C  **************************************************************
C                       SUBROUTINE LEGENP
C  **************************************************************
      SUBROUTINE LEGENP(X,PL,NL)
C
C    This subroutine computes the first NL Legendre polynomials
C  for the argument X, using their recurrence relation. PL is an
C  array of physical dimension equal to NL or larger. On output
C  PL(J), J=1:NL, contains the value of the Legendre polynomial
C  of degree (order) L-1.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
!!! JC AUG 05 2005 EXPLICITLY DECLARE VARIABLE TYPES
	INTEGER*8 NL,J     
	REAL*8 PL(NL), X, TWOX, F1, F2, D
      
	PL(1)=1.0D0
      PL(2)=X
      IF(NL.GT.2) THEN
        TWOX=2.0D0*X
        F1=X
        D=1.0D0
        DO 1 J=3,NL
          F1=F1+TWOX
          F2=D
          D=D+1.0D0
          PL(J)=(F1*PL(J-1)-F2*PL(J-2))/D
    1   CONTINUE
      ENDIF
      RETURN
      END


C  **************************************************************
C                        SUBROUTINE SMPLX
C  **************************************************************
      SUBROUTINE SMPLX(FCT,X,TOL,N,NITER,IW)
C
C     THIS SUBROUTINE FINDS A RELATIVE MINIMUM OF THE EXTERNAL
C  FUNCTION FCT BY USING THE SIMPLEX METHOD.
C
C     INPUT:
C        FCT ....... NAME OF THE EXTERNAL FUNCT. TO BE MINIMIZED.
C        N ......... NUMBER OF VARIABLE ARGUMENTS IN FCT.
C        X ......... ARRAY OF DIMENSION GREATER OR EQUAL THAN N
C                    CONTAINING THE ARGUMENT STARTING VALUES IN
C                    ITS FIRST N POSITIONS.
C        TOL ....... TOLERANCE. THE CALCULATION IS FINISHED WHEN
C                    EITHER THE LARGEST RELATIVE DIFFERENCE OF
C                    CURRENT FUNCTION VALUES OR THE FRACTIONAL
C                    SIMPLEX SIZE BECOME SMALLER THAN TOL.
C        NITER ..... MAXIMUM NUMBER OF ITERATIONS, A CONVENIENT
C                    VALUE IS ABOUT 100*N.
C        IW ........ PARTIAL RESULTS ARE WRITTEN ON UNIT 6 EACH
C                    IW-TH ITERATION WHEN IW>0.
C     OUTPUT:
C        X ......... ARGUMENT VALUES FOR WHICH THE FUNCTION TAKES
C                    THE LOWER VALUE OBTAINED IN THE CALCULATION.
C
C        IF N IS GREATER THAN 25, THE DIMENSIONS OF THE ARRAYS P,
C     F AND X0 MUST BE ENLARGED.
C
C                                              F. SALVAT. 1993.
c
c  Warning: this routine uses rng(), which must be previously
c           initialized
c
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      IMPLICIT INTEGER*8 (I-N)
      EXTERNAL FCT
!!! JC AUG 05 2005 EXPLICITLY DECLARE VARIABLE TYPES
	INTEGER*8 NPUNT, NPUN1, N, N1, IR, NSTEP, NSTART, I, IC, K, ISIGN
	INTEGER*8 K0, K1, IW, J, NITER, K2, F2
      PARAMETER(NPUNT=500,NPUN1=NPUNT+1)
      REAL*8 P(NPUNT,NPUN1),F(NPUN1),X0(NPUNT),X(1)
	REAL*8 RND, SNORM, SFAC, DN, DN1, FCT, FMIN, XS, RANDOM, RNG
	REAL*8 F0,F1,TLEN,H,TST, TOL, FT, FAC
      COMMON/RSEED/RND

com: Validate dimensions...
      if (n.gt.npunt) then
        CALL mexprintf('smplx Error: array too big; enlarge npunt')
	  CALL mexprintf(CHAR(10))
        stop
      endif

C  ****  INITIATION.
C
c     IW=IABS(IW)
      N1=N+1
      SNORM=0.0D0
      DO 100 I=1,N
      SNORM=SNORM+X(I)*X(I)
  100 CONTINUE
      SNORM=10.0D0*DSQRT(SNORM)
      IF(SNORM.LT.1.0D-4) SNORM=1.0D-4
      SFAC=N1
      IF(SNORM.LT.SFAC) SFAC=SNORM
      DN=1.0D0/DFLOAT(N)
      DN1=1.0D0/SFAC
      IR=1
      NSTEP=0
      NSTART=0
C  ****  STARTING SIMPLEX.
      DO 101 I=1,N
      P(I,1)=X(I)
  101 CONTINUE
      F(1)=FCT(X)
      FMIN=F(1)
      DO 103 K=2,N1
      IC=K-1
      XS=X(IC)
      RANDOM=rng()
      IF(RANDOM.LT.0.5D0) THEN
      ISIGN=-1
      ELSE
      ISIGN=1
      ENDIF
      X(IC)=X(IC)+SFAC*ISIGN
      DO 102 I=1,N
      P(I,K)=X(I)
  102 CONTINUE
      F(K)=FCT(X)
      X(IC)=XS
  103 CONTINUE
C
C  ****  CONVERGENCE.
C
C  ****  SORTING.
  201 K0=1
      F0=F(1)
      K1=1
      F1=F0
      K2=1
      F2=F0
      DO 204 K=2,N1
      IF(F0.LT.F(K)) GO TO 202
      K0=K
      F0=F(K)
  202 IF(F1.GT.F(K)) GO TO 203
      K2=K1
      F2=F1
      K1=K
      F1=F(K)
      GO TO 204
  203 IF(F2.GT.F(K)) GO TO 204
      K2=K
      F2=F(K)
  204 CONTINUE
C  ****  SIMPLEX SIZE.
      TLEN=0.0D0
      DO 206 K=1,N1
      IF(K.EQ.K0) GO TO 206
      H=0.0D0
      DO 205 I=1,N
      X0(I)=P(I,K)-P(I,K0)
      H=H+X0(I)**2
  205 CONTINUE
      TLEN=TLEN+DSQRT(H)
  206 CONTINUE
C  ****  FRACTIONAL DISPLACEMENT.
      H=0.0D0
      DO 207 I=1,N
      H=H+P(I,K0)**2
  207 CONTINUE
      TLEN=TLEN*DN1/(DSQRT(H)+1.0D-35)
C  ****  CONVERGENCE CHECK.
      TST=2.0D0*DABS(F1-F0)
      IF(F0.GT.FMIN) GO TO 208
C+++++++++++++++++++
      IF(IW.NE.0) THEN
      IF(MOD(NSTEP,IW).EQ.0)
     1   WRITE(6,1001) NSTEP,F0,TLEN,TST,(P(J,K0),J=1,N)
 1001 FORMAT(3X,'**** STEP =',I4,', FMIN = ',1PD21.14/8X,'TLEN ='
     1  ,D9.2,', TST =',D9.2,'.  PARAMETERS ARE:'/(7X,5D13.5))
      ENDIF
C+++++++++++++++++++
      FMIN=F0
  208 CONTINUE
      IF(NSTEP.EQ.NITER) then
        CALL mexprintf('smplx Warning: Max No. Iterations reached')
	  CALL mexprintf(CHAR(10))
        GO TO 601
      endif
      IF(TST.LT.TOL.AND.TLEN.LT.TOL) GO TO 601
      IF(TLEN.LT.5.0D-3*SNORM.AND.NSTART.LT.N) GO TO 501
C
C  ****  FORMING X0 (CENTER OF THE SIMPLEX FACE OPOSITE
C                          TO THE 'MAXIMUM' VERTEX).
C
      DO 302 I=1,N
      X0(I)=0.0D0
      DO 301 K=1,N1
      IF(K.EQ.K1) GO TO 301
      X0(I)=X0(I)+P(I,K)
  301 CONTINUE
      X0(I)=X0(I)*DN
  302 CONTINUE
C
C  ****  DOWNHILL SIMPLEX METHOD.
C
C  ****  REFLECTION.
      NSTEP=NSTEP+1
      DO 401 I=1,N
      X(I)=2.0D0*X0(I)-P(I,K1)
  401 CONTINUE
      FT=FCT(X)
      IF(FT.GE.F2) GO TO 404
C
  402 F(K1)=FT
      DO 403 I=1,N
      P(I,K1)=X(I)
  403 CONTINUE
      IF(FT.LT.F0) GO TO 408
      GO TO 201
C  ****  CONTRACTION.
  404 CONTINUE
      IF(FT.GT.F1) GO TO 406
      F1=FT
      F(K1)=FT
      DO 405 I=1,N
      P(I,K1)=X(I)
  405 CONTINUE
C
  406 CONTINUE
      DO 407 I=1,N
      X(I)=0.5D0*(P(I,K1)+X0(I))
  407 CONTINUE
      FT=FCT(X)
      F0=FT-DABS(FT)
      IF(FT.LT.F1) GO TO 402
      GO TO 410
C  ****  EXPANSION.
  408 F0=FT
      DO 409 I=1,N
      X(I)=2.0D0*X(I)-X0(I)
  409 CONTINUE
      FT=FCT(X)
      IF(FT.GT.F0) GO TO 201
      F0=FT-DABS(FT)
      GO TO 402
C  ****  SHRINKAGE.
  410 CONTINUE
      DO 412 K=1,N1
      IF(K.EQ.K0) GO TO 412
      DO 411 I=1,N
      X(I)=0.5D0*(P(I,K)+P(I,K0))
      P(I,K)=X(I)
  411 CONTINUE
      F(K)=FCT(X)
  412 CONTINUE
      GO TO 201
C
C  ****  RESTART.
C
  501 NSTART=NSTART+1
      SFAC=0.5D0*SFAC
      DO 504 K=1,N1
      IF(K.EQ.K0) GO TO 504
      H=0.0D0
      DO 502 I=1,N
      X0(I)=P(I,K)-P(I,K0)
      H=H+X0(I)**2
  502 CONTINUE
      RANDOM=rng()
      IF(RANDOM.LT.0.5D0) THEN
      ISIGN=-1
      ELSE
      ISIGN=1
      ENDIF
      FAC=SFAC*ISIGN/DSQRT(H)
      DO 503 I=1,N
      X(I)=P(I,K0)+FAC*X0(I)
      P(I,K)=X(I)
  503 CONTINUE
      F(K)=FCT(X)
  504 CONTINUE
      GO TO 201
C
C  ****  OUTPUT.
C
  601 CONTINUE
      DO 602 I=1,N
      X(I)=P(I,K0)
  602 CONTINUE
      RETURN
      END


c* end of file *****************************************************


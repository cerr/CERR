! JC Jun 13 2005
! Adapt the orginal FORTRAN file to be call by MATLAB.
! Replace write(*,*) with "CALL mexprintf('')
! since MATLAB has the control of display


C *** TIME LIBRARY FOR THE GNU f77 COMPILER *******************
C
C Short description:
C   The subroutines included here provide information on the
C   execution time. They are adapted to the GNU specifications for their
C   g77 compiler, although it is possible they also work with other
C   compilers, especially on UNIX systems.
C
C Notes:
C   The following implicits are used in this file:
C   - int time(void)                         --current time in s
C   - (char *) ctime(int)                    --formatted date
C   - real etime(real(2))                    --CPU time
C
C Last revision:
C   29-1-2001
C     - All routines modified with 'implicit none'.
C     - All routines adapted to GNU's intrinsic function
C       specifications. Some routines have become obsolete; now only
C       initim(), endtim(), cputim() and elaps() form the end user interface.
C
C   28/03/1995
C     INITIM & ELAPS have been modified to account for time intervals
C     that span 24 h.
C
C   16/03/1995
C     CPU time routines have been included.
C     - TRESOL has been created.
C     - ENDTIM has been extended: it also writes a CPU time report.
C     - CPUTIM has been created.
C     - SCHRON and CHRONO have been created.
C     - DELTAT has been created.
C     Notice that, in spite of returning real*8 data, time routines
C     yield a resolution that is limited by the machine and OS in
C     which they are running. TRESOL() returns this resolution.
C
C   11/03/1995
C     Created
C
C **************************************************


c **************************************************
      subroutine initim
c  Initializes the real time timer. Writes present date in text format
c  to standard output. Should be called at the beginning of your main
c  program.
      implicit none
      integer*8 start
      common /timer/ start
      character*80 date
      integer*8 time

      CALL mexprintf('initim: Sorry! time functions not available.')
	CALL mexprintf(CHAR(10))

c     *** opt-Time ON: activate lines below and deactivate line above:
c      start = time()
c      date = ctime(start)
c      write(*,1000) date
c1000  format (1x,'Program timer started on ',a80)
c      call mexprintf(' '
      end


c **************************************************
      subroutine endtim
c  Writes ending date on standard output; also real and CPU times.
      implicit none
      character*80 date
      real*8 tarray(2),dummy,etime
      real*8 elaps

      call mexprintf('endtim: Sorry! time functions not available.')
	CALL mexprintf(CHAR(10))

c     *** opt-Time ON: activate lines below and deactivate line above:
c      date = ctime(time())
c      write(*,1000) date
c 1000 format (1x,'program ended on ',a80)
c      dummy = etime(tarray)
c      write(*,1001) elaps()
c 1001 format (1x,'real time:',f12.2,' s')
c      write(*,1002) tarray(1)
c 1002 format (1x,'user time:',f12.2,' s')
c      write(*,1003) tarray(2)
c 1003 format (1x,'syst time:',f12.2,' s')
c      call mexprintf(' '
      end


c **************************************************
      real*8 function cputim()
c  CPU (user) time since program started (in s).
      implicit none
      real*8 tarray(2),dummy,etime

      cputim = 0.0d0

c     *** opt-Time ON: activate lines below and deactivate line above:
c      dummy = etime(tarray)
c      cputim = dble(tarray(1))
      end


c **************************************************
      real*8 function elaps()
c  Gives the real time since initim() was called.
      integer*8 time
      integer*8 start
      common /timer/ start

      elaps = 0.0d0

c     *** opt-Time ON: activate line below and deactivate line above:
c      elaps = dble(time()-start)
      end


c **************************************************
      real*8 function deltat()
c     *** Obsolete ***
c     Returned CPU (user) time elapsed since previous invocation (s).
      implicit none
      call mexprintf('deltat:error: Obsolete.')
	CALL mexprintf(CHAR(10))
      deltat = 0.0d0
      stop
c      real tarray(2),dummy
c      call dtime(tarray,dummy)
c      deltat = dble(tarray(1))
      end


c **************************************************
      subroutine schron
c     *** Obsolete ***
c     Previously reseted the chrono.
      call mexprintf('schron:error: Obsolete.')
	CALL mexprintf(CHAR(10))

      stop
      end


c **************************************************
      real*8 function chrono()
c     *** Obsolete ***
c     Previously, CPU (user) time elapsed since last call to schron (in s).
      chrono = 0.0d0
      call mexprintf('chrono:error: Obsolete.')
	CALL mexprintf(CHAR(10))

      stop
      end


c **** end of file *********************************

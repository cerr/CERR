#
# f90opts.sh	Shell script for configuring MEX-file creation script,
#               mex.  These options were tested with the specified compiler.
#
# usage:        Do not call this file directly; it is sourced by the
#               mex shell script.  Modify only if you don't like the
#               defaults after running mex.  No spaces are allowed
#               around the '=' in the variable assignment.
#
# SELECTION_TAGs occur in template option files and are used by MATLAB
# tools, such as mex and mbuild, to determine the purpose of the contents
# of an option file. These tags are only interpreted when preceded by '#'
# and followed by ':'.
#
#SELECTION_TAG_MEX_OPT: Template Options file for building Fortran 90 MEX-files via the system ANSI compiler
#
# Copyright 1984-2004 The MathWorks, Inc.
# $Revision: 1.4.4.6 $  $Date: 2004/04/25 21:30:51 $
#----------------------------------------------------------------------------
#
    TMW_ROOT="$MATLAB"
    MFLAGS=''
    if [ "$ENTRYPOINT" = "mexLibrary" ]; then
        MLIBS="-L$TMW_ROOT/bin/$Arch -lmx -lmex -lmat -lmwservices -lut"
    else  
        MLIBS="-L$TMW_ROOT/bin/$Arch -lmx -lmex -lmat"
    fi
    case "$Arch" in
        Undetermined)
#----------------------------------------------------------------------------
# Change this line if you need to specify the location of the MATLAB
# root directory.  The script needs to know where to find utility
# routines so that it can determine the architecture; therefore, this
# assignment needs to be done while the architecture is still
# undetermined.
#----------------------------------------------------------------------------
            MATLAB="$MATLAB"
            ;;
        hpux)
#----------------------------------------------------------------------------
#           what `which cc`
#           HP92453-01 B.11.11.06 HP C Compiler
            CC='cc'
            COMPFLAGS='-z +Z +DA2.0 -mt'
            CFLAGS="-Ae $COMPFLAGS -Wp,-H65535"
            CLIBS="$MLIBS -lm -lc"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#
#           what `which aCC`
#           HP aC++ B3910B A.03.37
#           HP aC++ B3910B A.03.30 Language Support Library
            CXX='aCC'
            CXXFLAGS="$MCXXFLAGS -AA -D_HPUX_SOURCE $COMPFLAGS"
            CXXLIBS="$MLIBS -lm -lstd_v2 -lCsup_v2"
            CXXOPTIMFLAGS='-O -DNDEBUG +Oconservative'
            CXXDEBUGFLAGS='-g'
#
#           what `which f90`
#           HP-UX f90 20020606 (083554)  B3907DB/B3909DB B.11.01.60
#           HP F90 v2.6
#            $ PATCH/11.00:PHCO_95167  Oct  1 1998 13:46:32 $
            F90LIBDIR='/opt/fortran90/lib/pa2.0'
            FC='f90'
            FFLAGS='+Z +DA2.0'
            FLIBS="$MLIBS -lm -L$F90LIBDIR -lF90 -lcl -lc -lisamstub"
            FOPTIMFLAGS='-O +Oconservative'
            FDEBUGFLAGS='-g'
#
            if [ "$ffiles" = "1" ]; then
            LD='cc'
            else
            LD="$COMPILER"
            fi
            LDEXTENSION='.mexhpux'
            LDFLAGS="-b -Wl,+e,mexVersion,+e,mexFunction,+e,mexfunction,+e,mexLibrary,+e,_shlInit $COMPFLAGS"
            LDOPTIMFLAGS='-O'
            LDDEBUGFLAGS='-g'
#
            POSTLINK_CMDS=':'
#----------------------------------------------------------------------------
            ;;
        glnx86)
#----------------------------------------------------------------------------
            RPATH="-Wl,-rpath-link,$TMW_ROOT/bin/$Arch"
#           gcc -v
#           gcc version 3.2.3
            CC='gcc'
            CFLAGS='-fPIC -ansi -D_GNU_SOURCE -pthread -fexceptions -m32'
            CLIBS="$RPATH $MLIBS -lm -lstdc++"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#           
#           g++ -v
#           gcc version 3.2.3
            CXX='g++'
            CXXFLAGS='-fPIC -ansi -D_GNU_SOURCE -pthread '
            CXXLIBS="$RPATH $MLIBS -lm"
            CXXOPTIMFLAGS='-O -DNDEBUG'
            CXXDEBUGFLAGS='-g'
#
#For the Linux platform, we are still using the native g77. 
#           g77 -fversion
#           GNU Fortran (GCC 3.2.3) 3.2.3 20030422 (release)
#           NOTE: g77 is not thread safe
            FC='g77'
            FFLAGS='-fPIC -fexceptions'
            FLIBS="$RPATH $MLIBS -lm -lstdc++"
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-g'
#
            LD="$COMPILER"
            LDEXTENSION='.mexglx'
            LDFLAGS="-pthread -shared -m32 -Wl,--version-script,$TMW_ROOT/extern/lib/$Arch/$MAPFILE"
            LDOPTIMFLAGS='-O'
            LDDEBUGFLAGS='-g'
#
            POSTLINK_CMDS=':'
#----------------------------------------------------------------------------
            ;;
        glnxi64)
#----------------------------------------------------------------------------
echo "Error: Did not imbed 'options.sh' code"; exit 1 #imbed options.sh glnxi64 12
#----------------------------------------------------------------------------
            ;;
        glnxa64)
#----------------------------------------------------------------------------
            RPATH="-Wl,-rpath-link,$TMW_ROOT/bin/$Arch"
#           gcc -v
#           gcc version 3.2.3
            CC='gcc'
            CFLAGS='-fPIC -fno-omit-frame-pointer -ansi -D_GNU_SOURCE -pthread -fexceptions'
            CLIBS="$RPATH $MLIBS -lm -lstdc++"
            COPTIMFLAGS='-O -DNDEBUG'
            CDEBUGFLAGS='-g'
#           
#           g++ -v
#           gcc version 3.2.3
            CXX='g++'
            CXXFLAGS='-fPIC -fno-omit-frame-pointer -ansi -D_GNU_SOURCE -pthread '
            CXXLIBS="$RPATH $MLIBS -lm"
            CXXOPTIMFLAGS='-O -DNDEBUG'
            CXXDEBUGFLAGS='-g'
#
#For the Linux platform, we are still using the native g77. 
#           g77 -fversion
#           GNU Fortran (GCC 3.2.3) 3.2.3 20030422 (release)
#           NOTE: g77 is not thread safe
            FC='g77'
            FFLAGS='-fPIC -fno-omit-frame-pointer -fexceptions'
            FLIBS="$RPATH $MLIBS -lm -lstdc++"
            FOPTIMFLAGS='-O'
#            FDEBUGFLAGS='-g'
#
            LD="$COMPILER"
            LDEXTENSION='.mexa64'
            LDFLAGS="-pthread -shared -Wl,--version-script,$TMW_ROOT/extern/lib/$Arch/$MAPFILE"
            LDOPTIMFLAGS='-O3'
            LDDEBUGFLAGS='-g'
#
            
            FC='ifort'
            FFLAGS='-fpp -fPIC -u -g -w95 -warn all'
#            FLIBS='$RPATH $MLIBS -L/opt/intel/fce/9.1.043/lib -lm'
            FLIBS='$RPATH $MLIBS -L/opt/intel/fce/10.1.008/lib -lm'
            FOPTIMFLAGS='-O3'
            FDEBUGFLAGS='-g'

#            LD='icc'
            LDFLAGS='-pthread -shared'
            LDOPTIMFLAGS='$FOPTIMFLAGS'
            LDDEBUGFLAGS='-g'


            POSTLINK_CMDS=':'
#----------------------------------------------------------------------------
            ;;
        sol2)
#----------------------------------------------------------------------------
#           cc -V
#           Sun C 5.5 Patch 112760-06 2004/01/13
            CC='cc'
            CFLAGS='-KPIC -dalign -xlibmieee -D__EXTENSIONS__ -D_POSIX_C_SOURCE=199506L -mt'
            CLIBS="$MLIBS -lm -lc"
            COPTIMFLAGS='-xO3 -xlibmil -DNDEBUG'
            CDEBUGFLAGS='-xs -g'
#           
#           CC -V
#           Sun C++ 5.5 Patch 113817-05 2004/01/13
            CXX='CC -compat=5'
            CCV=`CC -V 2>&1`
            version=`expr "$CCV" : '.*\([0-9][0-9]*\)\.'`
            if [ "$version" = "4" ]; then
                    echo "SC5.0 or later C++ compiler is required"
            fi
            CXXFLAGS='-KPIC -dalign -xlibmieee -D__EXTENSIONS__ -D_POSIX_C_SOURCE=199506L -mt'
            CXXLIBS="$MLIBS -lm -lCstd -lCrun"
            CXXOPTIMFLAGS='-xO3 -xlibmil -DNDEBUG'
            CXXDEBUGFLAGS='-xs -g'
#
#           f90 -V
#           Sun Fortran 95 7.1 Patch 112762-09 2004/01/26
            FC='f90'
            FFLAGS='-KPIC -dalign -mt'
            FLIBS="$MLIBS -lfui -lfsu -lsunmath -lm -lc"
            FOPTIMFLAGS='-O'
            FDEBUGFLAGS='-xs -g'
#
            LD="$COMPILER"
            LDEXTENSION='.mexsol'
            LDFLAGS="-G -mt -M$TMW_ROOT/extern/lib/$Arch/$MAPFILE"
            LDOPTIMFLAGS='-O'
            LDDEBUGFLAGS='-xs -g'
#
            POSTLINK_CMDS=':'
#----------------------------------------------------------------------------
            ;;
        mac)
#----------------------------------------------------------------------------
#           gcc-3.3 -v
#           gcc version 3.3 20030304 (Apple Computer, Inc. build 1435)
            CC='gcc-3.3'
            CFLAGS='-fno-common -no-cpp-precomp -fexceptions'
            CLIBS="$MLIBS -lstdc++"
            COPTIMFLAGS='-O3 -DNDEBUG'
            CDEBUGFLAGS='-g'
#
#           g++-3.3 -v
#           gcc version 3.3 20030304 (Apple Computer, Inc. build 1435)
            CXX=g++-3.3
            CXXFLAGS='-fno-common -no-cpp-precomp -fexceptions'
            CXXLIBS="$MLIBS -lstdc++"
            CXXOPTIMFLAGS='-O3 -DNDEBUG'
            CXXDEBUGFLAGS='-g'
#
#           f90 -V
#           Absoft Pro FORTRAN Version 8.2a
            FC='f90'
            FFLAGS='-YEXT_NAMES=LCS -YEXT_SFX=_ -N11 -s -Q51'
            ABSOFTLIBDIR=`which $FC | sed -n -e '1s|bin/'$FC'|lib|p'`
            FLIBS="-L$ABSOFTLIBDIR -lfio -lf77math"
            FOPTIMFLAGS='-O -cpu:g4'
            FDEBUGFLAGS='-g'
#
            LD="$CC"
            LDEXTENSION='.mexmac'
            LDFLAGS="-bundle -Wl,-flat_namespace -undefined suppress -Wl,-exported_symbols_list,$TMW_ROOT/extern/lib/$Arch/$MAPFILE"
            LDOPTIMFLAGS='-O'
            LDDEBUGFLAGS='-g'
#
            POSTLINK_CMDS=':'
#----------------------------------------------------------------------------
            ;;
    esac
#############################################################################
#
# Architecture independent lines:
#
#     Set and uncomment any lines which will apply to all architectures.
#
#----------------------------------------------------------------------------
#           CC="$CC"
#           CFLAGS="$CFLAGS"
#           COPTIMFLAGS="$COPTIMFLAGS"
#           CDEBUGFLAGS="$CDEBUGFLAGS"
#           CLIBS="$CLIBS"
#
#           FC="$FC"
#           FFLAGS="$FFLAGS"
#           FOPTIMFLAGS="$FOPTIMFLAGS"
#           FDEBUGFLAGS="$FDEBUGFLAGS"
#           FLIBS="$FLIBS"
#
#           LD="$LD"
#           LDFLAGS="$LDFLAGS"
#           LDOPTIMFLAGS="$LDOPTIMFLAGS"
#           LDDEBUGFLAGS="$LDDEBUGFLAGS"
#----------------------------------------------------------------------------
#############################################################################



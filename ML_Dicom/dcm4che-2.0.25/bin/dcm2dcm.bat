@echo off
rem -------------------------------------------------------------------------
rem dcm4che2/dcm2dcm  Launcher
rem -------------------------------------------------------------------------

rem $Id: dcm2dcm.bat 5252 2007-10-04 21:32:38Z gunterze $

rem Need jai-imageio-1.1 or jai-imageio-1.2 installed!! 
rem (download from https://jai-imageio.dev.java.net/binary-builds.html)

rem For jai-imageio-1.1 CLASSPATH Installation, set
rem set JIIO_LIB=C:\Program Files\Sun Microsystems\JAI Image IO Tools 1.1\lib
rem set PATH=%JIIO_LIB%;%PATH%

rem For jai-imageio-1.2 CLASSPATH Installation, set
rem set JIIO_LIB=%INSTALLDIR%\lib\ext
rem set PATH=%INSTALLDIR%\bin;$PATH

if not "%ECHO%" == ""  echo %ECHO%
if "%OS%" == "Windows_NT"  setlocal

set MAIN_CLASS=org.dcm4che2.tool.dcm2dcm.Dcm2Dcm
set MAIN_JAR=dcm4che-tool-dcm2dcm-2.0.25.jar

set DIRNAME=.\
if "%OS%" == "Windows_NT" set DIRNAME=%~dp0%

rem Read all command line arguments

set ARGS=
:loop
if [%1] == [] goto end
        set ARGS=%ARGS% %1
        shift
        goto loop
:end

if not "%DCM4CHE_HOME%" == "" goto HAVE_DCM4CHE_HOME

set DCM4CHE_HOME=%DIRNAME%..

:HAVE_DCM4CHE_HOME

if not "%JAVA_HOME%" == "" goto HAVE_JAVA_HOME

set JAVA=java

goto SKIP_SET_JAVA_HOME

:HAVE_JAVA_HOME

set JAVA=%JAVA_HOME%\bin\java

:SKIP_SET_JAVA_HOME

set CP=%DCM4CHE_HOME%\etc\
set CP=%CP%;%DCM4CHE_HOME%\lib\%MAIN_JAR%
set CP=%CP%;%DCM4CHE_HOME%\lib\dcm4che-core-2.0.25.jar
set CP=%CP%;%DCM4CHE_HOME%\lib\dcm4che-image-2.0.25.jar
set CP=%CP%;%DCM4CHE_HOME%\lib\dcm4che-imageio-2.0.25.jar
set CP=%CP%;%DCM4CHE_HOME%\lib\dcm4che-imageio-rle-2.0.25.jar
set CP=%CP%;%DCM4CHE_HOME%\lib\slf4j-log4j12-1.6.1.jar
set CP=%CP%;%DCM4CHE_HOME%\lib\slf4j-api-1.6.1.jar
set CP=%CP%;%DCM4CHE_HOME%\lib\log4j-1.2.16.jar
set CP=%CP%;%DCM4CHE_HOME%\lib\commons-cli-1.2.jar

if "%JIIO_LIB%" == "" goto :SKIP_SET_JIIO_CLASSPATH

set CP=%JIIO_LIB%\jai_imageio.jar;%JIIO_LIB%\clibwrapper_jiio.jar;%CP%

:SKIP_SET_JIIO_CLASSPATH

"%JAVA%" %JAVA_OPTS% -cp "%CP%" %MAIN_CLASS% %ARGS%

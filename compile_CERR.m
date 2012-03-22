function compile_CERR(CERR_CompilePath)
%function compile_CERR()
%Call this function to compile CERR

%compile_CERR('C:\Projects\CERR_compile\CERR3pt3PreRelease1\')

tic
% Name the directory where executable should be stored
% compileDirName = 'compiledCERR';
% compileAbsPath = [CERR_CompilePath,compileDirName];
compileAbsPath = CERR_CompilePath;
mkdir(compileAbsPath)
strToAppend = appendMfile(CERR_CompilePath);
% copyBinaries(getCERR_CompilePath,compileAbsPath);
strToEval = ['mcc -m CERR.m ',strToAppend];
cd(compileAbsPath)
eval(strToEval)
delete('*.h')
delete('*.c')
toc
return;

% -------- supporting functions
function copyBinaries(directory,compileDir)
%function copyBinaries(directory)
%This function copies all the binary files in the passed directory to the
%compiledDir
%Example:
%str = appendMfile(getCERRPath,compilePath);
%
%APA 9/23/2006

allDirS = dir(directory);
str = '';
for dirNum = 1:length(allDirS)
    if ~allDirS(dirNum).isdir & ~strcmp(allDirS(dirNum).name(end-1:end),'.m') & ~strcmp(allDirS(dirNum).name(end-1:end),'.asv')
        success = copyfile(fullfile(directory,allDirS(dirNum).name),[compileDir,'\',allDirS(dirNum).name],'f');
        if success
            continue
        end
    elseif ~strcmp(allDirS(dirNum).name,'.') & ~strcmp(allDirS(dirNum).name,'..')
        copyBinaries([directory,'\',allDirS(dirNum).name],compileDir)
    end
end

return;

function str = appendMfile(directory)
%function str = appendMfile(directory)
%This function obtains all the .m files in the passed directory and returns
%them for compilation in the format -a supportFun1 -a supportFun2 ....
%Example:
%str = appendMfile(getCERRPath);
%returns all the .m files on CERR path for compilation
%Note: CERR.m and CERROptions.m are not appended.
%
%APA 9/23/2006

allDirS = dir(directory);
str = '';
for dirNum = 1:length(allDirS)
    if ~allDirS(dirNum).isdir & strcmp(allDirS(dirNum).name(end-1:end),'.m') & ~strcmpi(allDirS(dirNum).name,'CERR.m') & ~strcmpi(allDirS(dirNum).name,'CERROptions.m') & ~strcmpi(allDirS(dirNum).name,'compile_CERR.m')
        str = [str,' -a ',allDirS(dirNum).name];
    elseif ~strcmp(allDirS(dirNum).name,'private') && ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..')
        str = [str appendMfile([directory,'\',allDirS(dirNum).name])];
    end
end

return;

function pathStr = getCERR_CompilePath()
%function pathStr = getCERR_CompilePath()
%This function returns path to compile directory 

pathStr = [fileparts(which('CERR.m')),'\'];


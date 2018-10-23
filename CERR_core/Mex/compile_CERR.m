function compile_CERR(CERR_path, compiled_path)
%function compile_CERR(CERR_path, compiled_path)
%
% Call this function to compile CERR.
% --> CERR_path is the absolute path where CERR_core, CERR_Data_Extraction,
% IMRTP, ML_Dicom and compile_CERR.m files reside.
% --> compiled_path is the absolute location where you want to save the
% compiled CERR.
%
% Usage:
% compile_CERR('G:\Projects\CERR_compile\CERR_git\CERR','C:\Projects\compiled_cerr_win7_64bit_Sep_01_2015')
%
% APA, 03/22/2012

tic
current_path = cd;
% Name the directory where executable should be stored
% compileDirName = 'compiledCERR';
% compileAbsPath = [CERR_CompilePath,compileDirName];
compileAbsPath = compiled_path;
mkdir(compileAbsPath)
strToAppend = appendMfile(CERR_path);
copyAdditionalFiles(CERR_path,compiled_path);
strToEval = ['mcc -m CERR.m ',strToAppend];
cd(compileAbsPath)
cd(compiled_path)
eval(strToEval)
delete('*.h')
delete('*.c')
cd(current_path)
toc
return;

% -------- supporting functions

function copyAdditionalFiles(CERR_path,compiled_path)
% function copyAdditionalFiles(CERR_path,compiled_path)
%
% This function creates bin, doc, pics directories and copies files to
% them.
%
% APA, 03/26/2012

% Create bin, doc and pics directories
mkdir(fullfile(compiled_path,'bin'));
mkdir(fullfile(compiled_path,'doc'));
mkdir(fullfile(compiled_path,'pics'));
copyfile(fullfile(CERR_path,'CERR_core','CERROptions.m'),compiled_path);
copyfile(fullfile(CERR_path,'CERR_core','CERROptions.json'),compiled_path);

% Fill-in the bin directory
destin = fullfile(compiled_path,'bin');
mkdir(fullfile(destin,'Compression'));
mkdir(fullfile(destin,'Importing'));
mkdir(fullfile(destin,'IMRTP'));
mkdir(fullfile(destin,'mat_files'));
mkdir(fullfile(destin,'MeshInterp'));
copyfile(fullfile(CERR_path,'ML_Dicom','dcm4che-2.0.27'),fullfile(destin,'dcm4che-2.0.27'));
copyfile(fullfile(CERR_path,'CERR_core','Mex'),fullfile(destin,'Mex'));

destin_compression = fullfile(compiled_path,'bin','Compression');
copyfile(fullfile(CERR_path,'CERR_core','Compression','7z.dll'),destin_compression);
copyfile(fullfile(CERR_path,'CERR_core','Compression','7z.exe'),destin_compression);
copyfile(fullfile(CERR_path,'CERR_core','Compression','7z.sfx'),destin_compression);
copyfile(fullfile(CERR_path,'CERR_core','Compression','7z_License.txt'),destin_compression);
copyfile(fullfile(CERR_path,'CERR_core','Compression','tar.exe'),destin_compression);

destin_importing = fullfile(compiled_path,'bin','Importing');
copyfile(fullfile(CERR_path,'CERR_core','Importing','readASCIIDose.exe'),destin_importing);
copyfile(fullfile(CERR_path,'CERR_core','Importing','ES - IPT4.1CompatibleDictionary.mat'),destin_importing);

destin_IMRTP = fullfile(compiled_path,'bin','IMRTP');
copyfile(fullfile(CERR_path,'IMRTP','QIBData'),fullfile(destin_IMRTP,'QIBData'),'f');
copyfile(fullfile(CERR_path,'IMRTP','vmc++'),fullfile(destin_IMRTP,'vmc++'),'f');

copyfile(fullfile(CERR_path,'CERR_core','Icons','copperColorMap.mat'),fullfile(compiled_path,'bin','mat_files'));

destin_MeshInterp = fullfile(compiled_path,'bin','MeshInterp');
copyfile(fullfile(CERR_path,'CERR_core','MeshBasedInterp','libMeshContour.dll'),destin_MeshInterp);
copyfile(fullfile(CERR_path,'CERR_core','MeshBasedInterp','MeshContour.h'),destin_MeshInterp);
copyfile(fullfile(CERR_path,'CERR_core','MeshBasedInterp','pretriang_4.txt'),destin_MeshInterp);
copyfile(fullfile(CERR_path,'CERR_core','MeshBasedInterp','pretriang_5.txt'),destin_MeshInterp);
copyfile(fullfile(CERR_path,'CERR_core','MeshBasedInterp','pretriang_6.txt'),destin_MeshInterp);

% Fill-in the pics directory
destin = fullfile(compiled_path,'pics');
copyfile(fullfile(CERR_path,'CERR_core','Icons'),fullfile(destin,'Icons'));
copyfile(fullfile(CERR_path,'CERR_core','CERR.png'),destin);
copyfile(fullfile(CERR_path,'CERR_core','Contouring','structureFusionBackground.png'),destin);


% Fill-in the docs directory
destin = fullfile(compiled_path,'doc');
mkdir(fullfile(destin,'html'));
copyfile(fullfile(CERR_path,'CERR_core','CommandLine','CERRCommandLinehelp.html'),fullfile(destin,'html'));

return;

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
    if ~allDirS(dirNum).isdir && ~strcmp(allDirS(dirNum).name(end-1:end),'.m') && ~strcmp(allDirS(dirNum).name(end-1:end),'.asv')
        success = copyfile(fullfile(directory,allDirS(dirNum).name),fullfile(compileDir,allDirS(dirNum).name),'f');
        if success
            continue
        end
    elseif ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..')
        % copyBinaries([directory,'\',allDirS(dirNum).name],compileDir)
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
    if ~allDirS(dirNum).isdir && strcmp(allDirS(dirNum).name(end-1:end),'.m') && ...
            ~strcmpi(allDirS(dirNum).name,'CERR.m') && ...
            ~strcmpi(allDirS(dirNum).name,'CERROptions.m') && ...
            ~strcmpi(allDirS(dirNum).name,'compile_CERR.m') && ...
            ~strcmpi(allDirS(dirNum).name,'CERRViewer.m')
        str = [str,' -a ',allDirS(dirNum).name];
    elseif ~strcmp(allDirS(dirNum).name,'private') && ~strcmp(allDirS(dirNum).name,'.') && ~strcmp(allDirS(dirNum).name,'..') && isempty(strfind(allDirS(dirNum).name,'+'))
        str = [str appendMfile(fullfile(directory,allDirS(dirNum).name))];
    end
end

return;


return;

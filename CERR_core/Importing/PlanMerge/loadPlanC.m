function [planC] = loadPlanC(filename,tmpExtractDir)
%"loadPlanC"
%   Load and return a planC given a fullpath filename.  The filename can
%   be a .mat or .mat.bz2 file.  Bz2 files are extracted to a temporary .mat
%   file, loaded, and then the temporary .mat file is deleted.
%
%JRA 3/2/05
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial,
% non-treatment-decision applications, and further only if this header is
% not removed from any file. No warranty is expressed or implied for any
% use whatever: use at your own risk.  Users can request use of CERR for
% institutional review board-approved protocols.  Commercial users can
% request a license.  Contact Joe Deasy for more information
% (radonc.wustl.edu@jdeasy, reversed).
%
%Usage:
%   [planC, planInfo] = loadPlanC(filename);

%Check that file exists.
if ~(exist(filename, 'file') == 2)
    error('Filename passed to loadPlanC does not exist.')
end

%Check for .bz2 compression and extract .mat file.
[pathstr, name, ext] = fileparts(filename);

%untar if it is a .tar file
tarFile = 0;
if strcmpi(ext, '.tar')
    if ispc
        untar(file,tmpExtractDir)
        fileToUnzip = fullfile(tmpExtractDir, name);
    else
        untar(file,pathstr)
        fileToUnzip = fullfile(pathstr, name);
    end    
    file = fileToUnzip;
    [pathstr, name, ext] = fileparts(fullfile(pathstr, name));
    tarFile = 1;
end

if strcmpi(ext, '.bz2') && length(name)>3 && strcmpi(name(end-3:end),'.mat')
    CERRStatusString(['Decompressing ' name ext '...']);
    bzFile      = 1;
    outstr      = gnuCERRCompression([fullfile(pathstr, name),ext], 'uncompress', tmpExtractDir);
    if ispc
        loadfile    = fullfile(tmpExtractDir, name);
    else
        loadfile    = fullfile(pathstr, name);
    end
    [pathstr, name, ext] = fileparts([fullfile(pathstr, name),ext]);
elseif strcmpi(ext, '.zip') && length(name)>3 && strcmpi(name(end-3:end),'.mat')
    bzFile      = 1;    
    if ispc
        unzip(filename,tmpExtractDir)
        loadfile    = fullfile(tmpExtractDir, name);
    else
        unzip(filename,pathstr)
        loadfile    = fullfile(pathstr, name);
    end    
    [pathstr, name, ext] = fileparts(fullfile(pathstr, name));
else
    bzFile      = 0;
    loadfile    = filename;
end

%Attempt to load the .mat file.
CERRStatusString(['Loading ' name ext '...']);
try
    planC = load(loadfile);
    planC = planC.planC;
end


%Remove unzipped file after loading.
if bzFile
    delete(loadfile);
end
if tarFile
    delete(fileToUnzip);
end

if ~exist('planC');
    error('.mat, .mat.bz2 or .mat.zip file does not contain a planC variable.');
    return;
end

CERRStatusString(['Loaded ' name ext '...']);

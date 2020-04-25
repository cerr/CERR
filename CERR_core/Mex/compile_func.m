function compile_func(func, CERR_path, compile_path, optC)
%function compile_func(func, CERR_path, compile_path, optC)
%
% Call this function to compile a CERR function.
% INPUTS:
% func: name of the .m file to compile (directory path should not be passed
% since it is obtained from the passed CERR_path)
% CERR_path: Path to CERR. i.e. absolute path where CERR_core, CERR_Data_Extraction,
% IMRTP, ML_Dicom and other directories reside.
% compiled_path: absolute directory location where you want to save the
% compiled function.
% optC: Options. Currently not supported.
%
% Usage:
% compile_CERR('G:\Projects\CERR_compile\CERR_git\CERR','C:\Projects\compiled_cerr_win7_64bit_Sep_01_2015')
%
% APA, 04/25/2020

addpath(genpath(CERR_path))
[~,~,ext] = fileparts(func);
if isempty(ext)
    func = [func,'.m'];
end
if exist(func,'file')==2 % valid .m file
    strToEval = ['mcc -m ',func,' ',compile_path];
    eval(strToEval)
end

% Update options file
%optFileName = fullfile(getCERRPath,'CERROptions.json');


function compile_func(func, compile_path, optC)
%function compile_func(func, compile_path, optC)
%
% This function compiles the passed CERR function func.
% It assumes CERR is already added to Matlab path.
% For example, addpath(genpath(CERR_path)) adds CERR to Matlab path.
%
% INPUTS:
% func: name of the .m file to compile (directory path should not be passed
% since it is obtained from CERR_path on Matlab path)
% compile_path: absolute directory location where you want to save the
% compiled function.
% optC: Options. Currently not supported.
%
% Usage:
% CERR_path = 'C:\path\to\CERR';
% addpath(genpath(CERR_path))
% compile_func('runSegClinic.m','C:\path\to\compiledRunSegClinic')
%
% APA, 04/25/2020

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


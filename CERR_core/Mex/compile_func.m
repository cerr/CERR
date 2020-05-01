function compile_func(func, compile_path, addFuncC, optC)
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
% addFuncC : Names of additional files to compile (not dependencies of 'func').
% optC: Options. Currently not supported.
%
% Usage example:
% CERR_path = 'C:\path\to\CERR';
% addpath(genpath(CERR_path))
%
% dirS = dir(fullfile(getCERRPath,'Contouring/customProcessing/*.m'));
% addFuncC = {dirS.name};
% 
% compile_func('runSegClinic.m','C:\path\to\compiledRunSegClinic',addFuncC)
%
% APA, 04/25/2020

[~,~,ext] = fileparts(func);
if isempty(ext)
    func = [func,'.m'];
end

if ~exist('addFuncC','var')
    addFuncC = {};
end

if exist(func,'file')==2 % valid .m file
    strToAppend = [];
    for n = 1:length(addFuncC)
        strToAppend = [strToAppend,' -a ',addFuncC{n}];
    end
    strToEval = ['mcc -m ',func,' -d ',compile_path, strToAppend];
    eval(strToEval)
    % Copy dependencies
    copyDependenciesForCERRCompile(compile_path)    
end

% Update options file
%optFileName = fullfile(getCERRPath,'CERROptions.json');


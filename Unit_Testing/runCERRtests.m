% runCERRtests.m
%
% Script to invoke unit testing for CERR. Output is written to
% UnitTestResult.txt file
%
% APA, 06/07/2013

% Generate path for storing the logFile
CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));

% Log file Name
logFileName = fullfile(topLevelCERRDir,'Unit_Testing',['UnitTestResult_',datestr(now,30),'.txt']);

% Tests dir
testsDir = fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr');

% Run tests
runtests(testsDir, '-verbose', '-logfile', logFileName)

disp(['--------- Tests Finished. Output written to ', logFileName, ' ---------'])

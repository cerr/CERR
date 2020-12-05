function out = runtests_xunit(varargin)
%runtests_xunit Run unit tests
%   runtests_xunit runs all the test cases that can be found in the current directory
%   and summarizes the results in the Command Window.
%
%   Test cases can be found in the following places in the current directory:
%
%       * An M-file function whose name starts or ends with "test" or
%         "Test" and that returns no output arguments.
%
%       * An M-file function whose name starts or ends with "test" or
%         "Test" and that contains subfunction tests and uses the
%         initTestSuite script to return a TestSuite object.
%
%       * An M-file defining a subclass of TestCase.
%
%   runtests_xunit(dirname) runs all the test cases found in the specified directory.
%
%   runtests_xunit(packagename) runs all the test cases found in the specified
%   package. (This option requires R2009a or later).
%
%   runtests_xunit(mfilename) runs test cases found in the specified function or class
%   name. The function or class needs to be in the current directory or on the
%   MATLAB path.
%
%   runtests_xunit('mfilename:testname') runs the specific test case named 'testname'
%   found in the function or class 'name'.
%
%   Multiple directories or file names can be specified by passing multiple
%   names to runtests_xunit, as in runtests_xunit(name1, name2, ...) or
%   runtests_xunit({name1, name2, ...}, ...)
%
%   runtests_xunit(..., '-verbose') displays the name and result, result, and time
%   taken for each test case to the Command Window.
%
%   runtests_xunit(..., '-logfile', filename) directs the output of runtests_xunit to
%   the specified log file instead of to the Command Window.
%
%   out = runtests_xunit(...) returns a logical value that is true if all the
%   tests passed.
%
%   Examples
%   --------
%   Find and run all the test cases in the current directory.
%
%       runtests_xunit
%
%   Find and run all the test cases in the current directory. Display more
%   detailed information to the Command Window as the test cases are run.
%
%       runtests_xunit -verbose
%
%   Save verbose runtests_xunit output to a log file.
%
%       runtests_xunit -verbose -logfile my_test_log.txt
%
%   Find and run all the test cases contained in the M-file myfunc.
%
%       runtests_xunit myfunc
%
%   Find and run all the test cases contained in the TestCase subclass
%   MyTestCase.
%
%       runtests_xunit MyTestCase
%
%   Run the test case named 'testFeature' contained in the M-file myfunc.
%
%       runtests_xunit myfunc:testFeature
%
%   Run all the tests in a specific directory.
%
%       runtests_xunit c:\Work\MyProject\tests
%
%   Run all the tests in two directories.
%
%       runtests_xunit c:\Work\MyProject\tests c:\Work\Book\tests

%   Steven L. Eddins
%   Copyright 2009-2010 The MathWorks, Inc.

verbose = false;
logfile = '';
if nargin < 1
    suite = TestSuite.fromPwd();
else
    [name_list, verbose, logfile] = getInputNames(varargin{:});
    if numel(name_list) == 0
        suite = TestSuite.fromPwd();
    elseif numel(name_list) == 1
        suite = TestSuite.fromName(name_list{1});
    else
        suite = TestSuite();
        for k = 1:numel(name_list)
            suite.add(TestSuite.fromName(name_list{k}));
        end
    end
end

if isempty(suite.TestComponents)
    error('xunit:runtests_xunit:noTestCasesFound', 'No test cases found.');
end

if isempty(logfile)
    logfile_handle = 1; % File handle corresponding to Command Window
else
    logfile_handle = fopen(logfile, 'w');
    if logfile_handle < 0
        error('xunit:runtests_xunit:FileOpenFailed', ...
            'Could not open "%s" for writing.', logfile);
    else
        cleanup = onCleanup(@() fclose(logfile_handle));
    end
end

fprintf(logfile_handle, 'Test suite: %s\n', suite.Name);
if ~strcmp(suite.Name, suite.Location)
    fprintf(logfile_handle, 'Test suite location: %s\n', suite.Location);
end
fprintf(logfile_handle, '%s\n\n', datestr(now));

if verbose
    monitor = VerboseTestRunDisplay(logfile_handle);
else
    monitor = TestRunDisplay(logfile_handle);
end
did_pass = suite.run(monitor);

if nargout > 0
    out = did_pass;
end

function [name_list, verbose, logfile] = getInputNames(varargin)
name_list = {};
verbose = false;
logfile = '';
k = 1;
while k <= numel(varargin)
    arg = varargin{k};
    if iscell(arg)
        name_list = [name_list; arg];
    elseif ~isempty(arg) && (arg(1) == '-')
        if strcmp(arg, '-verbose')
            verbose = true;
        elseif strcmp(arg, '-logfile')
            if k == numel(varargin)
                error('xunit:runtests_xunit:MissingLogfile', ...
                    'The option -logfile must be followed by a filename.');
            else
                logfile = varargin{k+1};
                k = k + 1;
            end
        else
            warning('runtests_xunit:unrecognizedOption', 'Unrecognized option: %s', arg);
        end
    else
        name_list{end+1} = arg;
    end
    k = k + 1;
end
    

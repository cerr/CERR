function ok = checkattributes(a, classes, attributes)
%CHECKATTRIBUTES is like VALIDATEATTRIBUTES but returns true or false
%   OK = CHECKATTRIBUTES(A,CLASSES,ATTRIBUTES) takes the same arguments as
%   VALIDATEATTRIBUTES, excluding the three optional arguments. However
%   CHECKATTRIBUTES returns true or false when VALIDATEATTRIBUTES would
%   return or throw an exception respectively.
%
%   See also VALIDATEATTRIBUTES.

try
    validateattributes(a, classes, attributes, 'checkattributes');
    ok = true;
catch ME
    if ~isempty(strfind(ME.identifier, ':checkattributes:'))
        ok = false;  % first argument failed the specified tests
    else
        rethrow(ME); % there was some other error
    end
end
end
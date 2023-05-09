function p = blockpanel(varargin)
%-*- texinfo -*-
%@deftypefn {Function} blockpanel
%@verbatim
%BLOCKPANEL Control panel
%   Usage: blockpanel(params)
%
%   Input parameters:
%      params: Cell-array of parameters specifications.
%
%   Output parameters:
%      p : Control panel Java object
%
%   BLOCKPANEL(params) creates a Java object containing GUI for changing
%   parameters during the playback. params should be a cell-array, whose 
%   elements are another cell array of the following format:
%
%      {'var','label',minVal,maxVal,defVal,valCount}
%
%   Example:
%
%   params = {
%               {'G','Gain',-20,20,0,21}
%            }
% 
%   The function takes in the additional optional arguments:
%
%       'location',location:   Window initial position. location
%                                has to be 2 element row vector [x,y]
%                                defining distance from the top-left
%                                corner of the screen. 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/blockpanel.html}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

definput.keyvals.location = [50,50];
definput.keyvals.params = {};
[~,kv,params]=ltfatarghelper({'params'},definput,varargin);

if ~isvector(kv.location) || any(size(kv.location)~=[1,2]) ||...
    any(kv.location<0) || ~isreal(kv.location)
   error(['%s: Location has to be a 2 element row vector of ',...
         ' positive numbers.'],upper(mfilename));  
end

if ~iscell(params)
    error('%s: Input should be a nonempty cell array.',upper(mfilename));
end

if ~isempty(params) && ~iscell(params{1})
    params = {params};
end

complainif_isjavaheadless('BLOCKPANEL');

try
  p = javaObject('net.sourceforge.ltfat.ContFrame');
catch% err
   error(['%s: Could not load net.sourceforge.ltfat.ContFrame. It is not ',...
          'compiled or it is not in Matlab classpath. In the latter case, ',...
          'ltfatstart should do the trick.'],upper(mfilename));
end


% Using Java LinkedList class for passing the cell-array
% (since there is no way how to pass the cell-array directly)
paramList = javaObject('java.util.LinkedList');
    

for ii = 1:numel(params)
   param = params{ii};
   if numel(param)<6
      error('%s: Parameter %i is not in format {''var'',''label'',minVal,maxVal,defVal,valCount}.',upper(mfilename),ii);
   end
   if param{3}>=param{4}
      error('%s: In parameter %i: minVal cannot be greater or equal to maxVal.',upper(mfilename),ii);
   end
   
   if param{5}<param{3} || param{5}>param{4}
      error('%s: In parameter %i: defVal is not in range minVal-maxVal.',upper(mfilename),ii);
   end
   
   if param{6}<=1
      error('%s: In parameter %i: valCount has to be >=2.',upper(mfilename),ii);
   end
   
   % Each element of the linked list paramList is again a linked list
   paramListEl = javaObject('java.util.LinkedList');
   for jj=1:numel(param)
        javaMethod('add',paramListEl,param{jj});
   end
   javaMethod('add',paramList,paramListEl);
    
   
end

% Pass the data
javaMethod('addControlElements',p,paramList);

javaMethod('setLocation',p,kv.location(1),kv.location(2));
 
% Give the object time to initialize properly.
pause(0.1);
 


function [par,varargout] = blockpanelget(p,varargin)
%-*- texinfo -*-
%@deftypefn {Function} blockpanelget
%@verbatim
%BLOCKPANELGET Get parameters from GUI
%   Usage: [par,...] = blockpanelget(p,spar,...)
%
%   Input parameters:
%         p    : JAVA object
%         spar : String. Name of the parameter.
%
%   Output parameters:
%         par  : Single value or vector of parameters.
%
%   par = BLOCKPANELGET(p,'spar') gets a current value of the parameter
%   'spar' from the GUI specified in p. 
%   par = BLOCKPANELGET(p,'spar1','spar2','spar3') gets current values
%   of the parameters 'spar1', 'spar2' and 'spar3' from the GUI and
%   stores them in a vector p.
%   [par1,par2,par3] = BLOCKPANELGET(p,'spar1','spar2','spar3') gets 
%   current values of the parameters 'spar1', 'spar2' and 'spar3' 
%   from the GUI and stores them in the separate variables par1,par2
%   and par3. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/blockpanelget.html}
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

nout = nargout();

complainif_notenoughargs(nargin,1,'BLOCKPANELGET');


if nout~=1 && nargin==1
   error(['%s: Ambiguous output. When no parameter is explicitly defined,',...
    ' the function cannot return more tha one output parameter.'],mfilename);
end


if nargin>1 
   if nout~=1 && nout ~= numel(varargin)
      error('%s: Number of inputs does not match with number of outputs.',upper(mfilename));
   end

   res = javaMethod('getParams',p,varargin);

   if nout == 1
      if numel(res)==1
         par = res(1);
      else
         par = res;
      end
   else
      par = res(1);
      varargout = num2cell(res(2:end));
   end
else
   par = javaMethod('getParams',p);
   if isoctave
      parTmp = par; 
      par = zeros(numel(parTmp),1);
      for ii=1:numel(parTmp)
          par(ii) = parTmp(ii);
      end
   end
end
   



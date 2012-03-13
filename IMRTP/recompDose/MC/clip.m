function vec_outV = clip(vec_inV,low_limitC,high_limitC,valC);
%"clip"
%   Clips the values to lie between the limits high_limitC and
%   low_limitC.  The clipped values are set equal to valC.
%   If vec_inV is a vector, if valC is set to 'delete',
%   which results in truncation.  If valC is the string 'limits'
%   then the vec is clipped at the limits.
%
%   JOD, inspired by Num Python specs , 
%   LM: 17 Jan 03, to improve speed.
%       11 June 03, JOD, improved speed of limits case.
%       23 Dec 04, JRA, Now replacement value can be explicitly defined.
%
%Usage:
%   vec_outV = clip(vec_inV,low_limitC,high_limitC,valC);
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

if ~ischar(valC)
  I=find([vec_inV<low_limitC]|[vec_inV>high_limitC]);
  vec_outV=vec_inV;
  vec_outV(I)=valC;
elseif valC=='delete'
  SV=size(vec_inV);
  if SV~=1
    error('Replacement with [] only works with vectors')
  end
  I=find([vec_inV<low_limitC]+[vec_inV>high_limitC]);
  vec_outV=vec_inV;
  vec_outV(I)=[];
elseif valC=='limits'
  vec_outV = vec_inV;
  vec_outV([vec_inV<low_limitC]) = low_limitC;
  vec_outV([vec_inV>high_limitC]) = high_limitC;
elseif isnumeric(valC);
  vec_outV = vec_inV;
  vec_outV([vec_inV<low_limitC]) = valC;
  vec_outV([vec_inV>high_limitC]) = valC;        
else
  error('valC is incorrectly set.')
end

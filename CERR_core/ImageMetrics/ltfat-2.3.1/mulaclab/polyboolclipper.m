function [pc, hc] = polyboolclipper(pa, pb, op, ha, hb, ug);
%-*- texinfo -*-
%@deftypefn {Function} polyboolclipper
%@verbatim
%function [pc, hc] = polyboolclipper(pa, pb, op, ha, hb, ug);
%
% polyboolclipper : a function to perform boolean set operations on 
%            planar polygons
% 
% INPUT:
% pa : EITHER a nx2 matrix of vertices describing a polygon 
%      OR a cell array with polygons, each of which is a nx2 matrix
%      of vertices (one vertex per row)
% pb : EITHER a nx2 matrix of vertices describing a polygon 
%      OR a cell array with polygons, each of which is a nx2 matrix
%      of vertices (one vertex per row)
% ha : (Optional) logical array with hole flags for polygons in
%      pa. If ha(k) > 0, pa{k} is an interior boundary of a polygon 
%      with at least one hole.
% hb : (Optional) logical array with hole flags for polygons in pb.
% op : type of algebraic operation:
%       'notb' : difference - points in polygon pa and not in polygon pb
%       'and'  : intersection - points in polygon pa and in polygon pb
%       'xor'  : exclusive or - points either in polygon pa or in polygon pb
%       'or'   : union - points in polygons pa or pb
% ug : (Optional) conversion factor from user coordinates to
%      integer grid coordinates. Default is 10^6.
% pc : cell array with the result(s) of the boolean set operation
%      of polygons pa and pb (can be more than one polygon)
% hc : logical array with hole flags for each of the output
%      polygons. If hc(k) > 0, pc{k} is an interior boundary of a 
%      polygon with at least one hole.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/mulaclab/polyboolclipper.html}
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

% DISCLAIMER
% This software was developed at the National Institute of Standards and
% Technology by employees of the United States Federal Government in the
% course of their official duties. Pursuant to title 17 Section 105 of
% the United States Code this software is not subject to copyright
% protection and is in the public domain. This software is an
% experimental system. NIST assumes no responsibility whatsoever for its
% use by other parties, and makes no guarantees, expressed or implied,
% about its quality, reliability, or any other characteristic.
% 
% Ulf Griesmann, June 2013
% ulf.griesmann@nist.gov, ulfgri@gmail.com

% This function is based on the Clipper Library for C++ by Angus Johnson 
% http://www.angusj.com/delphi/clipper.php
% The Clipper software is free software under the Boost software license.

% Ulf Griesmann, NIST, August 2014

   % check arguments
   if nargin < 3
      error('polyboolclipper :  expecting at least 3 arguments.');
   end
   if nargin < 4, ha = []; end
   if nargin < 5, hb = []; end
   if nargin < 6, ug = []; end

   if isempty(ha), ha = logical(zeros(1,length(pa))); end
   if isempty(hb), hb = logical(zeros(1,length(pb))); end
   if isempty(ug), ug = 1e6; end

   if ~islogical(ha) || ~islogical(hb)
      error('polyboolclipper :  hole flags must be logical arrays.');
   end
   
   % prepare arguments
   if ~iscell(pa), pa = {pa}; end
   if ~iscell(pb), pb = {pb}; end
   
   % call polygon clipper
   [pc, hc] = polyboolmex(pa, pb, op, ha, hb, ug);

end


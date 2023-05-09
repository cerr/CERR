function c=comp_wpfbt(f,wtNodes,rangeLoc,ext,interscaling)
%-*- texinfo -*-
%@deftypefn {Function} comp_wpfbt
%@verbatim
%COMP_WPFBT Compute Wavelet Packet Filterbank Tree
%   Usage:  c=comp_wpfbt(f,wtNodes,ext);
%
%   Input parameters:
%         f        : Input L*W array.
%         wtNodes  : Filterbank tree nodes (elementary filterbanks) in
%                    BF order. Length nodeNo cell array of structures.
%         ext      : Type of the forward transform boundary handling.
%
%   Output parameters:
%         c        : Coefficients stored in cell-array. Each element is one
%                    subband (matrix with W columns).
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_wpfbt.html}
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

% Do non-expansve transform if ext=='per'
doPer = strcmp(ext,'per');
% Pre-allocated output
c = cell(sum(cellfun(@(wtEl) numel(wtEl.h),wtNodes)),1);

interscalingfac = 1;
if strcmp('intscale',interscaling)
    interscalingfac = 1/2;
elseif strcmp('intsqrt',interscaling)
    interscalingfac = 1/sqrt(2);
end

%  OLD code doing the scaling directly on filters in the tree
%  if do_scale
%      for ii=1:numel(wtNodes)
%          range = 1:numel(wtNodes{ii}.h);
%          range(rangeLoc{ii}) = [];
%          wtNodes{ii}.h(range) = cellfun(@(hEl) setfield(hEl,'h',hEl.h/sqrt(2)),wtNodes{ii}.h(range),...
%                                         'UniformOutput',0); 
%      end
%  end

ca = f;
cOutRunIdx = 1;
cInRunIdxs = [];
% Go over all nodes in breadth-first order
for jj=1:numel(wtNodes)
   % Node filters to a cell array
   %hCell = cellfun(@(hEl) conj(flipud(hEl.h(:))),wtNodes{jj}.h(:),...
   %                'UniformOutput',0);
   hCell = cellfun(@(hEl) hEl.h(:),wtNodes{jj}.h(:),'UniformOutput',0);
   % Node filters subs. factors
   a = wtNodes{jj}.a;
   % Node filters initial skips
   if(doPer)
      %offset = cellfun(@(hEl) 1-numel(hEl.h)-hEl.offset,wtNodes{jj}.h);
      offset = cellfun(@(hEl) hEl.offset,wtNodes{jj}.h);
   else
      offset = -(a-1);
   end
   filtNo = numel(hCell);
   
   % Run filterbank
   c(cOutRunIdx:cOutRunIdx + filtNo-1)=...
                               comp_filterbank_td(ca,hCell,a,offset,ext);
   
   % Bookeeping. Store idxs of just computed outputs.
   outRange = cOutRunIdx:cOutRunIdx+filtNo-1;
   % Omit those, which are not decomposed further
   outRange(rangeLoc{jj}) = [];
   cInRunIdxs = [cInRunIdxs,outRange];
   
   cOutRunIdx = cOutRunIdx + filtNo;
   
   % Prepare input for the next iteration
   % Scaling introduced in order to preserve energy 
   % (parseval tight frame)
   if ~isempty(cInRunIdxs)
      c{cInRunIdxs(1)} = c{cInRunIdxs(1)}*interscalingfac;
      
      ca = c{cInRunIdxs(1)};
      cInRunIdxs(1) = [];
   end
end   




function c=comp_uwpfbt(f,wtNodes,rangeLoc,nodesUps,scaling,interscaling)
%-*- texinfo -*-
%@deftypefn {Function} comp_uwpfbt
%@verbatim
%COMP_UWPFBT Compute Undecimated Wavelet Packet Filterbank Tree
%   Usage:  c=comp_uwpfbt(f,wtNodes,nodesUps);
%
%   Input parameters:
%         f        : Input data as L*W array.
%         wtNodes  : Filterbank tree nodes (elementary filterbanks) in
%                    BF order. Cell array of structures of length nodeNo.
%         nodesUps : Filters upsampling factor of each node. Array of
%                    length nodeNo. 
%
%   Output parameters:
%         c        : Coefficients stored in L*M*W array.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_uwpfbt.html}
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

% Pre-allocated output
[L, W] = size(f);
M = sum(cellfun(@(wtEl) numel(wtEl.h),wtNodes));
c = zeros(L,M,W,assert_classname(f,wtNodes{1}.h{1}.h));

% Convenience input reshape
ca = reshape(f,size(f,1),1,size(f,2));
cOutRunIdx = 1;
cInRunIdxs = [1];

interscalingfac = 1;
if strcmp('intscale',interscaling)
    interscalingfac = 1/2;
elseif strcmp('intsqrt',interscaling)
    interscalingfac = 1/sqrt(2);
end

% For each node in tree in the BF order...
for jj=1:numel(wtNodes)
   % Node filters subs. factors
   a = wtNodes{jj}.a;
   
   % Optionally scale the filters
   h = comp_filterbankscale(wtNodes{jj}.h(:),a(:),scaling);
   
   % Node filters to a matrix
   % hMat = cell2mat(cellfun(@(hEl) conj(flipud(hEl.h(:))),h','UniformOutput',0));
   hMat = cell2mat(cellfun(@(hEl) hEl.h(:),h','UniformOutput',0));

   % Node filters initial skips
   % hOffet = cellfun(@(hEl) 1-numel(hEl.h)-hEl.offset,wtNodes{jj}.h);
   hOffet = cellfun(@(hEl) hEl.offset, wtNodes{jj}.h);
   % Number of filters of the current node
   filtNo = size(hMat,2);
   % Zero index position of the upsampled filters.
   offset = nodesUps(jj).*(hOffet);

   % Run filterbank
   c(:,cOutRunIdx:cOutRunIdx + filtNo-1,:)=...
      comp_atrousfilterbank_td(squeeze(ca(:,1,:)),hMat,nodesUps(jj),offset);
   
   % Bookkeeping
   outRange = cOutRunIdx:cOutRunIdx+filtNo-1;
   outRange(rangeLoc{jj}) = [];
   cInRunIdxs = [cInRunIdxs(2:end),outRange];
   
   cOutRunIdx = cOutRunIdx + filtNo;
   
   % Prepare input for the next iteration
   if ~isempty(cInRunIdxs)
      c(:,cInRunIdxs(1),:) = c(:,cInRunIdxs(1),:)*interscalingfac;
      ca = c(:,cInRunIdxs(1),:);
   end
end   




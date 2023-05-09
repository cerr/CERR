function f=comp_iuwpfbt(c,wtNodes,nodesUps,pOutIdxs,chOutIdxs,scaling,interscaling)
%-*- texinfo -*-
%@deftypefn {Function} comp_iuwpfbt
%@verbatim
%COMP_IUWPFBT Compute Inverse Undecimated Wavelet Packet Filter-Bank Tree
%   Usage:  f=comp_iuwpfbt(c,wtNodes,nodesUps,pOutIdxs,chOutIdxs)
%
%   Input parameters:
%         c          : Coefficients stored in L*M*W array.
%         wtNodes    : Filterbank tree nodes (elementary filterbans) in
%                      reverse BF order. Cell array of structures of length nodeNo.
%         nodesUps   : Filters upsampling factor of each node. Array of
%                      length nodeNo.
%         pOutIdxs   : Idx of each node's parent. Array of length nodeNo.
%         chOutIdxs  : Idxs of each node children. Cell array of vectors of
%                      length nodeNo.
%
%   Output parameters:
%         f     : Reconstructed data in L*W array.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_iuwpfbt.html}
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

interscalingfac = 1;
if strcmp('intscale',interscaling)
    interscalingfac = 1/2;
elseif strcmp('intsqrt',interscaling)
    interscalingfac = 1/sqrt(2);
end

% For each node in tree in the BF order...
 for jj=1:length(wtNodes)
    % Node filters subs. factors
    a = wtNodes{jj}.a;
    
    % Optionally scale the filters
    g = comp_filterbankscale(wtNodes{jj}.g(:),a(:),scaling);
    
    % Node filters to a matrix
    gMat = cell2mat(cellfun(@(gEl) gEl.h(:),g','UniformOutput',0));

    % Node filters initial skips
    gOffset = cellfun(@(gEl) gEl.offset,wtNodes{jj}.g);
    
    % Zero index position of the upsampled filters.
    offset = nodesUps(jj).*(gOffset);% + nodesUps(jj);

    % Run filterbank
    ctmp = comp_iatrousfilterbank_td(c(:,chOutIdxs{jj},:),gMat,nodesUps(jj),offset);
    
    if(pOutIdxs(jj))
       % Add to the existing subband
       c(:,pOutIdxs(jj),:) = interscalingfac*(c(:,pOutIdxs(jj),:)+reshape(ctmp,size(ctmp,1),1,size(ctmp,2)));
    else
       % We are at the root.
       f = ctmp;
    end
 end


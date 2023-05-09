function c=comp_wfbt(f,wtNodes,rangeLoc,rangeOut,ext)
%-*- texinfo -*-
%@deftypefn {Function} comp_wfbt
%@verbatim
%COMP_WFBT Compute Wavelet Filterbank Tree
%   Usage:  c=comp_wfbt(f,wtNodes,rangeLoc,rangeOut,ext);
%
%   Input parameters:
%         f        : Input L*W array.
%         wtNodes  : Filterbank tree nodes (elementary filterbanks) in
%                    BF order. Length nodeNo cell array of structures.
%         rangeLoc : Idxs of each node terminal outputs. Length nodeNo 
%                    cell array of vectors.
%         rangeOut : Output subband idxs of each node terminal outputs.
%         ext      : Type of the forward transform boundary handling.
%
%   Output parameters:
%         c        : Cell array of coefficients. Each element is one
%                    subband (matrix with W columns).
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_wfbt.html}
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
c = cell(sum(cellfun(@(rEl) numel(rEl),rangeOut)),1);

 ca = {f};
 % Go over all nodes in breadth-first order
 for jj=1:numel(wtNodes)
    % Load current filterbank
    wtNode = wtNodes{jj}.h(:);
    % Node filters to a cell array
    % hCell = cellfun(@(hEl) conj(flipud(hEl.h(:))),wtNode,'UniformOutput',0);
    hCell = cellfun(@(hEl) hEl.h(:),wtNode,'UniformOutput',0);
    % Node filters subs. factors
    a = wtNodes{jj}.a;
    % Node filters initial skips
    if(doPer)
       %offset = cellfun(@(hEl) 1-numel(hEl.h)-hEl.offset,wtNode);
       offset = cellfun(@(hEl) hEl.offset,wtNode);
    else
       offset = -(a-1);
    end

    % Run filterbank
    catmp=comp_filterbank_td(ca{1},hCell,a,offset,ext);
    % Pick what goes directy to the output...
    c(rangeOut{jj}) = catmp(rangeLoc{jj});
    % and save the rest.
    diffRange = 1:numel(hCell);
    diffRange(rangeLoc{jj}) = [];
    ca = [ca(2:end);catmp(diffRange)];
 end        







function wt = comp_wpfbtscale(wt,interscaling)
%-*- texinfo -*-
%@deftypefn {Function} comp_wpfbtscale
%@verbatim
%COMP_WPFBTSCALE Scale filters in the filterbank tree
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_wpfbtscale.html}
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


% Here we handle scaling of intermediate outputs in the tree
if ~strcmpi(interscaling,'intnoscale')
    if strcmp('intscale',interscaling)
        interscalingfac = 1/2;
    elseif strcmp('intsqrt',interscaling)
        interscalingfac = 1/sqrt(2);
    end
    
    wtPath = nodeBForder(0,wt);
    rangeLoc = nodesLocOutRange(wtPath,wt);
    wtNodes = wt.nodes(wtPath);

    for ii=1:numel(wtPath)
          range = 1:numel(wtNodes{ii}.h);
          % Remove the outputs which are terminal
          range(rangeLoc{ii}) = [];
          wtNodes{ii}.h(range) = ...
             cellfun(@(hEl) setfield(hEl,'h',hEl.h*interscalingfac),...
                     wtNodes{ii}.h(range),...
                     'UniformOutput',0); 
                 
          wtNodes{ii}.g(range) = ...
             cellfun(@(hEl) setfield(hEl,'h',hEl.h*interscalingfac),...
                     wtNodes{ii}.g(range),...
                     'UniformOutput',0);
    end
    % Write the scaled ones back
    wt.nodes(wtPath) = wtNodes;
end



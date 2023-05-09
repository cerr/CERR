function [newphase, usedmask] = comp_constructphasereal(s,tgrad,fgrad,a,M,tol,do_timeinv,mask,usephase)

absthr = max(s(:))*tol;

if isempty(mask)
    usedmask = zeros(size(s));
else
    usedmask = mask;
end

%-*- texinfo -*-
%@deftypefn {Function} comp_constructphasereal
%@verbatim
% Build the phase
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_constructphasereal.html}
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
if isempty(mask)
    % s is real and positive
    newphase=comp_heapintreal(s,tgrad,fgrad,a,M,tol(1),do_timeinv);

    % Find all small coefficients and set the mask
    bigenoughidx = s>absthr(1);
    usedmask(bigenoughidx) = 1;
else
    newphase=comp_maskedheapintreal(s,tgrad,fgrad,mask,a,M,tol(1),...
                                    do_timeinv,usephase);
    % Find all small coefficients in the unknown phase area
    missingidx = find(usedmask==0);
    bigenoughidx = s(missingidx)>absthr(1);
    usedmask(missingidx(bigenoughidx)) = 1;
end

% Do further tol
for ii=2:numel(tol)
    newphase=comp_maskedheapintreal(s,tgrad,fgrad,usedmask,a,M,tol(ii),...
                                    do_timeinv,newphase);
    missingidx = find(usedmask==0);
    bigenoughidx = s(missingidx)>absthr(ii);
    usedmask(missingidx(bigenoughidx)) = 1;
end


% Convert the mask so it can be used directly for indexing
usedmask = logical(usedmask);
% Assign random values to coefficients below tolerance
zerono = numel(find(~usedmask));
newphase(~usedmask) = rand(zerono,1)*2*pi;

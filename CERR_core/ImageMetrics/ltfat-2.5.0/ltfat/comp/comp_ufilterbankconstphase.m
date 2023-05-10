function [newphase,usedmask] = comp_ufilterbankconstphase(abss,tgrad,fgrad,fc,mask,usephase,a,tol,phasetype,do_real)

%   part of the heap integration for reconstructing phase from the
%   magnitude of filterbank coefficients
%
%   Url: http://ltfat.github.io/doc/comp/comp_ufilterbankconstphase.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%% DO the heap integration
absthr = max(abss(:))*tol;
if isempty(mask)
    usedmask = zeros(size(abss));
else
    usedmask = mask;
end

%phasetype = 0;
if isempty(mask)
    % Build the phase (calling a MEX file)
    newphase=comp_ufilterbankheapint(abss,tgrad,fgrad,fc,a,do_real,tol(1),phasetype);
    % Set phase of the coefficients below tol to random values
    bigenoughidx = abss>absthr(1);
    usedmask(bigenoughidx) = 1;
else
    newphase=comp_ufilterbankmaskedheapint(abss,tgrad,fgrad,fc,mask,a,do_real,tol(1),phasetype,...
                                usephase);
    % Set phase of small coefficient to random values
    % but just in the missing part
    % Find all small coefficients in the unknown phase area
    missingidx = find(usedmask==0);
    bigenoughidx = abss(missingidx)>absthr(1);
    usedmask(missingidx(bigenoughidx)) = 1;
end

% Do further tol
for ii=2:numel(tol)
    newphase=comp_ufilterbankmaskedheapint(abss,tgrad,fgrad,fc,usedmask,a,do_real,tol(ii),phasetype,...
                                newphase);
    missingidx = find(usedmask==0);
    bigenoughidx = abss(missingidx)>absthr(ii);
    usedmask(missingidx(bigenoughidx)) = 1;                  
end

% Convert the mask so it can be used directly for indexing
usedmask = logical(usedmask);
% Assign random values to coefficients below tolerance
zerono = numel(find(~usedmask));
newphase(~usedmask) = rand(zerono,1)*2*pi;

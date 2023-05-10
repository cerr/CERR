function [tgrad,fgrad,logs] = comp_ufilterbankphasegradfrommag(abss,N,a,M,sqtfr,fc,do_real,do_tfrdiff)

%   part of the heap integration for reconstructing phase from the
%   magnitude of filterbank coefficients
%
%   Url: http://ltfat.github.io/doc/comp/comp_ufilterbankphasegradfrommag.html

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

L=N*a;

% Prepare differences of center frequencies [given in normalized frequency]
% and dilation factors (square root of the time-frequency ratio)
cfreqdiff = mod(diff(fc),2);

if do_tfrdiff
    sqtfrdiff = diff(sqtfr);
else
    sqtfrdiff = zeros(size(cfreqdiff));
end
tfr = sqtfr.^2;

% Filterbankphasegrad does not support phasederivatives from absolute
% values
logs=log(abss+realmin);
tt=-11;
logs(logs<max(logs(:))+tt)=tt;

difforder = 2;
% Obtain the (relative) phase difference in frequency direction by taking
% the time derivative of the log magnitude and weighting it by the
% time-frequency ratio of the appropriate filter.
% ! Note: This disregards the 'quadratic' factor in the equation for the 
% phase derivative !
fgrad = pderiv(logs,1,difforder)/(2*pi);
for kk = 1:M
    fgrad(:,kk,:) = tfr(kk).*fgrad(:,kk,:);
end
    
% Obtain the (relative) phase difference in time direction using the
% frequency derivative of the log magnitude. The result is the mean of
% estimates obtained from 'above' and 'below', appropriately weighted by
% the channel distance and the inverse time-frequency ratio of the
% appropriate filter.
% ! Note: We consider the term depending on the time-frequency ratio 
% difference, but again disregard the 'quadratic' factor. !
tgrad = zeros(size(abss));
if do_real
    logsdiff = diff(logs,1,2);
    for kk = 2:M-1
        tgrad(:,kk,:) = (logsdiff(:,kk,:) + 2*sqtfrdiff(kk)./sqtfr(kk)./pi)./cfreqdiff(kk) + ...
                        (logsdiff(:,kk-1,:) + 2*sqtfrdiff(kk-1)./sqtfr(kk)./pi)./cfreqdiff(kk-1);
        tgrad(:,kk,:) = tgrad(:,kk,:)./tfr(kk)./(pi*L);
    end
    % For first and last channel, use a 1st order difference scheme as they
    % are not considered to be adjacent.
    tgrad(:,1,:) = 2*(logsdiff(:,1,:) + 2*sqtfrdiff(1)./sqtfr(1)./pi)./cfreqdiff(1);
    tgrad(:,1,:) = tgrad(:,1,:)./tfr(1)./(pi*L);
    tgrad(:,M,:) = 2*(logsdiff(:,M-1,:) + 2*sqtfrdiff(M-1)./sqtfr(M)./pi)./cfreqdiff(1);
    tgrad(:,M,:) = tgrad(:,M,:)./tfr(M)./(pi*L);

    % Fix the first and last rows .. the
    % borders are symmetric so the centered difference is 0
    if fc(1) == 0, tgrad(:,1,:) = 0; end
    if fc(M) == 1, tgrad(:,M,:) = 0; end
else
    logsdiff = diff([logs(:,M,:),logs,logs(:,1,:)],1,2); 
    cfreqdiff = [fc(1)-fc(M);cfreqdiff;fc(1)-fc(M)];
    sqtfrdiff = [sqtfr(1)-sqtfr(M);sqtfrdiff;sqtfr(1)-sqtfr(M)];
    for kk = 1:M
        tgrad(:,kk,:) = (logsdiff(:,kk+1,:) + 2*sqtfrdiff(kk+1)./sqtfr(kk)./pi)./cfreqdiff(kk+1) + ...
                        (logsdiff(:,kk,:) + 2*sqtfrdiff(kk)./sqtfr(kk)./pi)./cfreqdiff(kk);
        tgrad(:,kk,:) = tgrad(:,kk,:)./tfr(kk)./(pi*L);
    end
end


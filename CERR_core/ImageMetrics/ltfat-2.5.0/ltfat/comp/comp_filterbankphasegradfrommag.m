function [tgrad,fgrad,logs] = comp_filterbankphasegradfrommag(abss,N,a,M,sqtfr,fc,NEIGH,posInfo,gderivweight,do_tfrdiff)

%this function is called by filterbankconstphase
%
%   Url: http://ltfat.github.io/doc/comp/comp_filterbankphasegradfrommag.html

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

NEIGH = NEIGH + 1;
%chanStart = [0;cumsum(N)];
fac = gderivweight;
%cfreqdiff = diff(fc);
%sqtfr = sqrt(tfr);
%sqtfrdiff = diff(sqtfr);

L = a(1)*N(1);

difforder = 2;
tt=-11;

logs = log(abss + realmin);
%logsMax = max(logs);
%logs(logs<logsMax+tt) = tt;

% Obtain the (relative) phase difference in frequency direction by taking
% the time derivative of the log magnitude and weighting it by the
% time-frequency ratio of the appropriate filter.
% ! Note: This disregards the 'quadratic' factor in the equation for the 
% phase derivative !

%tmagdiff = zeros(size(logs));
fgrad = zeros(size(logs));
chanStart = 0;
for m = 1:M
    idx = chanStart+(1:N(m));
    fgrad(idx) = pderiv(logs(idx),1,difforder)/N(m);
    chanStart = chanStart + N(m);
end

% Obtain the (relative) phase difference in time direction using the
% frequency derivative of the log magnitude. The result is the mean of
% estimates obtained from 'above' and 'below', appropriately weighted by
% the channel distance and the inverse time-frequency ratio of the
% appropriate filter.
% ! Note: We consider the term depending on the time-frequency ratio 
% difference, but again disregard the 'quadratic' factor. !
%fac = 0;
%fac = 1/2; 
%fac = 2/3;
%fac = 2/pi;

tgrad = zeros(size(abss));

chanStart = 0;
for m = 1:M
    aboveNom = 0; aboveDenom = 1; belowNom = 0; belowDenom = 1; 
    denom = sqtfr(m)^2*(pi*L);
    if m<M
        if do_tfrdiff
            aboveNom = fac*(sqtfr(m+1)-sqtfr(m))/sqtfr(m);
        end
        aboveDenom = fc(m+1)-fc(m);
    end
    if m>1
        if do_tfrdiff
            belowNom = fac*(sqtfr(m)-sqtfr(m-1))/sqtfr(m);
        end
        belowDenom = fc(m)-fc(m-1);
    end
   
    temp = zeros(N(m),1);    
    for n = 1:N(m) 
        w = chanStart + n;
        tempValAbove = 0;
        numNeigh = 0;
        for jj = 1:2
           neigh = NEIGH(4+jj,w);           
           if neigh
              numNeigh = numNeigh+1;
              dist = (posInfo(2,neigh)-posInfo(2,w))/a(m);
              tempValAbove = tempValAbove + (logs(neigh)-logs(w) - dist*fgrad(w));
           end
        end
        if numNeigh
           tempValAbove = tempValAbove/numNeigh;
        end
        
        tempValBelow = 0;
        numNeigh = 0;
        for jj = 1:2
           neigh = NEIGH(2+jj,w);           
           if neigh
              numNeigh = numNeigh+1;
              dist = (posInfo(2,neigh)-posInfo(2,w))/a(m);
              tempValBelow = tempValBelow + (logs(w)-logs(neigh) - dist*fgrad(w));
           end
        end
        
        if numNeigh
            tempValBelow = tempValBelow/numNeigh; 
        end  
        
        temp(n) = (tempValAbove + aboveNom) / aboveDenom + ...
                   (tempValBelow + belowNom) / belowDenom;
        %temp(ll,2) = (tempValBelow + belowNom) / belowDenom;
    end
    % Maybe a factor of 1/2 is missing here?
    
    tgrad(chanStart+(1:N(m))) = temp/denom;
    
    chanStart = chanStart + N(m);
end

chanStart = 0;
for m = 1:M
    idx = chanStart+(1:N(m));
    fgrad(idx) = fgrad(idx).*sqtfr(m)^2/(2*pi)*N(m);
    
    chanStart = chanStart + N(m);
end





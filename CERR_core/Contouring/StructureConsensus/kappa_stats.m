function [kappa,pval,k, pk]=kappa_stats(D,ncat)
% calculate Kappa statisc for agreement
% D: matrix NxM of N scores by M raters
% cat: categories
% Written By Issam El Naqa Date: 03/21/07
% ref.: SAS docs. (Fleiss '81)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

[N,M]=size(D);
lk=length(ncat); % number of categories
for i=1:lk
    x(:,i) = sum(D==ncat(i),2);
end
p=sum(x)/(N*M);
k=1-sum(x.*(M-x))./((N*M*(M-1).*p.*(1-p))+eps);
sek=sqrt(2/(N*M*(M-1)));
pk=drxlr_get_p_gaussian(k./sek)/2; % one-sided
% kappa=sum(p.*(1-p).*k)/sum(p.*(1-p));
kappa=1-(N*M^2-sum(sum(x.^2)))/((N*M*(M-1)*sum(p.*(1-p)))+eps);
sekappa=sqrt(2)/(sum(p.*(1-p)*sqrt(N*M*(M-1)))+eps)*sqrt(sum(p.*(1-p))^2-sum(p.*(1-p).*(1-2*p)));
z=kappa/sekappa;
pval=drxlr_get_p_gaussian(z)/2; % one-sided
return

function p=drxlr_get_p_gaussian(x)
% two tailed p-value from a normal distribution
%DREX subfunction 
%Written by Issam El Naqa 2003-2005
%Extracted for generalized use 2005, AJH

    p = erfc(abs(x)./sqrt(2));

return

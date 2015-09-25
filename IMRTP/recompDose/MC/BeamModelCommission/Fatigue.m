function y = Fatigue(params, x)
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

%     N  = params(1);
%     s  = params(2);     % offset in y
%     b  = params(3);     % scale in y
% %    y = a + b.*nerf(c.*(x-x0));
% % Changed, since nerf can not be found.
% % The function from "Matthias Fippel" paper. Med. PHys. 30(3). pp 301
% % y = N*x.^s.*exp(-b.*x);

% Try to fit it 
% theta = params(1);
% m = params(2);
% sigma = params(3);
% 
% y = params(4)* exp((-log((x-theta)./m)).^2.0./(2.0*sigma*sigma))./(x-theta).*sigma*sqrt(2*pi);

gamma = params(1);
mu = params(2);
beta = params(3);
scale = params(4);

z = (sqrt((x-mu)./beta)-sqrt(beta./(x-mu)))./gamma;
phai = exp(-0.5*z.*z)./sqrt(2.0*pi);
y = (sqrt((x-mu)./beta)+sqrt(beta./(x-mu)))./(2.0*gamma.*(x-mu)).*phai.*scale;
return;
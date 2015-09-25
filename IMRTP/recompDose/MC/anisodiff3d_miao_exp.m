function diff = anisodiff3d_miao_exp(x, cerror, niter);
% Anisotropic diffusion routine based on Perona & Malik, PAMI, '90 
%         x     : - input image
%         niter :  # of iterations 
%         cerror: the uncertainty matrix
%         type -   diffusion function  'exp' gaussian, 'poly' rational polynomials
%         written by: Issam El Naqa         date: 04/20/04
%
%Slightly changed by JC. Dec. 2005, to save memory usage, and to make only
%'exp' option available now.
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

[m,n,k] = size(x);
diff = x;
% Selected parameters from Miao, PMB 2003, might need tweaking?
kappa=1.75*cerror;  
lambda=0.15;
alpha=2;
for i = 1:niter
    %fprintf('\rIteration %d',i);
    % padding by zeros
    diffl = zeros(m+2, n+2, k+2);
    diffl(2:m+1, 2:n+1, 2:k+1) = diff;
    
    % North, South, East, West, Top, and Bottom gradients
    deltaN = diffl(1:m,2:n+1,2:k+1) - diff;
    % diffusion function
    cN = exp(-(deltaN./kappa).^2);
    x1 = cN.*deltaN;
    clear cN deltaN;
    
    deltaS = diffl(3:m+2,2:n+1,2:k+1) - diff;
    cS = exp(-(deltaS./kappa).^2);
    x1 = x1+cS.*deltaS;
    clear cS deltaS;
    
    deltaE = diffl(2:m+1,3:n+2,2:k+1) - diff;
    cE = exp(-(deltaE./kappa).^2);
    x1 = x1+cE.*deltaE;
    clear cE deltaE;
    
    deltaW = diffl(2:m+1,1:n,2:k+1) - diff;
    cW = exp(-(deltaW./kappa).^2);
    x1 = x1+cW.*deltaW;
    clear cW deltaW;
    
    deltaT = diffl(2:m+1,2:n+1,1:k) - diff;
    cT = exp(-(deltaT./kappa).^2);
    x1 = x1+cT.*deltaT;
    clear cT deltaT;
    
    deltaB = diffl(2:m+1,2:n+1,3:k+2) - diff;
    cB = exp(-(deltaB./kappa).^2);
    x1 = x1+cB.*deltaB;
    clear cB deltaB;
    
    diff = diff + lambda*x1;
    clear x1;
    
    %diff = diff + lambda*(cN.*deltaN + cS.*deltaS + cE.*deltaE + cW.*deltaW+cT.*deltaT +cB.*deltaB);
    %gtitle=strcat('Diffusion at iteration=',num2str(i));
    %figure(i)
    %dispimage(diff,gtitle,1,1,1);
end


return
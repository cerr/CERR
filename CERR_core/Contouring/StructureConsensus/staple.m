function [W,p,q,Sall]=staple(D,iterlim,p,q)
%staple (simaltaneous truth and performance level estimation)
%
% - Detailed Description: given multiple expert contours, the algorithm
% uses EM based technique to estimate the 'true' segmentation by optimal weighting and the
% corresponding expert's performance level (ref. Warfield et al., TMI '04)
% - inputs:
%--------------
%     *D: a matrix of N (voxels) x R (binary decisions by experts)   
%     *p: intial sensitivity
%     *q: intial specificity
%     *iterlim: iteration limit
% - outputs:
% -------------
%     * p: final sensitivity estimate
%     * q: final specificity estimate
%     * W: estimated belief in true segmentation 
%
% Written By: Issam El Naqa    Date: 03/20/07
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


[N,R]=size(D);
if ~exist('p','var')
   p=ones(1,R,'single')*0.9999;
end

if ~exist('q','var')
   q=ones(1,R,'single')*0.9999;
end


Tol=1e-2;
iter=0;
gamma=sum(sum(D))/(R*N); % prior probability of true segmentation
W=zeros(N,1,'single'); % belief of true segmentation is 1
S0=sum(W);
waitbar_handle=waitbar(0,'STAPLE progress...');
while (1)
    iter=iter+1;
    waitbar(iter/iterlim,waitbar_handle);
    Sall(iter) = S0;
    
    ind1 = D==1;
    ind0 = D==0;
    p = repmat(p,[size(D,1) 1]);    
    p1 = p;
    p0 = 1-p;
    clear p
    p1(~ind1) = 1;
    p0(~ind0) = 1;
    a = gamma*prod(p1,2).*prod(p0,2);
    clear p1 p0
    
    q = repmat(q,[size(D,1) 1]);
    q1 = 1-q;
    q0 = q;
    clear q
    q1(~ind1) = 1;
    q0(~ind0) = 1;   
    clear ind0 ind1
    b = (1-gamma).*prod(q0,2).*prod(q1,2);    
    clear q1 q0
    
    W = a./(a + b);
    W = W';  
    
    clear a b p q
    
%     for i=1:N
%         ind1=find(D(i,:)==1);
%         ind0=find(D(i,:)==0);
%         a(i)=gamma*prod(p(ind1))*prod(1-p(ind0));
%         b(i)=(1-gamma)*prod(q(ind0))*prod(1-q(ind1));
%         W1(i)=a(i)/(a(i)+b(i));
%     end

    p=(W*D)./sum(W);
    q=((1-W)*(1-D))./sum(1-W);
    
    % Check convergence
    S=sum(W);
    if abs(S-S0) <Tol
        disp(['STAPLE converged in ',num2str(iter),' iterations.']);
        break;
    else
        S0=S;
    end
    
    % check iteration limit
    if (iter>iterlim)
        warning('STAPLE: Number of iterations exceeded without convergence (convergence tolerance = %e)', Tol)
        break; 
    end
end
abs(S-S0)
        
close(waitbar_handle);
return






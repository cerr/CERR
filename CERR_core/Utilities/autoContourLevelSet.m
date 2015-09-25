function phi=autoContourLevelSet(lambda1,lambda2,lambda3, mu,maxiter,cinit, x1,x2,y1,y2,uniqueSlices,ROI,scanNum)
%function autoContourLevelSet(structNum,percent)
%
%This function creates structure of active contour level for structNum in
%single or mutiple images (not supported in CERR)
%
%APA,12/15/2006, IEN & DY 11/07/2007
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

global planC stateS
indexS = planC{end};

% scanNum                             = getStructureAssociatedScan(structNum);
% [rasterSegments, planC, isError]    = getRasterSegments(structNum);
% [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum);
% scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
%%%% reverse data
%maxscan=max(scanArray3M(:));
%scanArray3M =maxscan-scanArray3M;
% [x1,x2,y1,y2]=computeMinMaxFromMask(mask3M);
z1 = min(uniqueSlices); z2 = max(uniqueSlices);
% ROI = planC{indexS.scan}.scanArray;
% ROI = ROI(y1:y2,x1:x2,z1:z2);

% SUVvals3M                           = mask3M.*scanArray3M(:,:,uniqueSlices);
maxSUVinStruct                      = double(max(ROI(:)));
[xVals, yVals, zVals]               = getScanXYZVals(planC{indexS.scan}(scanNum));
newStructNum                        = length(planC{indexS.structures}) + 1;

%%% scale
ROI=single(ROI/maxSUVinStruct*255);   
%%%% intialize
siz=size(ROI);
v=0; h=1; delta_t=1e-5; %delta_t=0.1;
h2=h*h;
eps=1;
%Tol=0.0001;
Tol = 1e-8;
%Sphere
%cc = single(initsphere([round((x2-x1)/2)+1 round((y2-y1)/2)+1 round((z2-z1)/2)+1],cinit,siz));
cc = single(initsphere([round((x2-0)/2)+1 round((y2-y1)/2)+1 round((z2-z1)/2)+1],cinit,siz));

% initialize the zero level set to the signed distance function...
phi=-direct_sdist(cc); %APA commented
convp=1e6;
for n=1:maxiter
    disp(['Iteration ', num2str(n)])
    [Fgrad, kappa]=curve_derivatives3d(phi);
    [delta_hv, dummy]=delta_h(phi,1,2);
    temp1=-v;
    temp2=0;
    %for i=1:N
        cin=mean(ROI(phi>=0));
        cout=mean(ROI(phi<0));
        temp1=temp1-lambda1*(ROI-cin).^2+lambda2*(ROI-cout).^2;
        temp2=temp2+lambda3*(cin-cout).^2;
    %end
    phi_old=phi;
    phi=phi+delta_t*delta_hv.*(mu/h2*kappa+temp1-temp2);


    % reinitialize
    if mod(n,10)==0
        phi=reinit_sdist(phi, delta_t, 5);
    end
    % convergence
    convr=mean((phi(:)-phi_old(:)).^2);
    
    if (convp-convr)/convp<Tol
        disp(['converged in ',num2str(n),' iterations']);
        break;
    else
        convp=convr;
    end
end


newStructS = newCERRStructure(scanNum, planC);
for slcNum = 1:length(uniqueSlices)
    C = contourc(xVals(x1:x2), yVals(y1:y2), double(phi(:,:,slcNum)),double([0 0]));
    indC = getSegIndices(C);
    if ~isempty(indC)
        for seg = 1:length(indC)
            points = [C(:,indC{seg})' zVals(uniqueSlices(slcNum))*ones(length(C(1,indC{seg})),1)];
            newStructS.contour(uniqueSlices(slcNum)).segments(seg).points = points;
        end
    else
        newStructS.contour(uniqueSlices(slcNum)).segments.points = [];
    end
end

for l = max(uniqueSlices)+1 : length(planC{indexS.scan}(scanNum).scanInfo)
    newStructS.contour(l).segments.points = [];
end
stateS.structsChanged = 1;

newStructS.strUID           = createUID('structure');
newStructS.assocScanUID     = planC{indexS.scan}(scanNum).scanUID;
newStructS.structureName    = ['Auto Bone Contour'];

planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
planC = getRasterSegs(planC, newStructNum);
%planC = setUniformizedData(planC);
planC = updateStructureMatrices(planC, newStructNum, uniqueSlices);

return;

function indC = getSegIndices(C)
% function getSegIndices(C)
%
%This function returns the indices for each segment of input contour C.
%C is output from in-built "contourc" function
%
%APA, 12/15/2006

start = 1;
counter = 1;
indC = [];
while start < length(C(2,:))
    numPts = C(2,start);
    indC{counter} = [(start+1):(start+numPts) start+1];
    start = start + numPts + 1;
    counter = counter + 1;
end
return


function res=direct_sdist(c)
% construct the signed distance function directly
dt1=bwdist(c<1,'quasi-euclidean');
dt2=bwdist(c>-1,'quasi-euclidean');
res=dt1-dt2;
return

function phi=reinit_sdist(initphi, delta_t, numiter)
% re initialize the the contour to sign distance function whose original
% function have the same  zero level (initphi)
% by solving phi_t+sign(v)*(abs(delta_phi)-1)
% Written by issam El Naqa 01/27/06
[m n k]=size(initphi);
phi=initphi; 
sign_phi=sign(initphi);

for i=1:numiter
    phil=zeros(m+2, n+2, k+2);
    diffxp=phil(2:m+1,3:n+2,2:k+1)-phi;
    diffxn=phi-phil(2:m+1,1:n,2:k+1);
    diffyp=phil(3:m+2,2:n+1,2:k+1)-phi;
    diffyn=phi-phil(1:m,2:n+1,2:k+1);
    diffzp=phil(2:m+1,2:n+1,3:k+2)-phi;
    diffzn=phi-phil(2:m+1,2:n+1,1:k);
    delta_phip = sqrt(max(diffxn,0).^2+min(diffxp,0).^2+...
        max(diffyn,0).^2+min(diffyp,0).^2+ max(diffzn,0).^2+min(diffzp,0).^2); % nonoscillatory upwind scheme
    phi=phi-delta_t.*sign_phi.*(delta_phip-1); 
end

return; 

function [Fgrad, Fcurve]=curve_derivatives3d(f)
% the gradients of the curve
[m,n,k]=size(f);
fx=zeros(m,n,k,'single'); 
fy=zeros(m,n,k,'single'); 
fz=zeros(m,n,k,'single'); 
fxx=zeros(m,n,k,'single'); 
fyy=zeros(m,n,k,'single'); 
fzz=zeros(m,n,k,'single'); 
fxy=zeros(m,n,k,'single'); 
fxz=zeros(m,n,k,'single'); 
fyz=zeros(m,n,k,'single'); 
% Fgradient=zeros(m,n,k); 
% Fcurve=zeros(m,n,k); 
%first order derivative using central differences
fx(2:m-1,2:n-1,2:k-1)=(f(3:m,2:n-1,2:k-1)-f(1:m-2,2:n-1,2:k-1))/2; 
fy(2:m-1,2:n-1,2:k-1)=(f(2:m-1,3:n,2:k-1)-f(2:m-1,1:n-2,2:k-1))/2; 
fz(2:m-1,2:n-1,2:k-1)=(f(2:m-1,2:n-1,3:k)-f(2:m-1,2:n-1,1:k-2))/2; 
%second order derivative 
%first order derivative minus the step in time 
fxx(2:m-1,2:n-1,2:k-1)=f(3:m,2:n-1,2:k-1)+f(1:m-2,2:n-1,2:k-1)-2*f(2:m-1,2:n-1,2:k-1); 
fyy(2:m-1,2:n-1,2:k-1)=f(2:m-1,3:n,2:k-1)+f(2:m-1,1:n-2,2:k-1)-2*f(2:m-1,2:n-1,2:k-1); 
fzz(2:m-1,2:n-1,2:k-1)=f(2:m-1,2:n-1,3:k)+f(2:m-1,2:n-1,1:k-2)-2*f(2:m-1,2:n-1,2:k-1); 
fxy(2:m-1,2:n-1,2:k-1)=(f(3:m,3:n,2:k-1)-f(1:m-2,3:n,2:k-1)-f(3:m,1:n-2,2:k-1)+f(1:m-2,1:n-2,2:k-1))/4; 
fxz(2:m-1,2:n-1,2:k-1)=(f(3:m,2:n-1,3:k)-f(1:m-2,2:n-1,3:k)-f(3:m,2:n-1,1:k-2)+f(1:m-2,2:n-1,1:k-2))/4; 
fyz(2:m-1,2:n-1,2:k-1)=(f(2:m-1,3:n,3:k)-f(2:m-1,1:n-2,3:k)-f(2:m-1,3:n,1:k-2)+f(2:m-1,1:n-2,1:k-2))/4; 

Fgrad=sqrt(fx.^2+fy.^2+fz.^2); 
Fcurve=(fxx.*(fy.^2+fz.^2)+fyy.*(fx.^2+fz.^2)+fzz.*(fx.^2+fy.^2)-2*(fxy.*fx.*fy+fxz.*fx.*fz+fyz.*fy.*fz))./(Fgrad.^3+eps); 
Fcurve(find(isnan(Fcurve)))=0;
Fgrad(find(isnan(Fgrad)))=0;
%Fcurve=((fxx.*(fy.^2))-(2*(fxy.*fx.*fy))+(fyy.*(fx.^2))); 
return 

function [delta,H]=delta_H(x,eps,type)
% compute the delta as the derivative of Heaviside function
switch type 
    case 1
        if x>eps
            H=1;
            delta=0;
        elseif x<-eps
            H=0;
            delta=0;
        else
            H=0.5*(1+x/eps+1/pi*sin(pi*x/eps));
            delta=0.5*(1/eps+1/eps*cos(pi*x/eps));
        end
    case 2
        H=0.5*(1+2/pi*atan(x/eps));
        delta=1./(pi*eps*(1+(x/eps).^2));
    otherwise
        error('Unknown Heaviside function!')
end
return

function c=initsphere(cen, r,siz)
% c=zeros(siz);
[x,y,z]=meshgrid(single(1:siz(2)),single(1:siz(1)),single(1:siz(3)));
xc=x-cen(1);
yc=y-cen(2);
if size(3)>1
    zc=z-cen(3);
else
    zc=0;
end
c=xc.^2+yc.^2+zc.^2-r^2;
return

function [delta,H]=delta_h(x,eps,type)
% compute the delta as the derivative of Heaviside function
switch type 
    case 1
        if x>eps
            H=1;
            delta=0;
        elseif x<-eps
            H=0;
            delta=0;
        else
            H=0.5*(1+x/eps+1/pi*sin(pi*x/eps));
            delta=0.5*(1/eps+1/eps*cos(pi*x/eps));
        end
    case 2
        H=0.5*(1+2/pi*atan(x/eps));
        delta=1./(pi*eps*(1+(x/eps).^2));
    otherwise
        error('Unknown Heaviside function!')
end

return




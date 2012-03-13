function [Vy,Vx,Vz] = optical_flow_global_methods(method,mainfigure,img1,imgt,ratios,maxiterratio,mvy,mvx,mvz,offsets, isLastStep)
%
% Gloabl optical flow methods
%
% Implemented by: Deshan Yang, 09/2006
%
% Input parameters:
% img1	-	Image to be registered
% imgt	-	The target image (the reference)
% method	-	1 - original Horn-Schunck method
%				2 - Issam modification: weighted smoothness
%				3 - Combined local LMS and HS global smoothness
%				4 - Combined local LMS and Issam's weighted smoothness
%				5 - Horn-Schunck and weighted panalization on optical flow
%				    constraint
%				6 - Horn-Schunck with divergence constraints for
%				    uncompressible media
%
% Outputs:
% u,v,w	-	The motion fields
%
% changes 10/21/2006
% Allow img1 to be larger than img2 with zoffset so that gradient in z
% direction could be computed more accurately
%
% 05/11/2007
% Allow image offsets in all x,y,z direction

if ~exist('method','var')
	method = 1;
end

if ~exist('maxiterratio','var') || isempty(maxiterratio)
	maxiterratio = 1;
end

if ~exist('offsets','var') || isempty(offsets)
	offsets = [0 0 0];
elseif length(offsets) == 1
	offsets = [0 0 offsets];
end

if length(ratios) == 1
	ratios = [1 1 ratios];
end

if ~ischar(method)
	method = fliplr(dec2bin(method-1,3));
end

%wy
if ~exist('isLastStep','var')
	isLastStep = 0;
end

if(isLastStep)
    ext = 5;
    mSize = size(img1);
    fSize = size(imgt);
    
    yM1 = ceil(mSize(1)/2) + ext; xM1 = ceil(mSize(2)/2) + ext;
    yF1 = ceil(fSize(1)/2) + ext; xF1 = ceil(fSize(2)/2) + ext;
    imgM = img1(1:yM1, 1:xM1, :);
    imgF = imgt(1:yF1, 1:xF1, :);
    [Vy1,Vx1,Vz1] = optical_flow(method, imgM,imgF,ratios,maxiterratio,mvy,mvx,mvz,offsets);
    
    yM1 = ceil(mSize(1)/2) - ext; xM1 = ceil(mSize(2)/2) + ext;
    yF1 = ceil(fSize(1)/2) - ext; xF1 = ceil(fSize(2)/2) + ext;
    imgM = img1(yM1:end, 1:xM1, :);
    imgF = imgt(yF1:end, 1:xF1, :);
    [Vy2,Vx2,Vz2] = optical_flow(method, imgM,imgF,ratios,maxiterratio,mvy,mvx,mvz,offsets);
    
    yM1 = ceil(mSize(1)/2) + ext; xM1 = ceil(mSize(2)/2) - ext;
    yF1 = ceil(fSize(1)/2) + ext; xF1 = ceil(fSize(2)/2) - ext;
    imgM = img1(1:yM1, xM1:end, :);
    imgF = imgt(1:yF1, xF1:end, :);
    [Vy3,Vx3,Vz3] = optical_flow(method, imgM,imgF,ratios,maxiterratio,mvy,mvx,mvz,offsets);
    
    yM1 = ceil(mSize(1)/2) - ext; xM1 = ceil(mSize(2)/2) - ext;
    yF1 = ceil(fSize(1)/2) - ext; xF1 = ceil(fSize(2)/2) - ext;
    imgM = img1(yM1:end, xM1:end, :);
    imgF = imgt(yF1:end, xF1:end, :);
    [Vy4,Vx4,Vz4] = optical_flow(method, imgM,imgF,ratios,maxiterratio,mvy,mvx,mvz,offsets);
    
    Vy = [Vy1(1:end-ext-1, 1:end-ext-1, :) Vy3(1:end-ext-1, 1+ext:end, :); ...
          Vy2(1+ext:end, 1:end-ext-1, :) Vy4(1+ext:end, 1+ext:end, :)];
      
    Vx = [Vx1(1:end-ext-1, 1:end-ext-1, :) Vx3(1:end-ext-1, 1+ext:end, :); ...
          Vx2(1+ext:end, 1:end-ext-1, :) Vx4(1+ext:end, 1+ext:end, :)];
      
    Vz = [Vz1(1:end-ext-1, 1:end-ext-1, :) Vz3(1:end-ext-1, 1+ext:end, :); ...
          Vz2(1+ext:end, 1:end-ext-1, :) Vz4(1+ext:end, 1+ext:end, :)];
    
    clear Vy1 Vx1 Vz1;
    clear Vy2 Vx2 Vz2;
    clear Vy3 Vx3 Vz3;
    clear Vy4 Vx4 Vz4;
    clear imgM imgF;
        
    Vy = lowpass3d(Vy,2);
    Vx = lowpass3d(Vx,2);
    Vz = lowpass3d(Vz,2);
    
else
    [Vy,Vx,Vz] = optical_flow(method, img1,imgt,ratios,maxiterratio,mvy,mvx,mvz,offsets);
end



function [Vy,Vx,Vz] = optical_flow(method,img1,imgt,ratios,maxiterratio,mvy,mvx,mvz,offsets)

options = str2num(method');

maxiter = 10;
stop = 2e-2;

dim=mysize(imgt);
yoffs = (1:dim(1))+offsets(1);
xoffs = (1:dim(2))+offsets(2);
zoffs = (1:dim(3))+offsets(3);

Vy = zeros(dim,'single'); Vx=Vy;Vz=Vy;

if ~exist('mvx','var') || isempty(mvx)
	options(3) = 0;	% Disable divergence constraint
end

if (length(options) >= 4 && options(4) == 1)	% Intensity difference correction
	disp('Performing intensity correction ...');
	disp('Computing max img ...');
	if dim(3) > 1
		maximg1 = minmaxfilt3(img1,'max',9);
	else
		maximg1 = maxfilt2(img1,9);
	end
	
	disp('Computing min img ...');
	if dim(3) > 1
		minimg1 = minmaxfilt3(img1,'min',9);
	else
		minimg1 = minfilt2(img1,9);
	end
	diffimg1 = maximg1 - minimg1;
	clear maximg1 minimg1;

	disp('Performing the correction ...');
	diffimg1 = sqrt(diffimg1.^2+0.01);
	diffimg1 = lowpass3d(diffimg1,5);
	diffimg1 = diffimg1(yoffs,xoffs,zoffs);
end

[Iy,Ix,Iz] = gradient_3d_by_mask(single(img1));
Iy = Iy(yoffs,xoffs,zoffs)/ratios(1);
Ix = Ix(yoffs,xoffs,zoffs)/ratios(2);
Iz = Iz(yoffs,xoffs,zoffs)/ratios(3);

img1 = img1(yoffs,xoffs,zoffs);
It = single(imgt) - single(img1);

if (length(options) >= 4 && options(4) == 1)	% Intensity difference correction
	It = It ./ diffimg1;
	Iy = Iy ./ diffimg1;
	Ix = Ix ./ diffimg1;
	Iz = Iz ./ diffimg1;
	clear diffimg1;
end


if options(1) == 0	% Original Horn-Schunck method
	% Parameters
	%lambda = 0.2;
	lambda = 0.3;
	disp(sprintf('Lambda = %d',lambda));

	suma = lambda*lambda + Ix.*Ix + Iy.*Iy + Iz.*Iz;
else % Issam's modification - weighted smoothness
	% Parameters
	T = 0.05;
	lambda0 = 0.5;
	disp(sprintf('T = %d, Lambda0 = %d',T,lambda0));

	sgrad=sqrt(Ix.^2+Iy.^2+Iz.^2);
	sgrad = sgrad / max(sgrad(:));

	lambda1=lambda0/2*(1+exp(-sgrad/T));
	% initialize params...
	lambda2=lambda1.*lambda1;
	suma = lambda2+Ix.^2+Iy.^2+Iz.^2;
end

if options(2) == 1 % Combing local LMS and global smoothness
	% Computing the Gaussian mask
	Ws = single([0.0625 0.25 0.375 0.25 0.0625]);
	if dim(3) == 1
		W = ones(5,5,1,'single');
		for k=1:5
			W(k,:,:) = W(k,:,:) * Ws(k);
			W(:,k,:) = W(:,k,:) * Ws(k);
		end
	else
		W = ones(5,5,5,'single');
		for k=1:5
			W(k,:,:) = W(k,:,:) * Ws(k);
			W(:,k,:) = W(:,k,:) * Ws(k);
			W(:,:,k) = W(:,:,k) * Ws(k);
		end
	end
	W2 = W.*W;

	% Smoothing the gradient fields
	
	IyIy = conv3fft(Iy.*Iy,W2);
	IyIx = conv3fft(Iy.*Ix,W2);
	IyIz = conv3fft(Iy.*Iz,W2);
	
	IxIx = conv3fft(Ix.*Ix,W2);
	IxIz = conv3fft(Ix.*Iz,W2);
    IzIz = conv3fft(Iz.*Iz,W2);

	ItIy = conv3fft(It.*Iy,W2);
	ItIx = conv3fft(It.*Ix,W2);
	ItIz = conv3fft(It.*Iz,W2);
else
	ItIy = It.*Iy;
	ItIx = It.*Ix;
	ItIz = It.*Iz;
end

maxiter = maxiter*maxiterratio;

max_motion_per_iteration = 0.5;
%max_motion_per_iteration = 0.5;

for i=1:maxiter
	
	[Vya,Vxa,Vza]=hs_velocity_avg3d(Vy,Vx,Vz);
	
	Vy0 = Vy; Vx0 = Vx; Vz0 = Vz;
	
	if length(options) >= 3 && options(3) == 1	% Divergence constraint
		[Vyy,dummy1,dummy2] = gradient_3d_by_mask(mvy+single(Vy));
		[dummy1,Vxx,dummy2] = gradient_3d_by_mask(mvx+single(Vx));
		[dummy1,dummy2,Vzz] = gradient_3d_by_mask(mvz+single(Vz));
		[Vyyy,Vyyx,Vyyz] = gradient_3d_by_mask(single(Vyy));
		[Vxxy,Vxxx,Vxxz] = gradient_3d_by_mask(single(Vxx));
		[Vzzy,Vzzx,Vzzz] = gradient_3d_by_mask(single(Vzz));
		clear Vyy Vxx Vzz;

		lambda2 = 0.005;
% 		ItIy2 = ItIy - lambda2*(Vyyy+Vxxy+Vzzy).*img1; clear Vyyy Vxxy Vzzy;
% 		ItIx2 = ItIx - lambda2*(Vyyx+Vxxx+Vzzx).*img1; clear Vyyx Vxxx Vzzx;
% 		ItIz2 = ItIz - lambda2*(Vyyz+Vxxz+Vzzz).*img1; clear Vyyz Vxxz Vzzz;
		ItIy2 = ItIy - lambda2*(Vyyy+Vxxy+Vzzy); clear Vyyy Vxxy Vzzy;
		ItIx2 = ItIx - lambda2*(Vyyx+Vxxx+Vzzx); clear Vyyx Vxxx Vzzx;
		ItIz2 = ItIz - lambda2*(Vyyz+Vxxz+Vzzz); clear Vyyz Vxxz Vzzz;
		clear dummy*;
	else
		ItIy2 = ItIy;
		ItIx2 = ItIx;
		ItIz2 = ItIz;
	end

	if options(2) == 1
		Vy = Vya - 10*(Vya.*IyIy + Vxa.*IyIx + Vza.*IyIz + ItIy2) ./ suma;
		Vx = Vxa - 10*(Vya.*IyIx + Vxa.*IxIx + Vza.*IxIz + ItIx2) ./ suma;
		Vz = Vza - 10*(Vya.*IyIz + Vxa.*IxIz + Vza.*IzIz + ItIz2) ./ suma;
	else
		sumb = Iy.*Vya + Ix.*Vxa + Iz.*Vza;
		Vy = Vya-(Iy.*sumb+ItIy2)./suma;
		Vx = Vxa-(Ix.*sumb+ItIx2)./suma;
		Vz = Vza-(Iz.*sumb+ItIz2)./suma;
	end
	
	
	% Limit the motion field update per iteration
	dV = sqrt(abs(Vy0 - Vy).^2 + abs(Vx0-Vx).^2 + abs(Vz0-Vz).^2);
	if max(dV(:)) > max_motion_per_iteration
		dVy = Vy - Vy0;
		dVx = Vx - Vx0;
		dVz = Vz - Vz0;
		idxes = find( dV > max_motion_per_iteration );
		dVy(idxes) = dVy(idxes) * max_motion_per_iteration ./ dV(idxes);
		dVx(idxes) = dVx(idxes) * max_motion_per_iteration ./ dV(idxes);
		dVz(idxes) = dVz(idxes) * max_motion_per_iteration ./ dV(idxes);
		Vy(idxes) = Vy0(idxes)+dVy(idxes);
		Vx(idxes) = Vx0(idxes)+dVx(idxes);
		Vz(idxes) = Vz0(idxes)+dVz(idxes);
		dV(idxes) = max_motion_per_iteration;
		clear dVy dVx dVz idxes;
	end
	
		
	clear Vy0 Vx0 Vz0;
	maxv = max(dV(:));
	disp(sprintf('Iteration %d: max movement: %d',i,maxv));
	
	if maxv <= stop
		break;
	end
	
end




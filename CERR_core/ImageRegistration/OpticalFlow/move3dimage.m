function newimg = move3dimage(img,Vy,Vx,Vz,method,offsets,jacobian_modulation)
%
% Calculate the moved image: 
%    newimg = move3dimage3(img,Vy,Vx,Vz,method,offsets)
%
% Input: 
%	Vy, Vx, Vz	- the motion field
%	method		- interpolation method, default value is 'linear'
%   zoffset		- Offset of Z for the motion field dimension respective to
%				  the img dimension
%
% In version 3, the input method is allowed to be larger than the dimension
% of motion fields. This actually allows better recostruction of the moved
% images because the motion fields could extend larger than the original
% dimension. An additional parameter has been added, the 'offsets'
% parameter.
% 
%
if ~exist('method','var') || isempty(method)
	method = 'linear';
end

if ~exist('offsets','var') || isempty(offsets)
	offsets = [0 0 0];
elseif length(offsets) == 1
	offsets = [0 0 offsets];
end

if ~exist('jacobian_modulation','var') || isempty(jacobian_modulation)
	jacobian_modulation = 0;
end

% Computer Jacobian
if jacobian_modulation ~= 0
	jac = compute_jacobian(Vy,Vx,Vz);
end

dimimg = mysize(img);
dimmotion = mysize(Vy);
x0 = single([1:dimmotion(2)])+offsets(2);
y0 = single([1:dimmotion(1)])+offsets(1);
z0 = single([1:dimmotion(3)])+offsets(3);
[xx,yy,zz] = meshgrid(x0,y0,z0);	% xx, yy and zz are the original coordinates of image pixels

Vy = max((yy-Vy),1); clear yy; Vy = min(Vy,dimimg(1)); 
Vx = max((xx-Vx),1); clear xx; Vx = min(Vx,dimimg(2));
Vz = max((zz-Vz),1); clear zz; Vz = min(Vz,dimimg(3));

if dimimg(3) > 1
	newimg = zeros(dimmotion,'single');
	if offsets(3) == 0 && size(img,3) == size(Vy,3)
		spacing = 20;
		if mod(dimimg(3),spacing) == 1
			spacing = 19;
		end
		
		N = ceil(dimimg(3)/spacing);
		fprintf('Moving image');
		for k = 1:N
			fprintf('.');
			zmin = (k-1)*spacing+1;
			zmax = min(dimimg(3),k*spacing);
			zmin2 = floor(min(min(min(Vz(:,:,zmin:zmax)))));
			zmax2 = ceil(max(max(max(Vz(:,:,zmin:zmax)))));
			%newimg(:,:,zmin:zmax) = interp3(xx(:,:,zmin2:zmax2),yy(:,:,zmin2:zmax2),zz(:,:,zmin2:zmax2),img(:,:,zmin2:zmax2),Vx(:,:,zmin:zmax),Vy(:,:,zmin:zmax),Vz(:,:,zmin:zmax),method);
			newimg(:,:,zmin:zmax) = interp3(x0,y0,z0(zmin2:zmax2),img(:,:,zmin2:zmax2),Vx(:,:,zmin:zmax),Vy(:,:,zmin:zmax),Vz(:,:,zmin:zmax),method);
		end
		fprintf('\n');
	else
		newimg = interp3(img,Vx,Vy,Vz,method,0);
	end
	%newimg = interp3(img,Vx,Vy,Vz,method,0);
else
	newimg = interp2(img,Vx,Vy,method,0);
end

%newimg = interpn(img,yy-Vy,xx-Vx,zz-Vz,method,0);


if jacobian_modulation ~= 0
	% Apply Jacobin intensity modulation
	jac(isinf(jac)) = 1;
	jac(jac<0) = 1;
	newimg = newimg .* jac;
end

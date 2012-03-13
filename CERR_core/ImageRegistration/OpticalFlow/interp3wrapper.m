function out = interp3wrapper(x,y,z,v,xi,yi,zi,method,exterpval,limitelem)
%
% out = interp3wrapper(x,y,z,v,xi,yi,zi,method,exterpval,limitelem)
%
dim = size(xi);
t = prod(dim);

if ndims(x) == 3
	% We don't need x y z to be a whole 3D matrix
	x = squeeze(x(1,:,1));
	y = squeeze(y(:,1,1));
	z = squeeze(z(1,1,:));
end


if( ~exist('limitelem','var') || isempty(limitelem) )
	limitelem = 200*200*50;
end

if t <= limitelem || ndims(xi) == 2 
	if exist('exterpval','var') && ~isempty(exterpval) 
		out = interp3(x,y,z,v,xi,yi,zi,method,exterpval);
	else
		out = interp3(x,y,z,v,xi,yi,zi,method);
	end
	return;
end

N = ceil( t / limitelem );
spacing = max(floor(dim(3)/N),2);
N = ceil(dim(3)/spacing);

%fprintf('Interp3wrapper ');
for k = 1:N
	%fprintf('.');
	zmin = (k-1)*spacing+1;
	zmax = min(dim(3),k*spacing);
	
	zmin2 = min(min(min(zi(:,:,zmin:zmax))));
	zmax2 = max(max(max(zi(:,:,zmin:zmax))));
	zminidx = find(z<zmin2,1,'last'); 
	if isempty(zminidx)
		zminidx = 1;
	end
	zmaxidx = find(z>zmax2,1,'first'); 
	if isempty(zmaxidx)
		zmaxidx = length(z);
	end
	if zmaxidx == zminidx
		if zmaxidx >= length(z)
			zminidx = zminidx-1;
		else
			zmaxidx = zmaxidx+1;
		end
	end
	
	xmin2 = min(min(min(xi(:,:,zmin:zmax))));
	xmax2 = max(max(max(xi(:,:,zmin:zmax))));
	xminidx = find(x<xmin2,1,'last'); 
	if isempty(xminidx)
		xminidx = 1;
	end
	xmaxidx = find(x>xmax2,1,'first'); 
	if isempty(xmaxidx)
		xmaxidx = length(x);
	end
	
	ymin2 = min(min(min(yi(:,:,zmin:zmax))));
	ymax2 = max(max(max(yi(:,:,zmin:zmax))));
	yminidx = find(y<ymin2,1,'last'); 
	if isempty(yminidx)
		yminidx = 1;
	end
	ymaxidx = find(y>ymax2,1,'first'); 
	if isempty(ymaxidx)
		ymaxidx = length(y);
	end
	
	if exist('exterpval','var') && ~isempty(exterpval) 
		out(:,:,zmin:zmax) = interp3(x(xminidx:xmaxidx),y(yminidx:ymaxidx),z(zminidx:zmaxidx),v(yminidx:ymaxidx,xminidx:xmaxidx,zminidx:zmaxidx),xi(:,:,zmin:zmax),yi(:,:,zmin:zmax),zi(:,:,zmin:zmax),method,exterpval);
	else
		out(:,:,zmin:zmax) = interp3(x(xminidx:xmaxidx),y(yminidx:ymaxidx),z(zminidx:zmaxidx),v(yminidx:ymaxidx,xminidx:xmaxidx,zminidx:zmaxidx),xi(:,:,zmin:zmax),yi(:,:,zmin:zmax),zi(:,:,zmin:zmax),method);
	end
end
%fprintf('\n');



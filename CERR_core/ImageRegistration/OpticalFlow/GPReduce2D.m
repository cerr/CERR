%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reduce an image applying Gaussian Pyramid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IResult = GPReduce2D(I,displayflag)

if ~exist('displayflag','var')
	displayflag = 0;
end

dim = size(I);
if length(dim) == 2
	IResult = GPReduce(I);
	return;
end

if displayflag == 1
	H = waitbar(0,'Progress');
	set(H,'Name','GPReduce ...');
end

for k=1:dim(3)
	if displayflag == 1
		waitbar((k-1)/dim(3),H,sprintf('(%d%%) %d out of %d',round((k-1)/dim(3)*100),k-1,dim(3)));
	else
		fprintf('.');
	end
	IResult(:,:,k) = GPReduce(squeeze(I(:,:,k)));
end

if displayflag == 1
	close(H);
else
	fprintf('\n');
end


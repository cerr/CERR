%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reduce an image applying Gaussian Pyramid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IResult = GPReduce(I,displayflag)

if ~exist('displayflag','var')
	displayflag = 1;
end

Wt = [0.0500    0.2500    0.4000    0.2500    0.0500];

dim = size(I);
newdim = ceil(dim*0.5);
IResult = zeros(newdim,class(I)); % Initialize the array in the beginning ..
I = single(I);
m = [-2:2];n=m;

switch length(dim)
	case 1
		%% Pad the boundaries.
		I = [ I(1) ; I(1) ;  I ; I(dim(1));  I(dim(1)) ];  % Add two rows towards the beginning and the end.
		for i = 0 : newdim(1) -1
			A = I(2*i+m+3).*Wt;;
			IResult(i + 1)= sum(A(:));
		end
	case 2
		%% Pad the boundaries.
		I = [ I(1,:) ; I(1,:) ;  I ; I(dim(1),:);  I(dim(1),:) ];  % Add two rows towards the beginning and the end.
		I = [ I(:,1)  I(:,1)     I   I(:,dim(2))  I(:,dim(2)) ];  % Add two columns towards the beginning and the end.
		
		Wt2 = Wt'*Wt;
		
		for i = 0 : newdim(1) -1
			for j = 0 : newdim(2) -1
				A = I(2*i+m+3,2*j+m+3).*Wt2;
				IResult(i + 1, j + 1) = sum(A(:));
			end
		end

	case 3
		Wt3 = ones(5,5,5);
		for i = 1:5
			Wt3(i,:,:) = Wt3(i,:,:) * Wt(i);
			Wt3(:,i,:) = Wt3(:,i,:) * Wt(i);
			Wt3(:,:,i) = Wt3(:,:,i) * Wt(i);
		end
		
		%% Pad the boundaries.
		I2 = zeros(dim+4,class(I));
		I2(3:2+dim(1),3:2+dim(2),3:2+dim(3)) = I;
		I2(1,:,:)=I2(3,:,:);I2(1,:,:)=I2(3,:,:);I2(end,:,:)=I2(end-2,:,:);I2(end-1,:,:)=I2(end-2,:,:);
		I2(:,1,:)=I2(:,3,:);I2(:,2,:)=I2(:,3,:);I2(:,end,:)=I2(:,end-2,:);I2(:,end-1,:)=I2(:,end-2,:);
		I2(:,:,1)=I2(:,:,3);I2(:,:,2)=I2(:,:,3);I2(:,:,end)=I2(:,:,end-2);I2(:,:,end-1)=I2(:,:,end-2);
		I=I2; clear I2;

		if( displayflag==1) 
			H = waitbar(0,'Progress');
			set(H,'Name','GPReduce ...');
		end
		for k = 0 : newdim(3) - 1
			if( displayflag==1)
				waitbar(k/newdim(3),H,sprintf('(%d%%) %d out of %d',round(k/newdim(3)*100),k,newdim(3)));
			else
				fprintf('.');
			end
			for j = 0 : newdim(2) -1
				for i = 0 : newdim(1) -1
					A = I(2*i+m+3,2*j+m+3,2*k+m+3).*Wt3;
					IResult(i+1,j+1,k+1) = sum(A(:));
				end
			end
		end
		if( displayflag==1) 
			close(H);
		else
			fprintf('\n');
		end
end


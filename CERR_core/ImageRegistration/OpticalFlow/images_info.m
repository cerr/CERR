function varargout = images_info(im1, im2, varargin)
%
% Function res = calc_images(im1, im2, types)
% Function res = calc_images(im1, im2, mask, types)
%
% Compututation for two 2D or 3D images
%
%	Input:
%			im1		-	image 1
%			im2		-	image 2
%
%			type = 1, 'NMI'		:	to calculate mutual information
%								:	NMI = (H(A)+H(B))/H(A,B)
%			type = 2, 'entropy'	:	jointed entropy
%			type = 3, 'CC'		:	to calculate crosscorelation
%			type = 4, 'MSE'		:	mean of square errors
%			type = 5, 'MI'		:	MI = H(A) + H(B) - H(A,B)
%			type = 6, 'MI3'		:	MI3 = MI / (H(A)+H(B))
%			type = 7, 'CC2'		:
%			type = 8, 'COV'		:	Covariance
%
%
%  implemented by:
%		Deshan Yang
%		Washington University in St Louis
%		07/2006
%

siz1 = size(im1);

% Normalize the intensity for both images
im1 = single(im1);
im2 = single(im2);

mask = varargin{1};
if ischar(mask)
	mask = ones(size(im1));
else
	if ~isequal(size(mask),size(im1))
		error(1,'Wrong array size for mask.');
	end
	varargin = varargin(2:end);
end

im1(mask==0) = NaN;
im2(mask==0) = NaN;

if ~isempty(find(isnan(im1),1)) && ~isempty(find(isnan(im2),1))
	goodidxes = find((~isnan(im1)) & (~isnan(im2)));
	im1 = im1(goodidxes);
	im2 = im2(goodidxes);
end

N = 256;
maxv = max(max(im1(:)),max(im2(:)));
im1b = round(im1 / maxv * (N-1));
im2b = round(im2 / maxv * (N-1));

jh = [];

for k = 1:length(varargin)
	type = varargin{k};

	switch( type )
		case {1,5,'MI','NMI',6,'MI3'}	% Mutual information
			%res = information(im1(:)',im2(:)');

			if isempty(jh)
				jh=joint_h(im1b,im2b,N); % calculating joint histogram for two images
			end
			
			[r,c] = size(jh);
			%b= jh./(r*c); % normalized joint histogram
			b= jh/sum(jh(:)); % normalized joint histogram
			y_marg=sum(b); %sum of the rows of normalized joint histogram
			x_marg=sum(b');%sum of columns of normalized joint histogran

			Hy=0;
			for i=1:c;    %  col
				if( y_marg(i)==0 )
					%do nothing
				else
					Hy = Hy + -(y_marg(i)*(log2(y_marg(i)))); %marginal entropy for image 1
				end
			end

			Hx=0;
			for i=1:r;    %rows
				if( x_marg(i)==0 )
					%do nothing
				else
					Hx = Hx + -(x_marg(i)*(log2(x_marg(i)))); %marginal entropy for image 2
				end
			end
			h_xy = -sum(sum(b.*(log2(b+(b==0))))); % joint entropy

			switch type
				case {1,'NMI'}
					res = (Hx + Hy)/h_xy;% Mutual information
					%res = MI2(im1,im2,'Normalized',N);
				otherwise
					%res = MI2(im1,im2,[],N);
					res = Hx + Hy - h_xy;
			end


			% 		jhist = joint_hist(im1,im2,N);
			%
			% 		jhist_log = zeros(N*N,1);
			% 		idx_good = find(jhist~=0);
			% 		jhist_log(idx_good) = log2(jhist(idx_good));
			% 		HAB = -sum(jhist_log(idx_good).*jhist(idx_good));
			%
			%  		HA = entropy_nan(im1b);
			%  		HB = entropy_nan(im2b);
			%
			% 		NMI = (HA+HB)/HAB;		% The mutual information
			% 		MI = HA + HB - HAB;
			% 		MI3 = MI / (HA+HB);
			%
			% 		switch type
			% 			case {1,'NMI'}
			% 				res = NMI;
			% 			case {5, 'MI'}
			% 				res = MI;
			% 			case {6, 'MI3'}
			% 				res = MI3;
			% 		end

		case {2,'entropy'}	% jointed entropy
			jhist_log = zeros(256*256,1);
			idx_good = find(jh~=0);
			jhist_log(idx_good) = log2(jh(idx_good));
			res = -sum(jhist_log(idx_good).*jh(idx_good));

		case {3,'CC',}	% Calculate the cross-correlation
			im1 = im1-mean(im1(:));
			im2 = im2-mean(im2(:));

			res = sum(im1(:).*im2(:)) / sqrt( sum(im1(:).^2) * sum(im2(:).^2));
		case {4,'MSE'}
			e = (single(im1 - im2)).^2;
			res = sqrt(mean(e(:)));
		case {7,'CC2'}
			res =	(mean(im1(:).*im2(:))-mean(im1(:))*mean(im2(:))) / sqrt(mean(im1(:).^2)-mean(im1(:)).^2) ...
				/ sqrt(mean(im2(:).^2)-mean(im2(:)).^2);
		case {8,'COV'}
			res = mean((im1(:)-mean(im1(:))).*(im2(:)-mean(im2(:))));
	end


	varargout{k} = res;
end






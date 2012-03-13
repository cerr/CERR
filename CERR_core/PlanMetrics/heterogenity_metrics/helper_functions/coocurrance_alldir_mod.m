function Ph=coocurrance_alldir(q)
%
% function Ph=coocurrance_alldir(q)
%
% To compute the co-ocurrance matrix regardless the directionality
%%
dim=size(q);
if ndims(q) == 2
	dim(3) = 1;
end

q2 = reshape(q,1,prod(dim));
qs = unique(q2);
q3 = q2*0;

for k = 1:length(qs)
	q3(q2==qs(k)) = k;
end

q3 = reshape(q3,dim);

lqs=length(qs);
Ph=zeros(lqs);

maxq3 = max(q3(:));

similarity = nan(size(q3));

for i = 1:dim(1)
	for j = 1:dim(2)
		for k = 1:dim(3)
			val_q3 = q3(i,j,k);
			i_min = max(1,i-1);
			i_max = min(i+1,dim(1));
			j_min = max(1,j-1);
			j_max = min(j+1,dim(2));
			k_min = max(1,k-1);
			k_max = min(k+1,dim(3));
			
            V = (i_max-i_min+1)*(j_max-j_min+1)*(k_max-k_min+1);
			
			neighbor = q3(i_min:i_max,j_min:j_max,k_min:k_max);
			good_neighbor = neighbor(neighbor~=maxq3);
			
			if length(good_neighbor) > 0 && val_q3 ~= maxq3
				meanneighbor = mean(good_neighbor);
				similarity(i,j,k) = abs(meanneighbor-val_q3);
			end

			for I2 = i_min:i_max
				for J2 = j_min:j_max
					for K2 = k_min:k_max
						if I2 == i && J2 == j && K2 == k
							continue;
						else
							val_neighbor = q3(I2,J2,K2);
							Ph(val_q3,val_neighbor) = Ph(val_q3,val_neighbor) + 1;
							%Ph(val_neighbor,val_q3) = Ph(val_neighbor,val_q3) + 1;
						end
					end
				end
			end
		end
	end
end


mean(similarity(~isnan(similarity)));

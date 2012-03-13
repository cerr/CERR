function [ua,va,wa]=hs_velocity_avg3d(u,v,w)
% compute the average velocities in nbh of size WxWxW
% no weighting?! add it? cross/pus?
[M,N,L]=size(u);
WS=3; % 27th neighborhood...

Lxy = floor(WS/2);
vec=-Lxy:Lxy;
% 3D laplacian (2*6x+20=1)
if L == 1
	W3 = 1/12*ones(WS,WS,1);
	W3(1,2,1)=1/6;W3(2,1,1)=1/6;W3(2,3,1)=1/6;W3(3,2,1)=1/6;
	W3(2,2,1)=0;
else
	W3=1/32*ones(WS,WS,WS);
	W3([1,3],2,2)=1/16; W3(2,[1,3],2)=1/16; W3(2,2,[1,3])=1/16;
	W3(2,2,2)=0;
end


mm = 1:M;
nn = 1:N;
kk = 1:L;

ua = zeros(size(u));
va = ua;
wa = ua;

K=3; if (L==1) K=1; end

for m = 1:3
	for n = 1:3
		for k = 1:K
			mm1 = mm + m - 2; mm1 = max(mm1,1); mm1 = min(mm1,M);
			nn1 = nn + n - 2; nn1 = max(nn1,1); nn1 = min(nn1,N);
			kk1 = kk + k - 2; kk1 = max(kk1,1); kk1 = min(kk1,L);
			ua = ua + u(mm1,nn1,kk1)*W3(m,n,k);
			va = va + v(mm1,nn1,kk1)*W3(m,n,k);
			wa = wa + w(mm1,nn1,kk1)*W3(m,n,k);
		end
	end
end

% ua=convn(u,W3,'same'); % check padding...
% clear u
% va=convn(v,W3,'same');
% clear v
% wa=convn(w,W3,'same');
% clear w
return

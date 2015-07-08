function [f,Ph]=haralick3D(x,nL)
% Haralick textures measurements
[mx nx]=size(x);
q=imquantize_cerr(x,nL);
qmax=max(q(:));
nanFlag = 0;
if any(isnan(q(:)))
    nanFlag = 1;
    q(isnan(q))=qmax+1;
end
qs=sort(unique(q));
lq=length(qs);
[f,Ph]=haralick_n_mod(qs,lq,q,nanFlag);
return



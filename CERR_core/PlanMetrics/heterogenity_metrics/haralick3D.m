function [f,Ph]=haralick3D(x,nL)
% Haralick textures measurements
[mx nx]=size(x);
q=imquantize(x,nL);
qmax=max(q(:));
q(isnan(q))=qmax+1;
qs=sort(unique(q));
lq=length(qs);
[f,Ph]=haralick_n_mod(qs,lq,q);
return



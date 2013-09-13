function [f,Ph]=haralick3D(x,nL)
% Haralick textures measurements
[mx nx]=size(x);
q=imquantize_cerr(x,nL);
qmax=max(q(:));
%q(isnan(q))=qmax+1;
q = q(~isnan(q)); 
qs=sort(unique(q));
lq=length(qs);
[f,Ph]=haralick_n_mod(qs,lq,q);
return



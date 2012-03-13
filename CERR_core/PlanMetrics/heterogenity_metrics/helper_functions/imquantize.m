function q=imquantize(x,L)
% image quantization 
xmax=max(x(:));
xmin=min(x(:));
range=xmax-xmin;
scale=(L-1)/range;
q=round(x*scale)/scale;
return
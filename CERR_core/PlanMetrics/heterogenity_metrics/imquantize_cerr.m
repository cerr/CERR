function q=imquantize_cerr(x,L)
% image quantization 
x01 = quantile(x(:),0.01);
x99 = quantile(x(:),0.99);
x(x<x01) = x01;
x(x>x99) = x99;
xmax=max(x(:));
xmin=min(x(:));
range=xmax-xmin;
scale=(L-1)/range;
q=round(x*scale)/scale;
return
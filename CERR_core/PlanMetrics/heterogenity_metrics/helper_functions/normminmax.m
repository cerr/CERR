function y=normminmax(x)
% bulld RBG image
xmin=min(x(:));
xmax=max(x(:));
y=(x-xmin)/(xmax -xmin);
return

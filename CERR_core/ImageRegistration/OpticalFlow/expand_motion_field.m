function [mvy2,mvx2,mvz2]=expand_motion_field(mvy,mvx,mvz,newdim,offsets)

if length(offsets) == 1
	offsets = [0 0 offsets];
end

mvy2=zeros(newdim,class(mvy));
mvx2 = mvy2;
mvz2 = mvy2;

dim = size(mvy);
ub = dim+offsets;

ys = 1:newdim(1); ys2 = ys-offsets(1); ys2(ys2<1) = 1; ys2(ys2>dim(1)) = dim(1);
xs = 1:newdim(2); xs2 = xs-offsets(2); xs2(xs2<1) = 1; xs2(xs2>dim(2)) = dim(2);
zs = 1:newdim(3); zs2 = zs-offsets(3); zs2(zs2<1) = 1; zs2(zs2>dim(3)) = dim(3);

mvy2(ys,xs,zs) = mvy(ys2,xs2,zs2);
mvx2(ys,xs,zs) = mvx(ys2,xs2,zs2);
mvz2(ys,xs,zs) = mvz(ys2,xs2,zs2);

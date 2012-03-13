function out = conv3fft(z1,z2)

z1 = single(z1);
z2 = single(z2);

siz1 = size(z1);
siz2 = size(z2);
siz = siz1+siz2-1;

z1x=size(z1,1);
z1y=size(z1,2);
z2x=size(z2,1);
z2y=size(z2,2);

out=real(ifftn(fftn(z1,siz).*fftn(z2,siz)));

p = ((siz2-1)+mod((siz2-1),2))/2;

out=out(p(1)+1:p(1)+siz1(1),p(2)+1:p(2)+siz1(2),p(3)+1:p(3)+siz1(3));

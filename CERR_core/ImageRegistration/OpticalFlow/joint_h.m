function h=joint_h(im1,im2,N)
% function h=joint_h(im1,im2,N=256)
%
% takes a pair of images of equal size and returns the 2d joint histogram.
% used for MI calculation
% 
% written by http://www.flash.net/~strider2/matlab.htm

if ~exist('N','var')
	N = 256;
end

rows=size(im1,1);
cols=size(im1,2);

h=zeros(N,N);

for i=1:rows;    %  col 
  for j=1:cols;   %   rows
    h(im1(i,j)+1,im2(i,j)+1)= h(im1(i,j)+1,im2(i,j)+1)+1;
  end
end
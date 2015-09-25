function v=blinnblob(centers,nx,ny,nz)
% Blinn's blobs
%
% Make something vaguely benzene like as follows:
%
% centers=[20+8*cos(theta);20+8*sin(theta);20+zeros(1,6)]'
% v=blob(centers,40,40,40)
% isosurface(v,.125)

% Written by Mike Garrity
% Copyright 2002 The MathWorks Inc
%
% From ACM Transactions on Graphics, July 1982, Volume 1, Number 3.
% "A Generalization of A;gebraic Surface Drawing" James F. Blinn

    x=makeXMat(nx,ny,nz);
    y=makeYMat(nx,ny,nz);
    z=makeZMat(nx,ny,nz);
    
    a=.05;
    b=1;
    
    numCenters=size(centers,1);
    v=zeros(nx,ny,nz);
    for i=1:numCenters
        dx=centers(i,1)-x;
        dy=centers(i,2)-y;
        dz=centers(i,3)-z;
        
        v=v+b*exp(-a*(dx.^2 + dy.^2 + dz.^2));
    end
    
function x=makeXMat(nx,ny,nz)
    x=repmat([1:ny],[nx 1 nz]);
    
function y=makeYMat(nx,ny,nz)
    y=repmat([1:nx]',[1 ny nz]);
    
function z=makeZMat(nx,ny,nz)
    z=repmat([1:nz],nx*ny,1);
    z=reshape(z,[nx ny nz]);

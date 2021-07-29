function param = paraminit(rho0,rho1,dim,h,gamma)
% Initialize parameters
% dim, h, gamma, D, A1, A2

n  = dim(1);
nx = dim(2);
ny = dim(3);
nz = dim(4);
nt = dim(5);
hx = h(1);
hy = h(2);
hz = h(3);
ht = h(4);
% reshape rho0 rho1

rho0 = reshape(rho0,[nx,ny,nz,n]);
rho1 = reshape(rho1,[nx,ny,nz,n]);
rho0 = permute(rho0,[4,1,2,3]);
rho1 = permute(rho1,[4,1,2,3]);
% graph divergence operator D3

% F2     = [1 0 0;1 0 0;0 1 0]';
% F1     = [0 1 0;0 0 1;0 0 1]';

% F2     = [1 0 0;0 1 0]';
% F1     = [0 1 0;0 0 1]';
F2     = [1 0]';
F1     = [0 1]';

F      = F2-F1;
m=size(F,2);
W      = eye(m);
divF0  = -F*W^(1/2);
divF0  = sparse(divF0);
D3     = kron(speye(nx*ny*nz*nt),divF0);

% average operators
Axx   = toeplitz([1/2 1/2 sparse(1,nx-2)],[1/2 sparse(1,nx-2)]);
A1x   = kron(kron(speye(ny*nz*nt),Axx),speye(n));
Ayy   = toeplitz([1/2 1/2 sparse(1,ny-2)],[1/2 sparse(1,ny-2)]);
A1y   = kron(kron(speye(nt*nz),Ayy),speye(n*nx));
Azz   = toeplitz([1/2 1/2 sparse(1,nz-2)],[1/2 sparse(1,nz-2)]);
A1z   = kron(kron(speye(nt),Azz),speye(n*nx*ny));


At    = toeplitz([1/2 1/2 sparse(1,nt-2)],[1/2 sparse(1,nt-2)]);
A2    = kron(At,speye(n*nx*ny*nz));
A3    = kron(At,speye(m*nx*ny*nz));
% define divergence operators D1 D2 D3
ddx   = @(n,h) (1/h)*spdiags(ones(n,1)*[-1,1],[-1,0],n,n-1);

% divergence operator D1 over x
D1x    = kron(kron(speye(ny*nz*nt),ddx(nx,hx)),speye(n));

% divergence operator D1 over y
D1y    = kron(kron(speye(nz*nt),ddx(ny,hy)),speye(n*nx));

% divergence operator D1 over z
D1z    = kron(kron(speye(nt),ddx(nz,hz)),speye(n*nx*ny));

% divergence operator D2 over t
D2    = kron(ddx(nt,ht),speye(n*nx*ny*nz));

% divergnece operator D
D  = [D1x D1y D1z D2 D3];

% initialize a and b
a = zeros(n,nx,ny,nz,nt);
for i = 1:nx
    for j = 1:ny
        for k=1:nz
            a(:,i,j,k,1)  = 1./rho0(:,i,j,k)./2;
            a(:,i,j,k,nt) = 1./rho1(:,i,j,k)./2;
        end
    end
end

b = zeros(n,nx,ny,nz,nt);
for i = 1:nx
    for j = 1:ny
        for k=1:nz
            b(:,i,j,k,1)  = rho0(:,i,j,k)./ht;
            b(:,i,j,k,nt) = -rho1(:,i,j,k)./ht;
        end
    end
end

c = zeros(m,nx,ny,nz,nt);
for i = 1:nx
    for j = 1:ny
        for k = 1:nz
            c(:,i,j,k,1)  = 1/2./(F2'*rho0(:,i,j,k));%+1/2./(F1'*rho0(:,i,j,k));
            c(:,i,j,k,nt) = 1/2./(F2'*rho1(:,i,j,k));%+1/2./(F1'*rho1(:,i,j,k));
        end
    end
end

F1 = kron(speye(nx*ny*nz*(nt-1)),F1);
F2 = kron(speye(nx*ny*nz*(nt-1)),F2);

% initialize parameters
param.dim   = dim;
param.m     = m;
param.h     = h;
param.gamma = gamma;
param.A1x   = A1x;
param.A1y   = A1y;
param.A1z   = A1z;
param.A2    = A2;
param.A3    = A3;
param.D     = D;
param.F1    = F1;
param.F2    = F2;
param.a     = a;
param.b     = b;
param.c     = c;

end


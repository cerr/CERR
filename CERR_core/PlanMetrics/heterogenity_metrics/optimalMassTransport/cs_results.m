function [cost,source] = cs_results(px,py,pz,rho,u,param)

e=1e-6;

h     = param.h;
dim   = param.dim;
gamma = param.gamma;
A1x   = param.A1x;
A1y   = param.A1y;
A1z   = param.A1z;
A2    = param.A2;
A3    = param.A3;
a     = param.a;
c     = param.c;
F1    = param.F1;
F2    = param.F2;

n  = dim(1);
nx = dim(2);
ny = dim(3);
nz = dim(4);
nt = dim(5);
hx = h(1);
hy = h(2);
hz = h(3);
ht = h(4);


%compute p^2 and u^2

pxsq  = px.^2;
pysq  = py.^2;
pzsq  = pz.^2;
usq   = u.^2;

% inverse of rho
rhoinv  = 1./rho;
rhoinv2 = 1./(F2'*rho(:));

E=eye(n);
E(n,n)=e;
W1=kron(speye((nx-1)*ny*nz*nt),E);
W2=kron(speye((ny-1)*nx*nz*nt),E);
W3=kron(speye((nz-1)*nx*ny*nt),E);

% cost f
cost = (A1x*W1*pxsq(:)+A1y*W2*pysq(:)+A1z*W3*pzsq(:))'*(A2*rhoinv(:) + a(:))*hx*hy*hz*ht + usq(:)'*(A3*rhoinv2(:)+ c(:))*hx*hy*hz*ht*gamma;
source=usq(:)'*(A3*rhoinv2(:)+ c(:))*hx*hy*hz*ht;
end


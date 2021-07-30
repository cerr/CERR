function c = phi1(costgradf,w,param,mu)
% compute c=cost+mu*dual error
D    = param.D;
b    = param.b;
dim  = param.dim;
h    = param.h;
m    = param.m;
n  = dim(1);
nx = dim(2);
ny = dim(3);
nz = dim(4);
nt = dim(5);
hx = h(1);
hy = h(2);
hz = h(3);
ht = h(4);

px              = w(1:n*(nx-1)*ny*nz*nt);
py              = w((n*(nx-1)*ny*nt*nz+1):(n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt));
pz              = w((n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt)+1:(n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt+n*nx*ny*(nz-1)*nt));
rho             = w((n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt+n*nx*ny*(nz-1)*nt)+1:...
                       (n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt+n*nx*ny*(nz-1)*nt+n*nx*ny*nz*(nt-1)));
u               = w((end-m*nx*ny*nz*nt+1):end);
c    = costgradf(px,py,pz,rho,u,param)/hx/hy/hz/ht;
c    = c + mu*sum(abs(D*w-b(:)));
end

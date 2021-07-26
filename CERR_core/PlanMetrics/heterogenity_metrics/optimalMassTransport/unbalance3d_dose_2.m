function [c,s,px,py,pz,rho,u,lambda] = unbalance3d_dose_2( source,target,gamma,H,reverse)

layer1=0.4;
layer2=1.0;

%profile on;
%% Input
%Source/Target

%load('deformedDoseOutputForLung_490pts_new/doseGrid.mat');
% Parameters
[nx,ny,nz]=size(source);
Hx=H.Hx;
Hy=H.Hy;
Hz=H.Hz;
% Hx=abs(xDoseV(length(xDoseV))-xDoseV(1))/10;
% Hy=abs(yDoseV(length(yDoseV))-yDoseV(1))/10;
% Hz=abs(zDoseV(length(zDoseV))-zDoseV(1))/10;

n=2;
nt    = 10;
hx    = Hx/nx;
hy    = Hy/ny;
hz    = Hz/nz;
ht    = 1/nt;


%% Input Normalization
source=double(source);
target=double(target);
if reverse=='r'
    source=255-source;
    target=255-target;
end
tr0  = sum(source(:));
tr1  = sum(target(:));
source = source+tr0/nx/ny/nz/15;
target = target+tr0/nx/ny/nz/15;

g=0;
g0=g+tr1/nx/ny/nz;
g1=g+tr0/nx/ny/nz;

rho0=g0*ones([size(source),2]);
rho0(:,:,:,1) = source;
rho1=g1*ones([size(target),2]);
rho1(:,:,:,1) = target;

%% Parameters Initialization
dim   = [n,nx,ny,nz,nt];
dim1=[n,round(nx*layer1),round(ny*layer1),round(nz*layer1),nt];
h     = [hx,hy,hz,ht];
h1=[Hx/dim1(2),Hy/dim1(3),Hz/dim1(4),ht];
param = paraminit(rho0(:),rho1(:),dim,h,gamma);
param1 = paraminit(resample3d(rho0,dim1(2),dim1(3),dim1(4)),resample3d(rho1,dim1(2),dim1(3),dim1(4)),dim1,h1,gamma);
m=param.m;
%% Set initial values for p rho u
px1     = zeros(n,dim1(2)-1,dim1(3),dim1(4),nt);
py1     = zeros(n,dim1(2),dim1(3)-1,dim1(4),nt);
pz1     = zeros(n,dim1(2),dim1(3),dim1(4)-1,nt);
u1      = zeros(m,dim1(2),dim1(3),dim1(4),nt);

tc=linspace(ht*3/2,1-ht/2,nt-1);
rho0_1=resample3d(rho0,dim1(2),dim1(3),dim1(4));
rho1_1=resample3d(rho1,dim1(2),dim1(3),dim1(4));
rho_1=ones(1,nt-1).*rho0_1(:)+tc.*(rho1_1(:)-rho0_1(:));

lambda1=zeros(dim1);
% initial values
init1.px     = px1;
init1.py     = py1;
init1.pz     = pz1;
init1.rho    = rho_1;
init1.u      = u1;
init1.lambda=lambda1;
%% iterations
max_iter=30;
tic
[px1,py1,pz1,rho_1,u1,lambda1,errorhist1] = SQPOPT(@(px,py,pz,rho,u,param) costgradf(px,py,pz,rho,u,param),init1,max_iter,param1);
toc
optcost=errorhist1(end,1);
iter_num=errorhist1(end,2);
fprintf('layer 1 Computed cost is: %f, iteration number=%d\n',optcost,iter_num);

%% results1
px1     = reshape(px1,[n,dim1(2)-1,dim1(3),dim1(4),nt]);
py1     = reshape(py1,[n,dim1(2),dim1(3)-1,dim1(4),nt]);
pz1     = reshape(pz1,[n,dim1(2),dim1(3),dim1(4)-1,nt]);
rho_1    = reshape(rho_1,[n,dim1(2),dim1(3),dim1(4),(nt-1)]);
u1      = reshape(u1,[m,dim1(2),dim1(3),dim1(4),nt]);
lambda1 = reshape(lambda1,[n,dim1(2),dim1(3),dim1(4),nt]);

px2     = zeros(n,dim(2)-1,dim(3),dim(4),nt);
py2     = zeros(n,dim(2),dim(3)-1,dim(4),nt);
pz2     = zeros(n,dim(2),dim(3),dim(4)-1,nt);
u2      = zeros(m,dim(2),dim(3),dim(4),nt);
rho_2    = zeros(n,dim(2),dim(3),dim(4),(nt-1));
lambda2=zeros(dim);
for k=1:nt
    temp=px1(:,:,:,:,k);
    temp=permute(temp,[2,3,4,1]);
    px2(:,:,:,:,k)=permute(resample3d(temp,dim(2)-1,dim(3),dim(4)),[4,1,2,3]);
    temp=py1(:,:,:,:,k);
    temp=permute(temp,[2,3,4,1]);
    py2(:,:,:,:,k)=permute(resample3d(temp,dim(2),dim(3)-1,dim(4)),[4,1,2,3]);
    temp=pz1(:,:,:,:,k);
    temp=permute(temp,[2,3,4,1]);
    pz2(:,:,:,:,k)=permute(resample3d(temp,dim(2),dim(3),dim(4)-1),[4,1,2,3]);
    if(k~=nt)
        temp=rho_1(:,:,:,:,k);
        temp=permute(temp,[2,3,4,1]);
        rho_2(:,:,:,:,k)=permute(resample3d(temp,dim(2),dim(3),dim(4)),[4,1,2,3]);
    end
    temp=u1(:,:,:,:,k);
    temp=permute(temp,[2,3,4,1]);
    u2(:,:,:,:,k)=permute(resample3d(temp,dim(2),dim(3),dim(4)),[4,1,2,3]);
    temp=lambda1(:,:,:,:,k);
    temp=permute(temp,[2,3,4,1]);
    lambda2(:,:,:,:,k)=permute(resample3d(temp,dim(2),dim(3),dim(4)),[4,1,2,3]);
end


% initial values
init.px     = px2;
init.py     = py2;
init.pz     = pz2;
init.rho    = rho_2;
init.u      = u2;
init.lambda=lambda2;
%% iterations
max_iter=20;
tic
[px,py,pz,rho,u,lambda,errorhist] = SQPOPT(@(px,py,pz,rho,u,param) costgradf(px,py,pz,rho,u,param),init,max_iter,param);
toc
optcost=errorhist(end,1);
iter_num=errorhist(end,2);
fprintf('layer 2 Computed cost is: %f, iteration number=%d\n',optcost,iter_num);

[c,s]=cs_results(px,py,pz,rho,u,param);
%% results
px     = reshape(px,[n,(nx-1),ny,nz,nt]);
py     = reshape(py,[n,nx,(ny-1),nz,nt]);
pz     = reshape(pz,[n,nx,ny,(nz-1),nt]);
rho    = reshape(rho,[n,nx,ny,nz,(nt-1)]);
u      = reshape(u,[m,nx*ny*nz*nt]);
lambda = reshape(lambda,[n,nx*ny*nz*nt]);

end
function [px,py,pz,rho,u,lambda,errorhist] = SQPOPT(costgradf,init,numiter,param)
% merit SQP algorithm

%% SQP Parameters
suffi_alpha=2e-4; %sufficient decrease factor 
max_search=20; % max line search steps
lspar2   = 0.5; % line search update
lspar3   = 0.75;%0.75; % sufficient decrease object combination coefficient(cost+lspar3*dual error)
error_tol=1e-3; % error tolerance for converge test
proj_tol=1e-4;
%% Load parameters
h     = param.h;
dim   = param.dim;
b     = param.b;
D     = param.D;
n  = dim(1);
nx = dim(2);
ny = dim(3);
nz = dim(4);
nt = dim(5);
hx = h(1);
hy = h(2);
hz = h(3);
ht = h(4);

m=param.m;
%% intialize p rho u lambda
px     = init.px;
py     = init.py;
pz     = init.pz;
rho    = init.rho;
u      = init.u;
lambda = init.lambda;
w      = [px(:); py(:); pz(:); rho(:); u(:)];
lambda = lambda(:);

%% Compute Hessian and Gradient 
[c,gradf,Ahat,Ahatinv] = costgradf(px(:),py(:),pz(:),rho(:),u(:),param);
nablalambdaL           = D*w - b(:);
nablawL                = gradf+D'*lambda(:);

%% SQP
errorhist = zeros(numiter,3);
errorhist(1,1)           = c;  % primal error
errorhist(1,2)           = sqrt(norm(D*w-b(:))^2*hx*hy*hz*ht); % dual error
errorhist(1,3)           = sqrt(norm(nablawL)^2*hx*hy*hz*ht); % KKT error

% Iterations
for iter = 1:numiter
    s= 1; % initial stepsize
     
    % Schur Complement
    S= D*Ahatinv*D';
    coeff=2e-4;
    if(iter<5)
        coeff=1e-1;
    end
    S           = S+coeff*speye(length(S));
    tempvec1    = nablalambdaL - D*(Ahatinv*nablawL);

    try
        L            = ichol(S); 
    catch
        L=speye(size(S));
    end
%     S_gpu=gpuArray(S);
%     tempvec1_gpu=gpuArray(tempvec1);
%     L_gpu=gpuArray(L);
%     LLp_gpu=L_gpu*L_gpu';
    [deltalambda,~]  = pcg(S,tempvec1,1e-2,100,L,L');
    %[deltalambda,~]  = pcg(S_gpu,tempvec1_gpu,1e-2,1000,LLp_gpu);
    %deltalambda=gather(deltalambda);
    deltaw    = -Ahatinv*(D'*deltalambda+nablawL);
    deltarho  = deltaw((n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt+n*nx*ny*(nz-1)*nt+1):...
            (n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt+n*nx*ny*(nz-1)*nt+n*nx*ny*nz*(nt-1)));
    
    % Gradient projection
    % Line search + Projection && Sufficient decrease(|delta_cost|>O(deltaw))
    countls  = 1;
    while 1
        ws               = w + s*deltaw;    
        lambdas          = lambda + s*deltalambda; 
        pxs              = ws(1:n*(nx-1)*ny*nz*nt);
        pys              = ws((n*(nx-1)*ny*nt*nz+1):(n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt));
        pzs              = ws((n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt)+1:(n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt+n*nx*ny*(nz-1)*nt));
        rhos             = ws((n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt+n*nx*ny*(nz-1)*nt)+1:...
                           (n*(nx-1)*ny*nz*nt+n*nx*(ny-1)*nz*nt+n*nx*ny*(nz-1)*nt+n*nx*ny*nz*(nt-1)));
        %Project
        for i=1:length(rhos)
            if(rhos(i)<proj_tol)
                rhos(i)=rho(i);
            end
        end
        us               = ws((end-m*nx*ny*nz*nt+1):end);
        ws=[pxs;pys;pzs;rhos;us];
        
        %If sufficient decrease condition satisfied 
        if (phi1(@(px,py,pz,rho,u,param) costgradf(px,py,pz,rho,u,param),ws,param,lspar3) -...
        phi1(@(px,py,pz,rho,u,param) costgradf(px,py,pz,rho,u,param), w,param,lspar3)<-suffi_alpha/s*norm(deltaw)) % merit function condition
            break;
        end

        s       = s*lspar2;
        countls = countls + 1;
        % Line search error
        if (countls > max_search) 
            %fprintf('\n Line search error! iter=%d, %d\n',countls,min(rho(:)+s*deltarho));
            break;
        end

    end
    
    % Line search sucess, Update and go to next step
    if(countls<=max_search)
    
        w      = ws;
        lambda = lambdas;
        px     = pxs;
        py     = pys;
        pz     = pzs;
        rho    = rhos;
        u      = us;
        % next iteration
        [c,gradf,Ahat,Ahatinv] = costgradf(px(:),py(:),pz(:),rho(:),u(:),param);
        nablalambdaL           = D*w-b(:);
        nablawL                = gradf+D'*lambda(:);
    end
    
    % Calculate Current Errors
    errorhist(iter+1,1)           = c;  % primal error
    errorhist(iter+1,2)           = sqrt(norm(D*w-b(:))^2*hx*hy*ht); % dual error
    errorhist(iter+1,3)           = sqrt(norm(nablawL)^2*hx*hy*ht); % KKT error
    if(errorhist(iter+1,2)/errorhist(iter,2)>(1-1e-3)||errorhist(iter+1,3)<error_tol)
        lspar3=min(lspar3*1.5,10);
    end
    if(errorhist(iter+1,3)/errorhist(iter,3)>(1-1e-3)||errorhist(iter+1,2)<error_tol)
        lspar3=max(lspar3/1.5,0.1);
    end
    %fprintf('[KKT error,dual error,cost,1/(||lambda||_infy+1),step_size,lspar3]=\n[%f, %f, %f, %f, %f, %f]\n',errorhist(iter+1,3),errorhist(iter+1,2),c, 1/(norm(lambda(:),'inf')+1),s,lspar3);
    % Converge or line search error: return
    if ((errorhist(iter+1,2)<error_tol)&&(errorhist(iter+1,3)<error_tol)||countls>max_search)
        errorhist(numiter,1) = errorhist(iter,1);
        errorhist(numiter,2) = iter;
        fprintf('[KKT error,dual error,cost,1/(||lambda||_infy+1),step_size,lspar3]=\n[%f, %f, %f, %f, %f, %f]\n',errorhist(iter+1,3),errorhist(iter+1,2),c, 1/(norm(lambda(:),'inf')+1),s,lspar3);
        return;
    end
end

end
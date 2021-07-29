function [cost, gradf, hessian, hessianinv]=costgradf(px,py,pz,rho,u,param)
% compute the cost function

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
rhoinv1 = 1./(F1'*rho(:));
rhoinv2 = 1./(F2'*rho(:));

E=eye(n);
E(n,n)=e;
W1=kron(speye((nx-1)*ny*nz*nt),E);
W2=kron(speye((ny-1)*nx*nz*nt),E);
W3=kron(speye((nz-1)*nx*ny*nt),E);

% cost f
%cost = (A1x*W1*pxsq(:)+A1y*W2*pysq(:)+A1z*W3*pzsq(:))'*(A2*rhoinv(:) + a(:))*hx*hy*hz*ht + usq(:)'*(A3*rhoinv1(:)+A3*rhoinv2(:)+ c(:))*hx*hy*hz*ht*gamma;
cost = (A1x*W1*pxsq(:)+A1y*W2*pysq(:)+A1z*W3*pzsq(:))'*(A2*rhoinv(:) + a(:))*hx*hy*hz*ht + usq(:)'*(A3*rhoinv2(:)+ c(:))*hx*hy*hz*ht*gamma;
% compute gradient of f
if nargout > 1
    % derivative wrt px
    A11xe    = 2*W1*A1x'*(A2*rhoinv(:)+a(:));
    nablapxf = px(:).*A11xe(:);
    
    % derivative wrt py
    A11ye    = 2*W2*A1y'*(A2*rhoinv(:)+a(:));
    nablapyf = py(:).*A11ye(:);

    % derivative wrt pz
    A11ze    = 2*W3*A1z'*(A2*rhoinv(:)+a(:));
    nablapzf = pz(:).*A11ze(:);
    
    % derivative wrt rho
    A22e     = A2'*(A1x*W1*pxsq(:) + A1y*W2*pysq(:)+ A1z*W3*pzsq(:));
    nablarhof = -A22e.*rhoinv(:).^2-gamma.*F2*((A3'*usq(:)).*rhoinv2(:).^2);
                %-gamma.*F1*((A3'*usq(:)).*rhoinv1(:).^2);
    
    % derivative wrt u
    %A33e    = 2*gamma*(A3*(rhoinv2(:)+rhoinv1(:))+c(:));
    A33e    = 2*gamma*(A3*(rhoinv2(:))+c(:));
    nablauf = u(:).*A33e(:);
    
    % gradient wrt p rho u
    gradf   = [nablapxf; nablapyf; nablapzf; nablarhof; nablauf];
    
    % compute Hessian
    if nargout > 2
        % Hessian over px
        A11x    = A11xe;   
        
        % Hessian over py
        A11y    = A11ye;
        
        % Hessian over py
        A11z    = A11ze;
        
         % hessian over rho
        temp1   = 2.*A22e.*rhoinv(:).^3;
        temp2   = 2.*gamma.*(F2*((A3'*usq(:)).*rhoinv2(:).^3));
        %temp3   = 2.*gamma.*(F1*((A3'*usq(:)).*rhoinv1(:).^3));
        A22     = temp1(:)+temp2(:)...+temp3(:)
        +1e-4*ones(n*nx*ny*nz*(nt-1),1);
        
        % hessian over u
        A33  = A33e;
        
        % hessian
        hessian = [A11x(:);A11y(:);A11z(:);A22(:);A33(:)];

        % compute the inverse of Hessian
        if nargout > 3
            % inverse of hessian
            hessianinv = spdiags(1./(hessian),0,numel(hessian),numel(hessian));
        end
    end
end

end
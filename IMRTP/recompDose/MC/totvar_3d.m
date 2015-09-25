function u=totvar_3d(u0,lambda0,cerror,IterMax)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Desc: Denoising of MC dose by total variation
% Written by: Issam El Naqa Date: 06/07/05
% u0: noisy image
% cerror: uncertainty
% lambda0: regularization parameter
% IterMax: Maximum number of iterations

% initialize parameters
[m n k]=size(u0);
eps=0.000001; %  needed to regularize TV at the origin
lambda=lambda0./(1+exp(cerror));
u=u0;
for Iter=1:IterMax,
    Iter
    div = []; beta = [];
    ul = zeros(m+2, n+2, k+2);
    ul(2:m+1, 2:n+1, 2:k+1) = u;
    ux=ul(3:m+2,2:n+1,2:k+1)-u;
    ux = ux.*ux; 
    uy=ul(2:m+1,3:n+2,2:k+1)-u;
    uy = uy.*uy+ux; clear ux;
    uz=ul(2:m+1,2:n+1,3:k+2)-u;
    uz = uz.*uz+uy; clear uy;
    Gradu1=sqrt(eps*eps+uz); clear uz;
    beta = 3./Gradu1; clear Gradu1;
    %div=(1./Gradu1).*(ul(3:m+2,2:n+1,2:k+1)+ul(2:m+1,3:n+2,2:k+1)+ul(2:m+1,2:n+1,3:k+2));
    div = ul(3:m+2,2:n+1,2:k+1)+ul(2:m+1,3:n+2,2:k+1);
    div = div + ul(2:m+1,2:n+1,3:k+2);
    %div = (1./Gradu1).*div;
    div = beta/3.*div;
    
    ux=ul(2:m+1,2:n+1,2:k+1)-ul(1:m,2:n+1,2:k+1);
    ux = ux.*ux; 
    uy=ul(1:m,3:n+2,2:k+1)-ul(1:m,2:n+1,2:k+1);
    uy = uy.*uy+ux; clear ux;
    uz=ul(1:m,2:n+1,3:k+2)-ul(1:m,2:n+1,2:k+1);
    uz = uz.*uz+uy; clear uy;
    co2=1./sqrt(eps*eps+uz); clear uz;
    beta = beta+co2;
    div=div+co2.*ul(1:m,2:n+1,2:k+1);
    clear co2;
    %co3=co1;
    ux=ul(3:m+2,1:n,2:k+1)-ul(2:m+1,1:n,2:k+1);
    ux = ux.*ux; 
    uy=ul(2:m+1,2:n+1,2:k+1)-ul(2:m+1,1:n,2:k+1);
    uy = uy.*uy+ux; clear ux;
    uz=ul(2:m+1,1:n,3:k+2)-ul(2:m+1,1:n,2:k+1);
    uz = uz.*uz+uy; clear uy;
    co4=1./sqrt(eps*eps+uz); clear uz;
    beta = beta+co4;
    div=div+co4.*ul(2:m+1,1:n,2:k+1);
    clear co4; 
    %co5=co1;  % some shortcuts still possible?!
    ux=ul(3:m+2,2:n+1,1:k)-ul(2:m+1,2:n+1,1:k);
    ux = ux.*ux; 
    uy=ul(2:m+1,3:n+2,1:k)-ul(2:m+1,2:n+1,1:k);
    uy = uy.*uy+ux; clear ux;
    uz=ul(2:m+1,2:n+1,3:k+2)-ul(2:m+1,2:n+1,1:k);
    uz = uz.*uz+uy; clear uy;
    co6=1./sqrt(eps*eps+uz);clear uz;
    beta = beta+co6;
    div=div+co6.*ul(2:m+1,2:n+1,1:k);
    clear co6 ul;
    % since co3 == co1, and co5 == c01
    % So clear co3, co5, and replace them by co1
    co=1.+(1./(2*lambda)).*beta; clear beta;
    u=(1./co).*(u0+(1./(2*lambda)).*div);
    clear div;
    %%% Compute the discrete energy at each iteration
    %Energy(Iter)=sum(sum(sum(Gradu1+lambda.*(u0-u).^2)));
end

return



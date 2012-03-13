function y=dicomrt_mmdigit(x,n,b,t)
% dicomrt_mmdigit(x,n,b,t)
%
% Round values to given significant digits
%
% x is the array to be rounded
% n is the number of significant places
% b is the base (b=10 default)
% t is the type of algorithm to use to round (t='round' default)
%   permitted types are also: 'fix', 'ceil' and 'round'
%
% If x is immaginary real and immaginary parts are rounded separately
%
% From "Mastering MATLAB 6" Duane Hanselman and Bruce Littlefield, 
%       Prentice Hall, 2001 ISBN 0-13-019468-9
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

if nargin<2
    error('dicomrt_mmdigit: Not enough input arguments')
elseif nargin==2
    b=10;
    t='round';
elseif nargin==3
    t='round';
end
n=round(abs(n(1)));
if isempty(b),b=10;
else          b=round(abs(b(1)));
end
if isreal(x)
    y=abs(x)+(x==0);
    e=floor(log(y)./log(b)+1);
    p=repmat(b,size(x)).^(n-e);
    if strncmpi(t,'round',1)
        y=round(p.*x)./p;
    elseif strncmpi(t,'fix',1)
        y=fix(p.*x)./p;
    elseif strncmpi(t,'ceil',1)
        y=ceil(p.*x)./p;
     elseif strncmpi(t,'floor',1)
        y=floor(p.*x)./p;
    else
        error('dicomrt_mmdigit: Unknown rounding request');
    end
else % complex input
    y=complex(mmdigit(real(x),n,b,t),mmdigit(imag(x),n,b,t));
end
    
    

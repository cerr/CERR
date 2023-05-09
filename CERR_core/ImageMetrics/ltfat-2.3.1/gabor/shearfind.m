function [s0,s1,X] = shearfind(L,a,M,lt)
%-*- texinfo -*-
%@deftypefn {Function} shearfind
%@verbatim
%SHEARFIND  Shears for transformation of a general lattice to separable
%   Usage:  [s0,s1,br] = shearfind(L,a,M,lt);
%
%   [s0,s1,br]=SHEARFIND(L,a,M,lt) computes three numbers, the first two
%   represent a frequency and time shear respectively. With the returned
%   choices of s_0 and s_1 one can transform an initial lattice given by
%   a, M and lt into a separable (rectangular) lattice given by 
%
%       ar = a*L/(br*M)  and  Mr = L/br.
%
%   If s_0 is non-zero, the transformation from general to separable
%   lattice requires a frequency-side shear. Similarly, if s_1 is
%   non-zero, a time-side shear is required.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/shearfind.html}
%@seealso{pchirp, matrix2latticetype}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    
    if nargin < 4 
        error('Too few input arguments');
    end
    
    Ltest=dgtlength(L,a,M,lt);
    if Ltest~=L
        error(['%s: Incorrect transform length L=%i specified. '...
               'See the help of DGTLENGTH for the requirements.'],...
              upper(mfilename),L);
    end;

    b=L/M;
    s=b*lt(1)/lt(2);
        
    [Labfac,sfac,lenLabfac] = lattfac(a,b,s,L);

    %lenLabfac = size(Labfac,2);

    if s/a == round(s/a)
        if s/a <= b/2
            s1 = -s/a;
        else 
            s1 = b-s/a;
        end
        s0 = 0;
        X = b;
    elseif ones(1,lenLabfac) == (min(Labfac(3,:),Labfac(4,:)) <= sfac(2,1:end-1))
        s0 = 0;
        [Y,alpha,temp] = gcd(a,b);
        s1 = -alpha*s/Y;
         
        B = prod(Labfac(1,:).^max(Labfac(4,:)-Labfac(3,:),0));
        if abs(s1) > B/2
            s1 = s1+sign(alpha)*B;            
        end
        X = b;
        s1 = mod(s1,b);
    elseif ones(1,lenLabfac) == (Labfac(3,:) < sfac(2,1:end-1))
        s1 = 0;
        [X,alpha,temp] = gcd(s,b);
        if alpha < 0
            alpha = b/X + alpha;
        end
        s0 = mod(alpha*a/X,a*lt(2));
        
    else
        s1fac = (Labfac(3,:) == sfac(2,1:end-1)).*(Labfac(3,:) < Labfac(4,:));
        s1 = prod(Labfac(1,:).^s1fac);

        if s1*a/b == round(s1*a/b) 
            s1 = 0; 
        else 
           B = prod(Labfac(1,:).^max(Labfac(4,:)-Labfac(3,:),0));
           if s1 > B/2
                s1 = s1-B;
           end   
        end

        [X,alpha,temp] = gcd(s1*a+s,b);
        if alpha < 0
            alpha = b/X + alpha;
        end
        tempX = factor(X);
        tempalph = factor(alpha);

        Xfac = zeros(1,length(lenLabfac));
        alphfac = zeros(1,length(lenLabfac)+1);

        for kk = 1:lenLabfac
            Xfac(kk) = sum(tempX == Labfac(1,kk));
            tempX = tempX(tempX ~= Labfac(1,kk));
            alphfac(kk) = sum(tempalph == Labfac(1,kk));
            tempalph = tempalph(tempalph ~= Labfac(1,kk));
        end

        alphfac(lenLabfac+1) = prod(tempalph);

        s0fac = [Labfac(3,:)+min(alphfac(1:end-1),Labfac(4,:)-Xfac)-Xfac,0];
        pwrs = max(Labfac(4,:)-Xfac-alphfac(1:end-1),0);
        pwrs2 = max(-Labfac(4,:)+Xfac+alphfac(1:end-1),0);

        K = ceil(alphfac(end).*prod(Labfac(1,:).^(pwrs2-pwrs))-.5);

        s0fac(end) = K*prod(Labfac(1,:).^pwrs) - alphfac(end).*prod(Labfac(1,:).^pwrs2);

        s0 = prod(Labfac(1,:).^s0fac(1:end-1))*s0fac(end);

        if s0*X^2/(a*b) == round(s0*X^2/(a*b)) 
            s0 = 0; 
        end
    end
    
    s0=rem(s0,L);
    s1=rem(s1,L);
    
end

function [Labfac,sfac,lenLabfac] = lattfac(a,b,s,L)    

    tempL = factor(L);
    tempa = factor(a);
    
    if tempa == 1
        tempa = [];
    end
    tempb = factor(b);
    if tempb == 1
        tempb = [];
    end

    Labfac = unique(tempL);
    lenLabfac = length(Labfac);
    Labfac = [Labfac;zeros(3,lenLabfac)];

    for kk = 1:lenLabfac
       Labfac(2,kk) = sum(tempL == Labfac(1,kk));
       tempL = tempL(tempL ~= Labfac(1,kk));
       Labfac(3,kk) = sum(tempa == Labfac(1,kk));
       tempa = tempa(tempa ~= Labfac(1,kk));
       Labfac(4,kk) = sum(tempb == Labfac(1,kk));
       tempb = tempb(tempb ~= Labfac(1,kk));
    end

    if isempty(tempa) == 0 || isempty(tempb) == 0
        error('a and b must be divisors of L');
    end

    if s*L/(a*b) ~= round(s*L/(a*b));
        error('s must be a multiple of a*b/L');
    end

    temps = factor(s);

    sfac = [Labfac(1,:),0;zeros(1,lenLabfac+1)];

    for kk = 1:lenLabfac
       sfac(2,kk) = sum(temps == sfac(1,kk));
       temps = temps(temps ~= sfac(1,kk));
    end

    sfac(:,lenLabfac+1) = [prod(temps);1];

end


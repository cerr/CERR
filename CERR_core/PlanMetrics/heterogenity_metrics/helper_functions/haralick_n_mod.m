function [f,Ph]=haralick_n(qs,nL,q)
% Haralick textures measurements

Ph = coocurrance_alldir_mod(q);
% last row an column corresponds to outside ROI!
Ph=Ph(1:end-1,1:end-1);
nL=nL-1;

%compute features
R=sum(Ph(:));
Ph=Ph/R;
% Energy (1)
f(1)=sum(sum(Ph.^2));
% Contrast (2)
f(2)=0.0;
for n=0:nL-1
   temp=0;
   for i=1:nL
      for j=1:nL
         if (abs(i-j) == n)
            temp=temp+Ph(i,j);
         end
      end
   end
   f(2)=f(2)+n^2*temp;
end
% Correlation
%using symmetry Ph'=Ph!
Px=sum(Ph);
Py=sum(Ph');
vec=[1:nL];
ux=sum(Px .*vec);
uy=sum(Py .*vec);

varx=sum(Px .* vec.^2)-ux^2;
sigx=sqrt(varx);
vary=sum(Py .* vec.^2)-uy^2;
sigy=sqrt(vary);
u=vec*Ph(i,j)*vec';
f(3)=(u-ux*uy)/(sigx*sigy);

%Entropy (3)
f(4)=-sum(sum(Ph.*log(Ph+realmin))); % log????
      
% variance
f(5)=0;
for i=1:nL
   for j=1:nL
      f(5)=f(5)+(i-u)^2*Ph(i,j);
   end
end
% P(x+y)
f(6)=0;  % sum of entropy...
for k=2:2*nL
   temp=0.0;
   for i=1:nL
      for j=1:nL
         if ((i+j) == k)
            temp=temp+Ph(i,j);
         end
      end
   end
   Pxpy(k)=temp;
   f(6)=f(6)-temp*log(temp+realmin);
end

% inverse different moment..
f(7)=0;
f(8)=0;  %Homogeneity (4)
for i=1:nL
   for j=1:nL
      temp1=1/(1+(i-j)^2)*Ph(i,j);
      temp2=1/(1+abs(i-j))*Ph(i,j);
      f(7)=f(7)+temp1;
      f(8)=f(8)+temp2;
   end
end

return
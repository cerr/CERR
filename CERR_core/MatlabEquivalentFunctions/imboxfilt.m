function J = imboxfilt(I,siz)
% Function for 2-D box filtering of images   
% AI 8/13/2020

%Build kernel  
F = ones(siz,siz)./siz^2;
  
%Apply filter
J = imfilter(I,F,'replicate');  
  
  end
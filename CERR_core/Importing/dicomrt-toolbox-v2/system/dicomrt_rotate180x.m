function [A] = dicomrt_rotate180x(matrix)
% dicomrt_rotate180x(matrix)
%
% Rotate 3D matrix accordingly with original patient position.
%
% Example:
%
% [A]=dicomrt_rotate180x(Dose)
%
% rotate Dose 3D matrice of 180 degrees about the X axis
%
% See also dicomrt_ctcreate, dicomrt_loaddose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check cases
if ndims(matrix) ~= 3 
    error ('Only 3D matrices are supported. Exit now !');
end

% Execute rotation
for i=1:size(matrix,2)
    temp=squeeze(matrix(:,i,:));
    A(:,i,:)=rot90(temp,2);     
end
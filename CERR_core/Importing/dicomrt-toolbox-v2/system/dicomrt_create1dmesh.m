function [mesh] = dicomrt_create1dmesh(start,pix,dim,dir)
% dicomrt_create1dmesh(start,pix,dim,dir)
%
% Create one dimensional mesh.
%
% See also dicomrt_loadct, dicomrt_loaddose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% set up vector dimensions
mesh=zeros(dim,1);

% create mesh
if dir == 0 % positive direction
    for i=1:dim
        mesh(i)=start+(pix.*double(i))-pix;
    end
else % negative direction
    for i=1:dim
        mesh(i)=start-(pix.*double(i))+pix;
    end
end
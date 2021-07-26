function interp4M = fastResample3d(field4M,dimV)
% fastResample3d.m
% AI 7/23/21


%Input coordinates
xFieldV = [1,1,size(field4M,2)];
yFieldV = [1,1,size(field4M,1)];
zFieldV = 1:1:size(field4M,3);

%Coordinates to interpolate from original data field3M.
xInterpV = linspace(1,size(field4M,2),dimV(2));
yInterpV = linspace(1,size(field4M,1),dimV(1));
zInterpV = linspace(1,size(field4M,3),dimV(3));
[xM1, yM1, zM1] = meshgrid(xInterpV, yInterpV, zInterpV);

%Loop over volumes
interp4M = nan([size(xM1),size(field4M,4)]);
for l=1:size(field4M,4)
    % Fast 3D linear interpolation
    field3Ml = squeeze(field4M(:,:,:,l));
    interp3M = finterp3(xM1(:), yM1(:), zM1(:), field3Ml,...
        xFieldV, yFieldV, zFieldV, NaN);
    interp3M = reshape(interp3M,size(xM1));
    interp4M(:,:,:,l) = interp3M;
end


end
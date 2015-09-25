function Vf = fillMissingGrid(xGridV, yGridV, zGridV, Vf)
% function matrixOut = fillMissingGrid(xGridV, yGridV, zGridV, Vf)
%
% This function takes in a matrix that contains NaN values and replaces
% them with values that are linearly interpolated from the surrounding.
%
% APA, 10/03/2012

% Find NaN locations
indNaN = isnan(Vf(:,:,:,1));

% Find Not NaN locations
indNotNaN = ~isnan(Vf(:,:,:,1));

% Create x,y,z 3D grid
[xM,yM,zM] = meshgrid(xGridV, yGridV, zGridV);

% Get x,y,z of NaN points
xNaNv = xM(indNaN);
yNaNv = yM(indNaN);
zNaNv = zM(indNaN);

% Get x,y,z of Not-NaN points
xNotNaNv = xM(indNotNaN);
yNotNaNv = yM(indNotNaN);
zNotNaNv = zM(indNotNaN);

% Get values at Not-NaN points
xVf = Vf(:,:,:,1);
xVfv = xVf(indNotNaN);
yVf = Vf(:,:,:,2);
yVfv = yVf(indNotNaN);
zVf = Vf(:,:,:,3);
zVfv = zVf(indNotNaN);


Fx = TriScatteredInterp([xNotNaNv yNotNaNv zNotNaNv],double(xVfv));
Fy = TriScatteredInterp([xNotNaNv yNotNaNv zNotNaNv],double(yVfv));
Fz = TriScatteredInterp([xNotNaNv yNotNaNv zNotNaNv],double(zVfv));


xVfNaN = Fx([xNaNv yNaNv zNaNv]);
yVfNaN = Fy([xNaNv yNaNv zNaNv]);
zVfNaN = Fz([xNaNv yNaNv zNaNv]);


% xVfNaN = zeros(1,length(xNaNv));
% yVfNaN = xVfNaN;
% zVfNaN = xVfNaN;
% numVoxels = length(xNaNv);
% 
% for i=1:numVoxels
%     disp([num2str(i),' / ', num2str(numVoxels)])
%     %     % Find distance of NaN from all the Not-NaN points
%     %     distV = (xNaNv(i) - xNotNaNv).^2 + (yNaNv(i) - yNotNaNv).^2 + (zNaNv(i) - zNotNaNv).^2;
%     %     % Sort by distance
%     %     [~,indV] = sort(distV);
%     
%     %     indKrig = indV(1:20);
%     indKrig = [];
%     % Search in neighborhood    
%     searchRadius = 0.2;
%     while sum(indKrig>0) < 5
%         indKrig = (xNaNv(i) - xNotNaNv).^2 + (yNaNv(i) - yNotNaNv).^2 + (zNaNv(i) - zNotNaNv).^2 <= searchRadius^2;
%         searchRadius = searchRadius + 0.1;
%     end
%     % Kriging
%     dmodelX = dacefit([xNotNaNv(indKrig) yNotNaNv(indKrig) zNotNaNv(indKrig)], double(xVfv(indKrig)), @regpoly0, @correxp, 10, 1e-1, 20);
%     xVfKrig = predictor([xNaNv(i) yNaNv(i) zNaNv(i)], dmodelX);
%     dmodelY = dacefit([xNotNaNv(indKrig) yNotNaNv(indKrig) zNotNaNv(indKrig)], double(yVfv(indKrig)), @regpoly0, @correxp, 10, 1e-1, 20);
%     yVfKrig = predictor([xNaNv(i) yNaNv(i) zNaNv(i)], dmodelY);
%     dmodelZ = dacefit([xNotNaNv(indKrig) yNotNaNv(indKrig) zNotNaNv(indKrig)], double(zVfv(indKrig)), @regpoly0, @correxp, 10, 1e-1, 20);
%     zVfKrig = predictor([xNaNv(i) yNaNv(i) zNaNv(i)], dmodelZ);
%     
%     xNotNaNv = [xNotNaNv; xNaNv(i)];
%     yNotNaNv = [yNotNaNv; yNaNv(i)];
%     zNotNaNv = [zNotNaNv; zNaNv(i)];
%     xVfv = [xVfv; xVfKrig];
%     yVfv = [yVfv; yVfKrig];
%     zVfv = [zVfv; zVfKrig];
%     
%     xVfNaN(i) = xVfKrig;
%     yVfNaN(i) = yVfKrig;
%     zVfNaN(i) = zVfKrig;
%     
% end

xVf(indNaN) = xVfNaN;
yVf(indNaN) = yVfNaN;
zVf(indNaN) = zVfNaN;
Vf(:,:,:,1) = xVf;
Vf(:,:,:,2) = yVf;
Vf(:,:,:,3) = zVf;


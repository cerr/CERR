
%Load an example dataset.  The contents are as follows:
%  gridDATA      30x30x30                       216000  double array
%  gridX          1x30                             240  double array
%  gridY          1x30                             240  double array
%  gridZ          1x30                             240  double array
load example.mat


%Convert the binary data to an STL mesh:
[faces,vertices] = CONVERT_voxels_to_stl('temp.stl',gridINPUT,gridX,gridY,gridZ,'ascii');


%Plot the original data:
figure;
imagesc(squeeze(sum(gridINPUT,3)));
colormap(gray);
axis equal tight


%Load and plot the stl file:
figure
[stlcoords] = READ_stl('temp.stl');
xco = squeeze( stlcoords(:,1,:) )';
yco = squeeze( stlcoords(:,2,:) )';
zco = squeeze( stlcoords(:,3,:) )';
[hpat] = patch(xco,yco,zco,'b');
axis equal
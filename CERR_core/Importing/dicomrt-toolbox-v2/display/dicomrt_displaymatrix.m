function [displaymatrix] = dicomrt_displaymatrix(matrix,xmesh,ymesh,zmesh,axis,slice,VOI,voi2use)
% dicomrt_displaymatrix(matrix,xmesh,ymesh,zmesh,axis,slice,VOI,voi2use)
%
% Display a matrix slice on the X, Y or Z plane. VOIs can be overlayed.
%
% matrix contains the 3D dose distribution
% xmesh,ymesh,zmesh are x-y-z coordinates of the center of the matrix voxels
% axis is a character (X Y or Z) and refers to the axis used for the slice display
% Slice is the slice number to be displayed
% VOI is an OPTIONAL cell array which contain the patients VOIs as read by dicomrt_loadVOI
% voi2plot is an OPTIONAL vector pointing to the number of VOIs to be displayed
%
% Example:
%
% dicomrt_displaymatrix(demo2_ct,ct_xmesh,ct_ymesh,ct_zmesh,'z',26,demo2_voi,[1 11 10]);
%
% display slice 26 of demo2_ct along the z axis and overlays VOIs 1 11 and 10.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(6,8,nargin))

% Check case and set-up some parameters and variables
[matrix2display_temp,type,label,PatientPosition]=dicomrt_checkinput(matrix);
matrix2display=dicomrt_varfilter(matrix2display_temp);

% Check axis
if ischar(axis) ~=1
    error('dicomrt_displaymatrix: Axis is not a character. Exit now!')
elseif axis=='x' | axis=='X'
    dir=1;
elseif axis=='y' | axis=='Y'
    dir=2;
elseif axis=='z' | axis=='Z'
    dir=3;
else
    error('dicomrt_displaymatrix: Axis can only be X Y or Z. Exit now!')
end

% Display
figure
set(gcf,'Name',['dicomrt_displaymatrix: ',inputname(1),', slice ',num2str(slice), ' (',axis,')']);
if dir==1 % X axis      -> YZ image
        imagesc(squeeze(matrix2display(:,slice,:)),'XData',zmesh,'YData',ymesh);
        xlabel('Z axis (cm) ','FontSize',12)
        ylabel('Y axis (cm) ','FontSize',12)
elseif dir==2 % Y axis  -> XZ image
        imagesc(squeeze(matrix2display(slice,:,:)),'XData',zmesh,'YData',xmesh);
        xlabel('Z axis (cm) ','FontSize',12)
        ylabel('X axis (cm) ','FontSize',12)
else % Z axis           -> XY image
        imagesc(matrix2display(:,:,slice),'XData',xmesh,'YData',ymesh);
        xlabel('X axis (cm) ','FontSize',12)
        ylabel('Y axis (cm) ','FontSize',12)
end

% Overlay VOI
if exist('VOI')==1 & exist('voi2use')==1  
    hold on
    if dir==3
        dicomrt_overlayvoi(zmesh,VOI,voi2use,slice,axis,PatientPosition);
    elseif dir ==2
        dicomrt_overlayvoi(ymesh,VOI,voi2use,slice,axis,PatientPosition);
    elseif dir==1
        dicomrt_overlayvoi(xmesh,VOI,voi2use,slice,axis,PatientPosition);
    end
    hold off
end

% Modify display as function of PatientPosition
dicomrt_setaxisdir(PatientPosition);
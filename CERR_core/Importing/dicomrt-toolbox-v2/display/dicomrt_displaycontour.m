function [contour] = dicomrt_displaycontour(matrix,xmesh,ymesh,zmesh,dose,dose_xmesh,dose_ymesh,dose_zmesh,axis,slice,norm,levels,VOI,voi2use)
% dicomrt_displaycontour(matrix,xmesh,ymesh,zmesh,dose,dose_xmesh,dose_ymesh,dose_zmesh,axis,slice,norm,levels,VOI,voi2use)
%
% Display dose contour overlayed in a slice. VOIs can be also plotted.
%
% matrix contains the 3D dose distribution
% xmesh,ymesh,zmesh,dose_xmesh,dose_ymesh,dose_zmesh are x-y-z coordinates of the center of the matrix voxels
% axis is a character (X Y or Z) and refers to the axis used for the slice display
% Slice is the slice number to be displayed
% norm is the dose normalization level
% norm =0 (default) no normalization is carried out
%      ~=0 doses are normalized to norm (100%)
% levels is a vector which contains dose contour levels to be plotted consistently to the input matrix
% VOI is an OPTIONAL cell array which contain the patients VOIs. 
% voi2use is an OPTIONAL vector pointing to the number of VOIs to be displayed
%
% Colors for contours are automatically set using the following convention:
%
% |---------------|----------|
% |dose value (%) |  color   |
% |---------------|----------|
% |   > 105       |  magenta |
% |   95-105      |  red     |
% |   80-95       |  green   |
% |   50-80       |  cyan    |
% |   0-50        |  blu     |
% |---------------|----------|
%
% Example:
%
% dicomrt_displaycontour(CT,ct_xmesh,ct_ymesh,ct_zmesh,A,dose_xmesh,dose_ymesh,dose_zmesh,...
%       'z',26,60,[100 95 50],A_voi,[1 11 10]);
%
% display dose contours for slice 26 of A along the z axis superimposed to
% the corresponding CT image from matrix. Dose is normalized to 60Gy and 
% contours of 100% 95% and 50% are shown with overlays from VOIs 1 11 and 10.
%
% See also dicomrt_displaycontourcomp, dicomrt_build3dVOImtx, dicomrt_plot3dVOI
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(12,14,nargin))

% Check case and set-up some parameters and variables
[matrix2display_temp,type_matrix,labelm,PatientPosition]=dicomrt_checkinput(matrix);
[dose2display_temp,type_dose,labeld,PatientPosition]=dicomrt_checkinput(dose);
matrix2display=dicomrt_varfilter(matrix2display_temp);
dose2display=dicomrt_varfilter(dose2display_temp);

if exist('VOI')==1
    [VOI_temp]=dicomrt_checkinput(VOI);
    VOI=dicomrt_varfilter(VOI_temp);
end

% Check axis and find the ct slice corresponding to slice
if ischar(axis) ~=1
    error('dicomrt_displaycontour: Axis is not a character. Exit now!')
elseif (axis=='x' | axis=='X')
    dir=1;
    ctslice=dicomrt_findsliceVECT(dose_xmesh,slice,xmesh,PatientPosition);
elseif (axis=='y' | axis=='Y') 
    dir=2;
    ctslice=dicomrt_findsliceVECT(dose_ymesh,slice,ymesh,PatientPosition);
elseif axis=='z' | axis=='Z'
    dir=3;
    ctslice=dicomrt_findsliceVECT(dose_zmesh,slice,zmesh,PatientPosition);
else
    error('dicomrt_displaycontour: Axis can only be X Y or Z. Exit now!')
end

% Check normalization and initialize plot parameters: 
if norm~=0
    dose2display=dose2display./norm.*100;
end

% Set isolevels display
[contourcolor,doseareas]=dicomrt_setisolevels(norm,dose);

% Display slice
figure
set(gcf,'NumberTitle','off');
title(['Contour plot for ',inputname(5)],'FontSize',16,'Interpreter','none');
if dir==1 % X axis      -> YZ image
    set(gcf,'Name',['dicomrt_displaycontour: ',inputname(5),' slice no. ',num2str(slice),...
            ' (',num2str(dose_xmesh(slice)),' cm / ',axis,')']);
    if isempty(ctslice)~=1
        imagesc(squeeze(matrix2display(:,ctslice,:)),'XData',zmesh,'YData',ymesh);
        xlabel('Z axis (cm)','FontSize',12)
        ylabel('Y axis (cm)','FontSize',12)
        if exist('VOI')==1
            hold on
            dicomrt_plotVOI(dir,ctslice,VOI_temp,voi2use,xmesh,ymesh,zmesh,PatientPosition);
            hold off
        end
    else
        warning('dicomrt_displaycontour: Cound not find CT slice. Try using dicomrt_fitCT2dm');
        matrix2display=dicomrt_fitCT2dm(matrix,xmesh,ymesh,zmesh,dose_xmesh,dose_ymesh,dose_zmesh);
        imagesc(squeeze(matrix2display(:,slice,:)),'XData',zmesh,'YData',ymesh);
        xlabel('Z axis (cm)','FontSize',12)
        ylabel('Y axis (cm)','FontSize',12)
    end
elseif dir==2 % Y axis  -> XZ image
    set(gcf,'Name',['dicomrt_displaycontour: ',inputname(5),' slice no. ',num2str(slice),...
            ' (',num2str(dose_ymesh(slice)),' cm / ',axis,')']);
    if isempty(ctslice)~=1
        imagesc(squeeze(matrix2display(ctslice,:,:)),'XData',zmesh,'YData',xmesh);
        xlabel('Z axis (cm)','FontSize',12)
        ylabel('X axis (cm)','FontSize',12)
        if exist('VOI')==1
            hold on
            dicomrt_plotVOI(dir,ctslice,VOI_temp,voi2use,xmesh,ymesh,zmesh,PatientPosition);
            hold off
        end
    else
        warning('dicomrt_displaycontour: Cound not find CT slice. Try using dicomrt_fitCT2dm');
        matrix2display=dicomrt_fitCT2dm(matrix,xmesh,ymesh,zmesh,dose_xmesh,dose_ymesh,dose_zmesh);
        imagesc(squeeze(matrix2display(slice,:,:)),'XData',zmesh,'YData',xmesh);
        xlabel('Z axis (cm)','FontSize',12)
        ylabel('Y axis (cm)','FontSize',12)
    end
else % Z axis           -> XY image
    set(gcf,'Name',['dicomrt_displaycontour: ',inputname(5),' slice no. ',num2str(slice),...
            ' (',num2str(dose_zmesh(slice)),' cm / ',axis,')']);
    imagesc(matrix2display(:,:,ctslice),'XData',xmesh,'YData',ymesh);
    if exist('VOI')==1
        hold on 
        dicomrt_plotVOI(dir,ctslice,VOI_temp,voi2use,xmesh,ymesh,zmesh,PatientPosition);
        hold off
    end
    xlabel('X axis (cm)','FontSize',12)
    ylabel('Y axis (cm)','FontSize',12)
end

hold on

for i=1:length(levels)
    if dir==1 % X axis      -> YZ image
        [n,p] = histc(levels(i),doseareas);
        [C,h]=contour(dose_zmesh,dose_ymesh,squeeze(dose2display(:,slice,:)),[levels(i) levels(i)],contourcolor(p));
        set(h,'Linewidth',2);
        xlabel('Z axis (cm)','FontSize',12)
        ylabel('Y axis (cm)','FontSize',12)
        if isempty(C)~=1
            labl=clabel(C,h);
            set(labl,'Color',contourcolor(p));
            set(labl,'FontWeight','bold');
        else
            warning(['dicomrt_displaycontour: Contour for :',num2str(levels(i)),' was not found']);
        end
    elseif dir==2 % Y axis  -> XZ image
        [n,p] = histc(levels(i),doseareas);
        [C,h]=contour(dose_zmesh,dose_xmesh,squeeze(dose2display(slice,:,:)),[levels(i) levels(i)],contourcolor(p));
        xlabel('Z axis (cm)','FontSize',12)
        ylabel('X axis (cm)','FontSize',12)
        set(h,'Linewidth',2);
        if isempty(C)~=1
            labl=clabel(C,h);
            set(labl,'Color',contourcolor(p));
            set(labl,'FontWeight','bold');
        else
            warning(['dicomrt_displaycontour: Contour for :',num2str(levels(i)),' was not found']);
        end
    else % Z axis           -> XY image
        [n,p] = histc(levels(i),doseareas);
        [C,h]=contour(dose_xmesh,dose_ymesh,dose2display(:,:,slice),[levels(i) levels(i)],contourcolor(p));
        xlabel('X axis (cm)','FontSize',12)
        ylabel('Y axis (cm)','FontSize',12)
        set(h,'Linewidth',2);
        if isempty(C)~=1
            labl=clabel(C,h);
            set(labl,'Color',contourcolor(p));
            set(labl,'FontWeight','bold');
        else
            warning(['dicomrt_displaycontour: Contour for :',num2str(levels(i)),' was not found']);
        end
    end
end


hold off;
dicomrt_setaxisdir(PatientPosition);

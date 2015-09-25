function [displaymatrix] = dicomrt_overlayvoi(vectref,VOI,voi2use,slice,axis,PatientPosition)
% dicomrt_overlayvoi(vectref,VOI,voi2use,slice,axis,PatientPosition)
%
% Overlay selected voi to a graph.
% Find the voi section to plot by matching the Z location.
% 
% Differs from dicomrt_plotVOI as voi section to plot is searched.
%
% See also dicomrt_displaymatrix, dicomrt_plotVOI
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);
voitype=dicomrt_checkvoitype(VOI_temp);

% Check axis
if ischar(axis) ~=1
    error('dicomrt_overlayvoi: Axis is not a character. Exit now!')
elseif axis=='x' | axis=='X'
    dir=1;
elseif axis=='y' | axis=='Y'
    dir=2;
elseif axis=='z' | axis=='Z'
    dir=3;
else
    error('dicomrt_overlayvoi: Axis can only be X Y or Z. Exit now!')
end

% Find VOI corresponding to slice 
[locate_voi]=dicomrt_findvoi2slice(VOI_temp,voi2use,vectref,slice,axis,PatientPosition);

% Overlay VOI
hold on
if isequal(voitype,'2D')==1 & dir==3
    for j=1:length(voi2use)
        if isnan(locate_voi(j))~=1
            hPatch = patch(VOI{voi2use(j),2}{locate_voi(j)}(:,1),VOI{voi2use(j),2}{locate_voi(j)}(:,2),'w');
            set(hPatch,'FaceColor','y', 'LineWidth', 1,'EdgeColor', 'w','FaceAlpha',0.001);
            %plot(VOI{voi2use(j),2}{locate_voi(j)}(:,1),VOI{voi2use(j),2}{locate_voi(j)}(:,2),'w');
        end
    end
elseif isequal(voitype,'3D')==1 & dir==1
    for j=1:length(voi2use)
        if isnan(locate_voi(j))~=1
            dicomrt_plotcontourc(VOI{voi2use(j),2}{1}{locate_voi(j)}{2});
        end
    end
elseif isequal(voitype,'3D')==1 & dir==2
    for j=1:length(voi2use)
        if isnan(locate_voi(j))~=1
            dicomrt_plotcontourc(VOI{voi2use(j),2}{2}{locate_voi(j)}{2});
        end
    end
end
    
hold off;
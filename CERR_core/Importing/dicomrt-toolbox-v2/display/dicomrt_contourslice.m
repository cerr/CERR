function dicomrt_contourslice(inputdose,dose_xmesh,dose_ymesh,dose_zmesh,axis,plane,type,VOI,voi2plot)
% dicomrt_contourslice(inputdose,dose_xmesh,dose_ymesh,dose_zmesh,axis,plane,type,VOI,voi2plot)
%
% Show 3D dose distributions.
% 
% inputdose contains the 3D dose distribution
% inputdose can be an rtplan generated or a monte carlo generated 3D dose distribution or a dose difference.
%
% dose_xmesh,dose_ymesh,dose_zmesh are x-y-z coordinates of the center of the dose-pixel 
% axis is the plane to be used for slicing the 3D dose matrix (can be x,y or z. Key insensitive).
% plane is a vector containing the slice number of the slices to be displayed
% type OPTIONAL parameter which determines whether display the slices in the same 
%      plot (type==0) or in independent subplots (type~=0)
% VOI is an OPTIONAL cell array which contain the patients VOIs as read by dicomrt_loadVOI
% voi2plot is an OPTIONAL vector pointing to the number of VOIs to be displayed
%
% Example:
%
% dicomrt_contourslice(A,xmesh,ymesh,zmesh,'z',[10 15 25], A_voi,[1 2 3])
%
% plot a figure that contains: 3 plots with inputdose sliced at voxel number 10 15 and 25
% All plots show also VOIs # 1 2 and 3.
%
% See also dicomrt_loadmcdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(6,9,nargin))

% Check type
if exist('type')~=1
    type=0;
end

% Check case and set-up some parameters and variables
[dose_temp,type_dose,doselabel,PatientPosition]=dicomrt_checkinput(inputdose);
dose=dicomrt_varfilter(dose_temp);

% Check axis
if ischar(axis) ~=1
    error('dicomrt_contourslice: Axis is not a character. Exit now!')
elseif axis=='x' | axis=='X'
    dir=1;
elseif axis=='y' | axis=='Y'
    dir=2;
elseif axis=='z' | axis=='Z'
    dir=3;
else
    error('dicomrt_contourslice: Axis can only be X Y or Z. Exit now!')
end

% rebuilding mesh matrices
[rtdose_xmesh,rtdose_ymesh,rtdose_zmesh]=dicomrt_rebuildmatrix(dose_xmesh,dose_ymesh,dose_zmesh);

% Initialize plot parameters: 
color = char('r','g','b','c','m','y','k','w');
line = char('-','--',':','-.');
marker = char('+','o','*','x','s','d','^');
width = [0.5,1.0,1.5,2.0,2.5,3.0];

% Rendering 3D dose 
figure
set(gcf,'Name',['dicomrt_contourslice: ',inputname(1)]);
hold

if length(plane)==1
    if dir==1
        p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,dose_xmesh(plane),[],[]);
    elseif dir==2
        p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,[],dose_ymesh(plane),[]);
    elseif dir==3
        p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,[],[],dose_zmesh(plane));
    else
        error('dicomrt_contourslice: Error while rendering. Exit now');
    end
    view(30,30);
    set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
    xlabel('X axis (cm)')
    ylabel('Y axis (cm)')
    zlabel('Z axis (cm)')
    if exist('VOI')==1 % VOI is defined
        dicomrt_rendervoi(VOI,voi2plot,1,1,1);
    end
    grid on
else
    if type~=0
        for i=1:length(plane)
            subplot(2,round((length(plane)/2)),i);
            if dir==1
                p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,dose_xmesh(plane(i)),[],[]);
                set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
            elseif dir==2
                p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,[],dose_ymesh(plane(i)),[]);
                set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
            elseif dir==3
                p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,[],[],dose_zmesh(plane(i)));
                set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
            else
                error('dicomrt_contourslice: Error while rendering. Exit now');
            end
            view(30,30);
            set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
            xlabel('X axis (cm)')
            ylabel('Y axis (cm)')
            zlabel('Z axis (cm)')
            if exist('VOI')==1 % VOI is defined
                hold
                dicomrt_rendervoi(VOI,voi2plot,1,1,1);
            end
        end
    else
        for i=1:length(plane)
            if dir==1
                p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,dose_xmesh(plane(i)),[],[]);
                set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
            elseif dir==2
                p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,[],dose_ymesh(plane(i)),[]);
                set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
            elseif dir==3
                p = slice(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,dose,[],[],dose_zmesh(plane(i)));
                set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
            else
                error('dicomrt_contourslice: Error while rendering. Exit now');
            end
            view(30,30);
            set(p,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
            xlabel('X axis (cm)')
            ylabel('Y axis (cm)')
            zlabel('Z axis (cm)')
        end
        if exist('VOI')==1 % VOI is defined
            dicomrt_rendervoi(VOI,voi2plot,1,1,1);
        end
        grid on
    end
end
    

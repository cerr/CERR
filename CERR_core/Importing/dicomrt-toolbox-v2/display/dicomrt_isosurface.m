function dicomrt_isosurface(inputdose,dose_xmesh,dose_ymesh,dose_zmesh,levels,norm,VOI,voi2plot)
% dicomrt_isosurface(inputdose,dose_xmesh,dose_ymesh,dose_zmesh,levels,norm,VOI,voi2plot)
%
% Show isosurface for 3D dose distributions.
% 
% inputdose contains the 3D dose distribution
% inputdose can be an rtplan generated or a monte carlo generated 3D dose distribution or a dose difference.
%
% dose_xmesh,dose_ymesh,dose_zmesh are x-y-z coordinates of the center of the dose-pixel 
% levels is a vector containing the values of the % dose difference to be displayed in 3D
% norm is the dose normalization level:
%   1.   norm =0  no normalization is carried out
%   2.       =-1 same as (1) but matrix is treated as dose difference (transparency display)
%   3.       >0  doses are normalized to norm (100%)
% VOI is an OPTIONAL cell array which contain the patients VOIs as read by dicomrt_loadVOI
% voi2plot is an OPTIONAL vector pointing to the number of VOIs to be displayed
%
% Example:
%
% dicomrt_isosurface(A,xmesh,ymesh,zmesh,[100 90],60,A_voi,[1 2 3])
%
% overlay 2 isosurfaces for matrix A at the 100% and 90% levels. Dose is normalised to 60Gy (100%).
% The figure also shows VOIs # 1 2 and 3.
%
% See also dicomrt_loaddose, dicomrt_loadmcdose, dicomrt_contourslice, dicomrt_dosediff
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(6,8,nargin))

% Check case and set-up some parameters and variables
[dose_temp,type_dose,doselabel,PatientPosition]=dicomrt_checkinput(inputdose);
dose=dicomrt_varfilter(dose_temp);

% Check normalization
if norm>0
    dose=dose./norm.*100;
end

% Initialize plot parameters: 
color = char('r','g','b','c','m','y','k','w');
line = char('-','--',':','-.');
marker = char('+','o','*','x','s','d','^');
width = [0.5,1.0,1.5,2.0,2.5,3.0];
alphal=[0.1:0.1:1.0];

% Set isolevels display
[contourcolor,doseareas,transl]=dicomrt_setisolevels(norm,dose_temp);

% Fetching legend information
legend_matrix=char(num2str(levels'));

% Rendering 3D dose 
handle=figure;
set(handle,'Name',['dicomrt_isosurface: ',inputname(1)]);
grid on;
hold

if exist('VOI')~=1 % No VOI is defined
    if length(levels)==1
        [n,p] = histc(levels,doseareas);
        handle = patch(isosurface(dose_xmesh,dose_ymesh,dose_zmesh,dose,levels));
        isonormals(dose_xmesh,dose_ymesh,dose_zmesh,dose,handle);
        set(handle,'FaceColor',contourcolor(p),'EdgeColor','None','FaceAlpha',0.5);
        view(30,30); 
        legend(handle,[int2str(levels)]);
        xlabel('X axis (cm)','Fontsize',12)
        ylabel('Y axis (cm)','Fontsize',12)
        zlabel('Z axis (cm)','Fontsize',12)
    elseif length(levels)~=1
        for i=1:length(levels)
            [n,p] = histc(levels(i),doseareas);
            if p==0
                p=1;
            end
            handle = patch(isosurface(dose_xmesh,dose_ymesh,dose_zmesh,dose,levels(i)));
            isonormals(dose_xmesh,dose_ymesh,dose_zmesh,dose,handle);
            set(handle,'FaceColor',contourcolor(p),'EdgeColor','None','FaceAlpha',transl(p));
        end
        legend(legend_matrix); 
        view(30,30);
        xlabel('X axis (cm)','Fontsize',12)
        ylabel('Y axis (cm)','Fontsize',12)
        zlabel('Z axis (cm)','Fontsize',12)
    end
    title(['Isosurface plot for: ',inputname(1)],'interpreter','none','FontSize',16);
elseif exist('VOI')==1 & exist('voi2plot')==1 % VOI was defined
    % Set VOI display parameters
    colorselect =7;
    lineselect =1;
    linewidth =1;
    if length(levels)==1
        [n,p] = histc(levels,doseareas); 
        if p==0
            p=1;
        end
        handle = patch(isosurface(dose_xmesh,dose_ymesh,dose_zmesh,dose,levels));
        isonormals(dose_xmesh,dose_ymesh,dose_zmesh,dose,handle);
        set(handle,'FaceColor',contourcolor(p),'EdgeColor','None','FaceAlpha',0.5);
        view(30,30); 
        legend(handle,[int2str(levels)]);
        xlabel('X axis (cm)','Fontsize',12)
        ylabel('Y axis (cm)','Fontsize',12)
        zlabel('Z axis (cm)','Fontsize',12)
    elseif length(levels)~=1
        for i=1:length(levels)
            [n,p] = histc(levels(i),doseareas);
            if p==0
                p=1;
            end
            handle = patch(isosurface(dose_xmesh,dose_ymesh,dose_zmesh,dose,levels(i)));
            isonormals(dose_xmesh,dose_ymesh,dose_zmesh,dose,handle);
            set(handle,'FaceColor',contourcolor(p),'EdgeColor','None','FaceAlpha',transl(p));
        end
        legend(legend_matrix);
        view(30,30);
        xlabel('X axis (cm)','Fontsize',12)
        ylabel('Y axis (cm)','Fontsize',12)
        zlabel('Z axis (cm)','Fontsize',12)
    end
    title(['Isosurface plot: ',inputname(1)],'interpreter','none','FontSize',16);
    % Plot VOIs
    dicomrt_rendervoi(VOI,voi2plot,1,1,1);
else
    error('dicomrt_isosurface: VOI or voi2plot is missing. Exit now !');
end

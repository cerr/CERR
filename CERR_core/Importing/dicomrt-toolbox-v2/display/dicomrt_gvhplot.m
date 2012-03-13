function [volumegrid,GAMMAgrid] = dicomrt_gvhplot(GVH,typegvh,int)
% dicomrt_gvhplot(GVH,typegvh,int)
%
% Display GAMMA Volume Histogram (GVH) for selected Volume Of Interest (VOI)
%
% GVH is a GVH cell matrix generated with dicomrt_gvhcal
% typegvh   is a parameter which switch between cumulative (=0 default)
%           and frequency (=1) histogram 
% int       is an OPTIONAL parameter that allows the user to define colors for
%           gvh plot. If not passed as input default color, style and marker are used.
%
% GVHs are stored in a cell array with the following structure:
%
%  --------------------------------
%  | [GVH-name] | [3D gamma mask] |
%  |            -------------------
%  |            | [gvh data]      |
%  |            -------------------
%  |            | VOI volume      | 
%  |            -------------------
%  |            | Voxel volume    | 
%  --------------------------------
%
% [gvh data] is a 2 columns vector with following structure:
%
% ----------------------
% | gamma grid | count |
% ----------------------
% |            |       |
% |            |       |
% |            |       |
% |            |       |
% ----------------------
%
%
% Example:
%
% dicomrt_gvhplot(A,2,2) plot a cumulative GVH for VOI 2 contained in GVH cell array A.
%
% See also dicomrt_loaddose, roifilt2, dicomrt_gvhcal
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(1,3,nargin))

% Initialize plot parameters: 
color = char('r','g','b','c','m','y','k');
line = char('-','--',':','-.');
marker = char('+','o','*','x','s','d','^');
width = [0.5,1.0,1.5,2.0,2.5,3.0];

% Set-up typedvh of plot (cumulative frequency)
if exist('typegvh')==0
    typegvh=0;
end

% Prepare plot
figure;
hold
legend_matrix=GVH{1,1};

% Plot GVH for all the selected/available VOIs
% Volume is always normalized to Volume of Interest
% GAMMA is always given in GAMMA units except if GAMMA normalization is requested
%

if typegvh == 0 % cumulative GVH
    volume_VOI=GVH{1,2}{3};
    volumegrid=cumsum(GVH{1,2}{2}(:,2))/volume_VOI*100;
    GAMMAgrid=GVH{1,2}{2}(:,1);
    
    % User input
    if exist('int')~=0
        colorselect = menu(['Choose a color for ', GVH{1,1}],'Red','Green','Blue','Cyan', ...
            'Magenta','Yellow','Black');
        lineselect = menu(['Choose a linestyle for ', GVH{1,1}],'Solid','Dashed','Dotted', ...
            'Dash-Dot');
        markerselect = menu (['Choose a marker for ', GVH{1,1}],'Plus sign','Circle','Asterisk', ...
            'Cross','Square','Diamond','Triangle');
        linewidth = menu(['Choose line width for ', GVH{1,1}],'0.5','1.0','1.5', ...
            '2.0','2.5','3.0');
    else
        colorselect = 7;
        lineselect = 1;
        markerselect = 2;
        linewidth = 2;
    end
        
    handle=plot(GAMMAgrid,volumegrid);
    
    set(handle, 'LineStyle', line(lineselect,:));
    set(handle, 'Marker', marker(markerselect,:));
    set(handle, 'Color', color(colorselect,:));
    set(handle, 'LineWidth', linewidth);
    set(gcf,'Name',['dicomrt_gvhplot: GAMMA Volume Histogram ',inputname(1)]);
    title('Cumulative GAMMA Volume Histogram','FontSize',18);
    xlabel('GAMMA','FontSize',14);
    ylabel('Volume [%]','FontSize',14);
    legend(legend_matrix);
    grid on
    
else % frequency GVH (default)    
    volume_VOI=GVH{1,2}{3};
    volumegrid=GVH{1,2}{2}(:,2)/volume_VOI*100;
    GAMMAgrid=GVH{1,2}{2}(:,1);
    
    % User input
    if exist('int')~=0
        colorselect = menu(['Choose a color for ', GVH{1,1}],'Red','Green','Blue','Cyan', ...
        'Magenta','Yellow','Black');
        lineselect = menu(['Choose a linestyle for ', GVH{1,1}],'Solid','Dashed','Dotted', ...
            'Dash-Dot');
        markerselect = menu (['Choose a marker for ', GVH{1,1}],'Plus sign','Circle','Asterisk', ...
            'Cross','Square','Diamond','Triangle');
        linewidth = menu(['Choose line width for ', GVH{1,1}],'0.5','1.0','1.5', ...
            '2.0','2.5','3.0');
    else
        colorselect = 7;
        lineselect = 1;
        markerselect = 2;
        linewidth = 2;
    end
    
    handle=plot(GAMMAgrid,volumegrid);
    
    set(handle, 'LineStyle', line(lineselect,:));
    set(handle, 'Marker', marker(markerselect,:));
    set(handle, 'Color', color(colorselect,:));
    set(handle, 'LineWidth', linewidth);
    set(gcf,'Name',['dicomrt_gvhplot: GAMMA Volume Histogram ',inputname(1)]);
    title('Frequency GAMMA Volume Histogram','FontSize',18);
    xlabel('GAMMA','FontSize',14);
    ylabel('Volume [%]','FontSize',14);
    legend(legend_matrix);
    grid on
end
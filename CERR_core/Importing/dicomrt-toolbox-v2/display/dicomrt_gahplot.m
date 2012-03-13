function [areagrid2e,GAMMAgrid2e] = dicomrt_gahplot(GAH,type,norm,int)
% dicomrt_gahplot(GAH,type,norm,int)
%
% Display in 3D GAMMA Area Histogram (GAH) for selected Volume Of Interest (VOI), section by section.
%
% GAH is a GAH cell matrix generated with dicomrt_gahcal
% type is a parameter which switch between cumulative (=0 default)
%      and frequency (~=0) histogram 
% norm is a parameter which switch between normalized (~=0)
%      and non normalized (=0 default) GAMMA axis
%      if norm~=1 user input is required to get normalization value 
%      THIS REMAINS FOR CONSISTENCY WITH dicomrt_dvhplot: 
%      USE ZERO FOR THIS PARAMETER.
% int  is an OPTIONAL parameter that allows the user to define colors for
%      gah plot. If not passed as input default color, style and marker are used.
%
% GAHs are stored in a cell array with the following structure:
%
%  -------------------------------
%  | [GAH-name] | [3D gamma mask] |
%  |            -------------------
%  |            | [gah section 1] |
%  |            | [gah section 2] |
%  |            |     ...         |
%  |            | [gah section m] |
%  |            -------------------
%  |            | [info area 1]   |
%  |            | [info area 2]   |
%  |            |     ...         |  
%  |            | [info area m]   |
%  |            -------------------
%  |            | Pixel area      | 
%  --------------------------------
%
% [gamma data] is a 2 columns vector with following structure:
%
% -----------------
% | gamma | count |
% -----------------
% |       |       |
% |       |       |
% |       |       |
% |       |       |
% -----------------
%
% [info area] is a 2 columns vector with following structure:
%
% ---------------------------------
% | area sec | z location section |
% ---------------------------------
%
% Example:
%
% dicomrt_gahplot(A,2,2) plot a series of cumulative GAH for sections in VOI 2.
% Data are from GAH in cell array A.
%
% See also dicomrt_loaddose, roifilt2, dicomrt_gahcal
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(1,4,nargin))

if nargin==1
    type=0;
    norm=0;
end

% Initialize plot parameters: 
color = char('r','g','b','c','m','y','k');
line = char('-','--',':','-.');
marker = char('+','o','*','x','s','d','^');
width = [0.5,1.0,1.5,2.0,2.5,3.0];

% Prepare plot
figure;
hold
legend_matrix=GAH{1,1};

% Plot GAH for all the selected/available VOIs
% Area is always normalized to the current section Area 
% GAMMA is always given in GAMMA units except if GAMMA normalization is requested
%
if norm~=0
    go=0; % go ahead pointer
    while go~=1
        disp('You selected to normalize GAH GAMMA to a specific GAMMA.');
        GAMMAnorm = input('Input the normalization value for gamma: ');
        if isempty(GAMMAnorm)~=1
            x_label=['\gamma [%]'];
            go=1;
        else
            go=0;
        end
    end
else
    GAMMAnorm=100;
    x_label=['\gamma'];
end

areagrid2e=cell(size(GAH));
GAMMAgrid2e=cell(size(GAH));

if type == 0 % cumulative GAH
    % User input
    if exist('int')~=0
        colorselect = menu(['Choose a color for ', GAH{1,1}],'Red','Green','Blue','Cyan', ...
            'Magenta','Yellow','Black');
        lineselect = menu(['Choose a linestyle for ', GAH{1,1}],'Solid','Dashed','Dotted', ...
            'Dash-Dot');
        markerselect = menu (['Choose a marker for ', GAH{1,1}],'Plus sign','Circle','Asterisk', ...
            'Cross','Square','Diamond','Triangle');
        linewidth = menu(['Choose line width for ', GAH{1,1}],'0.5','1.0','1.5', ...
            '2.0','2.5','3.0');
    else
        colorselect = 7;
        lineselect = 1;
        markerselect = 1;
        linewidth = 1;
    end
   
    for kk=1:size(GAH{1,2}{1},3)
        % inside section
        areagrid=(cumsum(GAH{1,2}{2}{kk}(:,2)))/GAH{1,2}{3}{kk}(1)*100;
        GAMMAgrid=GAH{1,2}{2}{kk}(:,1)*GAMMAnorm/100;
        zgrid=[1:length(GAMMAgrid)];
        zgrid(:)=GAH{1,2}{3}{kk}(2);
        handle=plot3(GAMMAgrid,zgrid,areagrid);
        set(handle, 'LineStyle', line(lineselect,:));
        set(handle, 'Marker', marker(markerselect,:));
        set(handle, 'Color', color(colorselect,:));
        set(handle, 'LineWidth', linewidth);
        set(gcf,'Name',['dicomrt_gahplot: GAMMA Area Histogram (GAH) for ',inputname(1)]);
        title('Cumulative GAMMA Area Histogram','FontSize',18);
        xlabel(x_label,'FontSize',14);
        ylabel('Z [cm]','FontSize',14);
        zlabel('Voi section area [%]','FontSize',14);
        view(30,45);
        % Export calculated quantities
        areagrid2e{1,2}{kk}=areagrid;
        GAMMAgrid2e{1,2}{kk}=GAMMAgrid;
    end
    % Export calculated quantities
    areagrid2e{1,1}=[GAH{1,1},' cGAH'];
    GAMMAgrid2e{1,1}=[GAH{1,1},' cGAH'];
    legend(legend_matrix);
    grid on
else % frequency GAH
    % User input
    if exist('int')~=0
        colorselect = menu(['Choose a color for ', GAH{1,1}],'Red','Green','Blue','Cyan', ...
            'Magenta','Yellow','Black');
        lineselect = menu(['Choose a linestyle for ', GAH{1,1}],'Solid','Dashed','Dotted', ...
            'Dash-Dot');
        markerselect = menu (['Choose a marker for ', GAH{1,1}],'Plus sign','Circle','Asterisk', ...
            'Cross','Square','Diamond','Triangle');
        linewidth = menu(['Choose line width for ', GAH{1,1}],'0.5','1.0','1.5', ...
            '2.0','2.5','3.0');
    else
        colorselect = 7;
        lineselect = 1;
        markerselect = 2;
        linewidth = 2;
    end
        
    for kk=1:size(GAH{1,2}{1},3)
        % inside section
        areagrid=GAH{1,2}{2}{kk}(:,2)*GAH{1,2}{4}/GAH{1,2}{3}{kk}(1)*100;
        GAMMAgrid=GAH{1,2}{2}{kk}(:,1)*GAMMAnorm/100;
        zgrid=[1:length(GAMMAgrid)];
        zgrid(:)=GAH{1,2}{3}{kk}(2);
        handle=plot3(GAMMAgrid,zgrid,areagrid);
        set(handle, 'LineStyle', line(lineselect,:));
        set(handle, 'Marker', marker(markerselect,:));
        set(handle, 'Color', color(colorselect,:));
        set(handle, 'LineWidth', linewidth);
        set(gcf,'Name',['dicomrt_gahplot: GAMMA Area Histogram (GAH) for ',inputname(1)]);
        title('Frequency GAMMA Area Histogram','FontSize',18);
        xlabel(x_label,'FontSize',14);
        ylabel('Z [cm]','FontSize',14);
        zlabel('Voi section area [%]','FontSize',14);
        view(30,45);
        % Export calculated quantities
        areagrid2e{1,2}{kk}=areagrid;
        GAMMAgrid2e{1,2}{kk}=GAMMAgrid;
    end
    % Export calculated quantities
    areagrid2e{1,1}=[GAH{1,1},' fGAH'];
    GAMMAgrid2e{1,1}=[GAH{1,1},' fGAH'];
    legend(legend_matrix);
    grid on
end
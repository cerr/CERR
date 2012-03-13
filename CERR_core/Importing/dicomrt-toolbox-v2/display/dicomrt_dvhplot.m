function dicomrt_plotdvh(DVH,dvhselect,typedvh,dnorm,vnorm)
% dicomrt_plotdvh(DVH,dvhselect,typedvh,dnorm,vnorm)
%
% Display Dose Volume Histogram (DVH) for selected Volume Of Interest (VOI)
%
% DVH is a DVH cell matrix generated with dicomrt_dvhcal
% dvhselect is a vector which contains the number of VOI to plot.
%           if dvhselect==0 DVH for all the available VOIs are plotted
% typedvh   is a parameter which switch between cumulative (=0 default)
%           and frequency (=1) histogram 
% dnorm     OPTIONAL parameter which switch between normalized (~=0)
%           and non normalized (=0 default) dose axis.
%           If dnorm~=0 the dose axis is normalised to dnorm.
% vnorm     OPTIONAL parameter which switch between normalized (~=0)
%           and non normalized (=0 default) volume axis.
%           If vnorm~=0 the volume axis is normalised to the volume of the
%           selected VOI. If vnorm=0 volume is expressed in cubic centimeters.
%
% DVHs are stored in a cell array with the following structure:
%
%  -----------------------------
%  | [DVH 1] | [3D dose mask]  |
%  |         -------------------
%  |         | [dvh data]      |
%  |         -------------------
%  |         | VOI volume      | 
%  |         -------------------
%  |         | Voxel volume    | 
%  -----------------------------
%  |   ...   |     ...         |  
%  -----------------------------
%  | [DVH n] | [3D dose mask]  |
%  |         -------------------
%  |         | [dvh data]      |
%  |         -------------------
%  |         | VOI volume      | 
%  |         -------------------
%  |         | Voxel volume    | 
%  -----------------------------
%
% Example:
%
% dicomrt_dvhplot(A,2,2) plot a cumulative DVH for VOI 2 contained in DVH cell array A using
%
% See also dicomrt_loaddose, roifilt2, dicomrt_dvhcal
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(2,5,nargin))

% check for dvhselect
if length(dvhselect)==1 & dvhselect==0
    dvhselect=[1:1:size(DVH,1)];
end

% Initialize plot parameters: 
color = char('r','g','b','c','m','y','k');
line = char('-','--',':','-.');
marker = char('+','o','*','x','s','d','^');
width = [0.5,1.0,1.5,2.0,2.5,3.0];
dosegrid_max=0;

% Prepare plot
figure;
hold
for i=1:length(dvhselect)
    if i==1
        legend_matrix=DVH{dvhselect(i),1};
    else
        legend_matrix=char(legend_matrix,DVH{dvhselect(i),1});
    end
end

% Set-up typedvh of plot (cumulative frequency)
if exist('typedvh')==0
    typedvh=0;
end

% Plot DVH for all the selected/available VOIs
% Volume is always normalized to Volume of Interest
% Dose is always given in Gy except if dose normalization is requested
%
if exist('dnorm') 
    if dnorm~=0
        dosenorm = dnorm;
        x_label=['Dose [%]'];
    else
        dosenorm = 100;
        x_label=['Dose [Gy]'];
    end
else
    dosenorm=100;
    x_label=['Dose [Gy]'];
end

if exist('vnorm') 
    if vnorm~=0
        for k=1:length(dvhselect)
            volumenorm(k)=DVH{dvhselect(k),2}{3};
        end
        y_label=['Volume [%]'];
    else
        for k=1:length(dvhselect)
            volumenorm(k)=100;
        end
        y_label=['Volume [cc]'];
    end
else
    for k=1:length(dvhselect)
        volumenorm(k)=100;
    end
    y_label=['Volume [cc]'];
end

if typedvh == 0 % cumulative DVH
    for k=1:length(dvhselect)
        % volumegrid=(volume_VOI-cumsum(counts)*volume_bin)/volume_VOI*100
        %volumegrid=(DVH{dvhselect(k),2}{3} - cumsum(DVH{dvhselect(k),2}{2}(:,2)) ...
            %*DVH{dvhselect(k),2}{4})/DVH{dvhselect(k),2}{3}*100;
        %volumegrid=(cumsum(DVH{dvhselect(k),2}{2}(:,2)) ...
         %   *DVH{dvhselect(k),2}{4})/DVH{dvhselect(k),2}{3};
        volumegrid=(DVH{dvhselect(k),2}{3}-cumsum(DVH{dvhselect(k),2}{2}(:,2)))./volumenorm(k).*100;        
        %volumegrid=(DVH{dvhselect(k),2}{3} - cumsum(DVH{dvhselect(k),2}{2}(:,2)) ...
        %    *DVH{dvhselect(k),2}{4})/DVH{dvhselect(k),2}{3};
        dosegrid=DVH{dvhselect(k),2}{2}(:,1)*100/dosenorm;
        dosegrid_max=max(dosegrid_max,max(dosegrid));
        % User input
        colorselect = menu(['Choose a color for ', DVH{dvhselect(k),1}],'Red','Green','Blue','Cyan', ...
            'Magenta','Yellow','Black');
        lineselect = menu(['Choose a linestyle for ', DVH{dvhselect(k),1}],'Solid','Dashed','Dotted', ...
            'Dash-Dot');
        markerselect = menu (['Choose a marker for ', DVH{dvhselect(k),1}],'Plus sign','Circle','Asterisk', ...
            'Cross','Square','Diamond','Triangle');
        linewidth = menu(['Choose line width for ', DVH{dvhselect(k),1}],'0.5','1.0','1.5', ...
            '2.0','2.5','3.0');
        handle=plot(dosegrid,volumegrid);
        set(handle, 'LineStyle', line(lineselect,:));
        set(handle, 'Marker', marker(markerselect,:));
        set(handle, 'Color', color(colorselect,:));
        set(handle, 'LineWidth', linewidth);
        set(gcf,'NumberTitle','off');
        set(gcf,'Name',['dicomrt_dvhplot: Dose Volume Histogram ',inputname(1)]);
        title('Cumulative Dose Volume Histogram','FontSize',18);
        xlabel(x_label,'FontSize',14);
        ylabel(y_label,'FontSize',14);
    end
    legend(legend_matrix);
    grid on
else % frequency DVH (default)    
    for k=1:length(dvhselect)
        volumegrid=DVH{dvhselect(k),2}{2}(:,2)*volumenorm(k)/DVH{dvhselect(k),2}{3};
        dosegrid=DVH{dvhselect(k),2}{2}(:,1)*100/dosenorm;
        dosegrid_max=max(dosegrid_max,max(dosegrid));
        % User input
        colorselect = menu(['Choose a color for ', DVH{dvhselect(k),1}],'Red','Green','Blue','Cyan', ...
            'Magenta','Yellow','Black');
        lineselect = menu(['Choose a linestyle for ', DVH{dvhselect(k),1}],'Solid','Dashed','Dotted', ...
            'Dash-Dot');
        markerselect = menu (['Choose a marker for ', DVH{dvhselect(k),1}],'Plus sign','Circle','Asterisk', ...
            'Cross','Square','Diamond','Triangle');
        linewidth = menu(['Choose line width for ', DVH{dvhselect(k),1}], '0.5','1.0','1.5', ...
            '2.0','2.5','3.0');
        
        handle=plot(dosegrid,volumegrid);
        
        set(handle, 'LineStyle', line(lineselect,:));
        set(handle, 'Marker', marker(markerselect,:));
        set(handle, 'Color', color(colorselect,:));
        set(handle, 'LineWidth', linewidth);
        set(gcf,'NumberTitle','off');
        set(gcf,'Name',['dicomrt_dvhplot: Dose Volume Histogram ',inputname(1)]);
        title('Frequency Dose Volume Histogram','FontSize',18);
        xlabel(x_label,'FontSize',14);
        ylabel('Volume [%]','FontSize',14);
    end
    legend(legend_matrix);
    grid on
    
end

% Reset y limits
current_ylimits=ylim;
current_ylimits(1)=0;
ylim(current_ylimits);

% Reset x limits
current_xlimits=xlim;
current_xlimits(2)=dosegrid_max;
xlim(current_xlimits);

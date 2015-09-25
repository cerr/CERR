function [data] = dicomrt_rendervoi(voi,voi2render,int,addopt,nolegend)
% dicomrt_rendervoi(voi,voi2render,int,addopt,nolegend)
%
% Plot 3D Volumes Of Interests (VOIs) 
%
% voi is the VOI cell array as created by dicomrt_loadvoi
% voi2render is a vector containing the number of the VOI to be plotted
% int is an OPTIONAL parameter which if set to "1" allow the user to select line properties
% addopt is an OPTIONAL parameter which if set to "1" add VOIs plots to an existing figure
% nolegend is an OPTIONAL parameter which if set to "1" do not plot legend in the figure
%
% Example:
%
% dicomrt_rendervoi(A,2) 
%
% plot VOI number 2 stored in cell array A
%
% See also dicomrt_loadvoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(2,5,nargin))

% Check case and set-up some parameters and variables
[voi_temp,type,label]=dicomrt_checkinput(voi);
voi=dicomrt_varfilter(voi_temp);

voitype=dicomrt_checkvoitype(voi_temp);

% Initialize plot parameters: 
color = char('r','g','b','c','m','y','k','w');
line = char('-','--',':','-.');
width = [0.5,1.0,1.5,2.0,2.5,3.0];

if exist('addopt')~=1
    addopt=0;
end

if exist('nolegend')~=1
    nolegend=0;
end

% downgrading 3D to 2D for backward compatibility
if isequal(voitype,'3D')==1
    voi=dicomrt_3dto2dVOI(voi);
end

if length(voi2render)==1
    % Get number of countour in selected VOI to render
    ncont=size(voi{voi2render,2},1);
    % Plot selected VOI
    if exist('int')
        if int==1
            colorselect = menu(['Choose a color for VOI: ',voi{voi2render,1}],'Red','Green','Blue','Cyan', ...
                'Magenta','Yellow','Black','White');
            lineselect = menu(['Choose a linestyle for VOI: ',voi{voi2render,1}],'Solid','Dashed','Dotted', ...
                'Dash-Dot');
            linewidth = menu(['Choose line width for VOI: ',voi{voi2render,1}],'0.5','1.0','1.5', ...
                '2.0','2.5','3.0');
        else
            colorselect = 7;
            lineselect = 1;
            linewidth = 1;
        end
    else
        colorselect = 7;
        lineselect = 1;
        linewidth = 1;
    end
    if addopt~=1 % Plot VOI in a new figure
        figure
        hold on;
        title(voi{voi2render,1},'Fontsize',18,'Interpreter','none');
        set(gcf,'Name',['dicomrt_rendervoi: ',inputname(1)]);
    end
    for i=1:ncont       
        handle=plot3(voi{voi2render,2}{i,1}(:,1),voi{voi2render,2}{i,1}(:,2),...
            voi{voi2render,2}{i,1}(:,3));
        if i==1 & nolegend~=1
            legend(voi{voi2render,1});
        end
        set(handle, 'Color', color(colorselect,:));  
        set(handle, 'LineStyle', line(lineselect,:));
        set(handle, 'LineWidth', width(linewidth));
    end
    xlabel('X axis (cm)','Fontsize',12);
    ylabel('Y axis (cm)','Fontsize',12);
    zlabel('Z axis (cm)','Fontsize',12);
    grid on
    % Plot done
else
    if addopt~=1
        figure
        hold on;
        set(gcf,'Name',['dicomrt_rendervoi: ',inputname(1)]);
        title([inputname(1), ': volumes of interest'],'Fontsize',18,'Interpreter','none');
    end
    for k=1:length(voi2render)
        % Get number of countour in selected VOI to render
        ncont=size(voi{voi2render(k),2},1);
        % Plot selected VOI
        if exist('int')==1
            if int==1
                colorselect = menu(['Choose a color for VOI: ',voi{voi2render(k),1}],'Red','Green','Blue','Cyan', ...
                    'Magenta','Yellow','Black','White');
                lineselect = menu(['Choose a linestyle for VOI: ',voi{voi2render(k),1}],'Solid','Dashed','Dotted', ...
                    'Dash-Dot');
                linewidth = menu(['Choose line width for VOI: ',voi{voi2render(k),1}],'0.5','1.0','1.5', ...
                    '2.0','2.5','3.0');
            else
                colorselect = k;
                lineselect = 1;
                linewidth = 1;
            end
        else
            colorselect = k;
            lineselect = 1;
            linewidth = 1;
        end
        for i=1:ncont        
            handle=plot3(voi{voi2render(k),2}{i,1}(:,1),voi{voi2render(k),2}{i,1}(:,2),...
                voi{voi2render(k),2}{i,1}(:,3));
            set(handle, 'Color', color(colorselect,:));  
            set(handle, 'LineStyle', line(lineselect,:));
            set(handle, 'LineWidth', width(linewidth));
            if i==1 & k==1 & nolegend~=1
                legend_handle=handle;
                legend_matrix=voi{voi2render(k),1};
            elseif i==1 & k~=1 & nolegend~=1
                legend_handle=[legend_handle;handle];
                legend_matrix=char(legend_matrix,voi{voi2render(k),1});
            elseif nolegend~=1
                legend(legend_handle,legend_matrix);
            end
        end
    end
    xlabel('X axis (cm)','Fontsize',12);
    ylabel('Y axis (cm)','Fontsize',12);
    zlabel('Z axis (cm)','Fontsize',12);
    grid on
    % Plot done
end
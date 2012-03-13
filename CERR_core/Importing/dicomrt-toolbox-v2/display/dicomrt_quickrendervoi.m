function [data]= dicomrt_quickrendervoi(voi,voi2render,colorselect,lineselect,linewidth)
% dicomrt_quickrendervoi(voi,voi2render,colorselect,lineselect,linewidth)
%
% Plot 3D Volumes Of Interests (VOIs) 
%
% voi is the VOI cell array as created by dicomrt_loadvoi
% voi2render is a vector containing the number of the VOI to be plotted
% colorselect,lineselect,linewidth represent color line and line width respectively
%
% See also dicomrt_loadvoi, dicomrt_rendervoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[voi_temp,type,label]=dicomrt_checkinput(voi);
voi=dicomrt_varfilter(voi_temp);

voitype=dicomrt_checkvoitype(voi_temp);

% downgrading 3D to 2D for backward compatibility
if isequal(voitype,'3D')==1
    voi=dicomrt_3dto2dVOI(voi);
end

% Get number of countour in selected VOI to render
ncont=size(voi{voi2render,2},1);

% Plot selected VOI
for i=1:ncont
   handle=plot3(voi{voi2render,2}{i,1}(:,1), ... 
      voi{voi2render,2}{i,1}(:,2),voi{voi2render,2}{i,1}(:,3));
   set(handle, 'Color', colorselect);  
   set(handle, 'LineStyle', lineselect);
   set(handle, 'LineWidth', linewidth);
end

% Plot done

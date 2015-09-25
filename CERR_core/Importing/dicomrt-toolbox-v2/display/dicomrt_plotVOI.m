function [contour] = dicomrt_plotVOI(dir,slice,VOI,voi2use,xmesh,ymesh,zmesh,PatientPosition)
% dicomrt_plorVOI(dir,slice,VOI,voi2use,xmesh,ymesh,zmesh,PatientPosition)
%
% Plot VOIs in X and Y plane. 
%
% dir is the direction (=1 -> x, =2 -> y, =3 -> z)
% slice is the slice number to plot the contour for
% VOI is a cell array which contain the patients VOIs. 
% voi2use is a vector pointing to the number of VOIs to be displayed
%
% Differs from dicomrt_overlayvoi as voi section to plot is not searched.
%
% See also dicomrt_findsliceVECT, dicomrt_displaycontour, dicomrt_loadvoi, dicomrt_rendervoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(8,9,nargin))
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

voitype=dicomrt_checkvoitype(VOI_temp);

% Set parameter
voilookup=1;
voiZ=[];
C=[];
h=[];

% Initialize plot parameters: 
color = char('r','g','b','c','m','y','k','w');
line = char('-','--',':','-.');
width = [0.5,1.0,1.5,2.0];

% Default values
colorselect=8;
lineselect=1;
linewidth=2;

if dir==1 & isequal(voitype,'3D')==1
    for i=1:length(voi2use)
        dicomrt_plotcontourc(VOI{voi2use(i),2}{1}{slice}{2});
    end
elseif dir==1 & isequal(voitype,'3D')~=1
    warning('Contour plot is not possible. Use dicomrt_build3dVOI to build a 3D VOI');
elseif dir==2 & isequal(voitype,'3D')==1
    for i=1:length(voi2use)
        dicomrt_plotcontourc(VOI{voi2use(i),2}{2}{slice}{2});
    end
elseif dir==2 & isequal(voitype,'3D')~=1
    warning('Contour plot is not possible. Use dicomrt_build3dVOI to build a 3D VOI');
elseif dir==3 & isequal(voitype,'3D')~=1
    for i=1:length(voi2use)
        [voiZ,voiZ_index]=dicomrt_getvoiz(VOI_temp,voi2use(i));
        voiZ=dicomrt_makevertical(voiZ);
        zslice=dicomrt_findpointVECT(voiZ,zmesh(slice));
        zslice=voiZ_index(zslice);
        if isempty(zslice)~=1
            closexVOI=[VOI{voi2use(i),2}{zslice}(:,1);VOI{voi2use(i),2}{zslice}(1,1)];
            closeyVOI=[VOI{voi2use(i),2}{zslice}(:,2);VOI{voi2use(i),2}{zslice}(1,2)];
            hplot=plot(closexVOI,closeyVOI);
            set(hplot,'Color',color(colorselect,:));
            set(hplot,'LineStyle',line(lineselect,:));
            set(hplot,'LineWidth', linewidth);
        else
            warning(['dicomrt_plot3dVOI: VOI :',VOI{voi2use(i),1},' is not defined in the selected slice']);
        end
    end
elseif dir==3 & isequal(voitype,'3D')==1
    for i=1:length(voi2use)
        [voiZ,voiZ_index]=dicomrt_getvoiz(VOI_temp,voi2use(i));
        voiZ=dicomrt_makevertical(voiZ);
        zslice=dicomrt_findpointVECT(voiZ,zmesh(slice));
        zslice=voiZ_index(zslice);
        if isempty(zslice)~=1
            closexVOI=[VOI{voi2use(i),2}{3}{zslice}(:,1);VOI{voi2use(i),2}{3}{zslice}(1,1)];
            closeyVOI=[VOI{voi2use(i),2}{3}{zslice}(:,2);VOI{voi2use(i),2}{3}{zslice}(1,2)];
            hplot=plot(closexVOI,closeyVOI);
            set(hplot,'Color',color(colorselect,:));
            set(hplot,'LineStyle',line(lineselect,:));
            set(hplot,'LineWidth', linewidth);
        else
            warning(['dicomrt_plot3dVOI: VOI :',VOI{voi2use(i),1},' is not defined in the selected slice']);
        end
    end
end

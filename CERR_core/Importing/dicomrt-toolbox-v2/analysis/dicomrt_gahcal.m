function [GAH] = dicomrt_gahcal(VOI,gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,gahselect,xgrid)
% dicomrt_gahcal(VOI,gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,gahselect,xgrid)
%
% Calculate GAMMA-AREA-HISTOGRAMS for VOIs and cell_case_study.
% This function calculate GAHs for all the available VOIs or for a selected number of them.
%
% gamma contains the 3D gamma map
% gamma_xmesh,gamma_ymesh,gamma_zmesh are x-y-z coordinates of the center of the gamma-voxels 
% VOIs is a cell array and contains all the Volumes of Interest
% gahselect is an OPTIONAL parameter which contains the number of the VOI to calculate GAHs for.
% xgrid is an OPTIONAL parameter that sets the resolution for GAH calculation (default = 30)
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
% gah=dicomrt_gahcal(VOI,gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,4) returns 
% the GAH for the VOI number 4 in VOI and the gamma distribution stored in the 
% 3D matrix 'gamma'.
%
% See also dicomrt_gvhcal, dicomrt_gvhplot
%           
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(5,7,nargin))

% Check input parameters and set default parameter
list_variables=who;
match=0;

% Check voi
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

if nargin==5 & (exist('gahselect')==1 | exist('xgrid')==1)
    error('dicomrt_gahcal: Not enough input paramenters. Exit now!');
end

if exist('gahselect')~=1
    gahselect=[1:1:size(VOI,1)];
end

% Check consistency for z values
if gamma_zmesh(1)~=VOI{gahselect,2}{1}(1,3)
    error(['dicomrt_gahcal: GAMMA map was not calculated for the selected voi (',VOI{gahselect,1},'). Exit now!']);
end

% Define xgrid
if exist('xgrid')~=1
    xgrid=[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 ...
            3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 Inf];
end

% Define cell array
GAH=cell(1,2);
GAH{1,1}=['GAH-',VOI{gahselect,1}];

% Notes on pixel area calculation
% Although slice thickness may vary the pixel area is supposed to be the
% same through all the volume. 
pixelarea=(abs(gamma_xmesh(2)-gamma_xmesh(1)).*(abs(gamma_ymesh(2)-gamma_ymesh(1))));

% start calculating time
disp(['GAH calculation for VOI: ',VOI{gahselect,1}]);
% Initialise parameters
count=0; % count dimensions of gamma_section
count_empty=0; % count number of times gamma_section is not defined
% mask gamma matrix with current VOI
[mask_VOI,volume_VOI,mask4VOI]=dicomrt_mask(VOI_temp,gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,gahselect,'nan','n');
% slice by slice select contents of mask_VOI ~=nan and put it into a vector for GAH calculation

for kk=1:size(mask_VOI{2,1},3)
    xgrid_temp=xgrid;
    agrid=histc(reshape(mask_VOI{2,1}(:,:,kk),1,size(mask_VOI{2,1},1)*size(mask_VOI{2,1},2)),xgrid_temp);
    % get back voxels with dose<min(xgrid) cause histc does not
    % account for it
    temp_min=find(mask_VOI{2,1}(:,:,kk)<xgrid_temp(1) & mask_VOI{2,1}(:,:,kk)>0);
    if isempty(temp_min)~=1
        agrid(1)=agrid(1)+length(temp_min);
    end
    % Inf value will won't be plotted in the x grid. Therefore we
    % collect all the Inf values in the last slot of xgrid/vgrid
    agrid(end-1)=agrid(end-1)+agrid(end);
    agrid(end)=[];
    xgrid_temp(end)=[];
    temp2=cumsum(agrid);
    agrid=agrid.*pixelarea;
    info_area=[temp2(end)*pixelarea VOI{gahselect,2}{kk}(1,3)];
    gahdata=[xgrid_temp' agrid'];
    % store data in cell array
    GAH{1,2}{2,1}{kk}=gahdata;
    GAH{1,2}{3,1}{kk}=info_area;
    % plot frequency GAH
    if isempty(agrid)~=1
        figure;
        if isempty(inputname(2))==1
            set(gcf,'Name',['dicomrt_gahcal: ','fGAH for ',inputname(1)]);
        else
            set(gcf,'Name',['dicomrt_gahcal: ','fGAH for ',inputname(2)]);
        end
        agrid(end-1)=agrid(end-1)+agrid(end);
        agrid(end)=[];
        xgrid_temp(end)=[];
        bar(xgrid_temp,agrid);
        title([VOI{gahselect,1},' section: ',num2str(kk)],'Fontsize', 18,'Interpreter','none');
        xlabel('\gamma','Fontsize', 14);
        ylabel('Area [cm^2]','Fontsize', 14);
    else
        warning(['dicomrt_gahcal: GAH is null for VOI: ',GAH{k,1},' section: ',num2str(kk)]);
        gahdata=[0,0];
        GAH{1,2}{2,1}{kk}=gahdata;
    end
    % store other data in cell array
    GAH{1,2}{1,1}=mask_VOI{2,1};
    GAH{1,2}{4,1}=pixelarea;
end
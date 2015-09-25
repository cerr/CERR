function [MVOI3DA] = dicomrt_build3dVOI(VOI,ct,ct_xmesh,ct_ymesh,ct_zmesh)
% dicomrt_build3dVOI(VOI,ct,ct_xmesh,ct_ymesh,ct_zmesh)
%
% Build a 3d matrix array from VOIs.
%
% VOI contains the patients VOIs as read by dicomrt_loadVOI
% ct_xmesh,ct_ymesh,ct_zmesh are OPTIONAL vectors which specify the grid onto new VOI will be interpolated
%
% See also: dicomrt_loadvoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check input
[ct_temp,type_ct,label,PatientPosition]=dicomrt_checkinput(ct);
ct=dicomrt_varfilter(ct_temp);
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

% Tag to attach to cell array 
tag='-3D';

% Create cell array which contains the matrices for creating VOIs in 3D
xdim=length(ct_xmesh);
ydim=length(ct_ymesh);
zdim=length(ct_zmesh);

voi2use=[1:size(VOI,1)];

locate_voi=cell(length(voi2use),1);
filter_array=voi2use;

% Create dummy matrix
emptym=zeros(xdim,ydim,zdim);
dummym=zeros(xdim,ydim,zdim);
xcontourcell=cell(1);
ycontourcell=cell(1);

% Create cell array which contains the matrices for creating VOIs in 3D
MVOI3DA=VOI_temp;

% Set Tags
for k=1:length(voi2use)
    MVOI3DA{2,1}{k,1}=[VOI{k,1},tag];
end

% Find VOI corresponding to slice 
for k=1:length(ct_zmesh)
    for kk=1:length(voi2use)
        % Find VOI corresponding to slice 
        locate_voi{kk}(k)=dicomrt_findvoi2slice(VOI_temp,voi2use(kk),ct_zmesh,k,'z',PatientPosition);
    end
end

for kk=1:length(voi2use)
    % Progress bar data
    count=0;
    total_iterations=zdim+xdim+ydim;
    h = waitbar(0,['Calculation progress for: ', VOI{kk,1}]);
    set(h,'Name','dicomrt_build3dVOI: calculates 3d VOIs');
    
    % Sore Z contour already in VOI
    zcontourcell=VOI{kk,2};
    % For each voi create a matrix with just 1 and 0
    for k=1:zdim
        if isnan(locate_voi{kk}(k))~=1
            % Binary mask
            BW=roipoly(ct_xmesh,ct_ymesh,emptym(:,:,k),...
                VOI{kk,2}{locate_voi{kk}(k)}(:,1)',VOI{kk,2}{locate_voi{kk}(k)}(:,2));
            BWfilter=BW.*filter_array(kk);
            [x,y]=find(BWfilter);
            for kkk=1:length(x)
                dummym(x(kkk),y(kkk),k)=filter_array(kk);
            end
        end
        % Update progress bar
        count=count+1;
        waitbar(count./total_iterations,h);
    end
    % After matrix is created create contours in X and Y direction
    % Loop over X
    for j=1:xdim
        Cx_temp=contourc(ct_zmesh,ct_ymesh,squeeze(dummym(:,j,:)),[filter_array(kk) filter_array(kk)]);
        xcontourcell{j,1}={ct_xmesh(j) Cx_temp};
        % Update progress bar
        count=count+1;
        waitbar(count./total_iterations,h);
    end
    % Loop over Y
    for j=1:ydim
        Cy_temp=contourc(ct_zmesh,ct_xmesh,squeeze(dummym(j,:,:)),[filter_array(kk) filter_array(kk)]);
        ycontourcell{j,1}={ct_ymesh(j) Cy_temp};
        % Update progress bar
        count=count+1;
        waitbar(count./total_iterations,h);
    end
    % Update 3d VOI cell array
    MVOI3DA{2,1}{kk,2}={xcontourcell ycontourcell zcontourcell};
    % Close progress bar
    close(h)
end
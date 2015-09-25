function dicomrt_plotgammamap2dvol(gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,ct,ct_xmesh,ct_ymesh,ct_zmesh,VOI,voi2use)
% dicomrt_plotgammamap2dvol(gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,ct,ct_xmesh,ct_ymesh,ct_zmesh,VOI,voi2use)
%
% Plot gamma maps.
% 
% gamma is the ganmma matrix
% gamma_xmesh,gamma_ymesh,gamma_zmesh are x-y-z coordinates of the center of the gamma-pixel 
% ct is the 3D CT dataset (OPTIONAL)
% ct_xmesh, ct_ymesh, ct_zmesh are the coordinates of the ct voxels (OPTIONAL)
% VOI is an OPTIONAL cell array which contain the patients VOIs as read by dicomrt_loadVOI
% voi2use is an OPTIONAL number pointing to the number of VOIs to be displayed
%
% Example:
%
% dicomrt_plotgammamap2dvol(gamma2dvol,xmesh,ymesh,zmesh,demo1_ct,ct_xmesh,ct_ymesh,ct_zmesh,demo1_voi,9);
%
% plot the gamma map in gamma2dvol on top of a ct slice and with contour of VOI 9.
%
% See also dicomrt_GAMMAcal2D, dicomrt_GAMMAcal2DVol, dicomrt_rendervoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(4,11,nargin))

if size(gamma,3)==1 
    error('dicomrt_plotgammamap2dvol: Format not supported, try dicomrt_plotgammamap. Exit now !');
end

if exist('VOI')==1 & exist('voi2use')==1
    [mask_gamma]=dicomrt_mask(VOI,gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,voi2use,'n');
else
    mask_gamma=gamma;
end

if size(gamma,3)~=length(VOI{voi2use,2})
    disp('Warning: the size of gamma does not match the size of the VOI!');
    disp('There is the possibility that the gamma map was calculated for a different VOI.');
    goahead=input('dicomrt_plotgammamap2dvol: Do you want to continue (y/n) ? (n=default)','s');
    if goahead~='y' | goahead~='Y' 
        error('dicomrt_plotgammamap2dvol: Exiting as requested');
    elseif isempty(goahead)==1
        error('dicomrt_plotgammamap2dvol: Exiting as requested');
    end
end

if length(size(ct))==2 & ct==0
    for k=1:size(gamma,3) % Loop over gamma slices
        % plot ct map
        figure;
        set(gcf,'Name',['dicomrt_plotgammamap2dvol: ',inputname(1),', Z= ',num2str(gamma_zmesh(k))]);
        set(gcf,'NumberTitle','off');
        if exist('VOI')==1 & exist('voi2use')==1
            % plot voi on the same slice 
            p=plot3(VOI{voi2use,2}{k,1}(:,1),VOI{voi2use,2}{k,1}(:,2),...
                VOI{voi2use,2}{k,1}(:,3));
            % set VOI contour to Z=-1 to display together with gamma map
            p_handle=get(p);
            ZData_temp_2=p_handle.ZData;
            for i=1:length(ZData_temp_2)
                ZData_temp_2(i)=-1;
            end
            set(p, 'Color', 'k','LineWidth', 1.5);
            set(p,'ZData',ZData_temp_2); 
        end
        hold;
        % plot gamma map
        %mesh(mask_gamma(:,:,k),'XData',gamma_xmesh,'YData',gamma_ymesh);
        % ms=surf(mask_gamma(:,:,k));
        ms=surfl(mask_gamma(:,:,k));
        shading interp;
        set(ms,'XData',gamma_xmesh,'YData',gamma_ymesh);
        % add labels
        xlabel('X axis (cm)','Fontsize',12);
        ylabel('Y axis (cm)','Fontsize',12);
        zlabel('\gamma','Fontsize',14);
        title(['\gamma map slice: ',num2str(k)],'Fontsize',18);
        axis tight;
    end
else
    % rebuilding mesh matrices
    [xmin,xmax,ymin,ymax,zmin,zmax]=dicomrt_voiboundaries(ct_xmesh,ct_ymesh, ct_zmesh,VOI,voi2use);
    [ct3d_xmesh,ct3d_ymesh,ct3d_zmesh]=dicomrt_rebuildmatrix(ct_xmesh(xmin:xmax),ct_ymesh(ymin:ymax),ct_zmesh);
    for k=1:size(gamma,3) % Loop over gamma slices
        % plot ct map
        figure;
        set(gcf,'Name',['dicomrt_plotgammamap2dvol: ',inputname(1),', Z= ',num2str(ct_zmesh(dicomrt_findsliceVECT(gamma_zmesh,k,ct_zmesh)))]);
        set(gcf,'NumberTitle','off');
        handle=slice(ct3d_xmesh,ct3d_ymesh,ct3d_zmesh,ct(ymin:ymax,xmin:xmax,:),[],[],ct_zmesh(dicomrt_findsliceVECT(gamma_zmesh,k,ct_zmesh)));
        % set ct map to Z=-1 to display together with gamma map
        set(handle,'FaceColor','interp','EdgeColor','none','DiffuseStrength',.8);
        gco_handle=get(handle);
        ZData_temp_1=gco_handle.ZData;
        for i=1:size(ZData_temp_1,1)
            for j=1:size(ZData_temp_1,2)
                ZData_temp_1(i,j)=-1;
            end
        end
        set(handle,'ZData',ZData_temp_1); 
        hold;
        if exist('VOI')==1 & exist('voi2use')==1
            % plot voi on the same slice 
            if k==23
                disp(num2str(k));
            end
            p=plot3(VOI{voi2use,2}{k,1}(:,1),VOI{voi2use,2}{k,1}(:,2),...
                VOI{voi2use,2}{k,1}(:,3));
            % set VOI contour to Z=-1 to display together with gamma map
            p_handle=get(p);
            ZData_temp_2=p_handle.ZData;
            for i=1:length(ZData_temp_2)
                ZData_temp_2(i)=-1;
            end
            set(p, 'Color', 'w','LineWidth', 1.5);
            set(p,'ZData',ZData_temp_2); 
        end
        % plot gamma map
        mesh(mask_gamma(:,:,k),'XData',gamma_xmesh,'YData',gamma_ymesh);
        % add labels
        xlabel('X axis (cm)','Fontsize',12);
        ylabel('Y axis (cm)','Fontsize',12);
        zlabel('\gamma','Fontsize',14);
        title(['\gamma map slice: ',num2str(k)],'Fontsize',18);
        axis tight;
    end
end

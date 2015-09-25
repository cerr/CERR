function [surf] = dicomrt_surfdose(inputdose,dose_xmesh,dose_ymesh,dose_zmesh,slice2disp,VOI,voi2use)
% dicomrt_surfdose(inputdose,dose_xmesh,dose_ymesh,dose_zmesh,slice2disp,VOI,voi2use)
%
% Show 2D dose distribution in 3D.
% 
% inputdose contains the 3D dose distribution
% dose_xmesh,dose_ymesh,dose_zmesh are x-y-z coordinates of the center of the dose-pixel 
% slice2disp is a vector containing the number of the slice to be meshed (not the coordinate !)
% VOI is an OPTIONAL cell array which contain the patients VOIs as read by dicomrt_loadVOI
% voi2use is the number of the VOI to be used for masking the dose matrix.
%
% NOTE: voi2use cannot be a vector. VOIs can be added to the plot later holding it on and using dicomrt_rendervoi.
%
% Example:
%
% dicomrt_surfdose(A,xmesh,ymesh,zmesh,'x',[10 15],A_voi,1)
%
% shows a surface plot of the planar dose matrix A perpendicular to the X axis on slices 10 and 15.
% A matrix is masked with structure #1 from A_voi cell array.
%
% See also dicomrt_dosegradient, dicomrt_voiboundaries
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(5,7,nargin))

% Check case and set-up some parameters and variables
[dose_temp,type_dose,doselabel,PatientPosition]=dicomrt_checkinput(inputdose);
dose=dicomrt_varfilter(dose_temp);

% Match slice to slice2disp with slice in VOI
if exist('VOI')==1 & exist('voi2use')==1
    [VOI_temp]=dicomrt_checkinput(VOI);
    VOI=dicomrt_varfilter(VOI_temp);
    % Find VOI corresponding to slice
    for i=1:length(slice2disp)
        locate_voi(i)=dicomrt_findvoi2slice(VOI_temp,voi2use,dose_zmesh,slice2disp(i),'z',PatientPosition);
    end
    slice2display_header=['dicomrt_surfdose : ',inputname(1),' (',VOI{voi2use,1},')'];
else
    slice2display_header=['dicomrt_surfdose : ',inputname(1)];
end

% Rebuilding mesh
[rtdose_xmesh,rtdose_ymesh,rtdose_zmesh]=dicomrt_rebuildmatrix(dose_xmesh,dose_ymesh,dose_zmesh);

% Mask dose with selected voi 
if exist('VOI')==1 & exist('voi2use')==1
    % Plot dose surfaces
    figure
    set(gcf,'Name',slice2display_header);
    if length(slice2disp)>1
        for i=1:length(slice2disp)
            subplot(2,round((length(slice2disp)/2)),i);
            % Locate VOI boundaries
            if isnan(locate_voi(i))~=1
                [locate_voi_min_x,locate_voi_max_x,locate_voi_min_y,locate_voi_max_y] = ...
                    dicomrt_voiboundaries_single(locate_voi(i),dose_xmesh,dose_ymesh,VOI_temp,voi2use,PatientPosition);
                h=surfl(dose(locate_voi_min_y:locate_voi_max_y,locate_voi_min_x:locate_voi_max_x,slice2disp(i)));
                dicomrt_setaxistick(dose_xmesh,locate_voi_min_x,locate_voi_max_x,'x',h);
                dicomrt_setaxistick(dose_ymesh,locate_voi_min_y,locate_voi_max_y,'y',h);
            else
                h=surfl(dose(:,:,slice2disp(i)));
            end
            shading interp
            colormap(gray)
            xlabel('X axis (cm)'); 
            ylabel('Y axis (cm)'); 
            zlabel('dose (Gy)'); 
            axis tight
            grid on
            title(['Slice no. ',num2str(slice2disp(i)),' (Z=',num2str(dose_zmesh(slice2disp(i))),' cm)'],'Interpreter','none');
            % Debug
            %disp(['******']);
            %disp(['Slice number: ',num2str(slice2disp(i))]);
            %disp(['Z location: ',num2str(dose_zmesh(slice2disp(i)))]);
            %disp(['Corresponding VOI number: ',num2str(voiZ_index(locate_voi))]);
            %disp(['Corresponding VOI Z location: ',num2str(voiZ(locate_voi))]);
        end
    else
        % Locate VOI boundaries
        if isnan(locate_voi)~=1
            [locate_voi_min_x,locate_voi_max_x,locate_voi_min_y,locate_voi_max_y] = ...
                dicomrt_voiboundaries_single(locate_voi,dose_xmesh,dose_ymesh,VOI_temp,voi2use,PatientPosition);
            h=surfl(dose(locate_voi_min_y:locate_voi_max_y,locate_voi_min_x:locate_voi_max_x,slice2disp));
            dicomrt_setaxistick(dose_xmesh,locate_voi_min_x,locate_voi_max_x,'x',h);
            dicomrt_setaxistick(dose_ymesh,locate_voi_min_y,locate_voi_max_y,'y',h);
        else
            h=surfl(dose(:,:,slice2disp));
        end
        shading interp
        colormap(gray)
        xlabel('X axis (cm)')
        ylabel('Y axis (cm)')
        zlabel('dose (Gy)')
        axis tight
        grid on
        title(['Slice no. ',num2str(slice2disp),' (Z=',num2str(dose_zmesh(slice2disp)),' cm)'],'Interpreter','none');
    end
else
    % Plot dose surfaces
    figure
    set(gcf,'Name',slice2display_header);
    if length(slice2disp)>1
        for i=1:length(slice2disp)
            subplot(2,round((length(slice2disp)/2)),i);
            h=surfl(dose(:,:,slice2disp(i)));
            shading interp
            colormap(gray)
            xlabel('X axis (cm)'); 
            ylabel('Y axis (cm)'); 
            zlabel('dose (Gy)'); 
            axis tight
            grid on
            title(['Slice no. ',num2str(slice2disp(i)),' (Z=',num2str(dose_zmesh(slice2disp(i))),' cm)'],'Interpreter','none');
        end
    else
        % Locate VOI boundaries
        h=surfl(dose(:,:,slice2disp));
        shading interp
        colormap(gray)
        xlabel('X axis (cm)')
        ylabel('Y axis (cm)')
        zlabel('dose (Gy)')
        axis tight
        grid on
        title(['Slice no. ',num2str(slice2disp),' (Z=',num2str(dose_zmesh(slice2disp)),' cm)'],'Interpreter','none');
    end
end

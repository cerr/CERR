function [study,xmesh,ymesh,zmesh,tags]=dicomrt_d2c_coordsystem(study,xmesh,ymesh,zmesh,tags)
% dicomrt_d2c_coordsystem(study,xmesh,ymesh,zmesh,tags)
%
% Convert DICOM data from native coordinate system to RTOG coordinate system
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 
% LM 04/28/2006 DK 
%         Fix for dose x-coordinates when patient position is FFS.

% Check input data
% PatientPosition is N/A in VOI hence it must be defined previously
% and stored in tags.dicomPatientPosition if we are dealing with VOI
if ~isfield(tags,'dicomPatientPosition') || isempty(tags(1).dicomPatientPosition)
    [study,type,dummylabel,PatientPosition]=dicomrt_checkinput(study);
    %tags.dicomPatientPosition=PatientPosition;
    for i=1:length(tags)
        tags(i).('dicomPatientPosition') = PatientPosition;
    end
else
    [study,type,dummylabel]=dicomrt_checkinput(study);
    PatientPosition=tags.dicomPatientPosition;
end

% Get DICOM-RT toolbox dataset info
study_pointer=study{1,1};
study_array=study{2,1};

% Accounting for different coordinate system between DICOM and RTOG
%
% NOTE: The origin of the RTOG coordinate system is defined as the coordinates of
% the geometrical center of the image. Offsets along the x- and y-direction
% are calculated from the DICOM original data.
%
if strcmpi('VOI',type)~=1                       % Separate case if study is a VOI
    if PatientPosition==1                       % HFS
        study_array                 = flipdim(study_array,3);
        tags.hio                    = 'IN';
        tags.pos                    = 'NOSE UP';
        if strcmpi('CT',type)~=1
            xmesh                       = xmesh;
            ymesh                       = -ymesh;
            zmesh                       = -zmesh;
            zmesh                       = flipdim(zmesh,1);
            %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted 
            tags.coord1OFFirstPoint     = xmesh(1);
            tags.coord2OFFirstPoint     = ymesh(1);
            temp_diff_x                 = diff(xmesh);
            temp_diff_y                 = diff(ymesh);
            tags.horizontalGridInterval = temp_diff_x(1);
            tags.verticalGridInterval   = temp_diff_y(1);
        else
            tags.originalCTxmesh        = xmesh;
            tags.originalCTymesh        = ymesh;
            tags.originalCTzmesh        = zmesh;
            xmesh                       = xmesh;
            ymesh                       = -ymesh;
            zmesh                       = -zmesh;
            zmesh                       = flipdim(zmesh,1);
            %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted 
            tags.xOffset                = xmesh(1) + sqrt(power((xmesh(1)-xmesh(end)),2))./2;
            tags.yOffset                = ymesh(1) - sqrt(power((ymesh(1)-ymesh(end)),2))./2;
            temp_diff_x                 = diff(xmesh);
            temp_diff_y                 = diff(ymesh);
            tags.grid1Units             = abs(temp_diff_x(1));
            tags.grid2Units             = abs(temp_diff_y(1));
        end
        tags.xcoordOfNormaliznPoint = '';
        tags.ycoordOfNormaliznPoint = '';
        tags.zcoordOfNormaliznPoint = '';
    elseif PatientPosition==2                   % FFS
        study_array                 = flipdim(study_array,3);
        tags.hio                    = 'OUT';
        tags.pos                    = 'NOSE UP';
        if strcmpi('CT',type)~=1
%             xmesh                       = xmesh;
            xmesh                       = -xmesh;%DK 
            ymesh                       = -ymesh;
            zmesh                       = -zmesh;
            zmesh                       = flipdim(zmesh,1);
            %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted
%             tags.coord1OFFirstPoint     = xmesh(1);
            tags.coord1OFFirstPoint     = -xmesh(1);%DK
            tags.coord2OFFirstPoint     = ymesh(1);
            temp_diff_x                 = diff(xmesh);
            temp_diff_y                 = diff(ymesh);
            tags.horizontalGridInterval = temp_diff_x(1);
            tags.verticalGridInterval   = temp_diff_y(1);
        else
            tags.originalCTxmesh        = xmesh;
            tags.originalCTymesh        = ymesh;
            tags.originalCTzmesh        = zmesh;
            xmesh                       = xmesh;
            ymesh                       = -ymesh;
            zmesh                       = -zmesh;
            zmesh                       = flipdim(zmesh,1);
            %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted
            tags.xOffset                = xmesh(1) + sqrt(power((xmesh(1)-xmesh(end)),2))./2;
            tags.yOffset                = ymesh(1) - sqrt(power((ymesh(1)-ymesh(end)),2))./2;
            temp_diff_x                 = diff(xmesh);
            temp_diff_y                 = diff(ymesh);
            tags.grid1Units             = abs(temp_diff_x(1));
            tags.grid2Units             = abs(temp_diff_y(1));
        end
        tags.xcoordOfNormaliznPoint = '';
        tags.ycoordOfNormaliznPoint = '';
        tags.zcoordOfNormaliznPoint = '';
    elseif PatientPosition==3                   % HFP
        study_array                 = flipdim(study_array,3);
        tags.hio                    = 'IN';
        tags.pos                    = 'NOSE DOWN';
        if strcmpi('CT',type)~=1
            xmesh                       = -xmesh;
            ymesh                       = ymesh;
            zmesh                       = -zmesh;
            zmesh                       = flipdim(zmesh,1);
            %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted 
            tags.coord1OFFirstPoint     = xmesh(1);
            tags.coord2OFFirstPoint     = ymesh(1);
            temp_diff_x                 = diff(xmesh);
            temp_diff_y                 = diff(ymesh);
            tags.horizontalGridInterval = temp_diff_x(1);
            tags.verticalGridInterval   = temp_diff_y(1);
        else
            tags.originalCTxmesh        = xmesh;
            tags.originalCTymesh        = ymesh;
            tags.originalCTzmesh        = zmesh;
            xmesh                       = -xmesh;
            ymesh                       = ymesh;
            zmesh                       = -zmesh;
            zmesh                       = flipdim(zmesh,1);
            %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted 
            tags.xOffset                = xmesh(1) + sqrt(power((xmesh(1)-xmesh(end)),2))./2;
            tags.yOffset                = ymesh(1) - sqrt(power((ymesh(1)-ymesh(end)),2))./2;
            temp_diff_x                 = diff(xmesh);
            temp_diff_y                 = diff(ymesh);
            tags.grid1Units             = abs(temp_diff_x(1));
            tags.grid2Units             = abs(temp_diff_y(1));
        end
        tags.xcoordOfNormaliznPoint = '';
        tags.ycoordOfNormaliznPoint = '';
        tags.zcoordOfNormaliznPoint = '';
    else                                        % FFP
        study_array                 = flipdim(study_array,3);
        tags.hio                    = 'OUT';
        tags.pos                    = 'NOSE DOWN';
        if strcmpi('CT',type)~=1
            xmesh                       = -xmesh;
            ymesh                       = ymesh;
            zmesh                       = -zmesh;
            zmesh                       = flipdim(zmesh,1);
            %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted
            tags.coord1OFFirstPoint     = xmesh(1);
            tags.coord2OFFirstPoint     = ymesh(1);
            temp_diff_x                 = diff(xmesh);
            temp_diff_y                 = diff(ymesh);
            tags.horizontalGridInterval = temp_diff_x(1);
            tags.verticalGridInterval   = temp_diff_y(1);
        else
            tags.originalCTxmesh        = xmesh;
            tags.originalCTymesh        = ymesh;
            tags.originalCTzmesh        = zmesh;
            xmesh                       = -xmesh;
            ymesh                       = ymesh;
            zmesh                       = -zmesh;
            zmesh                       = flipdim(zmesh,1);
            %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted
            tags.xOffset                = xmesh(1) + sqrt(power((xmesh(1)-xmesh(end)),2))./2;
            tags.yOffset                = ymesh(1) - sqrt(power((ymesh(1)-ymesh(end)),2))./2;
            temp_diff_x                 = diff(xmesh);
            temp_diff_y                 = diff(ymesh);
            tags.grid1Units             = abs(temp_diff_x(1));
            tags.grid2Units             = abs(temp_diff_y(1));
        end
        tags.xcoordOfNormaliznPoint = '';
        tags.ycoordOfNormaliznPoint = '';
        tags.zcoordOfNormaliznPoint = '';
    end
else
    if PatientPosition==1                       % HFS flip dimensions
        xmesh                       = xmesh;
        ymesh                       = -ymesh;
        zmesh                       = -zmesh;
        for jj=1:size(study_array,1)            % loop though the number of VOIs
            for kk=1:size(study_array{jj,2},1)  % loop though the number of sections
                % reverse Z
                study_array{jj,2}{kk}(:,3)=-study_array{jj,2}{kk}(:,3);
                % reverse Y
                study_array{jj,2}{kk}(:,2)=-study_array{jj,2}{kk}(:,2);
            end
        end
    elseif PatientPosition==2                   % FFS flip dimensions
        xmesh                       = xmesh;
        ymesh                       = -ymesh;
        zmesh                       = -zmesh;
        for jj=1:size(study_array,1)            % loop though the number of VOIs
            for kk=1:size(study_array{jj,2},1)  % loop though the number of sections
                % reverse Z
                study_array{jj,2}{kk}(:,3)=-study_array{jj,2}{kk}(:,3);
                % reverse Y
                study_array{jj,2}{kk}(:,2)=-study_array{jj,2}{kk}(:,2);
            end
        end
    elseif PatientPosition==3                   % HFP nothing to do
        xmesh                       = -xmesh;            
        ymesh                       = ymesh;
        zmesh                       = -zmesh;
        for jj=1:size(study_array,1)            % loop though the number of VOIs
            for kk=1:size(study_array{jj,2},1)  % loop though the number of sections
                % reverse Z
                study_array{jj,2}{kk}(:,3)=-study_array{jj,2}{kk}(:,3);
                % reverse X
                study_array{jj,2}{kk}(:,1)=-study_array{jj,2}{kk}(:,1);
            end
        end
    else
        xmesh                       = -xmesh;            
        ymesh                       = ymesh;
        zmesh                       = -zmesh;
        for jj=1:size(study_array,1)            % loop though the number of VOIs
            for kk=1:size(study_array{jj,2},1)  % loop though the number of sections
                % reverse Z
                study_array{jj,2}{kk}(:,3)=-study_array{jj,2}{kk}(:,3);
                % reverse X
                study_array{jj,2}{kk}(:,1)=-study_array{jj,2}{kk}(:,1);
            end
        end
    end
end
    
% Return data
study{2,1}=study_array;
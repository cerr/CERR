function [newVOI]=dicomrt_fitvoi2ct(VOI,zmesh,study)
% dicomrt_fitvoi2ct(VOI,zmesh,study)
% 
% Fit VOI Z-location to reference Z-location 
%
% When necessary this operation reduce the number of VOI Z locations so that they match 
% in number and in position to the provided dataset of reference (zmesh).
% 
% study is an optional argument which represents the original diagnostic
% scan dataset. When this is provided, calculations are made using the
% SliceThickness parameter, if originally stored in the DICOM file. 
% 
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(2,3,nargin))

% Check input
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

newVOI=VOI_temp;

if exist('study')==1
    slice_thickness=dicomrt_getslicethickness(study);
    if isempty(slice_thickness)==1
        slice_thickness=diff(zmesh);
        slice_thickness=vertcat(slice_thickness,slice_thickness(end));
    end
end

for k=1:size(newVOI{2,1},1) % loop through the number of VOIs
    newVOI{2,1}{k,2}=[];
end

for k=1:size(VOI,1) % Loop  through the number of VOIs
    [voiZ,index] = dicomrt_getvoiz(VOI_temp,k);
    voiZ=dicomrt_makevertical(voiZ);
    index=dicomrt_makevertical(index);
    slice=0;
    for j=1:length(zmesh) % loop through the number of CT
        locate_point=find(voiZ==zmesh(j)); % search for a match between Z-location of current CT and voiZ
        if isempty(locate_point)==1 
            % if match is not found it's either because the Z-location of current CT is outside range
            % or because VOI is defined on a slightly different plane. Then
            % try with dicomrt_findsliceVECT. Dicomrt_findsliceVECT
            % operates on the edges by default. 
            % This means that if contours of a VOI are not defined at the
            % CT slices but in other reconstructed planes some of them will be lost during the process. 
            % Although by setting the (optional) last argument  
            % to zero dicomrt_findsliceVECT searches considering zmesh as
            % centers of bins this is not reccommended in this case.
            %
            %[locate_point]=dicomrt_findsliceVECT(zmesh,j,voiZ,1,1);
            %
            % The above solution was OK but in some cases the histc algo.
            % used within dicomrt_findsliceVECT did not performed as
            % expected resulting in some segments duplicate.
            % The following solution gives better results, especially when
            % slice_thickness is calculated from DICOM info provided with
            % the 'study' argument.
            %
            [locate_point]=find(voiZ>zmesh(j)-slice_thickness(j)./2 & voiZ<zmesh(j)+slice_thickness(j)./2);
            if isempty(locate_point)~=1 
                % if a match is found the VOI segment was defined of a
                % plane 'close' to the Z-location of the VOI
                if length(locate_point)>1
                    % if this happens we have to decide i we are dealing
                    % with multiple segments on the same slice or if
                    % mpre segments on different slices, all 'close' to the 
                    % Z-location of the CT have been 'dragged' into the
                    % selection.
                    if find(diff(voiZ(locate_point)))
                        % different segments on different slices
                        % pick the first. Can be coded to cpick the closest
                        % to the Z-location of CT.
                        locate_point=locate_point(1);
                    end
                end
                for i=1:length(locate_point)
                    slice=slice+1;
                    newVOI{2,1}{k,2}{slice,1}=VOI{k,2}{index(locate_point(i))};
                    newVOI{2,1}{k,2}{slice,1}(:,3)=zmesh(j);
                end
            end
        else
            % if match is found it's because this segment(s) of the VOI was(were) defined at the Z-location 
            % of the current CT
            for i=1:length(locate_point)
                % store all the segments with the Z location of the current CT.
                slice=slice+1;
                newVOI{2,1}{k,2}{slice,1}=VOI{k,2}{index(locate_point(i))};
                newVOI{2,1}{k,2}{slice,1}(:,3)=zmesh(j);
            end
        end
        clear locate_point;
    end
end
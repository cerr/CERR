function [gamma,phase,dta,alpha,xmesh_lv,ymesh_lv,zmesh_lv]=dicomrt_GAMMAcal2D(evalm,refm,dose_xmesh,dose_ymesh,dose_zmesh,slice,resf,range,dta_criteria,dd_criteria,voi,voiselect,pbopt)
% dicomrt_GAMMAcal2D(evalm,refm,dose_xmesh,dose_ymesh,dose_zmesh,slice,resf,range,dta_criteria,dd_criteria,voi,voiselect,pbopt);
%
% Calculates 2D gamma distribution for a 2D dataset using a 2D algorithm.
%
% evalm is the 2D matrix to evaluate.
% refm is the reference 2D matrix.
%   Both eval and ref can be a TPS generated dataset or a MC generated dataset.
%   Doses are normalised to the target dose whenever is possible.
%   If no normalization dose is provided within the data it is assumed that matrices are already normalised.
% dose_xmesh, dose_ymesh, are the coordinates of the center of the pixels for eval and ref.
% slice is the number of the slice on which gamma should be calculated
% resf is the "resolution factor". Each voxel is divided resf times to allow dose to be interpolated
%   and quantities calculated. The higher resf the more accurate the calculation is, the slower the 
%   function will be.
% range is the "search range". Range is the number of pixel about (j,i) that is considered for calculation.
%   If a dta or a dd match is not found within the search range gamma and all the other quantities in that point
%   will be set to infinite value.
% dta_criteria is the Distance-to-agreement criteria in cm (e.g. 0.3).
% dd_criteria:
%   1) IF matrices ARE NOT NORMALIZED before calling the function 
%      dta_criteria is the percentage dose difference (e.g. =0.03);
%   2) IF matrices ARE already NORMALIZED before calling the function
%      dd_criteria must be given accordingly to the normalization applyed 
%      (e.g. =0.03 for 3% over dose norm =1Gy, or =1.98 for 3% over dose norm=66Gy).
% voi and voiselect are the vois' cell array and the # of the voi to be used for the gamma calculation respectively.
%   They have to be specified together. Both matrices will be masked and reduced in size accordingly with the selected
%   voi's dimensions. This reduce calculation time especially for the 3D algorithm.
% pbopt progress bar option (OPTIONAL): =0 (default) no progress bar is displayed, ~0 progress bar is displayed
% 
% Example: 
%
% [gamma1_2,phase1_2,dta1_2,alpha1_2,xmesh,ymesh]=dicomrt_GAMMAcal2D(image_eval,image_ref, ...
%                                                             xmesh_red,ymesh_red,40,2,4,0.3,0.03);
%
% returns the calculated gamma function for image_eval vs image_ref at slice # 40 in gamma1_2. 
% Gamma is calculated with 3%-3mm DD-DTA criteria.
% The phase is returned in phase1_2, the dta matrix in dta1_2.
% The function return also the direction cosines in alpha1_2. These are the 
% direction cosines on the gamma vector in the two dimensional space xy. The direction
% cosines may provide useful information in detecting systematic spatial displacements between eval and ref.
% Coordinates of the xy location where gamma is defined are returned in xmesh and ymesh.
%
% The concept of gamma function was developed by Low et al Med. Phys. 25 656-661.
%
% See also dicomrt_gvhcal, dicomrt_gahcal
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(10,13,nargin))

if nargin >10 & (exist('voi')==1 & exist('voiselect')~=1) | (exist('voi')~=1 & exist('voiselect')==1)
    error('dicomrt_GAMMAcal2D: Check VOI and voi2plot: they must be both present or both absent. Exit now!');
end

if exist('pbopt')~=1
    pbopt=0;
end

% Suppress warnings
warning off MATLAB:divideByZero

% Check case and set-up some parameters and variables
[eval_temp,type_dose_one,label1,PatientPosition]=dicomrt_checkinput(evalm);
[ref_temp,type_dose_two,label2,PatientPosition]=dicomrt_checkinput(refm);
local_eval=dicomrt_varfilter(eval_temp);
ref=dicomrt_varfilter(ref_temp);

% Get DICOM-RT toolbox dataset info
local_eval_pointer=eval_temp{1,1};
local_eval_header=local_eval_pointer{1};
ref_pointer=ref_temp{1,1};
ref_header=ref_pointer{1};

[voi_temp]=dicomrt_checkinput(voi);
voi=dicomrt_varfilter(voi_temp);

if strcmpi(type_dose_one,'rtplan')==1 & (strcmpi(type_dose_two,'mc')==1 | strcmpi(type_dose_two,'unknown')==1)
    targetdose_one=getfield(local_eval_header.DoseReferenceSequence,'Item_1','TargetPrescriptionDose'); % normalisation factor
    % Mask arrays
    temp=ref;
    % temp(find(local_eval==0))=0;
    % local_eval(find(temp==0))=0;
    % Normalise dose and calculate dose difference
    eval_norm_temp=local_eval(:,:,slice)/targetdose_one*100;
    ref_norm_temp=temp(:,:,slice)/targetdose_one*100;
elseif strcmpi(type_dose_two,'rtplan')==1 & (strcmpi(type_dose_one,'mc')==1 | strcmpi(type_dose_one,'unknown')==1)
    targetdose_two=getfield(ref{1,1}.DoseReferenceSequence,'Item_1','TargetPrescriptionDose'); % normalisation factor
    % Mask arrays
    temp=local_eval;
    % temp(find(ref==0))=0;
    % ref(find(temp==0))=0;
    % Normalise dose and calculate dose difference
    eval_norm_temp=temp(:,:,slice)/targetdose_two*100;
    ref_norm_temp=ref(:,:,slice)/targetdose_two*100;
elseif strcmpi(type_dose_one,'rtplan')==1 & strcmpi(type_dose_two,'rtplan')==1
    targetdose_one=getfield(local_eval_header.DoseReferenceSequence,'Item_1','TargetPrescriptionDose'); % normalisation factor
    targetdose_two=getfield(ref_header.DoseReferenceSequence,'Item_1','TargetPrescriptionDose'); % normalisation factor
    % no mask is performed. We assume TPS dose are calculated on the same patient using the same patient outline outline
    % Normalise dose and calculate dose difference
    eval_norm_temp=local_eval(:,:,slice)/targetdose_one*100;
    ref_norm_temp=ref(:,:,slice)/targetdose_two*100;
elseif (strcmpi(type_dose_one,'mc')==1 | strcmpi(type_dose_one,'unknown')==1) & ...
        (strcmpi(type_dose_one,'mc')==1 | strcmpi(type_dose_two,'unknown')==1)
    eval_norm_temp=local_eval(:,:,slice);
    ref_norm_temp=ref(:,:,slice);
else
    error('dicomrt_GAMMAcal2D: Cannot determine dose arrays format. Exit now!');
end

% Mask matrices as appropriate
if exist('voi')==1 & exist('voiselect')==1
    [locate_voi_min_x,locate_voi_max_x,locate_voi_min_y,locate_voi_max_y] = dicomrt_voiboundaries(...
        dose_xmesh,dose_ymesh,dose_zmesh,voi_temp,voiselect,PatientPosition);
    eval_norm=eval_norm_temp(locate_voi_min_y:locate_voi_max_y,locate_voi_min_x:locate_voi_max_x);
    ref_norm=ref_norm_temp(locate_voi_min_y:locate_voi_max_y,locate_voi_min_x:locate_voi_max_x);
else
    locate_voi_min_x=1;
    locate_voi_max_x=length(dose_xmesh);
    locate_voi_min_y=1;
    locate_voi_max_y=length(dose_ymesh);
    eval_norm=eval_norm_temp;
    ref_norm=ref_norm_temp;
end

% 
% Define parameters
% radians to degrees conversion factor
r2d=360/(2*pi);
d2r=2*pi/360;

% Retrieve basic information
pixel_spacing_x=dicomrt_mmdigit(dose_xmesh(2)-dose_xmesh(1),7);
pixel_spacing_y=dicomrt_mmdigit(dose_ymesh(2)-dose_ymesh(1),7);

% 2D algorithm
%
% create grid for matrix interpolation
% this is done using the resolution factor resf
%[xmesh,ymesh]=dicomrt_build2dgrid(dose_xmesh-pixel_spacing_x/resf,dose_ymesh-pixel_spacing_y/resf);

% Start calculating elapsed time
% tic

disp('(+) Initializing ...');

[xmesh,ymesh]=dicomrt_build2dgrid(dose_xmesh(locate_voi_min_x:locate_voi_max_x),...
    dose_ymesh(locate_voi_min_y:locate_voi_max_y));
xmesh_res=imresize(xmesh,resf,'bilinear');
ymesh_res=imresize(ymesh,resf,'bilinear');

% These variables are exported to use with other functions
xmesh_lv=xmesh(1,:);
ymesh_lv=ymesh(:,1);
zmesh_lv=dose_zmesh(slice);

% Normalize quantities
eval_norm=eval_norm./dd_criteria;
ref_norm=ref_norm./dd_criteria;
xmesh=xmesh./dta_criteria;
ymesh=ymesh./dta_criteria;
xmesh_res=xmesh_res./dta_criteria;
ymesh_res=ymesh_res./dta_criteria;

% interpolate reference matrix 
eval_norm_interp(:,:)=interp2(xmesh,ymesh,eval_norm(:,:),xmesh_res,ymesh_res);

% Define output size
gamma=zeros(size(ref_norm));
phase=zeros(size(ref_norm));
dta=zeros(size(ref_norm));
alpha=zeros(size(ref_norm));

% logical steps being taken:
%
% 0) So far the reference matrix was modified to comply with the resolution parameter resf input by the user.
%    Two new matrices which incorporate the dose difference criteria (dd_criteria) were also built.
% 1) The search_range parameter will be used now to define an area around each voxel of the new reference matrices.
%    This area is called Search Area (SA) and will be temporary stored onto a matrix called Transit Area (TA).
%    Distance to agreemenet (DTA) will be then searched within TA for each point of the evaluation matrix.
% 2) If one or more DTA matches are found the dose difference will be calculated for the minimum of the DTA matches.
%
% 1a) Calculate voxels that will define the search volume in 3D

disp('(+) Calculating ...');

if pbopt~=0
    h = waitbar(0,'Calculation progress');
    set(h,'Name','dicomrt_GAMMAcal2D: calculates gamma function');
end

for j=1:size(ref_norm,1)       % loop over y
    for i=1:size(ref_norm,2)   % loop over x
        % all voxels in the new matrices are used for the DTA search. A portion of the new matrices will be copied
        % in the temporary matrix called volume. In order to do this we need to calculate the index that refer to 
        % the portion of the matrix to copy.
        if i==1
            iSAmax=range*resf+resf;
            iSAmin=1;
        elseif i>1 & i< range +1
            iSAmax=resf*i+range*resf;
            iSAmin=1;
        elseif i>=range +1 & i<size(ref_norm,2)-range
            iSAmax=resf*i+range*resf;
            iSAmin=i*resf-(resf-1)-range*resf;
        elseif i>=size(ref_norm,2)-range
            iSAmax=size(eval_norm_interp,2);
            iSAmin=i*resf-(resf-1)-range*resf;
        end
        
        if j==1
            jSAmax=range*resf+resf;
            jSAmin=1;
        elseif j>1 & j< range +1
            jSAmax=resf*j+range*resf;
            jSAmin=1;
        elseif j>=range +1 & j<size(ref_norm,1)-range
            jSAmax=resf*j+range*resf;
            jSAmin=j*resf-(resf-1)-range*resf;
        elseif j>=size(ref_norm,1)-range
            jSAmax=size(eval_norm_interp,1);
            jSAmin=j*resf-(resf-1)-range*resf;
        end
        
        % debug start
        %display(['i is: ',num2str(i),' - j is: ', num2str(j)]);
        %display(['iSAmin is: ',num2str(iSAmin),' - iSAmax is: ', num2str(iSAmax)]);
        %display(['jSAmin is: ',num2str(jSAmin),' - jSAmax is: ', num2str(jSAmax)]);
        %if j==64 & i==22
        %    disp('debug');
        %end
        
        temp_xmesh_res=xmesh_res(jSAmin:jSAmax,iSAmin:iSAmax);
        temp_ymesh_res=ymesh_res(jSAmin:jSAmax,iSAmin:iSAmax);
        temp_eval_norm=eval_norm_interp(jSAmin:jSAmax,iSAmin:iSAmax);
        
        temp_dta=zeros(size(temp_eval_norm));
        %temp_dta(:,:)=nan;
        temp_dta(:,:)=inf;
        
        temp_dd=zeros(size(temp_eval_norm));
        %temp_dd(:,:)=nan;
        temp_dd(:,:)=inf;
        
        temp_gamma=zeros(size(temp_eval_norm));
        %temp_gamma(:,:)=nan;
        temp_gamma(:,:)=inf;
        
        dd_spot=eval_norm(j,i)-ref_norm(j,i);
                
        [lo]=find(temp_eval_norm<=ref_norm(j,i)+1 & temp_eval_norm>ref_norm(j,i)-1);
        
        % initialize variable: lo will contain the location (number) of the pixel
        % where the match was found. Pixel numbering is done following the example
        % below for a 2d matrix:
        %
        % A=
        %
        % 1 1 1   1|  /|  /|
        % 2 2 2    | / | / |
        % 1 3 1    |/  |/  |9
        %
        % 6 is the number of the pixel which contains the value 3 and it is the
        % result of the following command:
        %
        % find(A(:,:)==3)

        if isempty(lo)~=1
            temp_dta(lo)=sqrt((temp_xmesh_res(lo)-xmesh(j,i)).^2+(temp_ymesh_res(lo)-ymesh(j,i)).^2);
            temp_dd(lo)=temp_eval_norm(lo)-ref_norm(j,i);
            temp_gamma(lo)=sqrt(temp_dta(lo).^2+temp_dd(lo).^2);
            [temp_gamma_min,temp_gamma_min_index]=min(temp_gamma(lo));
            [gamma(j,i),index]=min([temp_gamma_min sqrt(dd_spot.^2)]);
            % the following if is due because dicomrt_mask, which is used to calculate DVHs GVHs and GAHs,
            % mask matrices to zero. This makes impossible to disguish between a point outside the VOI from
            % a point with dose or gamma equal to 0.
            % In practice this is not a problem for DVHs but can represent a problem for gamma
            % calculation. A value 0 or 0.001 do not change the meaning of gamma.
            %
            if gamma(j,i)==0
                gamma(j,i)=0.01;
            end
            %
            if index==2
                phase(j,i)=0;
                dta(j,i)=0;
                alpha(j,i)=0;
            else
                phase(j,i)=asin(temp_dd(lo(temp_gamma_min_index))./gamma(j,i))*r2d;
                dta(j,i)=temp_dta(lo(temp_gamma_min_index));
                alpha(j,i)=acos(((temp_xmesh_res(lo(temp_gamma_min_index))-xmesh(j,i))./dta(j,i)))*r2d;
                %alpha(j,i)=acos((temp_xmesh_res(lo(temp_gamma_min_index))-xmesh(j,i))/...
                %    (gamma(j,i)*cos(d2r*phase(j,i))))*r2d;
                %alpha(j,i)=acos((temp_xmesh_res(lo(temp_gamma_min_index))-xmesh(j,i))/...
                %    temp_dta(lo(temp_gamma_min_index)))*r2d;
                %alpha(j,i)=acos(temp_dta(lo(temp_gamma_min_index))/(gamma(j,i)*cos(d2r*phase(j,i))))*r2d;
                %alpha(j,i)=acos((temp_xmesh_res(lo(temp_gamma_min_index))-xmesh(j,i))/...
                %    (gamma(j,i)*cos(phase(j,i))))*r2d;
                %alpha(j,i)=asin(temp_dd(lo(temp_gamma_min_index))*sin(phase(j,i)*d2r))*r2d;
            end
        else
            %gamma(j,i)=nan;
            gamma(j,i)=inf;
            %phase(j,i)=nan;
            phase(j,i)=inf;
            %dta(j,i)=nan;
            dta(j,i)=inf;
            %alpha(j,i)=nan;
            alpha(j,i)=inf;
        end
        if pbopt~=0
            waitbar(j/size(ref_norm,1),h);
        end
    end
end
disp('(=) Calculation completed.');
if pbopt~=0
    close(h)
end

% Returns elapsed time
% toc

% Plot
%figure;
%set(gcf,'Name',['dicomrt_GAMMAcal2D: local_eval= ',inputname(1),', ref= ',inputname(2)]);
%surf(gamma,phase,'XData',dose_xmesh(locate_voi_min_x:locate_voi_max_x),'Ydata',dose_ymesh(locate_voi_min_y:locate_voi_max_y));
%colormap jet;
%shading interp;
%title(['gamma/phase',' Z= ',num2str(dose_zmesh(slice))],'FontSize',16);
%xlabel('X axis (cm)','FontSize',12);
%ylabel('Y axis (cm)','FontSize',12);
%grid on;
%colorbar;
%set(gca,'XLim',[min(dose_xmesh(locate_voi_min_x:locate_voi_max_x)) max(dose_xmesh(locate_voi_min_x:locate_voi_max_x))]);
%set(gca,'YLim',[min(dose_ymesh(locate_voi_min_y:locate_voi_max_y)) max(dose_ymesh(locate_voi_min_y:locate_voi_max_y))]);
%set(gca,'ZLim',[min(min(gamma)) max(max(gamma))]);
%set(gca,'ZLim',[min(min(gamma)) 1]);

%figure;
%set(gcf,'Name',['dicomrt_GAMMAcal2D: local_eval= ',inputname(1),', ref= ',inputname(2)]);
%surf(gamma,alpha,'XData',dose_xmesh(locate_voi_min_x:locate_voi_max_x),'Ydata',dose_ymesh(locate_voi_min_y:locate_voi_max_y));
%colormap jet;
%shading interp;
%title(['gamma/alpha',' Z= ',num2str(dose_zmesh(slice))],'FontSize',16);
%xlabel('X axis (cm)','FontSize',12);
%ylabel('Y axis (cm)','FontSize',12);
%grid on;
%colorbar;
%set(gca,'XLim',[min(dose_xmesh(locate_voi_min_x:locate_voi_max_x)) max(dose_xmesh(locate_voi_min_x:locate_voi_max_x))]);
%set(gca,'YLim',[min(dose_ymesh(locate_voi_min_y:locate_voi_max_y)) max(dose_ymesh(locate_voi_min_y:locate_voi_max_y))]);
%set(gca,'ZLim',[min(min(gamma)) max(max(gamma))]);
%set(gca,'ZLim',[min(min(gamma)) 1]);

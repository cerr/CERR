function [CN,Vt_dref,Vt,Vdref] = dicomrt_CNcal(inputdose,dose_xmesh,dose_ymesh,dose_zmesh,norm,dref,VOI,voi2use)
% dicomrt_CNcal(inputdose,dose_xmesh,dose_ymesh,dose_zmesh,norm,dref,VOI,voi2use)
%
% Calculate Conformity index for a given 3D dose distribution
%
% inputdose is the input 3D dose (e.g. RTPLAN or MC generated)
% dose_xmesh,dose_ymesh,dose_zmesh are x-y-z coordinates of the center of the dose-pixel 
% dref is the dose level that will be used for the calculation of the CN (Gy)
% norm is the dose normalization level
% norm =0 (default) no normalization is carried out
%      ~=0 doses are normalized to norm (100%)
% 
% VOI is a cell array which contain the patients VOIs as read by dicomrt_loadvoi
% voi2use is a vector pointing to the number of VOIs to be used ot the analysis and for the display.
% This function calculates the conformity index (or number ==> CN) accordingly to
% van't Riet etal IJROBP (1997) Vol.37 No.3 pp.731-736 :
%
% CN=(Vt_dref/Vt)*(Vt_dref/Vdref)
%
% where:
% Vt            volume of the target "t"
% Vt_dref       volume of "t" receiving a dose >= than the reference dose "dref" 
% Vdref         volume receiving a dose >= than the dreference dose "dref" 
%
% The first term of eq. (1) represents the coverage of the target volume. 
% The second term dreferes to the volume of healthy tissues receiving a dose equal or grater than 
% the dreference dose "dref".
% This is function increasing with conformity: 0<CN<1.
% It is important to note that CN~=0 when poor conformity in achieved (Vdref >> Vt_dref) 
% or when a geometrical miss occurs (Vt_dref~=0).
%
% Example:
%
% [volume_VOI,volume_threshold,conformity_index]=dicomrt_CNcal(A,dose_xmesh,dose_ymesh,dose_zmesh,...
%    105,60,demo_voi,9);
%
% calculates the CN for the dose matrix A and returns it in conformity_index.
% The volumes ot the VOI # 9 and the volume of the isodose volume for 105% (60 Gy = 100%) are also 
% returned into volume_VOI and volume_threshold respectively
% The above call is equavilent to the following:
%
% [volume_VOI,volume_threshold,conformity_index]=dicomrt_CNcal(A,dose_xmesh,dose_ymesh,dose_zmesh,...
%    63,0,demo_voi,9);
%
% See also dicomrt_CIcal, dicomrt_mask
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[dose_temp,type_dose,label]=dicomrt_checkinput(inputdose,1);
[dose]=dicomrt_varfilter(dose_temp);

% Check normalization
if norm~=0
    dose=dose./norm.*100;
end

% mask dose matrix using VOI: get VOI volume
[mask_VOI,Vt,mask4VOI,vbin]=dicomrt_mask(VOI,dose_temp,dose_xmesh,dose_ymesh,dose_zmesh,voi2use,'nan','n');
mask_VOI=dicomrt_varfilter(mask_VOI);

% Calculate volume covered by "dref" dose
Vt_dref=0;
for kk=1:size(mask_VOI,3)
    [ii,jj]=find(mask_VOI(:,:,kk)>=dref);
    if isempty(ii)~=1
        Vt_dref=Vt_dref+length(ii)*vbin(kk);
    end
end

% Calculate volume covered by "dref" dose
Vdref=0;
for kk=1:size(dose,3)
    [ii,jj]=find(dose(:,:,kk)>=dref);
    if isempty(ii)~=1
        Vdref=Vdref+length(ii)*vbin(kk);
    end
end

% Calculate CN
CN=(Vt_dref/Vt)*(Vt_dref/Vdref);

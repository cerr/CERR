function [gamma,phase,dta,alpha,gamma_xmesh,gamma_ymesh,gamma_zmesh]=dicomrt_GAMMAcal2DVol(evalm,refm,dose_xmesh,dose_ymesh,dose_zmesh,resf,range,dta_criteria,dd_criteria,voi,voiselect,voilookup)
% dicomrt_GAMMAcal2DVol(evalm,refm,dose_xmesh,dose_ymesh,dose_zmesh,resf,range,dta_criteria,dd_criteria,voi,voiselect,voilookup)
%
% Calculates 2D gamma distribution for a 3D dataset using a 2D algorithm.
% Calculates 2D gamma maps on every slice of a user selected voi and stack 2D maps onto a 3D array.
%
% evalm is the 2D matrix to evaluate.
% refm is the reference 2D matrix.
%   Both eval and ref can be a TPS generated dataset or a MC generated dataset.
%   Doses are normalised to the prescribed target dose whenever is possible.
%   If no normalization dose is provided within the data it is assumed that matrices are already normalised.
% dose_xmesh, dose_ymesh, are the coordinates of the center of the pixel for eval and ref.
% slice is the number of the slice quantities should be calculated for.
% resf is the "resolution factor". Each voxel is divided resf times to allow dose to be interpolated
%   and quantities calculated. The higher resf the more accurate the calculation is, the slower the 
%   function will be.
% range is the "search range". Range is the number of pixel about (j,i) that is considered for calculation.
%   If a dta or a dd match is not found within the search range gamma and all the other quantities in that point
%   will be NaN (Not a Number).
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
%
% NOTE: the use of tyhis function is equivalent to looping calls to dicomrt_GAMMAcal2D, storing 
% results in a 3D matrix. Useful and not mandatory parameter that this function returns is zmesh, which 
% is needed by dicomrt_gvhcal.
%
% Example: 
%
% [gamma1_2,phase1_2,dta1_2,alpha1_2,xmesh,ymesh,zmesh]=dicomrt_GAMMAcal2DVol(image_eval,image_ref, ...
%                                                             xmesh_red,ymesh_red,40,2,4,0.3,0.03);
%
% returns the calculated gamma function for image_eval vs image_ref at slice # 40 in gamma1_2. 
% Gamma is calculated with 3%-3mm DD-DTA criteria.
% The phase is returned in phase1_2, the dta matrix in dta1_2.
% The function return also the direction cosines in alpha1_2. These are the 
% direction cosines on the gamma vector in the two dimensional space xy. The direction
% cosines may provide useful information in detecting systematic spatial displacements between eval and ref.
% Coordinates of the xyz location where gamma is defined are returned in xmesh, ymesh, and zmesh.
%
% The concept of gamma function was developed by Low et al Med. Phys. 25 656-661.
%
% See also dicomrt_GAMMAcal3DP, dicomrt_loaddose, dicomrt_loadmcdose, dicomrt_gvhcal
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(11,12,nargin))

if exist('voilookup')~=1
    voilookup=1; % assume VOI number 1 is patient outline
end

% Check case and set-up some parameters and variables
[evalm_temp,evalm_type,evalm_label,evalm_PatientPosition]=dicomrt_checkinput(evalm);
evalm=dicomrt_varfilter(evalm_temp);
[refm_temp,refm_type,refm_label,refm_PatientPosition]=dicomrt_checkinput(refm);
refm=dicomrt_varfilter(refm_temp);
[voi_temp]=dicomrt_checkinput(voi);
voi=dicomrt_varfilter(voi_temp);
voitype=dicomrt_checkvoitype(voi_temp);

% Retrieve 
%voi_start=dicomrt_findslice(voi_temp,voiselect,1,voilookup);
%voi_stop=voi_start+size(voi{voiselect,2},1)-1;
%bias=voi_start-1;

gamma=[];
phase=[];
dta=[];
alpha=[];
gamma_zmesh=[];

% Mask the matrix using the selected VOI
voiZ=dicomrt_makevertical(dicomrt_getvoiz(voi_temp,voiselect));

for i=1:length(voiZ)
    [locate_slice]=dicomrt_findpointVECT(dose_zmesh,voiZ(i),evalm_PatientPosition);
    disp(['Working on ',voi{voiselect,1}, ' slice: ', num2str(i)]);   
    [gamma(:,:,i),phase(:,:,i),dta(:,:,i),alpha(:,:,i),gamma_xmesh,gamma_ymesh,zmesh_temp]=...
        dicomrt_GAMMAcal2D(evalm_temp,refm_temp,dose_xmesh,dose_ymesh,dose_zmesh,...
        locate_slice,resf,range,dta_criteria,dd_criteria,voi_temp,voiselect);
    gamma_zmesh=[gamma_zmesh zmesh_temp];
end

gamma=dicomrt_restorevarformat(evalm_temp,gamma);

% Label info and update time of creation
gamma{1,1}{1}.RTPlanLabel=[gamma{1,1}{1}.RTPlanLabel,'-GAMMA'];
gamma{1,1}{1}.RTPlanDate=date;
time=fix(clock);
creationtime=[num2str(time(4)),':',num2str(time(5))];
gamma{1,1}{1}.RTPlanTime=creationtime;

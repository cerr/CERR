%clear all
global planC

directoryname = uigetdir;
dirdata = dir(directoryname);
files={dirdata.name};
ln=length(files);
files=files(3:ln); ln=ln-2;

structNum_roi=1;
structNum_40p=2;
M=[];
Thresholds=[40:10:80];
for i=20:20
    name=files{i}
    load([directoryname,'\',name]);
    %     roiVol = getStructureVol(structNum_40p);
    %    [Dx, Vx(i,:), mean_suv_40p, max_suv_40p, min_suv_40p, slope_ivh_40p(i)]=analyze_ivh1(structNum_40p, 1, 0);
    %slope(i) = calc_slope_grigsby(structNum_roi,Thresholds);
    [energy_40p,contrast_40p,Entropy_40p,Homogeneity_40p,standard_dev_40p,Ph_40p] = getHaralicParams(structNum_40p);
    %     [Eccentricity_40p,EulerNumber_40p,Solidity_40p,Extent_40p]=getShapeParams(structNum_40p);
    %     row=[roiVol, mean_suv_40p, standard_dev_40p, max_suv_40p, min_suv_40p, slope_ivh_40p, Dx, Vx,energy_40p,contrast_40p,Entropy_40p,Homogeneity_40p,...
    %         Eccentricity_40p,EulerNumber_40p,Solidity_40p,Extent_40p];
    %     M=[M;row];
end
%xlswrite('pet_hetro_cervix_grigsby.xls',M)

% clear PlanC
% save pet_hetro_cervix




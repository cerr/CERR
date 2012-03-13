function uncertainty = getDPMUncertainty2(threshold, numBeam, planC)
% Feb 17, 2006
% Here, the assumption is that the IM.Errors stores the uncertainty.
% Only calculate for one beam.
% JC July 18, 2005
% Calculate the uncertainty of a plan with multiple beams
% 


%threshold = 0.5;
%numBeam = 6;
%load('../LungCCC.mat')
%dose3D is the sum dose of all beams.
%Get the indmax for the top 50% of total dose
%load dose3D_SUM_nhistp5M dose3D

%Get the indics of the total top 50% dose.

for indexBeam = 1 : numBeam,

eval(['load ./IMCalc_Beam',num2str(indexBeam)]);
eval(['load ./w_field',num2str(indexBeam)]);

%Get the error for dose3D
dose3D = getIMDose(IMCalc,[],1);
indmax = find(dose3D >= threshold*max(dose3D(:)));
meanDPMdose = mean(dose3D(indmax));
clear dose3D
IMCalc.beamlets =IMCalc.Errors;
error3D = getIMDose(IMCalc,[], 1);
clear IMCalc
error3D = 0.5*mean(error3D(indmax));

if( indexBeam == 1) 
    error3D_SUM = error3D.*error3D;
else
    error3D_SUM = error3D_SUM + error3D.*error3D
end

end

%get the mean of the uncertainty
error3d_SUM = sqrt(error3D_SUM/numBeam);


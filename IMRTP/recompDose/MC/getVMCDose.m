function dose3D = getVMCDose(planC, threshold);

weight = planC{8}(2).omega(:,3);

dose = [];
for i = 1 : length(weight)
    filename = ['dose3D_', num2str(i)]
    load(filename,'dose3D');
    if(i==1)
        dose = dose3D * weight(i);
    else
        dose = dose + dose3D * weight(i);
    end
end
dose3D = dose;

indmax = find(dose3D >= threshold*max(dose3D(:)));
meanDPMdose = mean(dose3D(indmax));

dose = planC{8}(2).doseArray;
indmax = find(dose >= threshold*max(dose(:)));
meanTPSdose = mean(dose(indmax));

dose3D = dose3D *(meanTPSdose/meanDPMdose);

filename = ['dose3D_DPM'];
save(filename, 'dose3D');
return

        
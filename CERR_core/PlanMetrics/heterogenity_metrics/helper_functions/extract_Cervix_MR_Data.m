%Script to ectract heterogenity metrics from MR images
%
%APA, 03/16/2010

global planC
indexS = planC{end};
structNum = 1;
disp('Heterogenity Metrics for MR')
[energy_40base,contrast_40base,Entropy_40base,Homogeneity_40base,standard_dev_40base,Ph_40base,slope_base] = getHaralicParams(structNum);
[jnk,jnk,raw] = xlsread('Cervix_MR_data.xls');
rowIndex = size(raw,1)+1;
dataM = [slope_base,energy_40base,contrast_40base,Entropy_40base,Homogeneity_40base,standard_dev_40base];
PtName = planC{indexS.scan}(1).scanInfo(1).patientName;
[SUCCESS,MESSAGE] = xlswrite('Cervix_MR_data.xls',{PtName},['A',num2str(rowIndex),':A',num2str(rowIndex)]);
if ~SUCCESS
    errordlg(MESSAGE.message,'Error Writing to Excel','modal')
    return
end
[SUCCESS,MESSAGE] = xlswrite('Cervix_MR_data.xls',{datestr(now)},['B',num2str(rowIndex),':B',num2str(rowIndex)]);
if ~SUCCESS
    errordlg(MESSAGE.message,'Error Writing to Excel','modal')
    return
end
acquisitionDate = datestr(datenum(num2str(planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.AcquisitionDate),'yyyymmdd'));
[SUCCESS,MESSAGE] = xlswrite('Cervix_MR_data.xls',{acquisitionDate},['D',num2str(rowIndex),':D',num2str(rowIndex)]);
if ~SUCCESS
    errordlg(MESSAGE.message,'Error Writing to Excel','modal')
    return
end
[SUCCESS,MESSAGE] = xlswrite('Cervix_MR_data.xls',dataM,['E',num2str(rowIndex),':J',num2str(rowIndex)]);
if ~SUCCESS
    errordlg(MESSAGE.message,'Error Writing to Excel','modal')
    return
end
function slope = calc_slope_grigsby(structNum,Thresholds,planC)
%function slope = calc_slope_grigsby(structNum,Thresholds,planC)
%
%This function returns shape features.
%
%IEN & APA, 07/06/2006

if ~exist('planC','var')
    global planC
end
indexS = planC{end};
for i=1:length(Thresholds)
    planC = contourSUV(structNum,Thresholds(i),planC);
    structVol(i) = getStructureVol(length(planC{indexS.structures}),planC);
    %runCERRCommand('del','structure',length(planC{indexS.structures}))
    n = length(planC{indexS.structures});
    len = n;
    planC = delUniformStr(n, planC); %Update the uniform data.
    planC{indexS.structures}(n:len-1) = planC{indexS.structures}(n+1:len);
    planC{indexS.structures} = planC{indexS.structures}(1:len-1);    
end
coeff = polyfit(Thresholds,structVol,1);
slope=coeff(1);
return;


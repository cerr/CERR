function slope = calc_slope_grigsby(structNum,Thresholds)
%function slope = calc_slope_grigsby(structNum,Thresholds)
%
%This function returns shape features.
%
%IEN & APA, 07/06/2006

global planC stateS
indexS = planC{end};
for i=1:length(Thresholds)
    contourSUV(structNum,Thresholds(i));
    structVol(i) = getStructureVol(length(planC{indexS.structures}));
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


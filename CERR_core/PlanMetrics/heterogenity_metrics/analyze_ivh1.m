function [Dx, Vx, mean_suv, max_suv, min_suv, Slope]=analyze_ivh(structNum, scanSet, plot_flag)
% IVH analysis
global planC
indexS=planC{end};
optS.IVHBinWidth=0.05;
[scansV, volsV] = getIVH(structNum, scanSet, planC);
[scanBinsV, volsHistV] = doseHist(scansV, volsV, optS.IVHBinWidth);
cumVolsV = cumsum(volsHistV);
cumVols2V  = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding scan
% calculate stats
mean_suv= calc_meanDose(scanBinsV, volsHistV);
max_suv=  calc_maxDose(scanBinsV, volsHistV);
min_suv=  calc_minDose(scanBinsV, volsHistV);
D50= calc_Dx(scanBinsV, volsHistV,50)

Slope=calc_Slope(scanBinsV, volsHistV, D50, 0);

range=max_suv-min_suv;
param=[10:10:90];
for i=1:length(param)
    per=param(i)*range/100+min_suv; % ith percentile
    Dx(i)= calc_Dx(scanBinsV, volsHistV,param(i));
    Vx(i)= calc_Vx(scanBinsV, volsHistV,per,1);
end

%including that scan bin.
% if plot_flag
% %     if ~isempty(planC{indexS.scan}(scanSet).scanOffset)
% %         h = plot([0, scanBinsV - planC{indexS.scan}(scanSet).scanOffset], [1, cumVols2V/cumVolsV(end)]);
% %     else
% %        h = plot([0, scanBinsV], [1, cumVols2V/cumVolsV(end)]);
% %     end
% end

return


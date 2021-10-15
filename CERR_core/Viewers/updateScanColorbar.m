function updateScanColorbar(scanSet)
% function updateScanColorbar(scanSet)
%
% This function updates the colorbar for scan with appropriate colormap and
% image min/max values.
%
% APA, 11/13/2015

global stateS planC
indexS = planC{end};

scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
cmapName = stateS.scanStats.Colormap.(scanUID);
cM      = CERRColorMap(cmapName);
nColors = size(cM,1);
tmpV    = 1:nColors;
cB      = ind2rgb(tmpV, cM);
%offset = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
minScanVal = stateS.scanStats.CTLevel.(scanUID) - stateS.scanStats.CTWidth.(scanUID)/2;
maxScanVal = stateS.scanStats.CTLevel.(scanUID) + stateS.scanStats.CTWidth.(scanUID)/2;
xTickV = [minScanVal,maxScanVal];
%imagesc([minScanVal maxScanVal],[0.5 0.5],cB,'parent',stateS.handle.scanColorbar)
set(stateS.handle.scanColorbarImage,'XData',[minScanVal maxScanVal],'CData',cB,...
    'visible','on')
strfun = @(x) sprintf('%0.5g',x);
strC = arrayfun(strfun,xTickV,'UniformOutput',false);
set(stateS.handle.scanColorbar,'YTick',[],'YTickLabel',[], 'visible','on',...
    'XTick',xTickV,'XTickLabel',strC,'xLim',[minScanVal maxScanVal]);


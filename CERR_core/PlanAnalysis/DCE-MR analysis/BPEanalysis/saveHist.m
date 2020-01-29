function saveHist(uqIntensityV,edges,histM,fout)


%Write histogram data to delimited file as
preBins = uqIntensityV;
postBinsC = cellfun(@num2str,num2cell(edges(1:end-1)),'un',0);
% postBinsC = strcat('post',cellfun(@num2str,num2cell(edges(1:end-1)),'un',0));
histHeadC = {'Base',postBinsC{:}};

%Write to excel file

HistData(:,1) = preBins;
HistData(:,2:size(histM,2)+1) = histM;
w = [histHeadC;num2cell(HistData)];
xlswrite(fout,w);


end
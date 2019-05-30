function writeHist(lowerEdge,upperEdge,binWidth,inputV,statV,outFolder,outfileBase,figTitle,textX,fName)
%
%INPUTS
%lowerEdge  :Histogram bin lower edge
%upperEdge  :Histogram bin upper edge
%binWidth   :Histogram bin width
%
% -------------------------------------------------------------------------------------------------
% Histogram bins
edges =  lowerEdge:binWidth:upperEdge;           % Histogram- lower edge:bin width:upper edge.
[binCounts, edges] = histcounts(inputV, edges);  % Get vector containing number of elements in each histogram bin
nBins = (upperEdge - lowerEdge)/binWidth;

%Plot figure
figure ('Name', figTitle);
histogram(inputV, edges);
figtext1 = [outfileBase figTitle];
figtext2 = ['Mean ' num2str(statV(1))];
figtext3 = ['Median ' num2str(statV(3))];

ymaxHist = max(binCounts);% for y axis location, use positions relative to y max
                          % which is the maximum bin count
%Display text
text (textX,0.97*ymaxHist, figtext1);
text (textX,0.88*ymaxHist, figtext2);
text (textX,0.78*ymaxHist, figtext3);

%Save histogram figure
savename = [outFolder,'\',outfileBase,'_',fName,'.jpg'];  
saveas(gcf,savename);
savename_matlabfig =  [outFolder,'\',outfileBase,'_',fName,'.fig'];
savefig(gcf,savename_matlabfig);
close(gcf);

%Write histogram data to delimited file as
%lower edge  upper edge  num elements
lowEdgeV = lowerEdge:binWidth:(upperEdge-binWidth);
upEdgeV = (lowerEdge+binWidth):binWidth:upperEdge;
histFile = [outfileBase,fName,'histo_bin_data'];
histHead = {'lower edge', 'upper edge', '# elements '};
xlsOutfile = [outFolder,'\',histFile,'.xlsx'];

%Write to excel file
HistData(1:nBins,1) = lowEdgeV;
HistData(1:nBins,2) = upEdgeV;
HistData(1:nBins,3) = binCounts;
w = [histHead;num2cell(HistData)];
xlswrite(xlsOutfile,w);


end
function writeFeaturesToCSV(featuresS,csvFile,idC)
% writeFeaturesToCSV.m Writes scalar radiomic texture features ("featuresS")
% computed for a single sstructuer across a cohort using
% calcGlobalRadiomicsFeatures.m to a CSV file.
% -------------------------------------------------------------------------
% INPUTS
% featuresS   : Dictionary of features for a selected structure output
%               by calcGlobalRadiomicsFeatures.m. For example, data
%               structure with following fields:               
%             featuresS = 
%               struct with fields:
%
%                   shapeS: [1×1 struct]
%                 Original: [1×1 struct]
% csvFile     : String containing path to output CSV file.
% idC         : Cell array of patient IDs.
% -------------------------------------------------------------------------
% AI 1/16/23, APA 6/12/2023 refactored

%Get patient IDs
numPts = length(featuresS);
if ~exist('idC','var')
    ptC = num2cell(1:numPts);
    idC = cellfun(@num2str,ptC,'un',0);
    idC = strcat('Pt ',idC);
end

[dataM,featNamC] = fetureStructToMatrix(featuresS);

%CSV file headings
outC = cell(numPts,1);
rowHeadings = strjoin(featNamC,',');
rowHeadings = ['id,',rowHeadings];
outC{1} = rowHeadings;

%Write to file
for pt = 1:size(dataM,1)
    lineStr = [idC{pt},',',sprintf('%.5g,' ,dataM(pt,:))];
    lineStr(end) = [];
    outC{pt+1} = lineStr;
end
cell2file(outC,csvFile);


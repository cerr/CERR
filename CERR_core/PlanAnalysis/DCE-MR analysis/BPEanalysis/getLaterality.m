function T = getLaterality(fname)
% Create laterality table from spreadsheet
% iyera@mskcc.org 5/8/18 
%---------------------------------------------------

[~,~,X] = xlsread(fname);
mrnC = X(:,1);
idxV = cellfun(@isempty,mrnC);
mrnC = mrnC(~idxV);
mrnC = mrnC(2:end); %Skip row1 (label = 'mrn');
lateralityC = X(:,4);
lateralityC = lateralityC(~idxV);
lateralityC = lateralityC(2:end);%Skip row1 (label = 'lat');
T = table(mrnC,lateralityC);
T.Properties.VariableNames = {'MRN','Laterality'};


end
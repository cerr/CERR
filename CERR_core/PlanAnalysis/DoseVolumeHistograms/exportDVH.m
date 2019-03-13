function exportDVH(structNum,doseSet,Opt,cumuDiff,exportPath)
% exportDVH(structNum,doseSet,Opt,cumuDiff,exportPath)
%
% This function exports DVH to EXCEL. 
%
% INPUTS:
% structNum: Structure index
% doseSet: Dose index
% Opt: Normalised or Absolute DVH ('ABS' or 'NOR')
% cumuDiff: Cumulative or Differential ('DIFF' or 'CUMU')
% expotPath: Path of the directory to write Excel file. The Excel file will be named as structure name.xlsx.
%
% % EXAMPLE:
% doseSet = 4;
% Opt = 'abs';
% cumuDiff = 'diff';
% exportPath = '\\vpensmph\deasylab1\Aditya\Ellen10-11-2018\CERR_files\35372944_DVHs_ab10';
%
% APA 10/12/2018
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.
%
% Usage
% exportDVH(structNum,Opt)

% for command line help document
if ~exist('structNum')& ~exist('doseSet')& ~exist('Opt')
    prompt = {'Enter the structure Number';'Enter the dose number';...
        'Enter "abs" for absolute OR "nor" for normalized DVH',...
        'Enter "diff" for differential OR "cumu" for cumulative DVH'};
    dlg_title = 'Export DVH';
    num_lines = 1;
    def = {'';'';'';''};
    outPutQst = inputdlg(prompt,dlg_title,num_lines,def);

    if isempty(outPutQst)
        return;
    end

    if isempty(outPutQst{1}) | isempty(outPutQst{2})| isempty(outPutQst{3})
        warning('Need to enter all the inputs');
        return
    else
        structNum = str2num(outPutQst{1});
        doseSet = str2num(outPutQst{2});
        Opt = outPutQst{3};
        cumuDiff = outPutQst{4};
        exportPath = uigetdir( 'C:\','Select destination Directory for DVH export');
    end
end

% exportPath = uigetdir( 'C:\','Select destination Directory for DVH export');
global planC
indexS = planC{end};
structureCell = planC{indexS.structures};
% optS = CERROptions;
pathStr = getCERRPath;
optName = [pathStr 'CERROptions.json'];
optS = opts4Exe(optName);
%loop over all the structures that need to be exported
for i = 1:length(structNum)
    name = structureCell(structNum(i)).structureName;
    [dosesV, volsV] = getDVH(structNum(i), doseSet(i), planC);
    [doseBinsV, volsHistV] = doseHist(dosesV, volsV, optS.DVHBinWidth);
    doseBinsV = doseBinsV * 100; % Gy to cGy
    if strcmpi(cumuDiff,'diff')
        fVol = volsHistV;
    else
        cumVolsV = cumsum(volsHistV);
        cumVols2V  = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding dose
        switch upper(Opt)
            case 'ABS'
                %             if abs flag is set just export the values as it is
                fVol = cumVols2V;
            case 'NOR'
                %Normalizing the volume
                fVol = cumVols2V/cumVolsV(end);
        end
    end    
    M = [doseBinsV; fVol];
%     %Export only NumPts points
%     NumPts = 65000;
%     if size(M,2)>NumPts
%         indAll = round(linspace(1,size(M,2),NumPts));
%         M = M(:,indAll);
%     end
    xlswrite(fullfile(exportPath,name), M');
end
clear fVol dosesV volsV cumVolsV cumVols2V doseBinsV volsHistV optS
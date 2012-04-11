%% Get Directory input
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

global planC stateS

stateS.planLoaded = 0;

stateS.optS = CERROptions;

vitaliDir = uigetdir();

if vitaliDir == 0
    disp('Import Cancled ...');
    return
end

all_plans = dir(vitaliDir);

all_plans = all_plans(~[all_plans.isdir]);

[filename, pathname] =  uiputfile('*.html', 'Output file for Stats', 'vitali');

fid = fopen(fullfile(pathname,filename), 'w');

outPut = ['<strong> Output for CERR structure stats ' date '</strong> \r'];

fprintf(fid, outPut, 'char');

%% Load plan

% Get all plan list
for i = 1:length(all_plans)
    planName = all_plans(i).name;
    
    fprintf(fid, ['<p><strong> '  planName ' </strong><br />\r'], 'char');
    
    CERRPlantoImport = fullfile(vitaliDir, planName);

    [pathstr, name, ext] = fileparts(CERRPlantoImport);

    if strcmpi(ext, '.bz2')
        zipFile = 1;
        CERRStatusString(['Decompressing ' name ext '...']);
        outstr = gnuCERRCompression(CERRPlantoImport, 'uncompress');
        loadfile = fullfile(pathstr, name);
        [pathstr, name, ext] = fileparts(fullfile(pathstr, name));
    elseif strcmpi(ext, '.zip')
        zipFile = 1;
        unzip(CERRPlantoImport,pathstr)
        loadfile = fullfile(pathstr, name);
        [pathstr, name, ext] = fileparts(fullfile(pathstr, name));
    else
        zipFile = 0;
        loadfile = CERRPlantoImport;
    end

    planC           = load(loadfile,'planC');
    try
        if zipFile
            delete(loadfile);
        end
        if tarFile
            delete(fileToUnzip);
        end
    catch
    end
    planC           = planC.planC; 
    %Conversion from struct created by load
    stateS.CERRFile = CERRPlantoImport;

    indexS = planC{end};
%% calculate Mean, Max and Min Dose

    for structNum = 1:length(planC{indexS.structures})
        [dosesV, volsV, isError] = getDVH(structNum(1), 1, planC);

        [doseBinsV, volsHistV] = doseHist(dosesV, volsV, planC{indexS.CERROptions}.DVHBinWidth);

        %% Calculates Min Mean Max
        meanD = sum(doseBinsV(:).* volsHistV(:))/sum(volsHistV);

        meanD = roundoff(meanD, 2);

        totalVol = roundoff(sum(volsHistV),2);

        ind = max(find([volsHistV~=0]));

        maxD = roundoff(doseBinsV(ind),2);

        ind = min(find([volsHistV~=0]));

        minD = roundoff(doseBinsV(ind),2);

%% print each in a text file with plan Name
        units = planC{indexS.dose}(1).doseUnits;



        outPut = ['<FONT COLOR="#0000FF">' planC{indexS.structures}(structNum).structureName ':</FONT> \t || Mean Dose: ' num2str(meanD) ' ' units ...
            '\t ||    Min Dose: ' num2str(minD) ' ' units '\t ||    Max Dose: '  num2str(maxD) ' ' units ...
            '\t ||    Volume Dose: ' num2str(totalVol) ' cc <br />\r'];
        fprintf(fid, outPut, 'char');
    end
    fprintf(fid, ['<br /><strong> END output for ' planName '</strong> </p>'], 'char');
    clear global planC
    clear global stateS
end

fclose(fid);

clear all;
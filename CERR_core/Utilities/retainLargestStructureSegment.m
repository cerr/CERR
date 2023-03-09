function planC = retainLargestStructureSegment(structNum,numSegs,planC)
%function planC = retainLargestStructureSegment(structNum,threshold,planC)
%
%This function retains the top numSegs for each slice of the structure.
%
%APA, 08/13/2010
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

if nargin ~= 3
    global planC stateS
end
indexS = planC{end};

if nargin <= 2
    %Ask for structure number
    prompt = {'Enter the structure number.'};
    name = 'Select Structure';
    numlines = 1;
    defaultanswer = {''};
    options.Resize='on';
    options.WindowStyle='normal';
    options.Interpreter='tex';
    structNum = inputdlg(prompt,name,numlines,defaultanswer,options);
    if isempty(structNum)
        return;
    else
        structNum = str2num(structNum{1});
    end
    if isempty(structNum)
        error('Incorrect Structure Number')
    end

    % Histogram of Volume vs #Segments
    areaV = [];
    for slcNum = 1:length(planC{indexS.structures}(structNum).contour)
        for segNum = 1:length(planC{indexS.structures}(structNum).contour(slcNum).segments)
            pointsM = planC{indexS.structures}(structNum).contour(slcNum).segments(segNum).points;
            if ~isempty(pointsM)
                areaV = [areaV polyarea(pointsM(:,1),pointsM(:,2))];
            end
        end
    end

    hFig = figure;
    hist(areaV)
    xlabel('\bfArea (cm^2)','fontsize',12)
    ylabel('\bf# Segments','fontsize',12)
    title(['\bfHistogram of Area for segments of ', planC{indexS.structures}(structNum).structureName],'fontsize',14)

    %Ask for threshold value
    prompt = {'Enter the number of segments to retain.'};
    name = 'Number of segments';
    numlines = 1;
    defaultanswer = {''};
    options.Resize='on';
    options.WindowStyle='normal';
    options.Interpreter='tex';
    numSegs = inputdlg(prompt,name,numlines,defaultanswer,options);
    if isempty(numSegs)
        return;
    else
        numSegs = str2double(numSegs{1});
    end
    if isempty(numSegs)
        error('Incorrect Threshold Area')
    end
    
    close(hFig)

end

% Delete segments below specified threshold
segToBeDeleted = {};
for slcNum = 1:length(planC{indexS.structures}(structNum).contour)
    segToBeDeleted{slcNum} = [];
    segNumV = [];
    areaV = [];
    for segNum = 1:length(planC{indexS.structures}(structNum).contour(slcNum).segments)
        pointsM = planC{indexS.structures}(structNum).contour(slcNum).segments(segNum).points;
        if ~isempty(pointsM)
                areaV = [areaV,polyarea(pointsM(:,1),pointsM(:,2))];
                segNumV = [segNumV,segNum];
        end
    end
    if length(segNumV) > 1
        [~,indSortV] = sort(areaV,'ascend');
        segToBeDeleted{slcNum} = [segToBeDeleted{slcNum} segNumV(indSortV(1:end-numSegs))];
    end
end

for slcNum = 1:length(planC{indexS.structures}(structNum).contour)
    if ~isempty(segToBeDeleted{slcNum})
        planC{indexS.structures}(structNum).contour(slcNum).segments(segToBeDeleted{slcNum}) = [];
    end
end

%Update Uniformized data
planC = getRasterSegs(planC, structNum);
planC = updateStructureMatrices(planC, structNum);

if exist('stateS','var') && isfield(stateS,'handle') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end

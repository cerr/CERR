function RegCenteredMattes_MI(handles)
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
    
global planC stateS;
indexS = planC{end}; 

    originF = [str2double(get(handles.originFx, 'string')) ...
               str2double(get(handles.originFy, 'string')) ...
               str2double(get(handles.originFz, 'string'))];
    spacingF = [str2double(get(handles.spacingFx, 'string')) ...
               str2double(get(handles.spacingFy, 'string')) ...
               str2double(get(handles.spacingFz, 'string'))];

    originM = [str2double(get(handles.originMx, 'string')) ...
               str2double(get(handles.originMy, 'string')) ...
               str2double(get(handles.originMz, 'string'))];
    spacingM = [str2double(get(handles.spacingMx, 'string')) ...
               str2double(get(handles.spacingMy, 'string')) ...
               str2double(get(handles.spacingMz, 'string'))];

    bins = str2double(get(handles.MultiRes_Centered2D_Bins, 'string'));
    samples = str2double(get(handles.MultiRes_Centered2D_Samples, 'string'));
    iternum = str2double(get(handles.MultiRes_Centered2D_IterNum, 'string'));
    reglevels = str2double(get(handles.MultiRes_Centered2D_RegLevels, 'string'));
    tscale = str2double(get(handles.MultiRes_Centered2D_tscale, 'string'));
    rscale = str2double(get(handles.MultiRes_Centered2D_rscale, 'string'));
    rf = str2double(get(handles.MultiRes_Centered2D_rf, 'string'));
    minstep = str2double(get(handles.MultiRes_Centered2D_minstep, 'string'));
    maxstep = str2double(get(handles.MultiRes_Centered2D_maxstep, 'string'));
    
    output = cell(1, 10);
    
    aIndex = stateS.currentAxis;
    hAxis = stateS.handle.CERRAxis(aIndex);
    axisInfo = get(hAxis, 'userdata');

    FImg = axisInfo.scanObj(stateS.imageRegistrationBaseDataset).data2M;
    MImg = axisInfo.scanObj(stateS.imageRegistrationMovDataset).data2M;
    
%     FImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
%     MImg = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray;
%     
%     %     downsample the input datasets
%     if (get(handles.dsampleCheck,'Value') == get(handles.dsampleCheck,'Max'))
%         
%         tic;
%         FImg = imdesample3d(FImg,2,2);
%         MImg = imdesample3d(MImg,2,2);
%         toc;
%         DesampleTime = num2str(floor(toc/60));
%     
%     end   
    

    %     call registration method
    tic;
    [im, TrackData, Offset] = MultiRes_Centered2D(int16(FImg), originF, spacingF, ...
                                                int16(MImg), originM, spacingM, ...
                                                bins, samples, iternum, reglevels, tscale, rscale, rf, minstep, maxstep);
    toc;

    RegTime = num2str(floor(toc/60));
    
    output{1} = ['Angle (radians)   = ' num2str(Offset(1))];
    output{2} = ['Angle (degrees)   = ' num2str(Offset(8))];
    output{3} = ['Center X      = ' num2str(Offset(2))];
    output{4} = ['Center Y      = ' num2str(Offset(3))];
    output{5} = ['Translation X = ' num2str(Offset(4))];
    output{6} = ['Translation Y = ' num2str(Offset(5))];
    output{7} = ['Iterations = ' num2str(Offset(6))];
    output{8} = ['Metric Value (mean square) = ' num2str(Offset(7))];
    output{9} = ['Elapsed time = ' RegTime];
    
    
    set(handles.OutputList, 'string', output);
    
%update the transM;
    
    Tv = [-Offset(4) Offset(5) 0];
    rot = eye(3); 
    rot(1) = cos(Offset(1)*pi/180); rot(2,2) = rot(1); 
    rot(1,2) = -sin(Offset(1)*pi/180);
    rot(2,1) = -rot(1,2);
    
    TM = eye(4);
    TM(:,4) = [Tv 1];
    
    RM = eye(4);
    RM(1:3, 1:3) = rot;
    
    newTransform = TM*RM;
    
    scanSetM = stateS.imageRegistrationMovDataset;
    oldTransM = getTransM(stateS.imageRegistrationMovDatasetType, scanSetM, planC);
    if isempty(oldTransM), oldTransM = eye(4); end;
    planC{indexS.(stateS.imageRegistrationMovDatasetType)}(scanSetM).transM = (newTransform * oldTransM);
%     planC{indexS.(stateS.imageRegistrationMovDatasetType)}(scanSetM).transM = newTransform;
    
    %planC{indexS.dose}(scanSetM).transM = (newTransform * oldTransM);
    sliceCallBack('refresh');
   
    
end

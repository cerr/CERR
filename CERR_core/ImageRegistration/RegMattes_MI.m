function RegMattes_MI(handles)
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

    Bins = str2double(get(handles.mattes_bins, 'string'));
    Samples = str2double(get(handles.mattes_samples, 'string'));
    RelaxFactor = str2double(get(handles.mattes_rf, 'string'));
    DefaultPixelValue = str2double(get(handles.mattes_pv, 'string'));
    Iter_MinStep = str2double(get(handles.mattes_minstep, 'string'));
    Iter_MaxStep = str2double(get(handles.mattes_maxstep, 'string'));
    Iter_Num = str2double(get(handles.mattes_inum, 'string'));
    
    output = cell(1, 8);
    
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
    
    aIndex = stateS.currentAxis;
    hAxis = stateS.handle.CERRAxis(aIndex);
    axisInfo = get(hAxis, 'userdata');

    FImg = axisInfo.scanObj(stateS.imageRegistrationBaseDataset).data2M;
    MImg = axisInfo.scanObj(stateS.imageRegistrationMovDataset).data2M;

    %     call registration method
    tic;
    [im, Rotation, Offset] = Mattes_MI2D(int16(FImg), originF, spacingF, ...
                                                int16(MImg), originM, spacingM, ...
                                                Bins, Samples, RelaxFactor, DefaultPixelValue, ...
                                                Iter_MinStep, Iter_MaxStep, Iter_Num);
    toc;

    RegTime = num2str(floor(toc/60));
    
    output{1} = ['Translation X = ' num2str(Offset(1))];
    output{2} = ['Translation Y = ' num2str(Offset(2))];
    output{3} = ['Iterations    = ' num2str(Offset(3))];
    output{4} = ['Metric Value (Mattes) = ' num2str(Offset(4))];
    output{5} = ['Elapsed time = ' RegTime];
    
    set(handles.OutputList, 'string', output);
    
%update the transM;
    
    Tv = [-Offset(1) Offset(2) 0];
    
    TM = eye(4);
    TM(:,4) = [Tv 1];
    
    newTransform = TM;
    
    scanSetM = stateS.imageRegistrationMovDataset;
    oldTransM = getTransM(stateS.imageRegistrationMovDatasetType, scanSetM, planC);
    if isempty(oldTransM), oldTransM = eye(4); end;
    planC{indexS.(stateS.imageRegistrationMovDatasetType)}(scanSetM).transM = (newTransform * oldTransM);
%     planC{indexS.(stateS.imageRegistrationMovDatasetType)}(scanSetM).transM = newTransform;
    
    %planC{indexS.dose}(scanSetM).transM = (newTransform * oldTransM);
    sliceCallBack('refresh');
   
    
end

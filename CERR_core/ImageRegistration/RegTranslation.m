function RegTranslation(handles, metric)
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

    [originF, spacingF, centerF] = getScanOriginSpacing(planC{indexS.scan}(stateS.imageRegistrationBaseDataset));

    [originM, spacingM, centerM] = getScanOriginSpacing(planC{indexS.scan}(stateS.imageRegistrationMovDataset));

    minstep = str2double(get(handles.para.minstep, 'string'));
    maxstep = str2double(get(handles.para.maxstep, 'string'));
    iternum = str2double(get(handles.para.iternum, 'string'));

    output = cell(1, 8);
    
    FImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
    MImg = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray;
    
%     downsample the input datasets
    if (get(handles.dsampleCheck,'Value') == get(handles.dsampleCheck,'Max'))
        
        tic;
        FImg = imdesample3d(FImg,2,2);
        MImg = imdesample3d(MImg,2,2);
        toc;
        DesampleTime = num2str(floor(toc/60));
    
    end   
    
%     call registration method
    tic;
    switch (metric)
        case 'mean squares'
            [im, Rotation, Offset] = MeanSquare3D(int16(FImg), originF, spacingF, ... %MeanSquare3D,NormalizedCorrelation3D
                                                int16(MImg), originM, spacingM, ...
                                                minstep, maxstep, iternum);
        case 'normalized correlation'
            [im, Rotation, Offset] = NormalizedCorrelation3D(int16(FImg), originF, spacingF, ... %MeanSquare3D,NormalizedCorrelation3D
                                                int16(MImg), originM, spacingM, ...
                                                minstep, maxstep, iternum);
    end
    toc;
    RegTime = num2str(floor(toc/60));
    
    output{1} = ['Translation X = ' num2str(Offset(1))];
    output{2} = ['Translation Y = ' num2str(Offset(2))];
    output{3} = ['Translation Z = ' num2str(Offset(3))];
    output{4} = ['Number of Iterations = ' num2str(Offset(4))];
    output{5} = ['Best Value = ' num2str(Offset(5))];
    output{6} = ['Desample time = ' DesampleTime 'm'];
    output{7} = ['Register time = ' RegTime 'm'];

    
    set(handles.OutputList, 'string', output);
    
    %update the transM;
    dx = Offset(1); dy = Offset(2); dz = Offset(3);
    
    scanSetM = stateS.imageRegistrationMovDataset;
    oldTransM = getTransM(stateS.imageRegistrationMovDatasetType, scanSetM, planC);
    
    newTransform = eye(4);
    newTransform(:,4) = [dx dy dz 1];
    
%     planC{indexS.(stateS.imageRegistrationMovDatasetType)}(scanSetM).transM = (newTransform * oldTransM);
%     planC{indexS.dose}(scanSetM).transM = (newTransform * oldTransM);
    planC{indexS.(stateS.imageRegistrationMovDatasetType)}(scanSetM).transM = newTransform;
    sliceCallBack('refresh');

end

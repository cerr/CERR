function RegMeanSquareVersor(handles, metric)
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
        
            
    Opt_S_X = str2double(get(handles.versor_s_x, 'string'));
    Opt_S_Y = str2double(get(handles.versor_s_y, 'string'));
    Opt_S_Z = str2double(get(handles.versor_s_z, 'string'));
    tscale  = str2double(get(handles.versor_s_t, 'string'));
    Min_Step_Len = str2double(get(handles.versor_i_minstep, 'string'));
    Max_Step_Len = str2double(get(handles.versor_i_maxstep, 'string'));
    Iteration_Num = str2double(get(handles.versor_i_num, 'string'));
    
        
    FImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
    MImg = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray;
    
    dimF = size(FImg);
    dimM = size(MImg);
    %generate cliped base dataset    
    clipBox = uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox_baseTrans'));
    if ~isempty(clipBox)
        FImg = FImg(clipBox(2):clipBox(4), clipBox(1):clipBox(3), :);
        originF(1) = originF(1) + spacingF(1)*double(clipBox(1)-1);
        originF(2) = originF(2) + spacingF(2)*double(uint16(dimF(1)-clipBox(4)));
    end
    clipBox = uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox_baseSag'));
    if ~isempty(clipBox)
        FImg = FImg(:, :, clipBox(2):clipBox(4));
        originF(3) = originF(3) + spacingF(3)*double(clipBox(2)-1);
    end
    
    %generate cliped move dataset   
    clipBox = uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox_movTrans'));
    if ~isempty(clipBox)
        MImg = MImg(clipBox(2):clipBox(4), clipBox(1):clipBox(3), :);
        originM(1) = originM(1) + spacingM(1)*double(clipBox(1)-1);
        originM(2) = originM(2) + spacingM(2)*double(uint16(dimM(1)-clipBox(4)));
    end
    clipBox = uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox_movSag'));
    if ~isempty(clipBox)
        MImg = MImg(:, :, clipBox(2):clipBox(4));
        originM(3) = originM(3) + spacingM(3)*double(clipBox(2)-1);
    end
    
%downsample the input datasets
    dsampled = 0;
    if (get(handles.dsampleCheck,'Value') == get(handles.dsampleCheck,'Max'))
        
        tic;
        xyScale =  2; zScale = 2;
        spacingF = [spacingF(1)*xyScale spacingF(2)*xyScale spacingF(3)*zScale];
        spacingM = [spacingM(1)*xyScale spacingM(2)*xyScale spacingM(3)*zScale];
        disp('downSampling ...');
%         FImg = imdesample3d(FImg,xyScale,zScale);
%         MImg = imdesample3d(MImg,xyScale,zScale);
%         FImg=GPReduce2D(FImg,1);        
%         MImg=GPReduce2(MImg,1);
        FImg = FImg(1:xyScale:end, 1:xyScale:end, 1:zScale:end);
        MImg = MImg(1:xyScale:end, 1:xyScale:end, 1:zScale:end);
          
        toc;
        dsampled = 1;
    end
    
%     call registration method
    switch metric
        case 'mean squares'
            metricIndex = 0;
        case 'normalized correlation'
            metricIndex = 1;
    end
    
        
    tic; 
tic;
        
%flip the source datasets on X for itk coordinate system
    fdim = 1;
    FImg = flipdim(FImg, fdim); 
    MImg = flipdim(MImg, fdim);
        
% transform initializing modes 0:MomentON 1:GeometryOn 2:initail transform On
    initMode = get(handles.InitTrans, 'value');

%prepare the initial transform matrix        
    transMB = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).transM;
    transMM = planC{indexS.scan}(stateS.imageRegistrationMovDataset).transM;
    if isempty(transMM), transMM = eye(4); end;
    if isempty(transMB), transMB = eye(4); end;
    transM = inv(transMB) * transMM;
        
%flip the moving dataset to match the initial transM    
    Tf = eye(4);
    flipM = 0;
    if (get(handles.flipX, 'value'))
        MImg = flipdim(MImg, 2);
        Tf = [-1 0 0 2*centerM(1); 0 1 0 0; 0 0 1 0; 0 0 0 1];
        flipM = 2;
    end
    if (get(handles.flipY, 'value'))
        MImg = flipdim(MImg, 1);
        Tf = [1 0 0 0; 0 -1 0 2*centerM(2); 0 0 1 0; 0 0 0 1];
        flipM = 1;
    end
    if (get(handles.flipZ, 'value'))
        MImg = flipdim(MImg, 3);
        Tf = [1 0 0 0; 0 1 0 0; 0 0 -1 2*centerM(3); 0 0 0 1];
        flipM = 3;
    end    
    transM = transM * inv(Tf);
    rotM = transM(1:3, 1:3); transV = transM(1:3, 4);
    rotM = rotM';
    transV = -transV;
    
    try
        [im, Rotation, Offset] = VersorRigid3D(int16(FImg), originF, spacingF, ...
                                           int16(MImg), originM, spacingM, ... 
                                           Opt_S_X, Opt_S_Y, Opt_S_Z, tscale, Min_Step_Len, Max_Step_Len, ...
                                           Iteration_Num, metricIndex, rotM, transV, initMode);
    catch
        [im, Rotation, Offset] = VersorRigid3D_64(int16(FImg), originF, spacingF, ...
                                           int16(MImg), originM, spacingM, ... 
                                           Opt_S_X, Opt_S_Y, Opt_S_Z, tscale, Min_Step_Len, Max_Step_Len, ...
                                           Iteration_Num, metricIndex, rotM, transV, initMode);
    end
    
    toc;
    
    im = flipdim(im, fdim); 
    
    output = cell(1, 16);
    
    output{1} = ['Translation X  = ' num2str(Offset(1))];
    output{2} = ['Translation Y  = ' num2str(Offset(2))];
    output{3} = ['Translation Z  = ' num2str(Offset(3))];
    output{4} = ['Rotation Angle = ' num2str(asin(Rotation(2))*180/pi)];
    output{5} = ['Iterations     = ' num2str(Offset(4))];
    output{6} = ['Metric value   = ' num2str(Offset(5))];
    output{7} = ['RCenter X   = ' num2str(Offset(7))];
    output{8} = ['RCenter Y   = ' num2str(Offset(8))];
    output{9} = ['RCenter Z   = ' num2str(Offset(9))];
    output{10} = ['Offset X   = ' num2str(Offset(10))];
    output{11} = ['Offset Y   = ' num2str(Offset(11))];
    output{12} = ['Offset Z   = ' num2str(Offset(12))];
        
    set(handles.OutputList, 'string', output);
    
%update the transM;
    
    Tv = [Offset(1) Offset(2) Offset(3)];
    Cv = [Offset(7) Offset(8) Offset(9)];
    Cv(3) = -Cv(3); %CERR z axis is opposite to the ITK.
    
    rot = reshape(Rotation, 3,3);
    offset = [Offset(10) Offset(11) Offset(12)]';
    
%     rot(2,1) = -rot(2,1); rot(1,2) = -rot(1,2);
%     rot(1,3) = -rot(1,3); rot(3,1) = -rot(3,1);
%     rot(2,3) = -rot(2,3); rot(3,2) = -rot(3,2);
%     
%     offset(1) = -offset(1);
%     offset(2) = -offset(2);
%     offset(3) = -offset(3);

    TM = eye(4);
    TM(:,4) = [offset; 1];
    
    RM = eye(4);
    RM(1:3, 1:3) = rot;
     
    newTransform = inv(TM*RM);
    newTransform =  transMB * newTransform * Tf;
    
    scanSetM = stateS.imageRegistrationMovDataset;
    scanSetF = stateS.imageRegistrationBaseDataset;
    planC{indexS.(stateS.imageRegistrationMovDatasetType)}(scanSetM).transM = newTransform;
    
    
% save the resampled dataset
    if (get(handles.saveCheck, 'value'))
        if (~dsampled)
            planC{indexS.scan}(end+1) = planC{indexS.scan}(scanSetF);
            planC{indexS.scan}(end).scanArray = im;
        else
            %imReg = resample(scanSetF, scanSetM); % need to up-sample im ???? 
            planC{indexS.scan}(end+1) = planC{indexS.scan}(scanSetF);
            planC{indexS.scan}(end).scanArray = imReg;
        end
        controlFrame('refresh');
    end

    sliceCallBack('refresh');
    
end

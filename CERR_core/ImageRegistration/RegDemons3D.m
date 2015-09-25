function RegDemons3D(handles, func, clipBox)
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

if (func~=3)
    Hist_Level = str2double(get(handles.Demons_HistLevel, 'string'));
    MatchPoints = str2double(get(handles.Demons_MatchPoints, 'string'));
    iternum = uint32([str2double(get(handles.Demons_iternum1, 'string')) ...
        str2double(get(handles.Demons_iternum2, 'string')) ...
        str2double(get(handles.Demons_iternum3, 'string')) ...
        str2double(get(handles.Demons_iternum4, 'string'))]);
    sd = str2double(get(handles.Demons_sd, 'string'));
else
    HistBins = str2double(get(handles.BSplineMI_HistBins, 'string'));
    SampleNum = str2double(get(handles.BSplineMI_SampleNum, 'string'));
    iternum = str2double(get(handles.BSplineMI_iternum, 'string'));
end
output = cell(1, 8);


if isempty(clipBox)
    FixedImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
    MovingImg = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray;
else
    FixedImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray(clipBox(2):clipBox(4), clipBox(1):clipBox(3), :);
    MovingImg = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray(clipBox(2):clipBox(4), clipBox(1):clipBox(3), :);
end


%downsample the input datasets
xyScale =  1; zScale = 1; DesampleTime = '0';
if (get(handles.dsampleCheck,'Value') == get(handles.dsampleCheck,'Max'))

    xyScale =  2; zScale = 2;
    spacingF = [spacingF(1)*xyScale spacingF(2)*xyScale spacingF(3)*zScale];
    spacingM = [spacingM(1)*xyScale spacingM(2)*xyScale spacingM(3)*zScale];

    disp('downsampling ...');
    tic;
    %         FImg = imdesample3d(FixedImg,xyScale,zScale);
    %         MImg = imdesample3d(MovingImg,xyScale,zScale);
    MImg=GPReduce2(MovingImg,2,0);
    FImg=GPReduce2(FixedImg,2,0);
    toc;
    DesampleTime = num2str(floor(toc/60));

else
    FImg = FixedImg;
    MImg = MovingImg;
end

%call registration method
try
    tic;
    switch func
        case 0
            disp('starting Demons ...');

            try
                disp('MutliRes_New_Demons3D_win32...');
                [im, DF_X, DF_Y, DF_Z, Offset] = MutliRes_New_Demons3D_win32(int16(FImg), originF, spacingF, ...
                    int16(MImg), originM, spacingM, ...
                    Hist_Level, MatchPoints, iternum, sd);
            catch
                try
                    % disp('MutliRes_New_Demons3D...');
                    % [im, DF_X, DF_Y, DF_Z, Offset] = MutliRes_New_Demons3D(int16(FImg), originF, spacingF, ...
                    % int16(MImg), originM, spacingM, ...
                    % Hist_Level, MatchPoints, iternum, sd);
                    [im, DF_X, DF_Y, DF_Z, Offset] = MutliRes_Demons3D(int16(FImg), originF, spacingF, ...
                        int16(MImg), originM, spacingM, ...
                        Hist_Level, MatchPoints, iternum(1), sd);
                catch
                    try
                        disp('Demons3D...');
                        [im, DF_X, DF_Y, DF_Z, Offset] = Demons3D(int16(FImg), originF, spacingF, ...
                            int16(MImg), originM, spacingM, ...
                            Hist_Level, MatchPoints, iternum(1), sd);

                    catch
                        disp('Demons3D_64...');
                        [im, DF_X, DF_Y, DF_Z, Offset] = Demons3D_64(int16(FImg), originF, spacingF, ...
                            int16(MImg), originM, spacingM, ...
                            Hist_Level, MatchPoints, iternum(1), sd);
                    end
                end
            end
            %                 [mvy,mvx,mvz,i1vx] = demon_global_methods(1,[],FImg,MImg,spacingF);
        case 1
            disp('starting Levelset Method ...');
            try
                [im, DF_X, DF_Y, DF_Z, Offset] = LevelsetMethod3D(int16(FImg), originF, spacingF, ...
                    int16(MImg), originM, spacingM, ...
                    Hist_Level, MatchPoints, iternum, sd);
            catch
                [im, DF_X, DF_Y, DF_Z, Offset] = LevelsetMethod3D_64(int16(FImg), originF, spacingF, ...
                    int16(MImg), originM, spacingM, ...
                    Hist_Level, MatchPoints, iternum, sd);
            end
        case 2
            disp('starting Symmetric Forces Demons ...');
            try
                [im, DF_X, DF_Y, DF_Z, Offset] = SymmetricForceDemons3D(int16(FImg), originF, spacingF, ...
                    int16(MImg), originM, spacingM, ...
                    Hist_Level, MatchPoints, iternum, sd); %sd = constraintWeight
            catch

            end
        case 3
            disp('starting BSplineMI method ...');
            try
                [im, DF_X, DF_Y, DF_Z, Offset] = BSplineMI(int16(FImg), originF, spacingF, ...
                    int16(MImg), originM, spacingM, ...
                    HistBins, SampleNum, iternum);
            catch
                [im, DF_X, DF_Y, DF_Z, Offset] = BSplineMI_64(int16(FImg), originF, spacingF, ...
                    int16(MImg), originM, spacingM, ...
                    HistBins, SampleNum, iternum);
            end

    end
    toc;
    disp('finished!');
    RegTime = num2str(floor(toc/60));

    output{1} = ['Iterations = ' num2str(Offset(1))];
    output{2} = ['Metric Value (mean square) = ' num2str(Offset(2))];
    output{3} = ['Desample time: ', DesampleTime];
    output{4} = ['register time: ', RegTime];
    set(handles.OutputList, 'string', output);
catch
    disp('Out of Memory, Registration failed, please restart Matlab!');
    %         clear all;
    return;
end

imIsDownsampled = 0;
if ~(xyScale == 1 && zScale == 1)
    try
        [DF_Y,DF_X,DF_Z] = recalculate_mvs(DF_Y,DF_X,DF_Z);
        im = move3dimage(single(MovingImg),DF_Y,DF_X,DF_Z);

    catch
        disp('Out of Memory, can not upscaling the motion field, system will save the downsampled dataset!');
        imIsDownsampled = 1;
    end
end

% save the base image for analysis
if ~isempty(clipBox) || imIsDownsampled

    planC{indexS.scan}(end+1) = planC{indexS.scan}(stateS.imageRegistrationBaseDataset);
    planC{indexS.scan}(end).scanUID =  createUID('scan');
    planC{indexS.scan}(end).scanArraySuperior = [];
    planC{indexS.scan}(end).scanArrayInferior = [];

    if (imIsDownsampled)
        bImg = FImg;
    else
        bImg = FixedImg;
    end
    planC{indexS.scan}(end).scanArray = int16(bImg);

    % setup scan info
    [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.imageRegistrationBaseDataset));
    if ~isempty(clipBox)
        xRange = [xV(clipBox(1)) xV(clipBox(3))];
        yRange = [yV(clipBox(4)) yV(clipBox(2))];
    else
        xRange = [xV(1) xV(end)];
        yRange = [yV(end) yV(1)];
    end

    for i = 1:length(planC{indexS.scan}(end).scanInfo)
        planC{indexS.scan}(end).scanInfo(i).sizeOfDimension1 = size(bImg,1);
        planC{indexS.scan}(end).scanInfo(i).sizeOfDimension2 = size(bImg,2);
        %planC{indexS.scan}(end).scanInfo(i).CTOffset = -1*min(bImg(:));
        planC{indexS.scan}(end).scanInfo(i).xOffset = (xRange(1)+xRange(2))/2;
        planC{indexS.scan}(end).scanInfo(i).yOffset = (yRange(1)+yRange(2))/2;
    end
end

% save the deformed image and deformation fields
scanSetM = stateS.imageRegistrationMovDataset;
scanSetF = stateS.imageRegistrationBaseDataset;

planC{indexS.scan}(end+1) = planC{indexS.scan}(scanSetF);
planC{indexS.scan}(end).scanUID =  createUID('scan');
planC{indexS.scan}(end).scanArraySuperior = [];
planC{indexS.scan}(end).scanArrayInferior = [];

planC{indexS.scan}(end).scanArray = int16(im);
planC{indexS.scan}(end).deformInfo.BaseUID = planC{indexS.scan}(scanSetF).scanUID;
planC{indexS.scan}(end).deformInfo.MoveUID = planC{indexS.scan}(scanSetM).scanUID;
planC{indexS.scan}(end).deformInfo.DFX = DF_X;
planC{indexS.scan}(end).deformInfo.DFY = DF_Y;
planC{indexS.scan}(end).deformInfo.DFZ = DF_Z;

planC{indexS.scan}(end).deformInfo.clipBox = clipBox;
if imIsDownsampled
    planC{indexS.scan}(end).deformInfo.downSampled = 'true';
else
    planC{indexS.scan}(end).deformInfo.downSampled = 'false';
end

% setup scan info
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSetF));
if ~isempty(clipBox)
    xRange = [xV(clipBox(1)) xV(clipBox(3))];
    yRange = [yV(clipBox(4)) yV(clipBox(2))];
else
    xRange = [xV(1) xV(end)];
    yRange = [yV(end) yV(1)];
end
for i = 1:length(planC{indexS.scan}(end).scanInfo)
    planC{indexS.scan}(end).scanInfo(i).sizeOfDimension1 = size(im,1);
    planC{indexS.scan}(end).scanInfo(i).sizeOfDimension2 = size(im,2);
    %planC{indexS.scan}(end).scanInfo(i).CTOffset = -1*min(im(:));
    planC{indexS.scan}(end).scanInfo(i).xOffset = (xRange(1)+xRange(2))/2;
    planC{indexS.scan}(end).scanInfo(i).yOffset = (yRange(1)+yRange(2))/2;
end

controlFrame('refresh');
sliceCallBack('refresh');
close('Registration Setup');
end




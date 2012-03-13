function RegOpticalFlow(handles, clipBox)
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
        

    method = get(handles.para.optFlowMethod, 'value');
    RegLevels = str2double(get(handles.para.optFlowRegistLevel, 'string'));
    
    
    output = cell(1, 16);
    
    if isempty(clipBox)
        FixedImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
        MovingImg = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray;
    else
        FixedImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray(clipBox(2):clipBox(4), clipBox(1):clipBox(3), :);
        MovingImg = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray(clipBox(2):clipBox(4), clipBox(1):clipBox(3), :);
    end

    xyScale =  1; zScale = 1; DesampleTime = '0';
    %downsample the input datasets
    if (get(handles.dsampleCheck,'Value') == get(handles.dsampleCheck,'Max'))
        
        tic;
        xyScale =  2; zScale = 2;
        spacingF = [spacingF(1)*xyScale spacingF(2)*xyScale spacingF(3)*zScale];
        spacingM = [spacingM(1)*xyScale spacingM(2)*xyScale spacingM(3)*zScale];
        disp('downSampling ...');
        
%         FImg = imdesample3d(FixedImg,xyScale,zScale);
%         MImg = imdesample3d(MovingImg,xyScale,zScale);
        FImg=GPReduce2(FixedImg,2,0);        
        MImg=GPReduce2(MovingImg,2,0);
        
        toc;
        DesampleTime = num2str(ceil(toc/60));
    else
        FImg = FixedImg;
        MImg = MovingImg;
    end   
    
%     call registration method
    switch method
        case 1
            methodIndex = 1;
        case 2
            methodIndex = 2;
        case 3
            methodIndex = 9;
        case 4
            methodIndex = 13;
        case 5
            methodIndex = 15;
        case 6
            methodIndex = 16;
        case 7
            methodIndex = 17;
        case 8
            methodIndex = 18;
                
    end
    
    tic;
    RegTime = '0';
    
    try 
        [mvy,mvx,mvz,im]=multigrid_nogui6(          methodIndex, ... %method,
                                                    MImg, ...%Moving Image,
                                                    FImg, ...%Fixed Image,
                                                    spacingF,   ...%ratio,
                                                    RegLevels);    %steps,

        maxv = max(max(MImg(:)),max(FImg(:)));
        im = im * single(maxv);
        im = cast(im, class(FImg));


        toc;
        RegTime = num2str(ceil(toc/60));
    catch
        disp('Out of Memory, Registration failed, please restart Matlab!');
        return;
    end

% if downsampled, upsample the deformation fields.
    imIsDownsampled = 0;
    if ~(xyScale == 1 && zScale == 1)
        try
            [mvy,mvx,mvz] = recalculate_mvs(mvy,mvx,mvz);
            im = move3dimage(single(MovingImg),mvy,mvx,mvz); %deform the image with upsampled df fields.
        catch
            disp('Out of Memory, can not upscaling the motion field, system will save the downsampled field!');
            imIsDownsampled = 1;
        end
    end
    
% save the base image for analysis        
    if ~isempty(clipBox) || imIsDownsampled
    
        planC{indexS.scan}(end+1) = planC{indexS.scan}(stateS.imageRegistrationBaseDataset);
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
    planC{indexS.scan}(end).scanArraySuperior = [];
    planC{indexS.scan}(end).scanArrayInferior = [];
    planC{indexS.scan}(end).scanArray = int16(im);
    planC{indexS.scan}(end).deformInfo.BaseUID = planC{indexS.scan}(scanSetF).scanUID;
    planC{indexS.scan}(end).deformInfo.MoveUID = planC{indexS.scan}(scanSetM).scanUID;
    planC{indexS.scan}(end).deformInfo.DFX = mvx;
    planC{indexS.scan}(end).deformInfo.DFY = mvy;
    planC{indexS.scan}(end).deformInfo.DFZ = mvz;
    
    planC{indexS.scan}(end).scanUID = createUID('CT');
    
    planC{indexS.scan}(end).deformInfo.clipBox = clipBox;
    if ~(xyScale == 1 && zScale == 1)
        planC{indexS.scan}(end).deformInfo.downSampled = 'true';
    else     
        planC{indexS.scan}(end).deformInfo.downSampled = 'false';
    end
% setup scan info
    [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSetF));
    xRange = [xV(clipBox(1)) xV(clipBox(3))];
    yRange = [yV(clipBox(4)) yV(clipBox(2))]; 
    for i = 1:length(planC{indexS.scan}(end).scanInfo)
        planC{indexS.scan}(end).scanInfo(i).sizeOfDimension1 = size(im,1);
        planC{indexS.scan}(end).scanInfo(i).sizeOfDimension2 = size(im,2);
        %planC{indexS.scan}(end).scanInfo(i).CTOffset = -1*min(im(:));
        planC{indexS.scan}(end).scanInfo(i).xOffset = (xRange(1)+xRange(2))/2; 
        planC{indexS.scan}(end).scanInfo(i).yOffset = (yRange(1)+yRange(2))/2; 
    end
    
% refresh view
    controlFrame('refresh');
    sliceCallBack('refresh');
    close('Registration Setup');
    
end


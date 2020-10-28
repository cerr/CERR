function axisfusion(hAxis, method, checkSize)
%"axisFusion"
%   Fuses two B&W (indexed) images in an axis, using the passed display
%   method. A new image tagged 'fused_image' is created to handle overlapping
%   areas.
%
%   Method can be 'blend' or 'check'.
%
%   In CERR this code is used for image fusion of scanSets.
%
%JRA 12/8/04
%
%Usage:
%   function axisFusion(hAxis, method, param)
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

global planC
global stateS

indexS = planC{end};

% if stateS.optS.useOpenGL
[view] = getAxisInfo(hAxis,'view');
%axisInfo = get(hAxis, 'userdata');
%surfaces = [axisInfo.scanObj.handles];
axNum = stateS.handle.CERRAxis == hAxis;
surfaces = [stateS.handle.aI(axNum).scanObj.handles];

switch upper(view)
    case 'CORONAL'
        dim = 2;
    case 'SAGITTAL'
        dim = 1;
    case 'TRANSVERSE'
        dim = 3;
    otherwise
        return;
end

% new color limit
cLim = get(hAxis, 'cLim');

% wy Cdata = get(surfaces(stateS.imageRegistrationBaseDataset), 'Cdata');
try
    % Cdata = get(surfaces(1), 'Cdata');
    Cdata = get(stateS.handle.aI(axNum).scanObj(1).handles, 'Cdata');
catch
    return;
end
%wy


% minC = min(Cdata(:));
% if minC<cLim(1)
%     set(hAxis, 'CLim', [minC cLim(2)]);
% end
set(hAxis, 'CLim', [0,1]);

% if length(surfaces) < 2
%     %set(hFig, 'renderer', 'zbuffer');
%     return;
% end

%set(hFig, 'renderer', 'opengl');

switch method
    case 'colorblend'
        ud = stateS.handle.controlFrameUd ;
        
        cLim = get(hAxis, 'cLim');
        %img1 = get(surfaces(1), 'cData');
        %img2 = get(surfaces(2), 'cData');
        
        if stateS.handle.aI(axNum).scanObj(1).scanSet == stateS.imageRegistrationBaseDataset
            %img1 = get(stateS.handle.aI(axNum).scanObj(1).handles,'cData');
            %img2 = get(stateS.handle.aI(axNum).scanObj(2).handles,'cData');            
            baseIndex = 1;
            movIndex = 2;
        elseif stateS.handle.aI(axNum).scanObj(1).scanSet == stateS.imageRegistrationMovDataset
            %img1 = get(stateS.handle.aI(axNum).scanObj(2).handles,'cData');
            %img2 = get(stateS.handle.aI(axNum).scanObj(1).handles,'cData');
            baseIndex = 2;
            movIndex = 1;
        end       
        
        CTOffset    = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanInfo(1).CTOffset;
        scanUID = ['c',repSpaceHyp(planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanUID(max(1,end-61):end))];
        CTLevel     = stateS.scanStats.CTLevel.(scanUID) + CTOffset;
        CTWidth     = stateS.scanStats.CTWidth.(scanUID);
        CTLow       = CTLevel - CTWidth/2;
        CTHigh      = CTLevel + CTWidth/2;
        img1 = stateS.handle.aI(axNum).scanObj(baseIndex).data2M;
        img1 = img1 - double(CTLow);
        img1 = img1 / double( CTHigh - CTLow);

        
        CTOffset    = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanInfo(1).CTOffset;
        scanUID = ['c',repSpaceHyp(planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanUID(max(1,end-61):end))];
        CTLevel     = stateS.scanStats.CTLevel.(scanUID) + CTOffset;
        CTWidth     = stateS.scanStats.CTWidth.(scanUID);
        CTLow       = CTLevel - CTWidth/2;
        CTHigh      = CTLevel + CTWidth/2;
        img2 = stateS.handle.aI(axNum).scanObj(movIndex).data2M;        
        img2 = img2 - double(CTLow);
        img2 = img2 / double( CTHigh - CTLow);
        
        
        surfaces = [stateS.handle.aI(axNum).scanObj(baseIndex).handles, ...
            stateS.handle.aI(axNum).scanObj(movIndex).handles];
        
        %if size(img2, 3) == 1
        
        if stateS.optS.checkerBoard && ~isempty(img1) && ~isempty(img2)
            imgOv = (img2 - cLim(1)) / (cLim(2)-cLim(1));
            imgOv = clip(imgOv, 0, 1, 'limits');            
            checkerSize = floor(str2double(get(ud.handles.ckSizeValue, 'string')));
            [m n]= size(imgOv);
            m1 = fix(m/checkerSize); n1 = fix(n/checkerSize);
            black = zeros(m1, n1, 'uint16');
            white = ones(m1, n1, 'uint16');
            tile = [black white; white black];
            I = repmat(tile, [ceil(m/(2*m1)) ceil(n/(2*n1)) 1]);
            I = double(I(1:m, 1:n, 1));
        end
        
        %try
        if (stateS.optS.difference || stateS.optS.newchecker || ... %stateS.optS.checkerBoard || ...
                stateS.optS.mirror || stateS.optS.mirrorscope || ...
                stateS.optS.blockmatch || stateS.optS.mirrchecker ...
                || stateS.optS.mirrorCheckerBoard) && ~isempty(img1) && ~isempty(img2)
            
            set(gcf,'Pointer','watch');
            %drawnow;
            coord = getAxisInfo(hAxis,'coord');
            %scanSets = getAxisInfo(hAxis,'scanSets');
            [slc1, sliceXVals1, sliceYVals1] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, dim, planC);
            [slc2, sliceXVals2, sliceYVals2] = getCTOnSlice(stateS.imageRegistrationMovDataset, coord, dim, planC);
            
            %Interpolate scan2 on scan1
            img2 = finterp2(sliceXVals2, sliceYVals2, slc2, sliceXVals1, sliceYVals1, 1, 0);
            img1 = slc1;
            
            CTOffset    = planC{indexS.scan}...
                (stateS.imageRegistrationBaseDataset)...
                .scanInfo(1).CTOffset;
            scanUID = ['c',repSpaceHyp(planC{indexS.scan}...
                (stateS.imageRegistrationBaseDataset)...
                .scanUID(max(1,end-61):end))];
            CTLevel = stateS.scanStats.CTLevel.(scanUID) + CTOffset;
            CTWidth = stateS.scanStats.CTWidth.(scanUID);
            CTLow       = CTLevel - CTWidth/2;
            CTHigh      = CTLevel + CTWidth/2;
            img1 = clip(img1, CTLow, CTHigh, 'limits');
            
            CTOffset    = planC{indexS.scan}...
                (stateS.imageRegistrationMovDataset)...
                .scanInfo(1).CTOffset;
            scanUID = ['c',repSpaceHyp(planC{indexS.scan}...
                (stateS.imageRegistrationMovDataset)...
                .scanUID(max(1,end-61):end))];
            CTLevel = stateS.scanStats.CTLevel.(scanUID) + CTOffset;
            CTWidth = stateS.scanStats.CTWidth.(scanUID);
            CTLow       = CTLevel - CTWidth/2;
            CTHigh      = CTLevel + CTWidth/2;
            img2 = clip(img2, CTLow, CTHigh, 'limits');
            set(gcf,'Pointer','arrow');
        end
        if stateS.optS.mirrorscope
            lineInfo = [];
            if isfield(stateS.handle.aI(axNum).axisFusion,'MirrorScopeLocator')
                hMirrorLocator = stateS.handle.aI(axNum).axisFusion.MirrorScopeLocator;
                if ishandle(hMirrorLocator)
                    lineInfo = get(hMirrorLocator, 'userdata');
                end
            end
            if ~isempty(lineInfo)
                mirrPos = lineInfo{3};
            end
        end
        
        if stateS.optS.blockmatch
            CERRStatusString('Computing Block translation, wait ...');
            blockSize = 12; %floor(str2num(get(ud.handles.bmSizeValue, 'string')));
            set(gcf,'Pointer','watch');drawnow;
            [offset, Nx, Ny] = RegdoBlockMatch(img1, img2, blockSize, blockSize);
            CERRStatusString('Ready ...');
            set(surfaces(1:end), 'facealpha', 0);
            set(surfaces(end), 'facealpha', 1);
            
            color1 = [1 0 0];
            color2 = [1 1 0];
            
            scaleX = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanInfo(1).grid2Units;
            scaleY = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanInfo(1).grid1Units;
            RegDrawBlockMatch(hAxis, surfaces(end), Nx, Ny, offset, color1, color2, scaleX, scaleY);
            set(gcf,'Pointer','arrow');
            return;
            
        elseif stateS.optS.mirrorscope
            %hBox = findobj('Tag', 'MirrorScope', 'Parent', hAxis);
            hBox = stateS.handle.aI(axNum).axisFusion.MirrorScopePatch;
            ud = get(hBox, 'userdata');
            xyRange = ud{1}; %ud{1} = [x: min(ud{2}) max(ud{2}) y: max(ud{3}) min(ud{3})];
            
            xInd  = find(sliceXVals1 >= xyRange(1) & sliceXVals1 <= xyRange(2) );
            yInd  = find(sliceYVals1 >= xyRange(4) & sliceYVals1 <= xyRange(3) );
            
            xlen = length(xInd);
            ylen = length(yInd);
            img1 = img1/max(img1(:))*1000;
            img2 = img2/max(img2(:))*1000;
            im2 = img2(yInd(1):yInd(ylen), xInd(1):xInd(xlen))+3;
            im1 = img1(yInd(1):yInd(ylen), xInd(1):xInd(xlen))+30;
            
            
            %                     if img1 and img2 have different pixel size, it is necessary to do a resample work to make sure
            %                     they have same grid size before mirroring.
            if xyRange(1) >= min(sliceXVals1) && xyRange(2) <= max(sliceXVals1)
                
                if mod(size(im1,2), 2) == 0
                    isEven = 1;
                else
                    isEven = 0;
                end
                
                mirrPos = round(size(im1,2)/2);
                minIm1 = min(im1(:));
                maxIm1 = max(im1(:));
                im1 = (im1-minIm1)/(maxIm1-minIm1);
                minIm2 = min(im2(:));
                maxIm2 = max(im2(:));
                im2 = (im2-minIm2)/(maxIm2-minIm2);
                imMirr = RegdoMirror(im1, im2, mirrPos, isEven);
                
                xVals = ud{2};
                yVals = ud{3};
                r  = ( max(xVals) -  min(xVals) )/2;
                cx = ( max(xVals) +  min(xVals) )/2;
                cy = ( max(yVals) +  min(yVals) )/2;
                
                minIm1 = min(img1(:));
                maxIm1 = max(img1(:));
                img1 = (img1-minIm1)/(maxIm1-minIm1);
                imSc = img1;
                pxV = sliceXVals1(xInd);
                pyV = sliceYVals1(yInd);
                [pxM,pyM] = meshgrid(pxV,pyV);
                indInsideMirror = (pxM-cx).^2 + (pyM-cy).^2 < r^2;
                imMirror = img1(yInd,xInd);
                imMirror(indInsideMirror) = imMirr(indInsideMirror);
                imSc(yInd(1):yInd(ylen), xInd(1):xInd(xlen)) = imMirror;
                
                set(surfaces(end-1), 'cData', imSc, 'xdata', [sliceXVals1(1) sliceXVals1(end)], 'ydata', [sliceYVals1(1) sliceYVals1(end)]);
                set(surfaces(1:end), 'facealpha', 1);
                set(surfaces(end), 'facealpha', 0);
                
                % Set stacking order so that MirrorScope patch is at the
                % top
                %childV = get(hAxis,'Children');
                %childV([1,2,3]) = childV([3,1,2]);
                %set(hAxis,'Children',childV);
                uistack(hBox,'top')
                
                return;
            end
            
            
            
        elseif stateS.optS.mirror
            if isempty(img1) || isempty(img2)
                return
            end
            
            lineInfo = [];
            if isfield(stateS.handle.aI(axNum).axisFusion,'MirrorScopeLocator')
                hMirrorLocator = stateS.handle.aI(axNum).axisFusion.MirrorScopeLocator;
                lineInfo = get(hMirrorLocator, 'userdata');
            end
            if ~isempty(lineInfo)
                mirrPos = lineInfo{3};
            end
            
            imgOv = RegdoMirror(img1, img2, mirrPos);
            
            xd1 = [sliceXVals1(1) sliceXVals1(end)];
            
            [originF, spacingF, centerF] = getScanOriginSpacing(planC{indexS.scan}(stateS.imageRegistrationBaseDataset));
            [originM, spacingM, centerM] = getScanOriginSpacing(planC{indexS.scan}(stateS.imageRegistrationMovDataset));
            
            switch lower(view)
                case 'transverse'
                    xd = [xd1(:,2) - spacingF(1)*(size(img1,2)-mirrPos) - spacingF(1)*(size(img2,2)-mirrPos+1) xd1(:,2)];
                    
                case 'sagittal'
                    if xd1(1)>xd1(2)
                        xd = [xd1(:,2) + spacingF(2)*(size(img1,2)-mirrPos) + spacingF(2)*(size(img2,2)-mirrPos) xd1(:,2)];
                    else
                        xd = [xd1(:,2) - spacingF(2)*(size(img1,2)-mirrPos) - spacingF(2)*(size(img2,2)-mirrPos) xd1(:,2)];
                    end
                case 'coronal'
                    xd = [xd1(:,2) - spacingF(1)*(size(img1,2)-mirrPos) - spacingF(1)*(size(img2,2)-mirrPos+1) xd1(:,2)];
                    
            end
            
            modeBase = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanType;
            modeMove = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanType;
            if strcmpi(modeBase, modeMove)
                imgOv = (imgOv-min(imgOv(:)))/(max(imgOv(:))-min(imgOv(:)));
                set(surfaces(end-1), 'cData', imgOv, 'xdata', xd, 'ydata', [sliceYVals1(1) sliceYVals1(end)]);
            else
                set(hAxis, 'CLim', [min(imgOv(:)) max(imgOv(:))]);
                set(surfaces(end-1), 'cData', imgOv, 'xdata', xd, 'ydata', [sliceYVals1(1) sliceYVals1(end)]);
            end
            
            %set(surfaces(1:end), 'facealpha', 1);
            %set(surfaces(end), 'facealpha', 0);
            
            return;
            
        elseif stateS.optS.mirrchecker
            if isempty(img1) || isempty(img2)
                return
            end
            imgOv = RegdoMirrCheckboard(img1, img2, checkerSize, checkerSize);
            set(surfaces(end-1), 'cData', double(imgOv));
            set(surfaces(1:end), 'facealpha', 0);
            set(surfaces(end-1), 'facealpha', 1);
            set(hAxis, 'cLim', [min(imgOv(:)) max(imgOv(:))]);
            return;
            
        elseif stateS.optS.newchecker
            if isempty(img1) || isempty(img2)
                return;
            end
            imgOv = RegdoCheckboard(img1, img2, checkerSize, checkerSize);
            set(surfaces(end-1), 'cData', double(imgOv), 'xdata', [sliceXVals1(1) sliceXVals1(end)], 'ydata', [sliceYVals1(1) sliceYVals1(end)]);
            set(surfaces(1:end), 'facealpha', 0);
            set(surfaces(end-1), 'facealpha', 1);
            set(hAxis, 'cLim', [min(imgOv(:)) max(imgOv(:))]);
            return;
            
        elseif stateS.optS.mirrorCheckerBoard
            if isempty(img1) || isempty(img2)
                return;
            end
            orientationVal = get(ud.handles.mirrorcheckerOrientation,'value');
            orientationStr = get(ud.handles.mirrorcheckerOrientation,'string');
            orientation = orientationStr{orientationVal};
            checkerSize = get(ud.handles.newcheckerSize,'value');
            metricVal = round(get(ud.handles.mirrorcheckerMetricPopup,'value'));
            set(ud.handles.mirrorcheckerMetricPopup,'value',metricVal)
            imgOv = RegdoMirrCheckboard(img1, img2, checkerSize, checkerSize, orientation, metricVal);
            set(surfaces(end-1), 'cData', double(imgOv));
            set(surfaces(1:end), 'facealpha', 0);
            set(surfaces(end-1), 'facealpha', 1);
            set(hAxis, 'cLim', [min(imgOv(:)) max(imgOv(:))]);
            return;
            
            
        elseif stateS.optS.difference
            %
            if isempty(img1) || isempty(img2)
                return
            end
            xdim = min(size(img1,1), size(img2,1));
            ydim = min(size(img1,2), size(img2,2));
            imgOv = imabsdiff(img1(1:xdim, 1:ydim), img2(1:xdim, 1:ydim));
            
            imgOv = (imgOv - min(imgOv(:))) / (max(imgOv(:)) - min(imgOv(:)));
            imgOv = adapthisteq(imgOv,'clipLimit',0.03,'Distribution','rayleigh');
            
            CA_Image = imgOv;
            CA_Image(:,:,2) = CA_Image(:,:,1);
            CA_Image(:,:,3) = CA_Image(:,:,1);
            CA_Image = single(CA_Image);
            
            c1 = 1;
            CA_Image(:,:,2) = CA_Image(:,:,2) + c1*0.126;
            CA_Image(:,:,3) = CA_Image(:,:,3) + c1*0.126;
            CA_Image = min(CA_Image,1);
            
            set(surfaces(end-1), 'cData', double(CA_Image), 'xdata', [sliceXVals1(1) sliceXVals1(end)], 'ydata', [sliceYVals1(1) sliceYVals1(end)]);
            set(surfaces(1:end), 'facealpha', 0);
            set(surfaces(end-1), 'facealpha', 1);
            set(hAxis, 'cLim', [min(CA_Image(:)) max(CA_Image(:))]);
            return;
            
        end
        
        %catch
        %    % CERRStatusString('...eee...');
        %    err = lasterror;
        %    disp(err.message)
        %    set(gcf,'Pointer','arrow');
        %end
        
        %wy enable base image display %
        %img23D = repmat(zeros(size(img1)), [1 1 3]);
        img23D = zeros([size(img1) 3]);
        %ud = stateS.handle.controlFrameUd ;
        clrVal = get(ud.handles.basedisplayModeColor,'value');
        
        switch num2str(clrVal)
            case '1' % Gray
                img23D = img1;
                
            case '2' %copper
                if ndims(img1) > 2
                    img23D = img1;
                else
                    cmap = CERRColorMap('copper');
                    
                    img1 = (img1 - cLim(1)) / (cLim(2)-cLim(1))*(size(cmap,1)-1);
                    
                    %clipImg = clip(round(img1(:)),1,size(cmap,1),'limits');
                    
                    clipImg = clip(uint16(img1(:)),1,size(cmap,1),'limits');
                    cmapV = cmap(clipImg, 1:3);
                    
                    
                    imgSiz = size(img1);
                    img23D(:,:,1) = reshape(cmapV(:,1),imgSiz);
                    img23D(:,:,2) = reshape(cmapV(:,2),imgSiz);
                    img23D(:,:,3) = reshape(cmapV(:,3),imgSiz);
                end
                %try
                %    img23D = reshape(cmap(clipImg, 1:3),size(img1,1),size(img1,2),3);
                %catch
                %    return
                %end
                
            case '6' %dose colormap
                if ndims(img1) > 2
                    img23D = img1;
                else
                    a = CERRColorMap('star');
                    N = length(a);
                    pts = linspace(1,N, 255);
                    b = interp1(1:N, a(:,1), pts);
                    c = interp1(1:N, a(:,2), pts);
                    d = interp1(1:N, a(:,3), pts);
                    cmap = [b' c' d'];
                    img1 = (img1 - cLim(1)) / (cLim(2)-cLim(1))*(size(cmap,1)-1);
                    %clipImg = clip(round(img1(:)),1,size(cmap,1),'limits');
                    clipImg = clip(uint16(img1(:)),1,size(cmap,1),'limits');
                    cmapV = cmap(clipImg, 1:3);
                    imgSiz = size(img1);
                    img23D(:,:,1) = reshape(cmapV(:,1),imgSiz);
                    img23D(:,:,2) = reshape(cmapV(:,2),imgSiz);
                    img23D(:,:,3) = reshape(cmapV(:,3),imgSiz);
                end
                %try
                %    img23D = reshape(cmap(clipImg, 1:3),size(img1,1),size(img1,2),3);
                %catch
                %    return
                %end
                
            case '7' %hotcold
                if ndims(img1) > 2
                    img23D = img1;
                else
                    
                    cmap = CERRColorMap('hotcold');
                    
                    img1 = (img1 - cLim(1)) / (cLim(2)-cLim(1))*(size(cmap,1)-1);
                    
                    %clipImg = clip(round(img1(:)),1,size(cmap,1),'limits');
                    clipImg = clip(uint16(img1(:)),1,size(cmap,1),'limits');
                    cmapV = cmap(clipImg, 1:3);
                    imgSiz = size(img1);
                    img23D(:,:,1) = reshape(cmapV(:,1),imgSiz);
                    img23D(:,:,2) = reshape(cmapV(:,2),imgSiz);
                    img23D(:,:,3) = reshape(cmapV(:,3),imgSiz);
                    
                    %try
                    %    img23D = reshape(cmap(clipImg, 1:3),size(img1,1),size(img1,2),3);
                    %catch
                    %    return
                    %end
                end
                
                if stateS.optS.checkerBoard
                    img23D = img23D.*repmat(I, [1 1 3]);
                end
                
                
            otherwise % case '3'(red) case '4'(green) case '5'(blue)
                if ndims(img1) > 2
                    img23D = img1;
                else
                    
                    img1 = (img1 - cLim(1)) / (cLim(2)-cLim(1));
                    %img1 = clip(img1, 0, 1, 'limits');
                    
                    if (clrVal==3)
                        img23D(:,:,1) = img1;
                        img23D(:,:,2) = img1*0.66;
                        img23D(:,:,3) = img1*0.66;
                    end
                    if (clrVal==4)
                        img23D(:,:,2) = img1;
                        img23D(:,:,1) = img1*0.66;
                        img23D(:,:,3) = img1*0.66;
                    end
                    if (clrVal==5)
                        img23D(:,:,3) = img1;
                        img23D(:,:,2) = img1*0.66;
                        img23D(:,:,1) = img1*0.66;
                    end
                end
        end
        %set(surfaces(end-1), 'cData', img23D);
        set(stateS.handle.aI(axNum).scanObj(baseIndex).handles,'cData',img23D);
        
        %wy
        
        img23D = repmat(zeros(size(img2)), [1 1 3]);
        ud = stateS.handle.controlFrameUd ;
        clrVal = get(ud.handles.displayModeColor,'value');
        
        switch num2str(clrVal)
            %case '1' % Gray
            %    if stateS.optS.checkerBoard
            %        img2 = img2.*I;
            %        set(surfaces(end), 'cData', img2);
            %    end
            %    return;
            
            case '2' %copper
                cmap = CERRColorMap('copper');
                
                img2 = (img2 - cLim(1)) / (cLim(2)-cLim(1))*(size(cmap,1)-1);
                
                %clipImg = clip(round(img2(:)),1,size(cmap,1),'limits');
                %clipImg = clip(uint16(img2(:)),1,size(cmap,1),'limits');
                clipImg = clip(uint16(img2(:)),1,size(cmap,1),'limits');
                nanIndV = isnan(clipImg);
                clipImg(nanIndV) = 1;
                
                try
                    
                    %img23D = reshape(cmap(clipImg, 1:3),size(img2,1),size(img2,2),3);
                    cmapV = cmap(clipImg, 1:3);
                    imgSiz = size(img2);
                    img23D(:,:,1) = reshape(cmapV(:,1),imgSiz);
                    img23D(:,:,2) = reshape(cmapV(:,2),imgSiz);
                    img23D(:,:,3) = reshape(cmapV(:,3),imgSiz);
                    
                catch
                    return
                end
                
                if stateS.optS.checkerBoard
                    img23D = img23D.*repmat(I, [1 1 3]);
                end
                
            case '6' %dose colormap
                a = CERRColorMap('star');
                N = length(a);
                pts = linspace(1,N, 255);
                b = interp1(1:N, a(:,1), pts);
                c = interp1(1:N, a(:,2), pts);
                d = interp1(1:N, a(:,3), pts);
                cmap = [b' c' d'];
                img2 = (img2 - cLim(1)) / (cLim(2)-cLim(1))*(size(cmap,1)-1);
                %clipImg = clip(round(img2(:)),1,size(cmap,1),'limits');
                clipImg = clip(uint16(img2(:)),1,size(cmap,1),'limits');
                nanIndV = isnan(clipImg);
                clipImg(nanIndV) = 1;
                cmapV = cmap(clipImg, 1:3);
                imgSiz = size(img2);
                img23D(:,:,1) = reshape(cmapV(:,1),imgSiz);
                img23D(:,:,2) = reshape(cmapV(:,2),imgSiz);
                img23D(:,:,3) = reshape(cmapV(:,3),imgSiz);
                
                %try
                %    img23D = reshape(cmap(clipImg, 1:3),size(img2,1),size(img2,2),3);
                %catch
                %    return
                %end
                
            case '7' %hotcold
                cmap = CERRColorMap('hotcold');
                
                img2 = (img2 - cLim(1)) / (cLim(2)-cLim(1))*(size(cmap,1)-1);
                
                %clipImg = clip(round(img2(:)),1,size(cmap,1),'limits');
                clipImg = clip(uint16(img2(:)),1,size(cmap,1),'limits');
                nanIndV = isnan(clipImg);
                clipImg(nanIndV) = 1;
                cmapV = cmap(clipImg, 1:3);
                imgSiz = size(img2);
                img23D(:,:,1) = reshape(cmapV(:,1),imgSiz);
                img23D(:,:,2) = reshape(cmapV(:,2),imgSiz);
                img23D(:,:,3) = reshape(cmapV(:,3),imgSiz);
                
                %try
                %    img23D = reshape(cmap(clipImg, 1:3),size(img2,1),size(img2,2),3);
                %catch
                %    return
                %end
                
                if stateS.optS.checkerBoard
                    img23D = img23D.*repmat(I, [1 1 3]);
                end
                
            otherwise % case '3'(red) case '4'(green) case '5'(blue)
                img2 = (img2 - cLim(1)) / (cLim(2)-cLim(1));
                img2 = clip(img2, 0, 1, 'limits');
                
                if stateS.optS.checkerBoard
                    img2 = img2.*I;
                end
                
                if clrVal == 1
                    img23D(:,:,3) = img2;
                    img23D(:,:,1) = img2;
                    img23D(:,:,2) = img2;
                end
                
                if (clrVal==3)
                    img23D(:,:,1) = img2;
                    img23D(:,:,2) = img2*0.66;
                    img23D(:,:,3) = img2*0.66;
                end
                if (clrVal==4)
                    img23D(:,:,2) = img2;
                    img23D(:,:,1) = img2*0.66;
                    img23D(:,:,3) = img2*0.66;
                end
                if (clrVal==5)
                    img23D(:,:,3) = img2;
                    img23D(:,:,2) = img2*0.66;
                    img23D(:,:,1) = img2*0.66;
                end
        end
        %set(surfaces(end), 'cData', img23D);
        set(stateS.handle.aI(axNum).scanObj(movIndex).handles,'cData',img23D);
        
        
        % end % size(img1,3)==1?
end

if ~isempty(surfaces)
    set(surfaces(1:end), 'facealpha', 1);
end
% For imageType image
% for iSurf = 1:length(surfaces)
%     alphaData = get(surfaces(iSurf),'AlphaData');
%     set(surfaces(iSurf),'AlphaData',double(alphaData~=0))
% end
% For imageType image ends
if stateS.imageRegistration && ~isempty(surfaces)
    set(stateS.handle.aI(axNum).scanObj(movIndex).handles, 'facealpha', stateS.doseAlphaValue.trans);
    % For imageType image
    %alphaData = get(surfaces(end),'AlphaData');
    %set(surfaces(end),'AlphaData',stateS.doseAlphaValue.trans*double(alphaData~=0))
elseif ~isempty(surfaces)
    set(stateS.handle.aI(axNum).scanObj(movIndex).handles, 'facealpha', 0.5);
    % For imageType image
    %alphaData = get(surfaces(end),'AlphaData');
    %set(surfaces(end),'AlphaData',0.5*double(alphaData~=0))
end

return;


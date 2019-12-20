function filteredScanM = sitkWrapper(sitkLibPath, scanM, filterType, paramS, planC)
%function filteredScanM = sitkWrapper(sitkLibPath, scanM, filterType, paramS, planC)
%Calculate image filters using the Simple ITK Python Library
%sitkLibPath - location of sitk python wrappscan to be filtered
%description - Short description string if desired.
%filterType - name of sitk filter
%paramS: parameters required to calculate the filter
%planC: to convert scan back to cerr
%
%example usage:
% filterType = 'GradientImageFilter';
% paramS.bImgSpacing = false;
% paramS.bImgDir = true;
% cerrFileName = 'E:\data\HeartSegDeepLab\testCase.mat';
% sitkLibPath = 'C:\Python34\Lib\site-packages\SimpleITK\';
% planC = loadPlanC(cerrFileName,tempdir);
% planC = updatePlanFields(planC);
% % Quality assure
% planC = quality_assure_planC(cerrFileName,planC);
% indexS = planC{end};
%  % Get Scan
%  scanNum  =1;
%  scanM = double(planC{indexS.scan}(scanNum).scanArray) ...
%      - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;%         
% 
% sitkWrapper(sitkLibPath, scanM, filterType, paramS, planC)
%
%
% Rutu Pandya, Dec, 16 2019.
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
% along with CERR.

% importing python module Simple ITK

indexS = planC{end};

sitkModule = 'SimpleITK';
P = py.sys.path;
currentPath = pwd;
cd(sitkLibPath);
sitkFileName = fullfile(sitkLibPath,sitkModule);

try    
    if count(P,sitkFileName) == 0
        insert(P,int32(0),sitkFileName);
    end
    py.importlib.import_module(sitkModule);
        
catch
    disp('SimpleITK module could not be imported, check the path');
end

cd(currentPath);

% visualize original scan
slc = 50;
figure, imagesc(scanM(:,:,50)), title('orig Image')

% convert scan to numpy array and integer
scanPy = py.numpy.array(scanM(:).');
scanPy = scanPy.astype(py.numpy.int64);

% get original shape of the scan 
origShape = py.numpy.array(size(scanM));
origShape = origShape.astype(py.numpy.int64);

% reshape numpy array to original shape
scanPy = reshape(scanPy,origShape);

try      
    switch filterType
        case 'GradientImageFilter'
                                  
            % Get image from the array
            itkimg = py.SimpleITK.GetImageFromArray(scanPy);
            
            % calculate gradient
            gradient = py.SimpleITK.GradientImageFilter();
            gradImg = gradient.Execute(itkimg);
            
            % extract numpy array from resulting image
            npGradImg = py.SimpleITK.GetArrayFromImage(gradImg);
            
            % convert resulting numpy array to matlab array in required shape
            dblGradResultM = double(py.array.array('d',py.numpy.nditer(npGradImg)));
            gradMatM = reshape(dblGradResultM,[3,512,512,121]);
            gradMatM = permute(gradMatM,[3,2,4,1]);
         
%             %visualize
%             size(gradMatM)
%             figure, imagesc(gradMatM(:,:,slc,1))
%             figure, imagesc(gradMatM(:,:,slc,2))
%             figure, imagesc(gradMatM(:,:,slc,3))
            
            filteredScanM = gradMatM;
            
        case 'HistogramMatchingImageFilter'
            
            refImg = py.SimpleITK.ReadImage(paramS.refImgPath);            
 
            % src images from the array
            srcImg = py.SimpleITK.GetImageFromArray(scanPy);            
            
            matcher = py.SimpleITK.HistogramMatchingImageFilter();
            matcher.SetNumberOfHistogramLevels(paramS.numHistLevel);
            matcher.SetNumberOfMatchPoints(paramS.numMatchPts);
            matcher.ThresholdAtMeanIntensityOn();
            matchedImg = matcher.Execute(srcImg,refImg);
            
            % extract numpy array from resulting image
            npmatchedImg = py.SimpleITK.GetArrayFromImage(matchedImg);
            
            %convert to double
            dblhistMatchResultM = double(py.array.array('d',py.numpy.nditer(npmatchedImg)));
            
            %reshape and permute to match matlab input
            histMatM = reshape(dblhistMatchResultM,[3,512,512,121]);
            histMatM = permute(histMatM,[3,2,4,1]);
            size(histMatM)
            figure, imagesc(histMatM(:,:,slc,1))
            figure, imagesc(histMatM(:,:,slc,2))
            figure, imagesc(histMatM(:,:,slc,3))
    end
    
catch
        disp('error using sitk filter')
   
end

%convert scan back to planC

newScanIndex = 1;
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(newScanIndex));
dx = abs(mean(diff(xVals)));
dy = abs(mean(diff(yVals)));
dz = abs(mean(diff(zVals)));
deltaXYZv = [dy dx dz];
minc = 1;
maxr = size(gradMatM,1);
uniqueSlicesV = 1:size(gradMatM,3);
zV = zVals(uniqueSlicesV);
regParamsS.horizontalGridInterval = deltaXYZv(1);
regParamsS.verticalGridInterval   = deltaXYZv(2); %(-)ve for dose
regParamsS.coord1OFFirstPoint   = xVals(minc);
regParamsS.coord2OFFirstPoint   = yVals(maxr);

regParamsS.zValues  = zV;
regParamsS.sliceThickness =[planC{indexS.scan}(newScanIndex).scanInfo(uniqueSlicesV).sliceThickness];

assocTextureUID ='';

planC = scan2CERR(squeeze(filteredScanM(:,:,:,1)),'x-direction','Passed',regParamsS,assocTextureUID,planC);
planC = scan2CERR(squeeze(filteredScanM(:,:,:,2)),'y-direction','Passed',regParamsS,assocTextureUID,planC);
planC = scan2CERR(squeeze(filteredScanM(:,:,:,3)),'z-direction','Passed',regParamsS,assocTextureUID,planC);

    









function visualStruct3D(V,TR,DoseFlag,DoseL,DoseT,StrN);
%function visualStruct3D(V,TR,DoseFlag,DoseL,DoseT,StrN);
%Latest modifications:  CZ, 18 Feb. 2003
%                       17 Apr 03, JOD, modifed variable name optS.visual3DxyDownsampleIndex.
%                       CZ, May 4, modification to resolve the case if there is no 'SKIN' strucutre (line 90-98)
%                       JOD, 9 may 03, added update notification (waitbar caused segmentation faults(?)).
%
%3D structure visualization
%V structure number vector
%TR -transparancy parameter vector
%DoseFlag = 1, show dose
%DoseL - dose cut level
%DoseT - dose transparency
%StrN - get3DDoses parameter
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


figure,
clf reset;
hold on;
axis off
global stateS planC
indexS = planC{end};

scanNum = unique(getStructureAssociatedScan(V));
if length(scanNum) > 1
    CERRStatusString('Structures must belong to same scan.')
    return
end
cmX = planC{planC{end}.scan}(scanNum).scanInfo(1,1).grid2Units*planC{planC{end}.scan}(scanNum).scanInfo(1,1).sizeOfDimension2;
cmY = planC{planC{end}.scan}(scanNum).scanInfo(1,1).grid1Units*planC{planC{end}.scan}(scanNum).scanInfo(1,1).sizeOfDimension1;
cmZ = planC{planC{end}.scan}(scanNum).scanInfo(1,end).zValue - planC{planC{end}.scan}(scanNum).scanInfo(1,1).zValue;

cmA = [cmX;cmY;cmZ];

m = max(cmA);

bA = cmA/m;


CERRStatusString(['Constructing surfaces.  Finished with 0 out of ' num2str(length(V)) ' structures.'])

for i=1:length(V),

    Str_Num=V(i);

    %color = stateS.optS.colorOrder(Str_Num,:);
    color = planC{indexS.structures}(Str_Num).structureColor;

    maskS = flipdim(getUniformStr(Str_Num), 2);

    mask = maskS; %No need to convert to double... waste of memory.

    SZ=size(mask);

    resize_factor = round(SZ(1)/stateS.optS.visual3DxyDownsampleIndex);

    mD = getDownsample3(mask, resize_factor, 1);
    
    %sz_mask = size(mD);
    %sz_mask(3) = sz_mask(3)*2;
    %mD = fft_upsample3d(mD,sz_mask);
    
    D = smooth3(mD,'gaussian');

    S = size(D);

    linered = logical(uint8(zeros(S)));
    linegreen = linered;

    linered((round(0.87*S(1))):(round(0.87*S(1)+2)),(round(0.94*S(2)-2)):(round(0.94*S(2))),(round(0.89*S(3)-15)):(round(0.89*S(3)))) = 1;
    linegreen((round(0.87*S(1))):(round(0.87*S(1)+2)),(round(0.94*S(2)-13)):(round(0.94*S(2))),(round(0.89*S(3)-2)):(round(0.89*S(3)))) = 1;

    [x,y,z,D] = subvolume(D,[1,S(1),1,S(2),1,S(3)]);

    p1 = patch(isosurface(x,y,z,D, 0.1),...
        'FaceColor',color,'EdgeColor','none','FaceAlpha',TR(i));
%    isonormals(x,y,z,D,p1); %%May or maynot be necessary... w/o isonormals
%    is still pretty good

    %p2 = patch(isocaps(x,y,z,D, 0.1),...
     %   'FaceColor','interp','EdgeColor','none','FaceAlpha',TR(i));

    CERRStatusString(['Constructing surfaces.  Finished with ' num2str(i) ' out of ' num2str(length(V)) ' structures.'])

end

[x,y,z,linered] = subvolume(linered,[1,S(1),1,S(2),1,S(3)]);

p1 = patch(isosurface(x,y,z,linered, 0.1),...
    'FaceColor','red','EdgeColor','none');
%isonormals(x,y,z,linered,p1);

%p2 = patch(isocaps(x,y,z,linered, 0.1),...
 %   'FaceColor','interp','EdgeColor','none');

[x,y,z,linegreen] = subvolume(linegreen,[1,S(1),1,S(2),1,S(3)]);

p1 = patch(isosurface(x,y,z,linegreen, 0.1),...
    'FaceColor','green','EdgeColor','none');
%isonormals(x,y,z,linegreen,p1);

%p2 = patch(isocaps(x,y,z,linegreen, 0.1),...
%    'FaceColor','green','EdgeColor','none');


if DoseFlag ==1

    % use appropriate scanNum here. Currently it is 1.    
    [sizeArray] = getUniformScanSize(planC{indexS.scan}(1));
    
    indexS = planC{end};
        
    %Uniformizing the dose, same size as uniform scan.
    doseIndx = stateS.doseSet;
    dose3M = zeros(sizeArray, 'single');
    for i = 1:sizeArray(3)
        zValue = planC{indexS.scan}(scanNum).uniformScanInfo.firstZValue + (i-1)*planC{indexS.scan}.uniformScanInfo.sliceThickness;
        doseM = calcDoseSlice(planC{indexS.dose}(doseIndx),zValue,3);
        if ~isempty(doseM)
            dose3M(:,:,i) = fitDoseToCT(doseM, planC{indexS.dose}(doseIndx), planC{indexS.scan}(stateS.scanSet), 3);
        end
    end


    Dose = double(dose3M);

    c = CERRColorMap(stateS.optS.doseColormap);

    f = size(c);

    doseMax = max(max(max(Dose)));

    colorDose = c(round(f(1)*DoseL/doseMax),:);

    SZ=size(Dose);

    mD = getDownsample3(Dose, resize_factor, 1);

    D = smooth3(mD,'gaussian');

    D(D < DoseL) = 0;

    S = size(D);

    [x,y,z,D] = subvolume(D,[1,S(1),1,S(2),1,S(3)]);

    p1 = patch(isosurface(x,y,z,D, 0.1),...
        'FaceColor',colorDose,'EdgeColor','none','FaceAlpha',DoseT);
    isonormals(x,y,z,D,p1);

    p2 = patch(isocaps(x,y,z,D, 0.1),...
        'FaceColor','interp','EdgeColor','none','FaceAlpha',DoseT);
end


h=gca;
view(3);
axis([1 S(1) 1 S(2) 1 S(3)]);

colormap(hsv);
lighting gouraud;
view(42.48,-15.40);

set(h,'CameraPosition',[716.99 -648.02 -226.14],'CameraTarget',[S(1)/2 S(2)/2 S(3)/(SZ(1)/S(1))],...
    'CameraViewAngle',6.91,'CameraUpVector',[-0.22 0.24 -0.76],'PlotBoxAspectRatio',[bA(1) bA(2) bA(3)]);

light('Color','white','Position',[22, 0, -8],'Style','infinite');
light('Color','white','Position',[-535.04, 9.98, 700.51],'Style','local');

axis off;

hold off;

CERRStatusString('')



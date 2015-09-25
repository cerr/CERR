function transM = getAutoRegMI(baseImgNum,moveImgNum)
%function transM = getAutoRegMI(scan1,scan2)

% imgidx = h.image_to_display;
% FImg = h.original_images{1};
% MImg = h.original_images{imgidx};

global planC
indexS = planC{end};

[originF, spacingF, centerF] = getScanOriginSpacing(planC{indexS.scan}(baseImgNum));
[originM, spacingM, centerM] = getScanOriginSpacing(planC{indexS.scan}(moveImgNum));

[xValsF, yValsF, zValsF] = getScanXYZVals(planC{indexS.scan}(baseImgNum));
[xValsM, yValsM, zValsM] = getScanXYZVals(planC{indexS.scan}(moveImgNum));
        
transMB = getTransM('scan',baseImgNum,planC);
if isempty(transMB)
    transMB = eye(4);
end
FImg = planC{indexS.scan}(baseImgNum).scanArray;
MImg = planC{indexS.scan}(moveImgNum).scanArray;

dimF = mysize(FImg);
dimM = mysize(MImg);

dimI = round(dimF(1)/2)-round(dimF(1)/4):round(dimF(1)/2)+round(dimF(1)/4)-1;
dimJ = round(dimF(2)/2)-round(dimF(2)/4):round(dimF(2)/2)+round(dimF(2)/4)-1;

clipBox =[round(dimF(2)/2)-round(dimF(2)/4) round(dimF(1)/2)-round(dimF(1)/4) ...
          round(dimF(2)/2)+round(dimF(2)/4)-1 round(dimF(1)/2)+round(dimF(1)/4)-1];
FImg = FImg(dimI,dimJ,round(dimF(3)/2):end);
% originF(2) = yValsF(dimI(end));
% originF(1) = xValsF(dimJ(1));
% originF(3) = zValsF(round(dimF(3)/2));
originF(1) = originF(1) + spacingF(1)*double(clipBox(1)-1);
originF(2) = originF(2) + spacingF(2)*double(uint16(dimF(1)-clipBox(4)));
originF(3) = originF(3) + spacingF(3)*double(round(dimF(3)/2)-1);
        
dimI = dimM(1)/2-round(dimM(1)/4):dimM(1)/2+round(dimM(1)/4)-1;
dimJ = dimM(2)/2-round(dimM(2)/4):dimM(2)/2+round(dimM(2)/4)-1;

clipBox =[round(dimM(2)/2)-round(dimM(2)/4) round(dimM(1)/2)-round(dimM(1)/4) ...
          round(dimM(2)/2)+round(dimM(2)/4)-1 round(dimM(1)/2)+round(dimM(1)/4)-1];
      
MImg = MImg(dimI,dimJ,:);
% originM(2) = yValsM(dimI(end));
% originM(1) = xValsM(dimJ(1));
originM(1) = originM(1) + spacingM(1)*double(clipBox(1)-1);
originM(2) = originM(2) + spacingM(2)*double(uint16(dimM(1)-clipBox(4)));
%originM(3) = originM(3) + spacingM(3)*double(clipBox(2)-1);

%MI Params:
Bins = 24;
Samples = 10000;
RelaxFactor = 0.8;
DefaultPixelValue = 0;
Iter_MinStep = 0.005;
Iter_MaxStep = 3;
Iter_Num = 200;

tscale = 0.001;
rscale = 1.0;
scaleFactor = 10.0;

rotM = eye(3);
transV = [0 0 0];
initMode = 1;

T = eye(4); 

fdim = 1;
FImg = flipdim(FImg, fdim); 
MImg = flipdim(MImg, fdim);

[im, Rotation, Offset] = Mattes_MI3D3206a(int16(FImg), originF, spacingF, ...
    int16(MImg), originM, spacingM, ...
    Bins, Samples, RelaxFactor, DefaultPixelValue, Iter_MinStep, Iter_MaxStep,...
    Iter_Num, tscale, rscale, scaleFactor, rotM, transV, initMode);
% 
% T(1:3,1:3) = Rot;
% T(1:3,4) = Offset(1:3);


rot = reshape(Rotation, 3,3);
offset = Offset(10:12); %offset related to origin rotation;

%     rot(2,1) = -rot(2,1); rot(1,2) = -rot(1,2);
%     rot(1,3) = -rot(1,3); rot(3,1) = -rot(3,1);
%     rot(2,3) = -rot(2,3); rot(3,2) = -rot(3,2);

%     offset(1) = -offset(1);
%     offset(2) = -offset(2);
%     offset(3) = -offset(3);

TM = eye(4);
TM(:,4) = [offset 1];

RM = eye(4);
RM(1:3, 1:3) = rot;

newTransform = inv(TM*RM);
newTransform =  transMB * newTransform;


transM = newTransform;

return;

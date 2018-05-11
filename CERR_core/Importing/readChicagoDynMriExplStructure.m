function planC = readChicagoDynMriExplStructure(maskFileName,structName,planC)
% readChicagoDynMriExplStructure.m

% Read segmentation mask exported from Chicago Dynamic MRI Explorer
%
% APA, 5/10/2018

if ~exist(planC','var')
    global planC
end
indexS = planC{end};

fid = fopen(maskFileName, 'rb');
limsV = fread(fid, 6, 'uint16=>uint16');
rowStart = limsV(1);
rowEnd = limsV(4);
colStart = limsV(2);
colEnd = limsV(5);
slcStart = limsV(3);
slcEnd = limsV(6);
maskV = fread(fid, numVox, 'uint8=>uint8');
croppedMask3M = reshape(maskV,(rowEnd-rowStart+1),(colEnd-colStart+1),(slcEnd-slcStart+1));
scanNum = 1;
sizV = size(planC{indexS.scan}(1).scanArray);
mask3M = zeros(sizV);
mask3M(rowStart:rowEnd,colStart:colEnd,slcStart:slcEnd) = croppedMask3M;

patPos = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.PatientPosition;
switch upper(patPos)
    case 'HFS' %+x,-y,-z
        error('unknown position')
    case 'HFP' %-x,+y,-z
        error('unknown position')
    case 'FFS' %+x,-y,-z
        error('unknown position')
    case 'FFP' %-x,+y,-z
        mask3M = flip(mask3M,3);
    otherwise
        error('unknown position')
end

isUniform = 1;
planC = maskToCERRStructure(mask3M,isUniform,scanNum,structName,planC);


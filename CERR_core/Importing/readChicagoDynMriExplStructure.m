function planC = readChicagoDynMriExplStructure(maskFileName,scanNum,structName,planC)
% readChicagoDynMriExplStructure.m

% Read segmentation mask exported from Chicago Dynamic MRI Explorer
%
% APA, 5/10/2018
%  AI, 8/15/18 Added input 'scanNum'

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

fid = fopen(maskFileName, 'rb');
limsV = fread(fid, 6, 'uint16=>uint16');
rowStart = double(limsV(1));
rowEnd = double(limsV(4));
colStart = double(limsV(2));
colEnd = double(limsV(5));
slcStart = double(limsV(3));
slcEnd = double(limsV(6));
numVox = (rowEnd-rowStart+1)*(colEnd-colStart+1)*(slcEnd-slcStart+1);
maskV = fread(fid, numVox, 'uint8=>uint8');
croppedMask3M = reshape(maskV,(rowEnd-rowStart+1),(colEnd-colStart+1),(slcEnd-slcStart+1));
sizV = size(planC{indexS.scan}(scanNum).scanArray);
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

%--- AI added: ---
%For axial scans, flip L-R
indexS = planC{end};
absAxV = [1 0 0 0 1 0].';
patOrtV = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.ImageOrientationPatient;
if isequal(absAxV,abs(patOrtV))
    mask3M = flip(mask3M,2);
end
%-- end added---

isUniform = 1;
planC = maskToCERRStructure(mask3M,isUniform,scanNum,structName,planC);


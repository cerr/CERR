function planC = addSEGToPlanC(segFileName,planC)
% function planC = addSEGToPlanC(segFileName,planC)
%
% APA, 1/10/2023

indexS = planC{end};

% Read SEG file
%segFileName = 'M:\Data\soft_tissue_sarcoma_DrBozzo\images\T2\Masks\RIA_16-1123_000_000001-RIA_16-1123_000001 - 99-T2 FATSAT - AXIAL\000000.dcm';
infoS = dicominfo(segFileName);
mask3M = dicomread(segFileName);
mask3M = squeeze(mask3M);

numSlices = length(planC{indexS.scan}.scanInfo);
patPosM = nan(numSlices,3);
for iSlc = 1:numSlices
    patPosM(iSlc,:) = planC{indexS.scan}.scanInfo(iSlc).imagePositionPatient;
end

sizV = size(planC{indexS.scan}.scanArray);
maskAll3M = false(sizV);
frameC = fieldnames(infoS.PerFrameFunctionalGroupsSequence);
for iFrame = 1:length(frameC)
    posV = infoS.PerFrameFunctionalGroupsSequence.(frameC{iFrame}).PlanePositionSequence.Item_1.ImagePositionPatient;
    diffM = patPosM - repmat(posV(:)',numSlices,1);
    indSlc = find(sum(abs(diffM) < 1000*eps,2) == 3);
    for slc=1:length(indSlc)
        maskAll3M(:,:,indSlc(slc)) = mask3M(:,:,iFrame);
    end
end

planC = maskToCERRStructure(maskAll3M,0,1,'tumor',planC);


function [mask3M,planC] = readNiftiStructureSet(ssFilename,ssList,...
                          strNameC,assocScan,planC)
% Read NIfTI structure set images, stored as one bit per structure, 
% allowing for overlapping structures 
%-------------------------------------------------------------------------
% INPUTS
% ssFilename : Path to struture set file 
% ssList     : .txt file listing structure indices and filenames
% strNameC   : Cell array of structure names to be read (default:all)
% --- Optional ---
% assocScan  : Index of associated scan
% planC
%-------------------------------------------------------------------------
%AI 04/26/2023

%Parse structure list
valC = file2cell(ssList);
colC  = split(valC,'|');
strIdxC = colC(:,:,1);
strLabelC = colC(:,:,3);

%Read structure set file
maskS = load_nii(ssFilename);
mask5M = maskS.img;
sizeV = size(mask5M);
label3M = zeros(sizeV(1),sizeV(2),sizeV(3));


%Loop over selected structures
if ~exist('strNameC','var')
    strNameC = strLabelC;
end

for nStr = 1:length(strNameC)

    % Get index of selected structure
    matchIdx = strcmpi(strLabelC,strNameC{nStr});
    selStr = str2num(strIdxC{matchIdx});

    %Loop over slices
    for slc = 1:sizeV(3)
        %Convert to bits
        maskSlc3M = squeeze(mask5M(:,:,slc,1,1:sizeV(5)));
        maskSlcBin = dec2bin(maskSlc3M,8);
        maskSlcBin = bsxfun(@minus,maskSlcBin,'0'); %convert to int

        maskSlcBin = reshape(maskSlcBin,[],1,8);
        maskSlcBin = reshape(maskSlcBin,sizeV(1),sizeV(2),[]);
        maskSlcBin = permute(maskSlcBin,[2,1,3]);
        maskSlcBin = flip(flip(maskSlcBin,1),2);
        maskSlcBin = flip(maskSlcBin,3);
        slcLabelM = maskSlcBin(:,:,selStr);
        label3M(:,:,slc) = slcLabelM;
    end

    %Import to planC
    label3M  = flip(label3M,3);
    mask3M = label3M == nStr;
    if exist('assocScan','var') && ~isempty(assocScan)
        planC = maskToCERRStructure(mask3M, 0, assocScan, strNameC{nStr}, planC);
    end

end

end
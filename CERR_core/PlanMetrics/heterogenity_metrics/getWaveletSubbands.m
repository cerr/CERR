function [subbands] = getWaveletSubbands(vol,waveletName,level,dim)
% Copyright (C) 2017-2019 Martin Vallières
% All rights reserved.
% https://github.com/mvallieres/radiomics-develop
%------------------------------------------------------------------------

% IMPORTANT: 
% - THIS FUNCTION IS TEMPORARY AND NEEDS BENCHMARKING. ALSO, IT
% ONLY WORKS WITH AXIAL SCANS FOR NOW. USING DICOM CONVENTIONS, OBVIOUSLY
% (NOT MATLAB).
% - Strategy: 2D transform for each axial slice. Then 1D transform for each
% axial line. I need to find a faster way to do that with 3D convolutions
% of wavelet filters, this is too slow now. Using GPUs would be ideal.
%------------------------------------------------------------------------
% AI 11/18/22 Adapted for levels other than 1
% AI 12/2/22  Adapted for 2D filtering


% INITIALIZATION
if ~exist('level','var')
    level = 1;
end
if ~exist('dim','var')
    dim = '3d';
end

% *************************************************************************
% STEP 1: MAKING SURE THE VOLUME HAS EVEN SIZE (necessary for swt2)
% Adding a layer identical to the last one of the volume. This should not
% create problems for sufficiently large bounding boxes. Is box10 ok?
remove = zeros(1,3);
sizeV = size(vol);
if mod(sizeV(1),2)
    volTemp = zeros(sizeV(1)+1,sizeV(2),sizeV(3));
    volTemp(1:end-1,:,:) = vol;
    volTemp(end,:,:) = squeeze(vol(end,:,:));
    vol = volTemp;
    remove(1) = true;
end
sizeV = size(vol);
if mod(sizeV(2),2)
    volTemp = zeros(sizeV(1),sizeV(2)+1,sizeV(3));
    volTemp(:,1:end-1,:) = vol;
    volTemp(:,end,:) = squeeze(vol(:,end,:));
    vol = volTemp;
    remove(2) = true;
end
if strcmp(dim,'3d')
    sizeV = size(vol);
    if mod(sizeV(3),2)
        volTemp = zeros(sizeV(1),sizeV(2),sizeV(3)+1);
        volTemp(:,:,1:end-1) = vol;
        volTemp(:,:,end) = squeeze(vol(:,:,end));
        vol = volTemp;
        remove(3) = true;
    end
end
% -------------------------------------------------------------------------



% *************************************************************************
% STEP 2: COMPUTE ALL SUB-BANDS

% Initialization
sizeV = size(vol);
subbands = struct; 

switch(lower(dim))

    case '2d'
        names = {'LL','LH','HL','HH'};
        nSub = numel(names);
        %wavNameSave = replaceCharacter(waveletName,'.','dot');
        wavNameSave = waveletName;
        for s = 1:nSub
            names{s} = [names{s},'_',wavNameSave];
            subbands.(names{s}) = zeros(sizeV);
        end

    case '3d'
        names = {'LLL','LLH','LHL','LHH','HLL','HLH','HHL','HHH'};
        nSub = numel(names);
        %wavNameSave = replaceCharacter(waveletName,'.','dot');
        wavNameSave = waveletName;
        for s = 1:nSub
            names{s} = [names{s},'_',wavNameSave];
            subbands.(names{s}) = zeros(sizeV);
        end
end

%Ensure odd filter dimensions
[lo_filt,hi_filt,~,~] = wfilters(waveletName);


% First pass using 2D stationary wavelet transform in axial direction
for k = 1:sizeV(3)
    [LL,LH,HL,HH] = swt2(vol(:,:,k),level,lo_filt,hi_filt);
    if strcmpi(dim,'2d')
    subbands.(['LL_',wavNameSave])(:,:,k) = LL(:,:,level);
    subbands.(['LH_',wavNameSave])(:,:,k) = LH(:,:,level);
    subbands.(['HL_',wavNameSave])(:,:,k) = HL(:,:,level);
    subbands.(['HH_',wavNameSave])(:,:,k) = HH(:,:,level);
    end
    if strcmpi(dim,'3d')
        subbands.(['LLL_',wavNameSave])(:,:,k) = LL(:,:,level);
        subbands.(['LLH_',wavNameSave])(:,:,k) = LL(:,:,level);
        subbands.(['LHL_',wavNameSave])(:,:,k) = LH(:,:,level);
        subbands.(['LHH_',wavNameSave])(:,:,k) = LH(:,:,level);
        subbands.(['HLL_',wavNameSave])(:,:,k) = HL(:,:,level);
        subbands.(['HLH_',wavNameSave])(:,:,k) = HL(:,:,level);
        subbands.(['HHL_',wavNameSave])(:,:,k) = HH(:,:,level);
        subbands.(['HHH_',wavNameSave])(:,:,k) = HH(:,:,level);
    end
end

% Second pass using 1D stationary wavelet transform for all axial lines
if strcmpi(dim,'3d')
    for j = 1:sizeV(2)
        for i = 1:sizeV(1)
            vector = squeeze(subbands.(['LLL_',wavNameSave])(i,j,:));
            [L,H] = swt(vector,level,lo_filt,hi_filt);
            subbands.(['LLL_',wavNameSave])(i,j,:) = L(level,:);
            subbands.(['LLH_',wavNameSave])(i,j,:) = H(level,:);

            vector = squeeze(subbands.(['LHL_',wavNameSave])(i,j,:));
            [L,H] = swt(vector,level,lo_filt,hi_filt);
            subbands.(['LHL_',wavNameSave])(i,j,:) = L(level,:);
            subbands.(['LHH_',wavNameSave])(i,j,:) = H(level,:);

            vector = squeeze(subbands.(['HLL_',wavNameSave])(i,j,:));
            [L,H] = swt(vector,level,lo_filt,hi_filt);
            subbands.(['HLL_',wavNameSave])(i,j,:) = L(level,:);
            subbands.(['HLH_',wavNameSave])(i,j,:) = H(level,:);

            vector = squeeze(subbands.(['HHL_',wavNameSave])(i,j,:));
            [L,H] = swt(vector,level,lo_filt,hi_filt);
            subbands.(['HHL_',wavNameSave])(i,j,:) = L(level,:);
            subbands.(['HHH_',wavNameSave])(i,j,:) = H(level,:);
        end
    end
end
% -------------------------------------------------------------------------



% *************************************************************************
% STEP 2: REMOVING UNECESSARY DATA ADDED IN STEP 1
if remove(1)
    for s = 1:nSub
        subbands.(names{s}) = subbands.(names{s})(1:end-1,:,:);
    end
end
if remove(2)
    for s = 1:nSub
        subbands.(names{s}) = subbands.(names{s})(:,1:end-1,:);
    end
end
if remove(3)
    for s = 1:nSub
        subbands.(names{s}) = subbands.(names{s})(:,:,1:end-1);
    end
end
% -------------------------------------------------------------------------

end


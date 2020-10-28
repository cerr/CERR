function slcWavScanM = wavDecom3D(scan3M,dirString,wavType,normFlag)
% function scan3M = wavDecomNew3D(scan3M,dirString,wavType)
%
% Example Usage:
% waveletDirString = 'HLH';
% waveletType = 'coif1';
% normFlag = 0;
% wavFilteredScan3M = wavDecom3D(scan3M,waveletDirString,waveletType,normFlag);
%
% AI, 7/6/2020
%------------------------------------------------------------------------

%% Get wavelet type and decomposition filters
if ~exist('wavType','var')
    wavType = 'coif1';
end
siz = size(scan3M);
dirString = upper(dirString);
level = 1;
if ~normFlag
    scan3M = scan3M .* sqrt(2);
end

%% Filter along rows
scanRowM = reshape(scan3M,[siz(1),siz(2)*siz(3)]);
padFlag = 0;
if mod(size(scanRowM,1),2)==1
    scanRowM = padarray(scanRowM,[1,0],'replicate','post');
    padFlag=1;
end

rowWavScanM = zeros(size(scanRowM,1),size(scanRowM,2));
for n = 1:size(scanRowM,2)
    %wavImgM = swt(scanRowM(:,n),1,wavType);
    wavImgM = modwt(scanRowM(:,n),wavType,level);
    if dirString(1) == 'L'
        rowWavScanM(:,n) = wavImgM(2,:);
    else
        rowWavScanM(:,n) = wavImgM(1,:);
    end
end
if padFlag
    rowWavScanM(end,:) = [];
end
if ~normFlag
    rowWavScanM = rowWavScanM .* sqrt(2);
end

%% Filter along cols
scanColM = reshape(rowWavScanM,siz);
scanColM = permute(scanColM,[2 1 3]);
scanColM = reshape(scanColM,[siz(2),siz(1)*siz(3)]);
padFlag = 0;
if mod(size(scanColM,1),2)==1
    scanColM = padarray(scanColM,[1,0],'replicate','post');
    padFlag=1;
end

colWavScanM = zeros(size(scanColM,1),size(scanColM,2));
for n = 1:size(scanColM,2)
    %wavImgM = swt(scanColM(:,n),1,wavType);
    wavImgM = modwt(scanColM(:,n),wavType,level);
    if dirString(1) == 'L'
        colWavScanM(:,n) = wavImgM(2,:);
    else
        colWavScanM(:,n) = wavImgM(1,:);
    end
end
if padFlag
    colWavScanM(end,:) = [];
end
colWavScanM = reshape(colWavScanM,[siz(2),siz(1),siz(3)]);
colWavScanM = permute(colWavScanM,[2 1 3]);

%% Filter along slices
%If dirString is of length 2, then filter only in x,y.
if length(dirString) > 2
    if ~normFlag
        colWavScanM = colWavScanM .* sqrt(2);
    end
    
    scanSlcM = permute(colWavScanM,[3 2 1]);
    scanSlcM = reshape(scanSlcM,[siz(3),siz(1)*siz(2)]);
    padFlag = 0;
    if mod(size(scanSlcM,1),2)==1
        scanSlcM = padarray(scanSlcM,[1,0],'replicate','post');
        padFlag=1;
    end
    
    slcWavScanM = zeros(size(scanSlcM,1),size(scanSlcM,2));
    for n = 1:size(scanSlcM,2)
        %wavImgM = swt(scanSlcM(:,n),1,wavType);
        wavImgM = modwt(scanSlcM(:,n),wavType,level);
        if dirString(1) == 'L'
            slcWavScanM(:,n) = wavImgM(2,:);
        else
            slcWavScanM(:,n) = wavImgM(1,:);
        end
    end
    if padFlag
        slcWavScanM(end,:) = [];
    end
    slcWavScanM = reshape(slcWavScanM,[siz(3) siz(2) siz(1)]);
    slcWavScanM = permute(slcWavScanM,[3 2 1]);
else
    slcWavScanM = colWavScanM;
end

%% Circ. shift
% Note: Offset to be investigated
[lo] = wfilters(wavType);
shift = ceil(length(lo))/2-1;
slcWavScanM = circshift(slcWavScanM,[-shift,-shift,-shift]);
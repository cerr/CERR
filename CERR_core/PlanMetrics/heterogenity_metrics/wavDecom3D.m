function scan3M = wavDecom3D(scan3M,dirString,wavType)
% function scan3M = wavDecom3D(scan3M,dirString,wavType)
% 
% Wavelet filtering as defined in:
% Aerts HJWL, Velazquez ER, Leijenaar RTH, et al. Decoding tumour phenotype
% by noninvasive imaging using a quantitative radiomics approach. Nature 
% Communications. 2014;5:4006. doi:10.1038/ncomms5006.
%
% Example Usage:
% waveletDirString = 'HLH';
% waveletType = 'coif1';
% wavFilteredScan3M = wavDecom3D(scan3M,waveletDirString,waveletType);
%
% APA, 5/24/2017

if ~exist('wavType','var')
    wavType = 'coif1';
end
[loD,hiD] = wfilters(wavType,'d');
numPad = length(loD);
siz = size(scan3M);
scan3M = padarray(scan3M,[numPad, numPad, numPad],'circular','both');

dirString = upper(dirString);

if dirString(1) == 'L'
    scan3M = convn(scan3M,loD','same');
else
    scan3M = convn(scan3M,hiD','same');
end

if dirString(2) == 'L'
    scan3M = convn(scan3M,loD,'same');
else
    scan3M = convn(scan3M,hiD,'same');
end

% If dirString is of length 2, then filter only in x,y.
if length(dirString) > 2
    if dirString(3) == 'L'
        scan3M = convn(scan3M,reshape(loD,1,1,length(loD)),'same');
    else
        scan3M = convn(scan3M,reshape(hiD,1,1,length(hiD)),'same');
    end
end

scan3M = scan3M(numPad+1:numPad+siz(1),numPad+1:numPad+siz(2),numPad+1:numPad+siz(3));


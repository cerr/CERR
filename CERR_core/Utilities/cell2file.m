function cell2file(dataC,fileName)
% function cell2file(dataC,fileName)
% 
% This function creates a file "fileName" from the passed dataC. dataC is
% nx1 cell array with all entries as strings. This can be extented in
% future to handle non-character and multi-dimensional cellArrays.
%
% APA, 07/12/2012

fid = fopen(fileName,'wb');
dataC = dataC(:);
for rowNum = 1:length(dataC)
    strIn = dataC{rowNum,1};
    strEscaped = escapeSlashes(strIn);
    fprintf(fid,[strEscaped,'\n']);
end
fclose(fid);

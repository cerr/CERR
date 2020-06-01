function strOut = escapeSlashes(strIn)
%function strOut = escapeSlashes(strIn)
%
% APA, 07/17/2012

strOut = strIn;
slashIndices = strfind(strIn,'\');
count = 0;
for ind = slashIndices
    strTmp = strIn(ind+1:end);
    strOut(ind+count:ind+count+1) = '\\';
    strOut(ind+count+2:end) = '';
    strOut = [strOut,strTmp];
    count = count + 1;
end
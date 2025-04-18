function [dirListC,dirIdx,selected] = listFilesROE(fpath,listProtocolsFlag)
%listFiles.m  List dialog for folder selection
%
% AI 12/14/2020

dirS = dir([fpath,filesep,'*.json']);
dirListC = {dirS(:).name};
dirListC = dirListC(~ismember(dirListC,{'.','..'}));

if listProtocolsFlag
    [dirIdx,selected] = listdlg('ListString',dirListC,...
        'ListSize',[300 100],'Name','Select protocols',...
        'SelectionMode','Multiple');
else
    %Select all
    dirIdx = 1:length(dirListC);
    selected = 1;
end

end
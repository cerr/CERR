function [dirListC,dirIdx,selected] = listFilesROE(fpath,listProtocolsFlag)
%Listdlg for config. folder selection
% AI 05/12/21

dirS = dir([fpath,filesep,'*.json']);
dirListC = {dirS(:).name};
dirListC = dirListC(~ismember(dirListC,{'.','..'}));
if listProtocolsFlag
    [dirIdx,selected] = listdlg('ListString',dirListC,...
        'ListSize',[300 100],'Name','Select protocols','SelectionMode','Multiple');
else
    %Select all
    dirIdx = 1:length(dirListC);
    selected = 1;
end

end

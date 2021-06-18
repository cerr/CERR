function [dirListC,dirIdx,selected] = listFilesROE(fpath)
%Listdlg for config. folder selection
% AI 05/12/21

dirS = dir([fpath,filesep,'*.json']);
dirListC = {dirS(:).name};
dirListC = dirListC(~ismember(dirListC,{'.','..'}));
[dirIdx,selected] = listdlg('ListString',dirListC,...
    'ListSize',[300 100],'Name','Select protocols','SelectionMode','Multiple');

end

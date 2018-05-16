function CERRViewer(CERRFileName)
% function CERRViewer(CERRFileName)
%
% Open CERR Viewer directly
%
% APA, 5/16/2018

global stateS
sliceCallBack('init');

if exist('CERRFileName','var')
    global planC
    stateS.CERRFile = CERRFileName;
    planC = loadPlanC(CERRFileName,tempdir);
    sliceCallBack('load');
end


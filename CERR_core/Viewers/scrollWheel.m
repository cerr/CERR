function scrollWheel(fig,stats)
% function scrollWheel(fig,stats)
%
% Callback function for the mouse scrollWheel.
%
% APA, 2/29/2016

global stateS

if ~stateS.planLoaded
    return;
end

if stats.VerticalScrollCount > 0
    sliceCallBack('ChangeSlc','prevslice')
else
    sliceCallBack('ChangeSlc','nextslice')        
end

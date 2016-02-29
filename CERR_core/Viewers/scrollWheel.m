function scrollWheel(fig,stats)
% function scrollWheel(fig,stats)
%
% Callback function for the mouse scrollWheel.
%
% APA, 2/29/2016

if stats.VerticalScrollCount > 0
    sliceCallBack('ChangeSlc','nextslice')
else
    sliceCallBack('ChangeSlc','prevslice')    
end

function moveLabelsROE(hObj,hEvt,hFig)
% Toggle datacursor mode to allow repositioning of NTCP, TCP/BED readouts
%
%AI 05/17/21

% Toggle lock icon display
status = get(hObj,'Value');
if status
    fname = 'unlock.gif';
else
    fname = 'lock.gif';
end
if isdeployed
    [I,map] = imread(fullfile(getCERRPath,'pics','Icons',fname),'gif');
else
    [I,map] = imread(fname,'gif');
end
lockImg = ind2rgb(I,map);
set(gcbo,'cdata',lockImg,'fontWeight','bold','foregroundColor',[0.5 0.5 0.5]);


% Toggle datacursormode
datacursormode(hFig,'toggle');

end
function hDataTip = createDataTipROE(hFig,target)
% Create new datatip or expand existing one.
%
% AI 10/15/21

ud = guidata(hFig);
cMode = datacursormode(hFig);
cursorInfoS = getCursorInfo(cMode);
%target = protS(pNum).(selTypeC{k})(selNum);


%Check if datatip exists
if ~isfield(ud.handle,'datatips')
    ud.handle.datatips = [];
end

evt.Target = target;
evt.Position = [evt.Target.XData(1),evt.Target.YData(1)];

existing = 0;
for c = 1:length(cursorInfoS)
    if isequal(get(cursorInfoS(c).Target,'userdata'),...
            get(evt.Target,'userdata'))
        hDataTip = ud.handle.datatips(c);
        guidata(hFig,ud);
        expandDataTipROE(hDataTip,evt,hFig);
        existing = 1;
        break
    end
end
if ~existing
    hDataTip = cMode.createDatatip(target);
    set(hDataTip,'Marker','^','OrientationMode','Manual',...
        'Tag','criteria','userdata',get(target,'userdata'),'UpdateFcn',...
        @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig)); %'MarkerSize,',7,
    ud.handle.datatips = [ud.handle.datatips,hDataTip];
    guidata(hFig,ud);
    expandDataTipROE(hDataTip,evt,hFig);
end

end
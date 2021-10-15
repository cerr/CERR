function createDataTipROE(hFig,target)
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
        hExp = ud.handle.datatips(c);
        guidata(hFig,ud);
        expandDataTipROE(hExp,evt,hFig);
        existing = 1;
        break
    end
end
if ~existing
    hExp = cMode.createDatatip(target);
    set(hExp,'OrientationMode','Manual',...
        'Tag','criteria','UpdateFcn',...
        @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
    ud.handle.datatips = [ud.handle.datatips,hExp];
    guidata(hFig,ud);
    expandDataTipROE(hExp,evt,hFig);
end

end
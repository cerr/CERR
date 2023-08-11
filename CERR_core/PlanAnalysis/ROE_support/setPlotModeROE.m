function setPlotModeROE(hObj,hEvt,hFig)
% Set plot mode for ROE
%
% AI 12/15/2020  

ud = guidata(hFig);
sel = get(hObj,'Value');
ud.plotMode = sel - 1;
if ud.plotMode==3
    txt = sprintf('Enter\n scale factor');
    set(ud.handle.modelsAxis(11),'String',txt);
    set(ud.handle.modelsAxis(10),'Visible','On','Enable','On');
    set(ud.handle.modelsAxis(11),'Visible','On');
elseif ud.plotMode==4
    txt = sprintf('Enter\n\delta nfrx');
    set(ud.handle.modelsAxis(11),'String',txt);
    set(ud.handle.modelsAxis(10),'Visible','On','Enable','On');
    set(ud.handle.modelsAxis(11),'Visible','On');
else
    set(ud.handle.modelsAxis(10),'Visible','Off');
    set(ud.handle.modelsAxis(11),'Visible','Off');
end

guidata(hFig,ud);

end
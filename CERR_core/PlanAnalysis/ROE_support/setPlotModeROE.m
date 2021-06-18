function setPlotModeROE(hObj,hEvt,hFig)
% Set ROE  plot mode
%
% AI 05/12/21

ud = guidata(hFig);
sel = get(hObj,'Value');
ud.plotMode = sel - 1;
if ud.plotMode==3
    set(ud.handle.modelsAxis(11),'String','Enter scale factor');
    set(ud.handle.modelsAxis(10),'Visible','On','Enable','On');
    set(ud.handle.modelsAxis(11),'Visible','On');
elseif ud.plotMode==4
    txt = sprintf('Enter\n \x0394nfrx');
    set(ud.handle.modelsAxis(11),'String',txt);
    set(ud.handle.modelsAxis(10),'Visible','On','Enable','On');
    set(ud.handle.modelsAxis(11),'Visible','On');
else
    set(ud.handle.modelsAxis(10),'Visible','Off');
    set(ud.handle.modelsAxis(11),'Visible','Off');
end

guidata(hFig,ud);

end

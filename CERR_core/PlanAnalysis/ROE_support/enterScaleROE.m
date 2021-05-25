function enterScaleROE(hObj,hEvt,hFig)
%Get user-input scale factor
%
% AI 5/12/2021

ud = guidata(hFig);
val = str2double(get(hObj,'String'));
if ud.plotMode==3
    slider = ud.handle.modelsAxis(7);
else
    slider = ud.handle.modelsAxis(8);
end
if val < get(slider,'Min') || val > get(slider,'Max')
    msgbox(sprintf(['Invalid input. Please enter value between'...
        ' %.1f and %.1f'],get(slider,'Min'),get(slider,'Max')));%Invalid input
else
    set(slider,'Value',val);
    scaleDoseROE(slider,[],hFig);
end

end
function switchFocusROE(hObj,~)
%--unused
% Switch focus between plots for different protocols

ud = get(hFig,'userData');
sel = get(hObj,'Value')-1;
ud.foreground=sel;
set(hFig,'userData',ud);
ROE_modular('PLOT_MODELS');

end

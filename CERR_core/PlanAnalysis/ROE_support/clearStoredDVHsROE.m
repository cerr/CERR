function clearStoredDVHsROE(~,~,hFig)
% Clear stored DVHs if prescribed dose is modified

ud = guidata(hFig);
rePlotFlag = 0;

for p = 1:length(ud.Protocols)
    modelC = ud.Protocols(p).model;
    for m = 1:length(modelC)
        if isfield(modelC{m},'dv')
            modelC{m} = rmfield(modelC{m},'dv');
            rePlotFlag = 1;
        end
    end
    ud.Protcols(p).model = modelC;
end

guidata(hFig,ud);

if rePlotFlag
    ROE('PLOT_MODELS');
end

end
function clearStoredDVHsROE(~,~,hFig)
% Clear stored DVHs if prescribed dose is modified

ud = guidata(hFig);
protocolS = ud.Protocols;
modelC = protocolS.model;

for m = 1:length(modelC)
    if isfield(modelC{m},'dv')
        modelC{m} = rmfield(modelC{m},'dv');
        rePlotFlag = 1;
    end
end

protocolS.model = modelC;
ud.Protcols = protocolS;
guidata(hFig,ud);

if rePlotFlag
    ROE('PLOT_MODELS');
end

end
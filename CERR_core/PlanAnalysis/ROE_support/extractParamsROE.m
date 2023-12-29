function hTab = extractParamsROE(hFig,modelS,planC)
% Extract model parameters & values for table display
%
% AI 12/14/2020

%Delete any previous param tables
ud = guidata(hFig);
if isfield(ud,'currentPar') && ~isempty(ud.currentPar)
    delete(ud.currentPar);
end

%Get parameter names
modelParS = modelS.parameters;
genParListC = fieldnames(modelParS);
nPars = numel(genParListC);
reservedFieldsC = {'type','cteg','desc'};

%Define table dimensions
figPosV = get(hFig,'Position');
scaleV = ud.FigSettings.charScale;
rowHt = 25;
rowWidth = figPosV(3)/10; %character units
fwidth = figPosV(3);
fheight = figPosV(3)*scaleV(1)/scaleV(2);
columnWidth = rowWidth*scaleV(1)-1; %pixel units
columnWidthC = {columnWidth,columnWidth};
%columnWidthC = {columnWidth/scaleV(1), columnWidth/scaleV(1)}; %character units
posV = [.2*fwidth .37*fheight 2.1*rowWidth rowHt/scaleV(2)];    %character units
row = 1;
hTab = [];

if ispc
    parFontSize = ud.FigSettings.smFontSize;
elseif ismac
    parFontSize = ud.FigSettings.fontSize;
end

% Create rows displaying model parameters
for k = 1:nPars
    if strcmpi(genParListC{k},'structures')
        if isstruct(modelParS.(genParListC{k}))

            structS = modelParS.(genParListC{k});
            strListC = fieldnames(structS);

            for s = 1:length(strListC)

                strParListC = fieldnames(structS.(strListC{s}));

                for t = 1:numel(strParListC)

                    parS = structS.(strListC{s}).(strParListC{t});
                    %parName = [strListC{s},' ',strParListC{t}];
                    parName = strParListC{t};

                    if ~strcmpi(parName,'optional')

                        [columnFormat,dispVal] = extractValROE(parS);
                        dataC = {parName,dispVal};
                        hTab(row) = uitable(hFig,'Tag','paramEdit','columnformat',...
                            columnFormat,'Data',dataC,'Visible','Off','units','characters',...
                            'FontSize',parFontSize,'columneditable',[false,true],'columnname',...
                            [],'rowname',[],'columnWidth',columnWidthC,'celleditcallback',...
                            @(hObj,hData)editParamsROE(hObj,hData,hFig,planC));
                        set(hTab(row),'Position',posV + [0 -(row*(rowHt+1))/scaleV(2) 0 0 ],...
                            'units','characters');
                        %hTab(row).Position(3:4) = hTab(row).Extent(3:4);
                        row = row+1;

                    end
                end
            end
        end
    else

        if ~strcmpi(genParListC{k},reservedFieldsC)

            parName = genParListC{k};
            [columnFormat,dispVal] = extractValROE(modelParS.(genParListC{k}));
            dataC = {parName,dispVal};
            hTab(row) = uitable(hFig,'Tag','paramEdit','columnformat',...
                columnFormat,'Data',dataC,'Visible','Off','FontSize',parFontSize,...
                'units','characters','columneditable',[false,true],'columnname',[],...
                'rowname',[],'columnWidth',columnWidthC,'celleditcallback',...
                @(hObj,hData)editParamsROE(hObj,hData,hFig,planC));
            set(hTab(row),'Position',posV + [0 -(row*(rowHt+1))/scaleV(2) 0 0 ],...
                'units','characters');
            row = row+1;

        end
    end
end

guidata(hFig,ud);

end
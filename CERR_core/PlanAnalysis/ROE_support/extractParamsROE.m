function hTab = extractParamsROE(hFig,modelS,planC)
% Extract model parameters & values for tabular display
%
% AI 05/12/2021

%Delete any previous param tables
ud = guidata(hFig);
if isfield(ud,'currentPar')
    delete(ud.currentPar);
    ud = rmfield(ud,'currentPar');
    guidata(hFig,ud);
end

%Get parameter names
modelParS = modelS.parameters;
genParListC = fieldnames(modelParS);
nPars = numel(genParListC);
reservedFieldsC = {'type','cteg','desc'};

%Define table dimensions
rowHt = 25;
%rowSep = 10;
rowWidth = 130;
pos = get(hFig,'Position');
fwidth = pos(3);
fheight = pos(3);
left = 10;
columnWidth ={rowWidth-1,rowWidth-1};
posV = [.22*fwidth-2.5*left .4*fheight 2*rowWidth rowHt];
row = 1;
hTab = gobjects(0);
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
                        %Correct string display
                        charIdxC = cellfun(@ischar,dataC,'un',0);
                        charC = dataC([charIdxC{:}]);
                        charC = strrep(charC,'0_0x2E_','0.');
                        dataC([charIdxC{:}]) = charC;
                        hTab(row) = uitable(hFig,'Tag','paramEdit',...
                            'Position', posV + [0 -(row*(rowHt+1)) 0 0 ],...
                            'columnformat',columnFormat,'Data',dataC,...
                            'Visible','Off','FontSize',10,...
                            'columneditable',[false,true],'columnname',...
                            [],'rowname',[],'columnWidth',columnWidth,...
                            'celleditcallback',@editParams);
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
            hTab(row) = uitable(hFig,'Tag','paramEdit','Position',...
                posV + [0 -(row*(rowHt+1)) 0 0 ],'columnformat',...
                columnFormat,'Data',dataC,'Visible','Off','FontSize',10,...
                'columneditable',[false,true],'columnname',[],'rowname',[],...
                'columnWidth',columnWidth,'celleditcallback',@editParams);
            row = row+1;
        end
    end
end
end
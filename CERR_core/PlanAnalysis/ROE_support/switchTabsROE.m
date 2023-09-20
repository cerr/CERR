function switchTabsROE(hObj,hEvt,hFig)
% Toggle between 'Settings' and 'Constraints' tabs.
% AI 10/21/2021

ud = guidata(hFig);
sel = get(hObj,'String');

settingsH = ud.handle.tab1H;
constraintsH = ud.handle.tab2H;

bkgColorOff = [211 228 228]./255;
bkgColorOn = [0.8 0.9 0.9];
fgColorOn = [0 0 0];
fgColorOff = [0.5 0.5 0.5];


switch(sel)
    case 'Settings'
        
        set(constraintsH, 'visible','off');
        constraintTabH = ud.handle.inputH(4);
        set(constraintTabH,'backgroundcolor',bkgColorOff,'foregroundColor',...
            fgColorOff,'value',0);
        
        if isfield(ud,'modelTree')
            set(ud.modelTree,'visible',true);
        end
        if isfield(ud,'currentPar') && all(isgraphics(ud.currentPar))
            set(ud.currentPar,'visible','on');
        end
        set(hObj,'backgroundcolor',bkgColorOn,'foregroundColor',fgColorOn)
        set(settingsH, 'visible','on');
        set(settingsH(7),'visible','off'); %JSON content disp decomissioned
        
    case 'Constraints'
        
        if ~ud.ConstraintsInit
            % Get list of constraints
            [structsC,numCriteria,numGuide,limC,typeC] = ...
                getConstraintsForDisplayROE(hFig);
            data(:,1) = num2cell(false(numCriteria+numGuide,1));
            data(:,2) = structsC(:);
            data(:,3) = limC(:);
            data = [{false},{'All'},{' '};{false},{'None'},{' '};data];
            uiTabH = ud.handle.tab2H(5);
            set(uiTabH,'data',data,'userdata',typeC)
            ud.ConstraintsInit = 1;
        end
        
        set(settingsH,'visible','off');
        settingsTabH = ud.handle.inputH(3);
        set(ud.modelTree,'visible',false);
        if isfield(ud,'currentPar') && all(isgraphics(ud.currentPar))
            set(ud.currentPar,'visible','off');
        end
        set(settingsTabH,'backgroundcolor',bkgColorOff,'foregroundColor',...
            fgColorOff,'value',0);
        
        set(hObj,'backgroundcolor',bkgColorOn,'foregroundColor',fgColorOn,...
            'enable','on');
        set(constraintsH,'visible','on');
end

guidata(hFig,ud);

end
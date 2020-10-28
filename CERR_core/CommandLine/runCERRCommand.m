function status = runCERRCommand(varargin)
%Hold all the defined commands.
%User-defined commands can be added, preferably at the bottom!
%If you add a command, please also add it to the help list in helpListC, just
%below the header.
%Created by JOD.
%Latest modifications:  30 Dec 02, JOD.
%                       05 Jan 03, JOD
%                       08 Jan 03, JOD, get handle to maskM to erase later; turn off zoom commands.
%                       08 Jan 03, JOD, added second input for 'loop command_str'
%                       09 Jan 03, JOD, added delete command.
%                       15 Jan 03, JOD, picksagcor changed to pick.
%                       09 Apr 03, JOD, added 3D and 3d and 3-d.
%                       30 Apr 03, JOD, added support for calling user
%                           defined functions with feval.
%                       01 May 03, JOD, added 'dose' command & corrected bug in 'pos' command.
%                       05 May 03, JOD, updated help function.
%                       13 Dec 05, DK,  Added Structure Volume command.
%                       26 Apr 06, DK,  Added exportDVH option
%                       22 Jun 06, DK,  Re written SLICE POSITIONING(all 'go to' command)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.


global stateS 

if ~exist('planC','var')
    global planC
end

if isfield(stateS,'planLoaded') && ~stateS.planLoaded
    error('Please load a plan first to use the command line help.')
    return;
end

indexS = planC{end};

CERRStatusString('')  %clear command window.

%Options removed from runCERRCommand due to incompatibility or obsolecence.
%    'To  delete a DVH, type ''del dvh [num]''.',...
%    'To reload all option settings in CERROptions.m:  ''reload options'' ',...
%    'To pick sagittal and/or coronal slice positions from transverse view:  ''pick'', then use the mouse to select position.',...
%    'To loop through the images but run a command line command on each slice, type ''loop [command]''.',...
%    'To create a dose distance plot, type ''ddp [structNum] [maximum distance of plot] [resolution in cm] [''max'' or ''min'' dose]''.',...
%    'To get the position of a point, type ''pos'', then select the position with the mouse.',...

%commandh = findobj('tag','command');
%Make the slice viewer the active figure

%figure(stateS.handle.CERRSliceViewer)

if nargin == 0
    in_str = get(stateS.handle.commandLine,'String');
else
    in_str = varargin{:};
end


status = 1; %OK unless we go to the outer catch statement.

if ~isempty(in_str)

    disp(['Command:  ' in_str])

    word1 = word(in_str,1);
    try
        switch lower(word1)

            case 'printmode'
                togglsStr = word(in_str,2);
                if (strcmpi(togglsStr,'on') && stateS.printMode) || (strcmpi(togglsStr,'off') && ~stateS.printMode)
                    return;
                end

                stateS.printMode = xor(stateS.printMode, 1);
                if stateS.printMode

                    structNum = strmatch('skin',lower({planC{indexS.structures}.structureName}),'exact');
                    if isempty(structNum)
                        structNum = strmatch('external',lower({planC{indexS.structures}.structureName}),'exact');
                    end

                    if isempty(structNum)
                        warndlg('"Skin" structure must be defined for printmode. If you have another name indicating skin, please change the name to skin and try again.','Undefined "Skin"','modal')
                        stateS.printMode = 0;
                        return;
                    end

                    [assocScan, relStructNum] = getStructureAssociatedScan(structNum, planC);
                    isSkinUniform = any(bitget(planC{indexS.structureArray}(assocScan).bitsArray,relStructNum));

                    if ~isSkinUniform
                        buttonName = questdlg('"Skin" must be uniformized to display in printmode in sagittal and coronal views. This may take a few seconds. Do you wish to uniformize skin?','Uniformize Skin?','Yes','No','Yes');
                        if strcmpi(buttonName,'yes')
                            planC = updateStructureMatrices(planC, structNum);
                        end
                    end

                else

                    set(stateS.handle.CERRAxis,'color',[0 0 0])

                end

                stateS.doseDisplayChanged = 1;
                sliceCallBack('refresh')

            case 'set'

                try
                    optS = stateS.optS;
                    tmp = strfind('set',in_str);

                    in_str2 = in_str(tmp + 3:length(in_str));

                    if isempty(in_str2)
                        prompt = { 'Enter the complete field and value to be set. Example "optS.loadCT = ''yes''; "' };
                        dlg_title = 'Set CERR Options';
                        num_lines = 1;
                        def = {''};
                        in_str2 = inputdlg(prompt,dlg_title,num_lines,def);
                        if isempty(in_str2)
                            return
                        end                        
                    end
                    
                    if iscell(in_str2)
                        in_str2 = in_str2{1};
                    end
                    
                    optS = setOptsExe(in_str2,optS);

                    stateS.optS = optS;
                    tmpInd = strfind('=',in_str2);

                    opt_str = deblank2(in_str2(1:tmpInd-1));
                    tmpInd = strfind('.',opt_str);

                    opt_str2 = opt_str(tmpInd+1:length(opt_str));

                    switch lower(opt_str2)

                        case 'ctwidth'

                            CTWidthh = findobj('tag','CTWidth');
                            set(CTWidthh,'String',num2str(stateS.optS.CTWidth));

                        case 'ctlevel'

                            CTLevelh = findobj('tag','CTLevel');
                            set(CTLevelh,'String',num2str(stateS.optS.CTLevel));
                    end

                catch
                    helpdlg('That was an invalid options setting.')
                end

            case 'reload'

                w2 = word(in_str,2);

                switch lower(w2)

                    case 'options'

                        [fname, pathname] = uigetfile('*.m','Select options .m file');
                        optName = [pathname fname];
                        optS = opts4Exe(optName);
                        stateS.optS = optS;
                        stateS.doseChanged = 1;  %This forces refresh of displays.
                        sliceCallBack('refresh')
                        sliceCallBack('refreshAllOthers')
                        return

                end


            case 'list'

                try

                    switch lower(word(in_str,2))

                        case 'header'
                            ind = 'header';
                            num = 1;

                            ind2 = getfield(indexS,ind);
                            fieldsC = fieldnames(planC{ind2}(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')

                            len1 = length(planC{ind2});
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}(num);
                            disp(infoS)

                        case 'comment'
                            ind = 'comment';
                            num = 1        ;
                            ind2 = getfield(indexS,ind);
                            fieldsC = fieldnames(planC{ind2}(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')

                            len1 = length(planC{ind2});
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}(num);
                            disp(infoS)

                        case 'slice'
                            ind = 'scan'   ;
                            num   = str2num(word(in_str,3));
                            if isempty(num)
                                prompt = {'Enter the slice Number:'};
                                dlg_title = 'List Slice';
                                num_lines = 1;
                                def = {''};
                                num = inputdlg(prompt,dlg_title,num_lines,def);
                                if isempty(num)
                                    return
                                else
                                    num = str2num(num{1});
                                end
                            end
                            ind2 = getfield(indexS,ind);
                            fieldsC = fieldnames(planC{ind2}.scanInfo(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')

                            len1 = length(planC{ind2}.scanInfo);
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}.scanInfo(num);
                            disp('Scan slice information is:')
                            disp(infoS)

                        case 'structure'
                            ind = 'structures';
                            num   = str2num(word(in_str,3));

                            if isempty(num)
                                prompt = {'Enter the structure Number:'};
                                dlg_title = 'List structure';
                                num_lines = 1;
                                def = {''};
                                num = inputdlg(prompt,dlg_title,num_lines,def);
                                if isempty(num)
                                    return
                                else
                                    num = str2num(num{1});
                                end
                            end

                            if words(in_str) > 3 & strcmp(lower(word(in_str,4)),'points')
                                slice = str2num(word(in_str,5));
                                disp(['Points for structure ' num2str(num) ', in slice ' num2str(slice) ':'])
                                for i = 1 : length(planC{indexS.structures}(num).contour(slice).segments)
                                    disp(['Segment ' num2str(i) ':'])
                                    disp(planC{indexS.structures}(num).contour(slice).segments(i).points)
                                end
                                return
                            end

                            ind2 = getfield(indexS,ind);
                            fieldsC = fieldnames(planC{ind2}(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')
                            len1 = length(planC{ind2});
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}(num);
                            disp(infoS)


                        case 'beam'
                            ind = 'beamGeometry';
                            num   = str2num(word(in_str,4));

                            if isempty(num)
                                prompt = {'Enter the beam Number:'};
                                dlg_title = 'List beam';
                                num_lines = 1;
                                def = {''};
                                num = inputdlg(prompt,dlg_title,num_lines,def);
                                if isempty(num)
                                    return
                                else
                                    num = str2num(num{1});
                                end
                            end

                            ind2 = getfield(indexS,ind);

                            fieldsC = fieldnames(planC{ind2}(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')

                            len1 = length(planC{ind2});
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}(num);
                            disp(infoS)

                            file = planC{indexS.beamGeometry}(num).file;
                            format compact
                            disp(['Beam geometry entry ' num2str(num) ' file contains:'])
                            for i = 1 : length(file)
                                disp(file{i})
                            end

                        case 'dose'
                            ind = 'dose';
                            num   = str2num(word(in_str,3));

                            if isempty(num)
                                prompt = {'Enter the dose Number:'};
                                dlg_title = 'List dose';
                                num_lines = 1;
                                def = {''};
                                num = inputdlg(prompt,dlg_title,num_lines,def);
                                if isempty(num)
                                    return
                                else
                                    num = str2num(num{1});
                                end
                            end


                            ind2 = getfield(indexS,ind);
                            fieldsC = fieldnames(planC{ind2}(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')

                            len1 = length(planC{ind2});
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}(num);
                            disp(infoS)

                        case 'dvh'
                            ind = 'DVH';
                            num   = str2num(word(in_str,3));

                            if isempty(num)
                                prompt = {'Enter the DVH Number:'};
                                dlg_title = 'List DVH';
                                num_lines = 1;
                                def = {''};
                                num = inputdlg(prompt,dlg_title,num_lines,def);
                                if isempty(num)
                                    return
                                else
                                    num = str2num(num{1});
                                end
                            end


                            ind2 = getfield(indexS,ind);
                            fieldsC = fieldnames(planC{ind2}(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')

                            len1 = length(planC{ind2});
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}(num);
                            disp(infoS)

                        case 'options'
                            ind = 'CERROptions';
                            num = 1;
                            ind2 = getfield(indexS,ind);
                            fieldsC = fieldnames(planC{ind2}(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')

                            len1 = length(planC{ind2});
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}(num);
                            disp(infoS)

                        case 'index'
                            ind = 'indexS';
                            num = 1;
                            ind2 = getfield(indexS,ind);
                            fieldsC = fieldnames(planC{ind2}(num));

                            disp(['RTOG/AAPM info for: ' in_str])
                            disp('')

                            len1 = length(planC{ind2});
                            if len1 == 1
                                disp(['There is ' num2str(len1) ' entry.'])
                            else
                                disp(['There are ' num2str(len1) ' entries.'])
                            end
                            disp('')

                            infoS = planC{ind2}(num);
                            disp(infoS)

                        otherwise
                            helpdlg(helpListC)


                    end  %list case


                    return

                catch
                    disp('Sorry that was an invalid name.')
                    len1 = length(planC{ind2});
                    if len1 == 0
                        disp(['There are no ' word(in_str,2) ' entries.'])
                    end
                    disp('')
                end    %list command


                disp('')


            case 'show'

                switch lower(word(in_str,2))

                    case 'name'
                        set(stateS.handle.patientName,'Visible', 'on');

                    case 'film'

                        entry = str2num(word(in_str,3));
                        str = 'No film stored.';
                        try
                            imageM = planC{indexS.digitalFilm}(entry).image;
                            if isempty(imageM)
                                warning(str)
                                CERRStatusString(str)
                                return
                            end
                            f = figure;
                        catch
                            warning(str)
                            CERRStatusString(str)
                            return
                        end
                        try
                            filmV = stateS.handle.film;
                        catch
                            filmV = [];
                        end
                        stateS.handle.film = [filmV(:)',f];
                        hFilm = image(imageM,'cdatamapping','scaled');
                        axis image;
                        colormap gray;
                        hP1 = get(hFilm,'parent');
                        hFig = get(hP1,'parent');
                        set(hFig,'name','CERR Film Viewer')
                        set(hFig,'numbertitle','off')
                        set(hFig,'tag','CERRFilmViewer')
                        Position = [115 54 780 570];
                        set(hFig,'position',Position)

                        filmNumber = planC{indexS.digitalFilm}(entry).filmNumber;
                        beamNumber = planC{indexS.digitalFilm}(entry).beamNumber;
                        if optS.displayPatientName == 1
                            name = planC{indexS.scan}(1).scanInfo(1).patientName;
                            name = fixDisplayString(name);
                            str = ['Patient name: ' name ];
                            text(0.0,1.05,str,'units','normalized','fontsize',8)
                        end
                        str = ['Film number: ' num2str(filmNumber) ', beam number:  ' num2str(beamNumber) '.'];
                        text(0.6,-0.10,str,'units','normalized','fontsize',8)
                        str = ['Film entry: ' num2str(entry)];
                        text(0.0,-0.10,str,'units','normalized','fontsize',8)

                        return

                    otherwise
                        helpdlg('Not a valid input.')
                        return
                end

            case 'hide'
                switch lower(word(in_str,2))
                    case 'name'
                        set(stateS.handle.patientName,'Visible', 'off');
                end

            case 'go'  %Go to a given slice

                w3 = word(in_str,3);
                
                numWords = words(in_str);

                if strcmpi(w3,'z')
                    % Get the z value passed
                    zNum = str2num(word(in_str,4));

                    % Pass variable to "goto" command
                    goto('z',zNum);

                elseif strcmpi(w3,'max')  %Go to slice of maximum dose
                    % Pass variable to "goto" command
                    goto('max')
                    
                elseif numWords > 3
                    if numWords==4
                    w4 = word(in_str,4);
                    w4 = str2num(w4); % only numeric data type supported
                    goto(w3,w4)
                    
                    elseif strcmpi(word(in_str,5),'all')
                    w4 = word(in_str,4);
                    w4 = str2num(w4); % only numeric data type supported
                    w5 = word(in_str,5);
                    goto(w3,w4,w5)

                    else
                    % Get the slice number passed
                    num = str2num(word(in_str,3));

                    % Pass variable to "goto" command
                    goto('slice',num);
                    end
                    
                end

            case 'mask'  %show a spy mask of values included in an ROI
                
                structNum   = str2num(word(in_str,2));
                doseNum = str2num(word(in_str,3));
                rxDose = str2num(word(in_str,4));
                lowCutoff = 0.95;
                highCutoff = 1.1;
                
                % This is for command line help funciton
                if isempty(structNum)
                    prompt = {'Enter the Structure Number'};
                    dlg_title = 'Calculate Structure MASK';
                    num_lines = 1;
                    def = {''};
                    structNum = inputdlg(prompt,dlg_title,num_lines,def);
                    if isempty(structNum)
                        return
                    else
                        structNum = str2num(structNum{1});
                    end
                end
                
                scanSet     = getStructureAssociatedScan(structNum);
                [xUnifV, yUnifV, jnk] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));                
                [jnk1, jnk2, zCTV] = getScanXYZVals(planC{indexS.scan}(scanSet));
                structColor = planC{indexS.structures}(structNum).structureColor;
                [scanNum, relStructNum] = getStructureAssociatedScan(structNum, planC);
                
                for indAxis = 1:length(stateS.handle.CERRAxis)
                    
                    hAxis = stateS.handle.CERRAxis(indAxis);
                    
                    view = getAxisInfo(hAxis, 'view');
                    
                    set(hAxis, 'nextplot', 'add');
                    
                    switch lower(view)
                        
                        case 'transverse'
                            
                            zValue = getAxisInfo(hAxis,'coord');                            
                            
                            if isfield(planC{indexS.scan}(scanNum),'transM') && ...
                                    (isempty(planC{indexS.scan}(scanNum).transM) || ...
                                    (~isempty(planC{indexS.scan}(scanNum).transM) && ...
                                    isequal(planC{indexS.scan}(scanNum).transM,eye(4))))
                                
                                sliceT=findnearest(zCTV,zValue);
                                zslice = zCTV(sliceT);
                                
                                [segmentsM, planC, isError] = getRasterSegments(structNum, planC);
                                indV = find(abs(segmentsM(:,1) - zslice) < 1e-3);  %mask values on this slice
                                
                                segmentsM = segmentsM(indV(:),7:9);     %segments
                                
                                %reconstruct the mask:
                                ROIImageSize   = [planC{indexS.scan}(scanSet).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanSet).scanInfo(1).sizeOfDimension2];
                                
                                maskM = zeros(ROIImageSize);
                                
                                for i = 1 : size(segmentsM,1)
                                    maskM(segmentsM(i,1),segmentsM(i,2):segmentsM(i,3)) = 1;
                                end
                                
                                %For Trans:
                                [i,j] = find(maskM);
                                
                                [xV, yV, zV] = mtoxyz(i,j,repmat(sliceT, [length(i) 1]),scanSet,planC);
                                if isempty(zV) || isempty(xV) || isempty(yV)
                                    continue
                                end
                                
                                
                            else
                                
                                dim = 3;
                                coord = zValue;
                                [slcC, xV, yV] = getStructureSlice(scanNum, dim, coord);
                                if isempty(xV) || isempty(yV)
                                    continue
                                end
                                if relStructNum<=52
                                    cellNum = 1;
                                else
                                    cellNum = ceil((relStructNum-52)/8)+1; %uint8
                                    relStructNum = relStructNum-(cellNum-2)*8-52;
                                end
                                structsOnSlice = cumbitor(slcC{cellNum}(:));
                                includeCurrStruct = bitget(structsOnSlice, relStructNum);
                                if includeCurrStruct
                                    oneStructM = bitget(slcC{cellNum}, relStructNum);
                                else
                                    continue;
                                end
                                
                                [i,j] = find(oneStructM');
                                xV = xV(j);
                                yV = yV(i);
                                zV = zValue*ones(size(xV));
                                
                            end  
                            % Store x,y,z coords for dose
                            xDoseV = xV;
                            yDoseV = yV;
                            zDoseV = zV;                            
                            
                            
                        case 'coronal'
                            
                            yValue=getAxisInfo(hAxis,'coord');
                            [scanNum, relStructNum] = getStructureAssociatedScan(structNum, planC);
                            if isfield(planC{indexS.scan}(scanNum),'transM') && isempty(planC{indexS.scan}(scanNum).transM)
                                
                                sliceC=findnearest(yUnifV,yValue);
                                
                                %For Cor:
                                maskM = getStructureMask(structNum, sliceC, 2, planC);
                                [i,j] = find(maskM);
                                
                                [xV, yV, zV] = mtoxyz(repmat(sliceC, [length(i) 1]), j, i, scanSet, planC, 'uniform', getUniformScanSize(planC{indexS.scan}(scanSet)));
                                if isempty(zV) || isempty(xV) || isempty(yV)
                                    continue
                                end
                                
                            else
                                dim = 2;
                                coord = yValue;
                                [slcC, xV, zV] = getStructureSlice(scanNum, dim, coord);
                                if isempty(xV) || isempty(zV)
                                    continue
                                end
                                if relStructNum<=52
                                    cellNum = 1;
                                else
                                    cellNum = ceil((relStructNum-52)/8)+1; %uint8
                                    relStructNum = relStructNum-(cellNum-2)*8-52;
                                end
                                structsOnSlice = cumbitor(slcC{cellNum}(:));
                                includeCurrStruct = bitget(structsOnSlice, relStructNum);
                                if includeCurrStruct
                                    oneStructM = bitget(slcC{cellNum}, relStructNum);
                                else
                                    continue;
                                end
                                
                                [i,j] = find(oneStructM);
                                xV = xV(j);
                                zV = zV(i);
                                yV = yValue*ones(size(xV));
                            end
                            
                            % Store x,y,z coords for dose
                            xDoseV = xV;
                            yDoseV = yV;
                            zDoseV = zV;
                            
                            % Change names so that we only need to plot
                            % xV,yV for all the views
                            yV = zV;
                            
                           
                            
                        case 'sagittal'
                            xValue=getAxisInfo(hAxis,'coord');
                            [scanNum, relStructNum] = getStructureAssociatedScan(structNum, planC);
                            
                            if isfield(planC{indexS.scan}(scanNum),'transM') && isempty(planC{indexS.scan}(scanNum).transM)
                                
                                sliceS=findnearest(xUnifV,xValue);
                                
                                %For Sag:
                                maskM = getStructureMask(structNum, sliceS,1, planC);
                                
                                [i,j] = find(maskM);
                                [xV, yV, zV] = mtoxyz(j, repmat(sliceS, [length(i) 1]), i, scanSet, planC, 'uniform', getUniformScanSize(planC{indexS.scan}(scanSet)));
                                
                                if isempty(zV) || isempty(xV) || isempty(yV)
                                    continue
                                end
                                
                            else
                                
                                dim = 1;
                                coord = xValue;
                                [slcC, yV, zV] = getStructureSlice(scanNum, dim, coord);
                                if isempty(yV) || isempty(zV)
                                    continue
                                end
                                if relStructNum<=52
                                    cellNum = 1;
                                else
                                    cellNum = ceil((relStructNum-52)/8)+1; %uint8
                                    relStructNum = relStructNum-(cellNum-2)*8-52;
                                end
                                structsOnSlice = cumbitor(slcC{cellNum}(:));
                                includeCurrStruct = bitget(structsOnSlice, relStructNum);
                                if includeCurrStruct
                                    oneStructM = bitget(slcC{cellNum}, relStructNum);
                                else
                                    continue;
                                end
                                
                                [i,j] = find(oneStructM);
                                yV = yV(j);
                                zV = zV(i);
                                xV = xValue*ones(size(yV));
                                
                            end
                            
                            % Store x,y,z coords for dose
                            xDoseV = xV;
                            yDoseV = yV;
                            zDoseV = zV;                            
                            
                            % Change names so that we only need to plot
                            % xV,yV for all the views
                            xV = yV;
                            yV = zV;
                            
                    end
                    
                    % Display mask on axis
                    if ~isempty(doseNum)
                        %paint low, prescription and high dose regions
                        doseV = getDoseAt(doseNum,xDoseV, yDoseV, zDoseV, planC);
                        lowDoseIndV = doseV < rxDose*lowCutoff;
                        highDoseIndV = doseV > rxDose*highCutoff;
                        prescrIndV = doseV >= rxDose*lowCutoff & doseV <= rxDose*highCutoff;
                        %prescrIndV = 1:length(doseV);
                        %prescrIndV([lowDoseIndV(:);highDoseIndV(:)]) = [];
                        h1 = plot(xV(lowDoseIndV),yV(lowDoseIndV),'marker','.','markersize', 5, 'linestyle','none','color','r', 'parent', hAxis, 'tag', 'ROIMask', 'hittest', 'off');
                        h2 = plot(xV(prescrIndV),yV(prescrIndV),'marker','.','markersize', 5, 'linestyle','none','color','g', 'parent', hAxis, 'tag', 'ROIMask', 'hittest', 'off');
                        h3 = plot(xV(highDoseIndV),yV(highDoseIndV),'marker','.','markersize', 5, 'linestyle','none','color','b', 'parent', hAxis, 'tag', 'ROIMask', 'hittest', 'off');
                        stateS.handle.mask = [stateS.handle.mask, h1, h2, h3];
                        
                        %Draw Mask on linked axes
                        for i=1:length(stateS.handle.CERRAxis)
                            linkedView = getAxisInfo(stateS.handle.CERRAxis(i),'view');
                            if ~strcmpi(linkedView,view)
                                continue;
                            end
                            
                            UD = stateS.handle.aI(i); %get(stateS.handle.CERRAxis(i),'userdata');
                            
                            if iscell(UD.view) && UD.view{2}==hAxis
                                h1 = plot(xV(lowDoseIndV),yV(lowDoseIndV),'marker','.','markersize', 5, 'linestyle','none','color','r', 'parent', stateS.handle.CERRAxis(i), 'tag', 'ROIMask', 'hittest', 'off');
                                h2 = plot(xV(prescrIndV),yV(prescrIndV),'marker','.','markersize', 5, 'linestyle','none','color','g', 'parent', stateS.handle.CERRAxis(i), 'tag', 'ROIMask', 'hittest', 'off');
                                h3 = plot(xV(highDoseIndV),yV(highDoseIndV),'marker','.','markersize', 5, 'linestyle','none','color','b', 'parent', stateS.handle.CERRAxis(i), 'tag', 'ROIMask', 'hittest', 'off');
                                stateS.handle.mask = [stateS.handle.mask, h1, h2, h3];
                            end
                        end
                        
                    elseif ~strcmpi(view,'legend')
                        
                        h = plot(xV,yV,'marker','.','markersize', 5, 'linestyle','none','color',structColor, 'parent', hAxis, 'tag', 'ROIMask', 'hittest', 'off');
                        stateS.handle.mask = [stateS.handle.mask, h];
                        
                    end     

                    
                end


            case 'dshpoints'  %show points on the surface of the ROI

                structNum = str2num(word(in_str,2));

                % This is for command line help funciton
                if isempty(structNum)
                    prompt = {'Enter the Structure Number'};
                    dlg_title = 'Calculate Structure DSHPOINTS';

                    num_lines = 1;
                    def = {''};

                    structNum = inputdlg(prompt,dlg_title,num_lines,def);

                    if isempty(structNum)
                        return
                    else
                        structNum = str2num(structNum{1});
                    end
                end


                h = findobj('tag','DSHPoints');
                if ~isempty(h)
                    delete(h)
                    return
                end

                pointsM = planC{indexS.structures}(structNum).DSHPoints;

                if isempty(pointsM)
                    optS = planC{indexS.CERROptions};
                    planC =  getDSHPoints(planC,optS,structNum);
                    pointsM = planC{indexS.structures}(structNum).DSHPoints;
                end

                zV = pointsM(:,3);
                yV = pointsM(:,2);
                xV = pointsM(:,1);

                scanNum = getStructureAssociatedScan(structNum);
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                [view coord] = getAxisInfo(hAxis,'view','coord');
                [xUniform,yUniform,zUniform] = getScanXYZVals(planC{indexS.scan}(scanNum));

                switch lower(view)
                    case 'coronal'
                        errordlg('Current view not a transverse view')
                        return
                        sliceNum = findnearest(xUniform,coord);
                        indV = find(abs(xV - xUniform(sliceNum)) < 10 * eps);  %mask values on this slice
                        xSliceV = yV(indV);
                        ySliceV = zV(indV);
                    case 'saggital'
                        errordlg('Current view not a transverse view')
                        return
                        sliceNum = findnearest(yUniform,coord);
                        indV = find(abs(yV - yUniform(sliceNum)) < 10 * eps);  %mask values on this slice
                        xSliceV = xV(indV);
                        ySliceV = zV(indV);
                    case 'transverse'
                        sliceNum = findnearest(zUniform,coord);
                        indV = find(abs(zV - zUniform(sliceNum)) < 10 * eps);  %mask values on this slice
                        xSliceV = xV(indV);
                        ySliceV = yV(indV);
                end
                hold on
                h = plot(xSliceV,ySliceV,'r.');
                set(h,'markersize',12)
                set(h,'tag','DSHPoints')
                hold off

                return

            case 'make'

                w2 = word(in_str,2);
                if strcmpi(w2,'contour')
                    drawContour
                end

            case 'pick'

                sliceCallBack('picksagcor')
                return

            case 'loop'

                n = words(in_str);
                if n > 1
                    [word1, start, stop] = word(in_str,1);
                    rest = in_str(stop+1:end);
                    rest = deblank2(rest);
                    sliceCallBack('loop',rest)
                else
                    sliceCallBack('loop')
                end
                return

            case 'movie'
                sliceCallBack('movieloop')
                return

            case 'dose'  %show dose of a point chosen with the mouse
                sliceCallBack('TOGGLEDOSEQUERY');
                return;

            case 'scan'
                sliceCallBack('TOGGLESCANQUERY');
                return;

            case {'3d','3-d'}
                struct3Dvisualmenu('update')


            case 'rename'
                structRenameGUI('init');

            case 'del'

                w2 = word(in_str,2);
                switch lower(w2)

                    case 'structure'

                        n = str2num(word(in_str,3));
                        if isempty(n)
                            prompt = {'Enter the structure number to delete:'};
                            dlg_title = 'Delete Structure';
                            num_lines = 1;
                            def = {''};
                            n = inputdlg(prompt,dlg_title,num_lines,def);
                            if isempty(n)
                                return
                            else
                                n = str2num(n{1});
                            end
                        end
                        len = length(planC{indexS.structures});
                        if n > len
                            CERRStatusString('Requested structure number is not in plan.');
                            return;
                        end
                        planC = delUniformStr(n, planC); %Update the uniform data.                        
                        planC{indexS.structures}(n:len-1) = planC{indexS.structures}(n+1:len);
                        planC{indexS.structures} = planC{indexS.structures}(1:len-1);
                        stateS.structsOnViews = setdiff(stateS.structsOnViews,n);
                        stateS.lastSliceNumTrans = -1;
                        stateS.lastSliceNumCor   = -1;
                        stateS.lastSliceNumSag   = -1;
                        delete(findobj('tag', 'structContour'));
                        stateS.structsChanged = 1;

                    case 'dose'

                        n = str2num(word(in_str,3));

                        if isempty(n)
                            prompt = {'Enter the dose number to delete:'};
                            dlg_title = 'Delete Dose';
                            num_lines = 1;
                            def = {''};
                            n = inputdlg(prompt,dlg_title,num_lines,def);
                            if isempty(n)
                                return
                            else
                                n = str2num(n{1});
                            end
                        end

                        len = length(planC{indexS.dose});
                        if n > len
                            CERRStatusString('Requested dose number is not in plan.');
                            return;
                        end
                        planC{indexS.dose}(n) = [];
                        removeCERRHandle('DoseMenu');
                        %         putDoseMenu(stateS.handle.CERRSliceViewer, planC, indexS);

                end
                CERRRefresh
                
            case 'create'
                
                w2 = word(in_str,2);
                switch lower(w2)                    
                    case 'structure'                        
                        createROI();                        
                end                
                
            case 'vol'
                structNum = word(in_str,3);

                % This is for command line help funciton
                if isempty(structNum)
                    prompt = {'Enter the Structure Number you want to calculate vol for'};
                    dlg_title = 'Calculate Structure Vol';
                    num_lines = 1;
                    def = {''};
                    structNum = inputdlg(prompt,dlg_title,num_lines,def);
                    if isempty(structNum)
                        return
                    else
                        structNum = str2num(structNum{1});
                    end
                end
                if ischar(structNum)
                    structNum = str2num(structNum);
                end
                structVol = getStructureVol(structNum);
                CERRStatusString(['Total volume for structure No ' num2str(structNum) ' is ' num2str(structVol) ' cubic cm.' ]);


            case 'exp'
                %exp [opt] [structNum] dose [doseNum]
                exportDVH(str2num(word(in_str,3)),str2num(word(in_str,5)),(word(in_str,2)));
                return

            case 'exportivh'
                %exportIVH [opt] [structNum] scan [scanNum]
                exportIVH(str2num(word(in_str,3)),str2num(word(in_str,5)),(word(in_str,2)));
                return

            case 'ddp'  %dose-distance plot

                structNum   = str2num(word(in_str,2));
                minDistance = str2num(word(in_str,3));
                maxOrMin    = word(in_str,4);
                resolution  = str2num(word(in_str,5));
                
                if isempty(structNum)
                    prompt = {'Enter Structure Number :';'Enter min Distance';'Enter Max, Min or Mean';'Enter Resolution. If not sure Leave empty'};
                    dlg_title = 'Dose Distance Plot';
                    num_lines = 1;
                    def = {'';'1';'Max';''};
                    zNum = inputdlg(prompt,dlg_title,num_lines,def);
                    if isempty(zNum)
                        return
                    else
                        structNum   = str2num(zNum{1});
                        minDistance = str2num(zNum{2});
                        maxOrMin    = zNum{3};
                        resolution  = str2num(zNum{4});

                    end
                end

                doseDistancePlot(structNum, minDistance,  maxOrMin, resolution);

            case 'goto'
                w2 = word(in_str,2);
                switch lower(w2)
                    case 'str'
                        n = str2num(word(in_str,3));
                        len = length(planC{indexS.structures});
                        if n > len
                            CERRStatusString('Requested structure number is not in plan.');
                            return;
                        end
                        contours = planC{indexS.structures}(n).contour;
                        topSlice = [];
                        for contNum = 1:length(contours)
                            if ~isempty(vertcat(contours(contNum).segments.points))
                                topSlice = contNum;
                                break;
                            end
                        end
                        if isempty(topSlice)
                            CERRStatusString('No contour lines in requested structure.');
                            return;
                        end
                        assocScan = getStructureAssociatedScan(n);
                        [xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(assocScan));
                        zValue = zV(topSlice);

                        for i=1:length(stateS.handle.CERRAxis)
                            aI = get(stateS.handle.CERRAxis(i), 'userdata');
                            view = aI.view;
                            if strcmpi(view, 'transverse')
                                aI.coord = zValue;
                                set(stateS.handle.CERRAxis(i), 'userdata', aI);
                            end
                        end
                        sliceCallBack('refresh');

                    otherwise
                        CERRStatusString('Not a valid input.')
                        return
                end

            case 'help'
                MATLABVERSION = version;

                if strcmpi(MATLABVERSION(1),'7') | str2num(MATLABVERSION(1))>= 7
                    html_file = fullfile(getCERRPath,'CommandLine','CERRCommandLinehelp.html');
                    showToolbar = 1;
                    showAddressBox = 1;
                    activeBrowser = com.mathworks.mde.webbrowser.WebBrowser.createBrowser(showToolbar, showAddressBox);
                    activeBrowser.setCurrentLocation(html_file);
                    activeBrowser.setName('CERR Command Line')
                else

                    helpListC = {'Valid command line inputs include:  ',...
                        '''list header'', ''list comment'', ''list slice [num]'', ''list structure [num]'', ',...
                        '''list beam geome [num]'', ''list dose [num]'', ''list dvh [num]'', or ''list options''. ',...
                        '',...
                        'SLICE POSITIONING',...
                        '1) To go to a slice number:  ''go to [slicenum]'' .',...
                        '',...
                        '2) To go to the slice with the maximum dose in total plan:  ''go to max'' .',...
                        '',...
                        '3) To go to a z value (or nearest slice):  ''go to z [z value]'' .',...
                        '',...
                        'STRUCTURE',...
                        '1) To show points in a structure, type ''list structure [structnum] points [slicenum]'' ',...
                        '',...
                        '2) To delete an anatomical structure, type ''del structure [num]''.',...
                        '',...
                        '3) To find volume for an anatomical structure, type ''vol structure [num]''.',...
                        '',...
                        'DOSE',...
                        '1) To create a dose distance plot, type ''ddp [structNum] [maximum distance of plot] [resolution in cm] [''max'' or ''min'' dose]''.',...
                        '',...
                        '2) To get the dose and position of a point, type ''dose'', then select the position with the mouse.',...
                        '',...
                        '3) To export DVH type "exp [opt] [structNum] dose [doseNum]" where [structNum] stands for the structure number as given under Structures menu ',...
                        '[opt]has to be a string suggesting you want absolute(abs) or Normalized(nor) DVH, [doseNum] stands for dose number given under Dose menu',...
                        'example to export absolute DVH for structure number 1 and dose number 1',...
                        'this is what you would type -> "exp abs 1 dose 1" (no quotes)',...
                        '',...
                        '4) To convert an iso-dose level to structure, type ''doseToStruct [doseNum] [doseLevel] [scanNum]'' ',...
                        '',...
                        'ROI',...
                        '1) To show the points included in an ROI:  ''mask [num]'' ',...
                        '',...
                        '2) To Toggle the points on the surface of an ROI (on the contour):  ''dshpoints [num]'' ',...
                        '',...
                        'OTHERS',...
                        'To reset and use a new option value:  ''set [optionName]'', i.e., optS.name in CERROptions.m',...
                        '',...
                        'To toggle on/off print friendly mode type ''printmode''.',...
                        '',...
                        'To raise the 3-D menu type ''3d''.',...
                        '',...
                        'To show a digital film, type: ''show film [num]''.',...
                        '',....
                        };
                    helpdlg(helpListC)
                end

            case 'translate'
                prompt = {'Enter Structure Number that you want to translate :';...
                    'Enter the x y z translation Example -1[space]0[space]0';'Name for the new structure'};
                dlg_title = 'Translate Structure';
                num_lines = 1;
                def = {'';'';''};
                output = inputdlg(prompt,dlg_title,num_lines,def);
                structNum = str2num(output{1});
                xyzT = str2num(output{2});
                structName = output{3};
                planC = translateStruct(structNum,xyzT,structName,planC);
                stateS.structsChanged = 1;
                CERRRefresh;

            case 'couch'
                couchRegister('init');
                return

            case 'rpcfilm'
                RPCFilmViewer('init');
                return

            case 'structcom'

                structNum   = str2num(word(in_str,2));

                if isempty(structNum)
                    prompt = {'Enter Structure Number'};
                    dlg_title = 'Center Of Mass';
                    num_lines = 1;
                    def = {''};
                    output = inputdlg(prompt,dlg_title,num_lines,def);
                    structNum = str2num(output{1});
                end

                output = structureStats(structNum);

                COM = output.COM;

                name = output.name;

                CERRStatusString(['Center of Mass for ' name '(X Y Z) is  ' num2str(COM)]);

            case 'assocstr'

                numWords = words(in_str);

                if numWords == 1
                    prompt = {'Enter Structure Number/s that you want to associate. Provide space between each structure number';...
                        'Enter A Scan number that you want this structure to be associated to'};
                    dlg_title = 'Associate Structure';
                    num_lines = 1;
                    def = {'';''};
                    output = inputdlg(prompt,dlg_title,num_lines,def);

                    if length(output)<2 | isempty(output)
                        CERRStatusString('Exiting Structure Association');
                        return;
                    end
                    strInd = str2num(output{1});

                    scanNum = str2num(output{2});
                else

                    for i=1:numWords
                        allWords{i} = word(in_str,i);
                    end
                    indTo = strmatch('to',lower(allWords),'exact');

                    %get scanNum to associate structures
                    scanNum = str2num(allWords{indTo+1});
                    %get structure Indices to be associated with scanNum
                    for i=2:indTo-1
                        strInd(i-1) = str2num(allWords{i});
                    end
                end

                %copy structures to scanNum
                for i=1:length(strInd)
                    planC = copyStrToScan(strInd(i),scanNum);
                end

            case 'keyboard'

                html_file = which('KeyboardShotcut.html');
                showToolbar = 1;
                showAddressBox = 1;
                activeBrowser = com.mathworks.mde.webbrowser.WebBrowser.createBrowser(showToolbar, showAddressBox);
                activeBrowser.setCurrentLocation(html_file);
                activeBrowser.setName('CERR Keyboard help');

            case 'dosetostruct'
                %doseToStruct [doseNum] [doseLevel] [scanNum]
                doseToStruct(str2num(word(in_str,2)),str2num(word(in_str,3)),str2num(word(in_str,4)))
                return

            case 'scantodose'
                %scan2dose [scanNum] [assocScanNum] [fractionGroupID]
                scan2dose(str2num(word(in_str,2)),str2num(word(in_str,3)),word(in_str,4))
                return
                
            case 'cropscan'
                %cropscan [scanNum] [structureNum] [margin]
                cropScan(str2num(word(in_str,2)),str2num(word(in_str,3)),str2num(word(in_str,4)))
                return  
                
            case 'cropdose'
                %cropscan [doseNum] [structureNum] [margin]
                cropDose(str2num(word(in_str,2)),str2num(word(in_str,3)),str2num(word(in_str,4)))
                return                  

            case 'getunionintersectionvol'
                numWords = words(in_str);
                % This is for command line help funciton
                if numWords ==1
                    prompt = {'Enter the Structure Numbers you want to calculate union/intersection for'};
                    dlg_title = 'Calculate Structure Union/Intersection';
                    num_lines = 1;
                    def = {''};
                    strNums = inputdlg(prompt,dlg_title,num_lines,def);
                    strV = str2num(strNums{1});
                    if isempty(strV)
                        return
                    end
                else
                    for i=2:numWords
                        strV(i-1) = str2num(word(in_str,i));
                    end
                end
                calcUnionIntersectionVol(strV);
                return

            case {'geudcolor','geudcolorn'}
                %scan2dose [a] [structNum] [doseNum]
                numWords = words(in_str);
                for i=1:numWords
                    allWords{i} = word(in_str,i);
                end
                a           = str2num(allWords{2});
                structNum   = str2num(allWords{3});
                doseNum     = str2num(allWords{4});
                if isempty(a) || isempty(structNum) || isempty(doseNum)
                    return;
                end
                nFlag = 0;
                if strcmpi(word1,'geudcolorn')
                    nFlag = 1;
                end
                gEUD = gEUD2dose(a,structNum,doseNum,nFlag);
                disp('----------------------')
                disp(['gEUD = ',num2str(gEUD)])
                disp('----------------------')
                return
                
            case 'addguide'
                num = str2double(word(in_str,2));
                if isempty(word(in_str,4))
                    units = [];
                    view = word(in_str,3);
                else
                    units = word(in_str,3);
                    view = word(in_str,4);
                end
                showPlaneLocators(num,units,view);
                
                
            otherwise


                try

                    %See if there is a user-specified function.
                    %These functions assume that the first word is the function name and the rest of the
                    %words comprise the argument list.  User defined functions are usually put under
                    %the directory userDefinedFunctions.  Note:  this is compilable.
                    argsC = words2cells(in_str);
                    fname = argsC{1};
                    argsC = argsC(2:end);
                    if ~isempty(argsC)
                        feval(fname, argsC)
                    else
                        feval(fname)
                    end

                catch

                    %helpdlg('Not a valid input.')
                    CERRStatusString('Not a valid input.')
                    return

                end
        end
    catch
        CERRStatusString('Not a valid input.')
    end
end  %don't do anything if no input on the command line.
return

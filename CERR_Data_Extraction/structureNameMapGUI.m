function structureNameMapGUI(command,varargin)
% function structureNameMapGUI(command,varargin)
% This function provides graphical interface to generate mapping for
% structures and doses per plan for a cohort.
%
%APA, 4/13/09
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

%head and neck standard structure names
% brain | brainstem | cord | cord+margin | larynx | lt eye | rt eye | lt lens | rt lens | lt parotid | rt parotid | upper esoph | oral cavity | optic chiasm | lt optic nerve |  rt optic nerve | mandible | ptv1 | ptv2 | ctv1 | ctv2

if ~exist('command','var')
    command = 'init';
end

hFig = findobj('tag','strNameMapGUI');
ud = get(hFig,'userdata');

switch upper(command)
    
    case 'INIT'
        
        %initialize figure for GUI
        hStrDictGUI = findobj('tag','strNameMapGUI');
        delete(hStrDictGUI)
        str1 = 'CERR+ (rhymes with "Surplus")';
        position = [200 100 700 400];
        figureColor = [0.8 0.9 0.9]; %get(hFig, 'Color');
          hFig = figure('color',figureColor,'name',str1,'tag','strNameMapGUI',...
            'numbertitle','off','position',position,'menubar','none',...
            'CloseRequestFcn','structureNameMapGUI(''QUIT'')');
        units = 'normalized';
        
        
        %Create tabs
        tabH.scan_dir = uicontrol(hFig,'style','togglebutton','tag','scan_dir_tab','string','Scan Directory','units',units,'position',[0.02 0.94 0.15 0.07],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'foregroundColor',[0.5 0.5 0.5],'HorizontalAlignment','left','callback','structureNameMapGUI(''scan_dir'')','tooltipString','Scan Directory');
        tabH.sum_doses = uicontrol(hFig,'style','togglebutton','tag','sum_doses_tab','string','Sum/Adjust Doses','units',units,'position',[0.175 0.94 0.15 0.07],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'foregroundColor',[0.5 0.5 0.5],'HorizontalAlignment','left','callback','structureNameMapGUI(''sum_doses'')','tooltipString','Sum/Adjust Doses');
        tabH.fix_names = uicontrol(hFig,'style','togglebutton','tag','fix_names_tab','string','Match Names','units',units,'position',[0.33 0.94 0.15 0.07],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'foregroundColor',[0.5 0.5 0.5],'HorizontalAlignment','left','callback','structureNameMapGUI(''fix_names'')','tooltipString','Match Names');
        tabH.review_plans = uicontrol(hFig,'style','togglebutton','tag','review_tab','string','Review','units',units,'position',[0.485 0.94 0.15 0.07],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'foregroundColor',[0.5 0.5 0.5],'HorizontalAlignment','left','callback','structureNameMapGUI(''review_plans'')','tooltipString','Review');
        tabH.extract_metrics = uicontrol(hFig,'style','togglebutton','tag','metrics_tab','string','Extract Metrics','units',units,'position',[0.64 0.94 0.15 0.07],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'foregroundColor',[0.5 0.5 0.5],'HorizontalAlignment','left','callback','structureNameMapGUI(''extract_metrics'')','tooltipString','Extract Metrics');
        tabH.results = uicontrol(hFig,'style','togglebutton','tag','metrics_tab','string','Results','units',units,'position',[0.795 0.94 0.15 0.07],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'foregroundColor',[0.5 0.5 0.5],'HorizontalAlignment','left','callback','structureNameMapGUI(''show_results'')','tooltipString','Results');
        tabH.frame = uicontrol(hFig,'style','frame','units',units,'position',[0.0 0.0 1 0.95],'BackgroundColor', figureColor);
        %Create tabs end
        
        
        %-------------- Handles for scanning directory
        %         scanDirH.scanDir_frame1 = uicontrol(hFig,'style','frame','units',units,'position',[0.02 0.995 0.18 0.01],'foregroundColor',figureColor,'backgroundColor',figureColor);
        scanDirH.scanDir_frame2 = uicontrol(hFig,'style','frame','units',units,'position',[0.02 0.94 0.15 0.01],'foregroundColor',figureColor,'backgroundColor',figureColor);
        %         scanDirH.scanDir_frame3 = uicontrol(hFig,'style','frame','units',units,'position',[0.02 0.94 0.01 1],'foregroundColor',figureColor,'backgroundColor',figureColor);
        %         scanDirH.scanDir_frame4 = uicontrol(hFig,'style','frame','units',units,'position',[0.2 0.94 0.01 1],'foregroundColor',figureColor,'backgroundColor',figureColor);
        
        scanDirH.dir_txt = uicontrol(hFig,'style','text','string','Choose Directory','units',units,'position',[0.02 0.8 0.2 0.05],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        scanDirH.dir_edit = uicontrol(hFig,'style','edit','tag','dir_edit_box','string','','units',units,'position',[0.25 0.8 0.45 0.05],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        scanDirH.dir_Push = uicontrol(hFig,'style','pushbutton','tag','dir_push_box','string','Browse','units',units,'position',[0.72 0.8 0.15 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''browse_dir'')');
        
        scanDirH.struct_txt = uicontrol(hFig,'style','text','string','Input structures to extract','units',units,'position',[0.02 0.65 0.25 0.1],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        scanDirH.struct_edit = uicontrol(hFig,'style','edit','tag','struct_edit_box','string','','units',units,'position',[0.25 0.7 0.7 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        scanDirH.struct_txt_help = uicontrol(hFig,'style','text','string','e.g.: Prostate| Prostate bed| Skin ... pipe-separated','units',units,'position',[0.25 0.64 0.7 0.05],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        
        scanDirH.dose_txt = uicontrol(hFig,'style','text','string','Input dose to extract','units',units,'position',[0.02 0.5 0.25 0.1],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        scanDirH.dose_edit = uicontrol(hFig,'style','edit','tag','dose_edit_box','string','','units',units,'position',[0.25 0.55 0.7 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        scanDirH.dose_txt_help = uicontrol(hFig,'style','text','string','e.g.: Final','units',units,'position',[0.25 0.49 0.7 0.05],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        
        scanDirH.done_Push = uicontrol(hFig,'style','pushbutton','tag','done_push','string','Start scan','units',units,'position',[0.72 0.35 0.15 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''done_selecting_dir'')');
        
        %Waitbar
        scanDirH.waitbar_status_text = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [0.05 0.15+0.08 0.2 0.03], 'string', 'Status', 'fontweight', 'bold','HorizontalAlignment','left','BackgroundColor', figureColor);
        scanDirH.percent_text = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [0.15 0.15+0.08 0.7 0.03], 'string', '', 'fontweight', 'normal','HorizontalAlignment','left','BackgroundColor', figureColor);
        scanDirH.waitbar_status_frame1 = uicontrol(hFig,'style','frame','units', units, 'Position', [0.05 0.18 0.9 0.04],'BackgroundColor', figureColor);
        scanDirH.waitbar_status_frame2 = uicontrol(hFig,'style','frame','units', units, 'Position', [0.05 0.18 0.001 0.04],'BackgroundColor', 'red');
        
        fNameC = fieldnames(scanDirH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals scanDirH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        
        %Store default values for directoryNames, structures and dose
        ud.scanDir.directoryName = '';
        ud.scanDir.strNamC       = {''};
        ud.scanDir.doseName      = '';
        
        %-------------- Handles for scanning directory end
        
        
        %-------------- Handles for fixing names
        
        %         fixNamesH.scanDir_frame1 = uicontrol(hFig,'style','frame','units',units,'position',[0.195 0.995 0.18 0.01],'foregroundColor',figureColor,'backgroundColor',figureColor);
        fixNamesH.fixNames_frame2 = uicontrol(hFig,'style','frame','units',units,'position',[0.33 0.94 0.15 0.01],'foregroundColor',figureColor,'backgroundColor',figureColor);
        fixNamesH.fixNames_frame3 = uicontrol(hFig,'style','frame','units',units,'position',[0.02 0.02 0.95 0.85],'foregroundColor',[0 0 0],'backgroundColor',[0.8 0.9 0.9]-0.015);
        %         fixNamesH.scanDir_frame3 = uicontrol(hFig,'style','frame','units',units,'position',[0.195 0.94 0.01 1],'foregroundColor',figureColor,'backgroundColor',figureColor);
        %         fixNamesH.scanDir_frame4 = uicontrol(hFig,'style','frame','units',units,'position',[0.375 0.94 0.01 1],'foregroundColor',figureColor,'backgroundColor',figureColor);
        
        % Previous Plan handle
        fixNamesH.prev_plan = uicontrol(hFig,'style','pushbutton','tag','prev_plan','string','<< Previous Plan','units',units,'position',[0.02 0.88 0.18 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''previous_plan'')');
        
        % Next Plan handle
        fixNamesH.next_plan = uicontrol(hFig,'style','pushbutton','tag','next_plan','string','Next Plan >>','units',units,'position',[0.78 0.88 0.18 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''next_plan'')');
        
        % Plan-Name text handle
        fixNamesH.plan_name = uicontrol(hFig,'style','text','tag','plan_name','string','','units',units,'position',[0.2 0.815 0.62 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','center');
        
        % Ambigious Structure and Dose message handle
        %msgTxt = '';
        %fixNamesH.plan_message = uicontrol(hFig,'style','text','tag','plan_message','string',msgTxt,'units',units,'position',[0.1 0.72 0.8 0.08],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'ForegroundColor', [1 0 0],'HorizontalAlignment','left');
        
        % Assign Structure Name handle
        fixNamesH.assign_struct_str = uicontrol(hFig,'style','text','string','Structures','units',units,'position',[0.04 0.75 0.25 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.structure_assign_txt2 = uicontrol(hFig,'style','text','tag','structure_assign_txt1','string','Desired','units',units,'position',[0.05 0.70 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.desired_structure_list = uicontrol(hFig,'style','listbox','tag','structure_desired_list','string','- - -','units',units,'Min',1,'Max',1,'position',[0.05 0.35 0.25 0.35],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.structure_assign_txt3 = uicontrol(hFig,'style','text','tag','structure_assign_txt2','string','>>','units',units,'position',[0.32 0.5 0.04 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.structure_assign_txt4 = uicontrol(hFig,'style','text','tag','structure_assign_txt3','string','Available','units',units,'position',[0.36 0.75 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.available_structure_list = uicontrol(hFig,'style','listbox','tag','structure_available_list','string','','units',units,'Min',1,'Max',1,'Value',1,'position',[0.36 0.35 0.25 0.4],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.structure_assign_push = uicontrol(hFig,'style','pushbutton','tag','structure_assign_push','string','>>','units',units,'position',[0.62 0.55 0.06 0.06],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''update_structure_map'')');
        fixNamesH.structure_assign_txt5 = uicontrol(hFig,'style','text','tag','structure_assign_txt4','string','','units',units,'position',[0.70 0.35 0.25 0.45],'fontWeight','normal','fontSize',7,'BackgroundColor', figureColor,'foregroundColor',[1 0 0],'HorizontalAlignment','left');
        
        % Assign Dose Name handle
        fixNamesH.assign_dose_str = uicontrol(hFig,'style','text','string','Dose','units',units,'position',[0.04 0.25 0.25 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.dose_popup = uicontrol(hFig,'style','popupmenu','tag','dose_popup','string','- - -','units',units,'position',[0.04 0.20 0.27 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.dose_assign_txt1 = uicontrol(hFig,'style','text','tag','dose_assign_txt2','string','>>','units',units,'position',[0.32 0.19 0.04 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.dose_list = uicontrol(hFig,'style','listbox','tag','dose_list','string','','units',units,'Min',1,'Max',1,'Value',1,'position',[0.36 0.05 0.25 0.25],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        fixNamesH.dose_assign_txt3 = uicontrol(hFig,'style','pushbutton','tag','dose_assign_txt2','string','>>','units',units,'position',[0.62 0.19 0.06 0.06],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''update_dose_map'')');
        fixNamesH.dose_assign_txt5 = uicontrol(hFig,'style','text','tag','dose_assign_txt4','string','','units',units,'position',[0.70 0.15 0.25 0.12],'fontWeight','normal','fontSize',7,'BackgroundColor', figureColor,'foregroundColor',[1 0 0],'HorizontalAlignment','left');
        
        % Save New Mapping handle
        %uicontrol(hFig,'style','text','string','Save mapping for selected structure','units',units,'position',[0.7 0.55 0.2 0.2],'fontWeight','normal','fontSize',11,'BackgroundColor', figureColor,'HorizontalAlignment','left')
        %fixNamesH.save_names_map = uicontrol(hFig,'style','pushbutton','string','Undo name assignment','units',units,'position',[0.66 0.06 0.28 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''undo'')');
        fixNamesH.load_cerr      = uicontrol(hFig,'style','pushbutton','string','View this Plan','units',units,'position',[0.4 0.88 0.18 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''load_cerr'')');
        
        fNameC = fieldnames(fixNamesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals fixNamesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        
        %Store default values for directoryNames, structures and dose
        ud.scanDir.planNum  = 1;
        ud.nameMapS         = [];
        ud.newNameMapS      = [];
        ud.scanDir.strNamC  = {''};
        ud.scanDir.doseName = '';
        
        %Store default values for directoryNames, structures and dose
        ud.sumDose.planNum  = 1;
        doseMapS = struct('DosesToSum',1,'NewDoseName','','AdjustmentType',1, ...
            'd', [], 'abRatio',[], 'maxDose',{[]},'save_to_disk',0);
        doseMapS(1) = [];
        ud.sumDose.doseMapS = doseMapS;
        
        
        %-------------- Handles for fixing names end
        
        
        %-------------- Handles for summing doses
        
        sumDosesH.sumDoses_frame2 = uicontrol(hFig,'style','frame','units',units,'position',[0.175 0.94 0.15 0.01],'foregroundColor',figureColor,'backgroundColor',figureColor);
        
        sumDosesH.sumDoses_frame3 = uicontrol(hFig,'style','frame','units',units,'position',[0.02 0.02 0.95 0.85],'foregroundColor',[0 0 0],'backgroundColor',[0.8 0.9 0.9]-0.015);
        
        % Previous Plan handle
        sumDosesH.prev_plan = uicontrol(hFig,'style','pushbutton','tag','prev_plan','string','<< Previous Plan','units',units,'position',[0.02 0.88 0.18 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''sum_dose_previous_plan'')');
        
        % Next Plan handle
        sumDosesH.next_plan = uicontrol(hFig,'style','pushbutton','tag','next_plan','string','Next Plan >>','units',units,'position',[0.78 0.88 0.18 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''sum_dose_next_plan'')');
        
        %Sum Button
        %sumDosesH.sum_doses_push = uicontrol(hFig,'style','pushbutton','tag','sum_doses_push','string','Done selecting doses to sum','units',units,'position',[0.32 0.88 0.36 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','fontWeight','bold','callback','structureNameMapGUI(''sum_selected_doses'')');
        
        % Plan-Name text handle
        sumDosesH.plan_name = uicontrol(hFig,'style','text','tag','plan_name','string','','units',units,'position',[0.2 0.81 0.62 0.04],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','center');
        
        % Dose List handle
        sumDosesH.dose_sum_str  = uicontrol(hFig,'style','text','string','Select Doses to Sum','units',units,'position',[0.04 0.74 0.25 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        sumDosesH.dose_sum_str2  = uicontrol(hFig,'style','text','string','(use Shift + mouse to select two or more)','units',units,'position',[0.27 0.735 0.34 0.04],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        sumDosesH.dose_sum_str3 = uicontrol(hFig,'style','text','string','DoseNumber  (Max Dose)   FractionGroupID','units',units,'position',[0.05 0.68 0.55 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        sumDosesH.dose_list     = uicontrol(hFig,'style','listbox','tag','dose_list','string','','units',units,'Min',1,'Max',1000,'Value',1,'position',[0.05 0.08 0.55 0.59],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''doses_to_sum_selected'')');
        
        % RadBio Correction
        sumDosesH.dose_adjustment_str = uicontrol(hFig,'style','text','string','Adjust Dose','units',units,'position',[0.65 0.72 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        sumDosesH.radbioCorrect_dose_popup = uicontrol(hFig,'style','popupmenu','tag','dose_popup','string',{'None','BED''s','EQD'},'units',units,'position',[0.78 0.73 0.15 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''fractionation_correction_selected'')');
        sumDosesH.stdFraction_str = uicontrol(hFig,'style','text','tag','stdPerFrac_txt','string','d as in EQD(d)','units',units,'position',[0.65 0.65 0.15 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','visible','off');
        sumDosesH.stdFraction_edit = uicontrol(hFig,'style','edit','tag','stdPerFrac_edit','string','2','units',units,'position',[0.8 0.65 0.05 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''APPLY_FRACT_CORRECT_VALS'')','visible','off');
        sumDosesH.numFraction_str = uicontrol(hFig,'style','text','tag','numPerFrac_txt','string','#Fr.','units',units,'position',[0.65 0.58 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','visible','off');
        sumDosesH.numFraction_edit = uicontrol(hFig,'style','edit','tag','numPerFrac_edit','string','35','units',units,'position',[0.70 0.58 0.05 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''APPLY_FRACT_CORRECT_VALS'')','visible','off');
        sumDosesH.abRatio_str = uicontrol(hFig,'style','text','tag','abratio_txt','string','a/b','units',units,'position',[0.78 0.58 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','visible','off');
        sumDosesH.abRatio_edit = uicontrol(hFig,'style','edit','tag','abratio_edit','string','3','units',units,'position',[0.82 0.58 0.05 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''APPLY_FRACT_CORRECT_VALS'')','visible','off');
        sumDosesH.applyAll_check = uicontrol(hFig,'style','checkbox','tag','all_check','string','All','units',units,'position',[0.892 0.58 0.05 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''apply_fract_correct_to_all'')','visible','off');        
        %New Dose Name
        sumDosesH.new_dose_str  = uicontrol(hFig,'style','text','tag','new_dose_name_str','string','Name New Dose','units',units,'position',[0.65 0.50 0.25 0.05],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        sumDosesH.new_dose_edit = uicontrol(hFig,'style','edit','tag','new_dose_name_edit','string','','units',units,'position',[0.65 0.42 0.25 0.07],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''doses_to_sum_selected'')');
        
        %Save to disk
        sumDosesH.save_to_disk_chk  = uicontrol(hFig,'style','checkbox','tag','new_dose_name_chk','string','Save to original plan','units',units,'position',[0.65 0.30 0.28 0.07],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''doses_to_sum_selected'')');
        sumDosesH.warning_txt = uicontrol(hFig,'style','text','tag','new_dose_warn','string','(will overwrite existing file)','units',units,'position',[0.65 0.25 0.3 0.04],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'ForegroundColor', [1 0 0],'HorizontalAlignment','left','callback','structureNameMapGUI(''doses_to_sum_selected'')');
        
        fNameC = fieldnames(sumDosesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals sumDosesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        %-------------- Handles for summing doses end
        
        
        %-------------- Handles for reviewing plans
        reviewPlansH.reviewPlans_frame2 = uicontrol(hFig,'style','frame','units',units,'position',[0.485 0.94 0.15 0.01],'foregroundColor',figureColor,'backgroundColor',figureColor);
        reviewPlansH.allStruct_txt       = uicontrol(hFig,'style','text','string','Structure to review','units',units,'position',[0.02 0.85 0.2 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        reviewPlansH.allStruct_list      = uicontrol(hFig,'style','listbox','string','','units',units,'Min',1,'Max',1,'Value',1,'position',[0.02 0.07 0.25 0.73],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        reviewPlansH.allPlans_txt        = uicontrol(hFig,'style','text','string','Plans to review','units',units,'position',[0.30 0.85 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        reviewPlansH.allPlans_list       = uicontrol(hFig,'style','listbox','string','','units',units,'Min',1,'Max',16,'Value',1:16,'position',[0.30 0.07 0.35 0.73],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        reviewPlansH.prevPlans_push      = uicontrol(hFig,'style','pushbutton','string','<--','units',units,'position',[0.46 0.84 0.06 0.06],'fontWeight','bold','fontSize',10,'HorizontalAlignment','center', 'callback','structureNameMapGUI(''PREV_COHORT'')');
        reviewPlansH.nextPlans_push      = uicontrol(hFig,'style','pushbutton','string','-->','units',units,'position',[0.53 0.84 0.06 0.06],'fontWeight','bold','fontSize',10,'HorizontalAlignment','center', 'callback','structureNameMapGUI(''NEXT_COHORT'')');
        reviewPlansH.openViewer_push     = uicontrol(hFig,'style','pushbutton','string','Viewer','units',units,'position',[0.60 0.84 0.07 0.06],'fontWeight','bold','fontSize',10,'HorizontalAlignment','center', 'callback','structureNameMapGUI(''COHORT_VIEVER'')');
        
        %Store default values for directoryNames, structures and dose
        ud.reviewPlans.planNums  = 1:16;
        ud.reviewPlans.structNum = 1;
        
        fNameC = fieldnames(reviewPlansH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals reviewPlansH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        %-------------- Handles for reviewing plans end
        
        
        %-------------- Handles for data extraction
        extractMetricsH.extractMetrics_frame2      = uicontrol(hFig,'style','frame','units',units,'position',[0.64 0.94 0.15 0.01],'foregroundColor',figureColor,'backgroundColor',figureColor);
        msgStr = 'DVHs for selected structures and doses will be extracted. If you want to extract additional metrics, please specify comma-separated function names in the box below. Note that these functions must be located on Matlab path.';
        extractMetricsH.structureNames_txt  = uicontrol(hFig,'style','text','string',msgStr,'units',units,'position',[0.04 0.75 0.9 0.15],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        extractMetricsH.additonal_metrics_txt   = uicontrol(hFig,'style','text','string','User-defined metrics','units',units,'position',[0.02 0.63 0.25 0.1],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        extractMetricsH.additonal_metrics_help_txt   = uicontrol(hFig,'style','text','string','myMetric1, myMetric2','units',units,'position',[0.04 0.58 0.25 0.1],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        extractMetricsH.additonal_metrics_edit  = uicontrol(hFig,'style','edit','string','','units',units,'position',[0.28 0.68 0.7 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        extractMetricsH.export_format_txt    = uicontrol(hFig,'style','text','string','Export Format','units',units,'position',[0.02 0.5 0.25 0.1],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        extractMetricsH.export_format_popup  = uicontrol(hFig,'style','popupmenu','string',{'DREES (.mat)','OQA (mySql database)', 'SPSS (MS-Excel)', 'RADRESEARCH (database)', 'BIRN (database)'},'units',units,'position',[0.28 0.57 0.3 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        extractMetricsH.excel_data_txt    = uicontrol(hFig,'style','text','string','Excel Data','units',units,'position',[0.02 0.41 0.25 0.1],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        extractMetricsH.excel_data_push  = uicontrol(hFig,'style','pushbutton','string','Select','units',units,'position',[0.28 0.46 0.25 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''GET_EXCEL_DATA'')');
        extractMetricsH.drees_fileName_str    = uicontrol(hFig,'style','text','string','Saved FileName','units',units,'position',[0.02 0.32 0.25 0.1],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        extractMetricsH.drees_fileName_push  = uicontrol(hFig,'style','pushbutton','string','Select','units',units,'position',[0.28 0.37 0.60 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''GET_DREES_FILENAME'')');
        extractMetricsH.export_push         = uicontrol(hFig,'style','pushbutton','string','Start Export','units',units,'position',[0.7 0.25 0.25 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''save_extracted_metrics'')');
        %Waitbar
        extractMetricsH.waitbar_status_text = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [0.05 0.15+0.05 0.2 0.03], 'string', 'Status', 'fontweight', 'bold','HorizontalAlignment','left','BackgroundColor', figureColor);
        extractMetricsH.percent_text = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [0.15 0.15+0.05 0.7 0.03], 'string', '', 'fontweight', 'normal','HorizontalAlignment','left','BackgroundColor', figureColor);
        extractMetricsH.waitbar_status_frame1 = uicontrol(hFig,'style','frame','units', units, 'Position', [0.05 0.15 0.9 0.04],'BackgroundColor', figureColor);
        extractMetricsH.waitbar_status_frame2 = uicontrol(hFig,'style','frame','units', units, 'Position', [0.05 0.15 0.001 0.04],'BackgroundColor', 'red');
        
        fNameC = fieldnames(extractMetricsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals extractMetricsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        %-------------- Handles for data extraction end
        
        
        
        %-------------- Handles for showing results
        resultsH.results_frame2      = uicontrol(hFig,'style','frame','units',units,'position',[0.72 0.94 0.18 0.01],'foregroundColor',figureColor,'backgroundColor',figureColor);
        
        resultsH.results_frame3 = uicontrol(hFig,'style','frame','units',units,'position',[0.02 0.02 0.95 0.25],'foregroundColor',[0 0 0],'backgroundColor',[0.8 0.9 0.9]-0.015);
        
        resultsH.structureNames_txt1 = uicontrol(hFig,'style','text','string','Strutures to extract:','units',units,'position',[0.02 0.85 0.2 0.04],'fontWeight','bold','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.structureNames_txt2 = uicontrol(hFig,'style','text','string','','units',units,'position',[0.25 0.84 0.7 0.06],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.doseNames_txt1      = uicontrol(hFig,'style','text','string','Doses to extract:','units',units,'position',[0.02 0.79 0.22 0.04],'fontWeight','bold','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.doseNames_txt2      = uicontrol(hFig,'style','text','string','','units',units,'position',[0.25 0.78 0.7 0.06],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.planNames_txt       = uicontrol(hFig,'style','text','string','File Names','units',units,'position',[0.04 0.72 0.25 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.planNames_list      = uicontrol(hFig,'style','listbox','string','','units',units,'Min',1,'Max',1,'Value',1,'position',[0.05 0.30 0.25 0.41],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''fix_selected_plan'')');
        resultsH.allStruct_txt       = uicontrol(hFig,'style','text','string','Structures selected','units',units,'position',[0.34 0.72 0.25 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.allStruct_list      = uicontrol(hFig,'style','listbox','string','','units',units,'Min',1,'Max',1,'Value',1,'position',[0.35 0.30 0.25 0.41],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.allDoses_txt       = uicontrol(hFig,'style','text','string','Doses selected','units',units,'position',[0.64 0.72 0.25 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.allDoses_list      = uicontrol(hFig,'style','listbox','string','','units',units,'Min',1,'Max',1,'Value',1,'position',[0.65 0.30 0.25 0.41],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        
        resultsH.writeFilesTxt      = uicontrol(hFig,'style','text','string','Write updated plans to disk','units',units,'position',[0.02 0.23 0.28 0.04],'fontWeight','bold','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        
        resultsH.dir_txt = uicontrol(hFig,'style','text','string','Choose directory to save updated plans','units',units,'position',[0.03 0.15 0.18 0.07],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.dir_edit = uicontrol(hFig,'style','edit','tag','write_dir_edit_box','string','','units',units,'position',[0.20 0.15 0.25 0.05],'fontWeight','normal','fontSize',8,'BackgroundColor', figureColor,'HorizontalAlignment','left');
        resultsH.dir_Push = uicontrol(hFig,'style','pushbutton','tag','write_dir_push_box','string','...','units',units,'position',[0.46 0.15 0.03 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''browse_dir_to_write_plans'')');
        
        resultsH.overwriteRadio = uicontrol(hFig,'style','radiobutton','tag','write_radio','string','Overwrite existing plans','units',units,'position',[0.51 0.15 0.30 0.05],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''overwrite_plans_option_selected'')');
        
        resultsH.write_plans_Push = uicontrol(hFig,'style','pushbutton','tag','write_plans_push_box','string','Write','units',units,'position',[0.82 0.13 0.10 0.09],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left','callback','structureNameMapGUI(''write_plans_to_disk'')');
        
        %Waitbar
        resultsH.waitbar_status_text = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [0.05 0.04+0.05 0.2 0.03], 'string', 'Status', 'fontweight', 'bold','HorizontalAlignment','left','BackgroundColor', figureColor);
        resultsH.percent_text = uicontrol(hFig, 'style', 'text', 'units', units, 'position', [0.15 0.04 0.7 0.03], 'string', '', 'fontweight', 'normal','HorizontalAlignment','left','BackgroundColor', figureColor);
        resultsH.waitbar_status_frame1 = uicontrol(hFig,'style','frame','units', units, 'Position', [0.05 0.04 0.9 0.04],'BackgroundColor', figureColor);
        resultsH.waitbar_status_frame2 = uicontrol(hFig,'style','frame','units', units, 'Position', [0.05 0.04 0.001 0.04],'BackgroundColor', 'red');
        
        
        fNameC = fieldnames(resultsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals resultsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        %-------------- Handles for showing results end
        
        
        ud.handles.fixNamesH = fixNamesH;
        ud.handles.sumDosesH = sumDosesH;
        ud.handles.scanDirH = scanDirH;
        ud.handles.reviewPlansH = reviewPlansH;
        ud.handles.extractMetricsH = extractMetricsH;
        ud.handles.resultsH = resultsH;
        ud.handles.tabH = tabH;
        set(hFig,'userdata',ud)
        
        
    case 'OVERWRITE_PLANS_OPTION_SELECTED'
        
        val = get(gcbo,'value');
        if val == 0
            set(ud.handles.resultsH.dir_edit,'enable','on')
            set(ud.handles.resultsH.dir_Push,'enable','on')
        else
            set(ud.handles.resultsH.dir_edit,'enable','off')
            set(ud.handles.resultsH.dir_Push,'enable','off')
        end
        set(hFig,'userdata',ud)
        
        
    case 'BROWSE_DIR_TO_WRITE_PLANS'
        directoryName = uigetdir;
        if isnumeric(directoryName)
            %Do nothing
            return;
        else
            ud.scanDir.writeDirectoryName = directoryName;
            set(ud.handles.resultsH.dir_edit,'string',directoryName)
        end
        set(hFig,'userdata',ud)
        
        
    case 'WRITE_PLANS_TO_DISK'
        %Get directory to write CERR plans
        ud.scanDir.writeDirectoryName = get(ud.handles.resultsH.dir_edit,'string');
        
        %Get waitbar handles
        waitbarH = ud.handles.resultsH.waitbar_status_frame2;
        statusStrH = ud.handles.resultsH.percent_text;
        
        for planNum=1:length(ud.newNameMapS)
            
            %Update Waitbar
            drawnow
            set(waitbarH,'position',[0.05 0.04 0.9*planNum/length(ud.newNameMapS) 0.04])
            set(statusStrH,'string',['Exporting ',int2str(planNum),' out of ',int2str(length(ud.newNameMapS))])
            
            %Load CERR plan
            try
                planC = loadPlanC(ud.newNameMapS(planNum).fullFileName, tempdir);
                planC = updatePlanFields(planC);
                indexS = planC{end};
                
                % Quality assure
                planC = quality_assure_planC(ud.newNameMapS(planNum).fullFileName, planC);
             
                %Sum doses if required
                dosesToSumV = ud.sumDose.doseMapS(planNum).DosesToSum;
                
                if length(dosesToSumV) > 1
                    
                    %New dose name
                    doseNameStr = ud.sumDose.doseMapS(planNum).NewDoseName;
                    assocScan = 1;
                    planC = sumDose(dosesToSumV,dosesToSumV.^0,assocScan,doseNameStr,planC);
                    
                else
                    
                    %Update name for selected dose
                    doseNum = ud.newNameMapS(planNum).doseMap;
                    if ~isempty(doseNum) && ~isempty(ud.scanDir.doseName)
                        planC{indexS.dose}(doseNum).fractionGroupID = ud.scanDir.doseName;
                    end
                    
                end
                
                %Update name for selected doses
                doseNum = ud.newNameMapS(planNum).doseMap;
                if ~isempty(doseNum) && ~isempty(ud.scanDir.doseName)
                    planC{indexS.dose}(doseNum).fractionGroupID = ud.scanDir.doseName;
                end
                
                %Update name for selected structures
                for m=1:length(ud.newNameMapS(planNum).structMap)
                    if ~isempty(ud.newNameMapS(planNum).structMap{m})
                        planC{indexS.structures}(ud.newNameMapS(planNum).structMap{m}).structureName = ud.scanDir.strNamC{m};
                    end
                end
                
                [pName,fName,ext] = fileparts(ud.nameMapS(planNum).fullFileName);
                fName = [fName,ext];
                %Save dose to plan on disk
                try
                    overWriteVal = get(ud.handles.resultsH.overwriteRadio,'value');
                    if overWriteVal == 1 % overwrite current files
                        save_planC(planC,[], 'passed', ud.nameMapS(planNum).fullFileName);
                    else % save in user defined directory
                        save_planC(planC,[], 'passed', fullfile(ud.scanDir.writeDirectoryName,fName));
                    end
                catch
                    disp([ud.newNameMapS(planNum).fullFileName, ' failed to save'])
                end
                
            catch
                disp([ud.newNameMapS(planNum).fullFileName, ' failed to load'])
                continue
            end
            
        end
        
        
        
    case 'BROWSE_DIR'
        directoryName = uigetdir;
        if isnumeric(directoryName)
            %Do nothing
            return;
        else
            ud.scanDir.directoryName = directoryName;
            set(ud.handles.scanDirH.dir_edit,'string',directoryName)
        end
        set(hFig,'userdata',ud)
        
        
    case 'SCAN_DIR'
        
        fixNamesH = ud.handles.fixNamesH;
        sumDosesH = ud.handles.sumDosesH;
        scanDirH = ud.handles.scanDirH;
        reviewPlansH = ud.handles.reviewPlansH;
        extractMetricsH = ud.handles.extractMetricsH;
        resultsH = ud.handles.resultsH;
        
        tabH = ud.handles.tabH;
        scan_dir_val = get(tabH.scan_dir,'value');
        
        %Turn off fixNames, sumDosesH, extractMetrics and results handles
        fNameC = fieldnames(fixNamesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals fixNamesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.fix_names,'value',0)
        set(tabH.fix_names,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(sumDosesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals sumDosesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.sum_doses,'value',0)
        set(tabH.sum_doses,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(reviewPlansH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals reviewPlansH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.review_plans,'value',0)
        set(tabH.review_plans,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(extractMetricsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals extractMetricsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.extract_metrics,'value',0)
        set(tabH.extract_metrics,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(resultsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals resultsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.results,'value',0)
        set(tabH.results,'foregroundColor',[0.5 0.5 0.5])
        
        %Turn on scan_dir handles
        fNameC = fieldnames(scanDirH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals scanDirH.(fNameC{i})];
        end
        if scan_dir_val == 1
            set(tabH.scan_dir,'foregroundColor',[0 0 0])
            set(handleVals, 'visible','on')
        else
            set(tabH.scan_dir,'foregroundColor',[0.5 0.5 0.5])
            set(handleVals, 'visible','off')
            return;
        end
        
        if isempty(ud.nameMapS)
            %Turn off waitbar
            set([scanDirH.waitbar_status_text,scanDirH.percent_text,scanDirH.waitbar_status_frame1,scanDirH.waitbar_status_frame2],'visible','off')
        else
            %Turn on waitbar
            set([scanDirH.waitbar_status_text,scanDirH.percent_text,scanDirH.waitbar_status_frame1,scanDirH.waitbar_status_frame2],'visible','on')
        end
        
        
    case 'FIX_NAMES'
        
        fixNamesH = ud.handles.fixNamesH;
        scanDirH = ud.handles.scanDirH;
        sumDosesH = ud.handles.sumDosesH;
        reviewPlansH = ud.handles.reviewPlansH;
        extractMetricsH = ud.handles.extractMetricsH;
        resultsH = ud.handles.resultsH;
        tabH = ud.handles.tabH;
        fix_names_val = get(tabH.fix_names,'value');
        
        %Turn off scanDir, results and extractMetrics handles
        fNameC = fieldnames(scanDirH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals scanDirH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.scan_dir,'value',0)
        set(tabH.scan_dir,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(sumDosesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals sumDosesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.sum_doses,'value',0)
        set(tabH.sum_doses,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(reviewPlansH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals reviewPlansH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.review_plans,'value',0)
        set(tabH.review_plans,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(extractMetricsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals extractMetricsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.extract_metrics,'value',0)
        set(tabH.extract_metrics,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(resultsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals resultsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.results,'value',0)
        set(tabH.results,'foregroundColor',[0.5 0.5 0.5])
        
        %Turn on scan_dir handles
        fNameC = fieldnames(fixNamesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals fixNamesH.(fNameC{i})];
        end
        if fix_names_val == 1
            set(tabH.fix_names,'foregroundColor',[0 0 0])
            set(handleVals, 'visible','on')
        else
            set(tabH.fix_names,'foregroundColor',[0.5 0.5 0.5])
            set(handleVals, 'visible','off')
            return;
        end
        
        if ~isempty(ud.nameMapS)
            structureNameMapGUI('REFRESH')
        end
        
    case 'SUM_DOSES'
        
        fixNamesH = ud.handles.fixNamesH;
        scanDirH = ud.handles.scanDirH;
        sumDosesH = ud.handles.sumDosesH;
        reviewPlansH = ud.handles.reviewPlansH;
        extractMetricsH = ud.handles.extractMetricsH;
        resultsH = ud.handles.resultsH;
        tabH = ud.handles.tabH;
        
        sum_doses_val = get(tabH.sum_doses,'value');
        
        %Turn off scanDir, fixNames and results handles
        fNameC = fieldnames(scanDirH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals scanDirH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.scan_dir,'value',0)
        set(tabH.scan_dir,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(sumDosesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals sumDosesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.sum_doses,'value',0)
        set(tabH.sum_doses,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(reviewPlansH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals reviewPlansH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.review_plans,'value',0)
        set(tabH.review_plans,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(extractMetricsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals extractMetricsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.extract_metrics,'value',0)
        set(tabH.extract_metrics,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(fixNamesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals fixNamesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.fix_names,'value',0)
        set(tabH.fix_names,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(resultsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals resultsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.results,'value',0)
        set(tabH.results,'foregroundColor',[0.5 0.5 0.5])
        
        
        %Turn on sum_doses handles
        fNameC = fieldnames(sumDosesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals sumDosesH.(fNameC{i})];
        end
        if sum_doses_val == 1
            set(tabH.sum_doses,'foregroundColor',[0 0 0])
            set(handleVals, 'visible','on')
            set([sumDosesH.dose_adjustment_str, sumDosesH.radbioCorrect_dose_popup, ...
                sumDosesH.numFraction_str, sumDosesH.numFraction_edit, ...
                sumDosesH.stdFraction_str, sumDosesH.stdFraction_edit, ...
                sumDosesH.abRatio_str, sumDosesH.abRatio_edit, sumDosesH.applyAll_check],...
                'visible','on')            
        else
            set(tabH.sum_doses,'foregroundColor',[0.5 0.5 0.5])
            set(handleVals, 'visible','off')
            return;
        end
        
        if ~isempty(ud.nameMapS)
            structureNameMapGUI('REFRESH_SUM_DOSE')
        end
        
        
    case 'REVIEW_PLANS'
        fixNamesH = ud.handles.fixNamesH;
        scanDirH = ud.handles.scanDirH;
        sumDosesH = ud.handles.sumDosesH;
        reviewPlansH = ud.handles.reviewPlansH;
        extractMetricsH = ud.handles.extractMetricsH;
        resultsH = ud.handles.resultsH;
        tabH = ud.handles.tabH;
        
        review_plans_val = get(tabH.review_plans,'value');
        
        %Turn off scanDir, fixNames and results handles
        fNameC = fieldnames(scanDirH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals scanDirH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.scan_dir,'value',0)
        set(tabH.scan_dir,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(sumDosesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals sumDosesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.sum_doses,'value',0)
        set(tabH.sum_doses,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(fixNamesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals fixNamesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.fix_names,'value',0)
        set(tabH.fix_names,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(extractMetricsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals extractMetricsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.extract_metrics,'value',0)
        set(tabH.extract_metrics,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(resultsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals resultsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.results,'value',0)
        set(tabH.results,'foregroundColor',[0.5 0.5 0.5])
        
        %Turn on scan_dir handles
        fNameC = fieldnames(reviewPlansH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals reviewPlansH.(fNameC{i})];
        end
        if review_plans_val == 1
            set(tabH.review_plans,'foregroundColor',[0 0 0])
            set(handleVals, 'visible','on')
        else
            set(tabH.review_plans,'foregroundColor',[0.5 0.5 0.5])
            set(handleVals, 'visible','off')
            return;
        end
        
        nameMapS = ud.newNameMapS;
        if isempty(nameMapS)
            return
        end
        
        allStructureNames = {};
        allFilenames = {};
        for i=1:length(nameMapS)
            [jnk,fName,ext] = fileparts(nameMapS(i).fullFileName);
            allFilenames = [allFilenames [fName,ext]];
        end
        
        set(ud.handles.reviewPlansH.allPlans_list,'string',allFilenames,'value',1:min(length(allFilenames),16))
        set(ud.handles.reviewPlansH.allStruct_list, 'string',ud.scanDir.strNamC,'value',1)
        
        
    case 'EXTRACT_METRICS'
        fixNamesH = ud.handles.fixNamesH;
        scanDirH = ud.handles.scanDirH;
        sumDosesH = ud.handles.sumDosesH;
        reviewPlansH = ud.handles.reviewPlansH;
        extractMetricsH = ud.handles.extractMetricsH;
        resultsH = ud.handles.resultsH;
        tabH = ud.handles.tabH;
        
        extract_metrics_val = get(tabH.extract_metrics,'value');
        
        %Turn off scanDir, fixNames and results handles
        fNameC = fieldnames(scanDirH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals scanDirH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.scan_dir,'value',0)
        set(tabH.scan_dir,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(sumDosesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals sumDosesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.sum_doses,'value',0)
        set(tabH.sum_doses,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(fixNamesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals fixNamesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.fix_names,'value',0)
        set(tabH.fix_names,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(reviewPlansH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals reviewPlansH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.review_plans,'value',0)
        set(tabH.review_plans,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(resultsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals resultsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.results,'value',0)
        set(tabH.results,'foregroundColor',[0.5 0.5 0.5])
        
        
        %Turn on scan_dir handles
        fNameC = fieldnames(extractMetricsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals extractMetricsH.(fNameC{i})];
        end
        if extract_metrics_val == 1
            set(tabH.extract_metrics,'foregroundColor',[0 0 0])
            set(handleVals, 'visible','on')
        else
            set(tabH.extract_metrics,'foregroundColor',[0.5 0.5 0.5])
            set(handleVals, 'visible','off')
            return;
        end
        
        
        
    case 'SHOW_RESULTS'
        fixNamesH = ud.handles.fixNamesH;
        scanDirH = ud.handles.scanDirH;
        sumDosesH = ud.handles.sumDosesH;
        reviewPlansH = ud.handles.reviewPlansH;
        extractMetricsH = ud.handles.extractMetricsH;
        resultsH = ud.handles.resultsH;
        tabH = ud.handles.tabH;
        
        results_val = get(tabH.results,'value');
        
        %Turn off scanDir, fixNames and results handles
        fNameC = fieldnames(scanDirH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals scanDirH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.scan_dir,'value',0)
        set(tabH.scan_dir,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(sumDosesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals sumDosesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.sum_doses,'value',0)
        set(tabH.sum_doses,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(fixNamesH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals fixNamesH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.fix_names,'value',0)
        set(tabH.fix_names,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(reviewPlansH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals reviewPlansH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.review_plans,'value',0)
        set(tabH.review_plans,'foregroundColor',[0.5 0.5 0.5])
        
        fNameC = fieldnames(extractMetricsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals extractMetricsH.(fNameC{i})];
        end
        set(handleVals, 'visible','off')
        set(tabH.extract_metrics,'value',0)
        set(tabH.extract_metrics,'foregroundColor',[0.5 0.5 0.5])
        
        
        %Turn on scan_dir handles
        fNameC = fieldnames(resultsH);
        handleVals =[];
        for i=1:length(fNameC)
            handleVals = [handleVals resultsH.(fNameC{i})];
        end
        if results_val == 1
            set(tabH.results,'foregroundColor',[0 0 0])
            set(handleVals, 'visible','on')
        else
            set(tabH.results,'foregroundColor',[0.5 0.5 0.5])
            set(handleVals, 'visible','off')
            return;
        end
        
        nameMapS = ud.newNameMapS;
        if isempty(nameMapS)
            return
        end
        
        allStructureNames = {};
        allDoseNames = {};
        allFilenames = {};
        for i=1:length(nameMapS)
            allStructureNames = [allStructureNames nameMapS(i).allStructureNames([nameMapS(i).structMap{:}])];
            if ~isempty(nameMapS(i).doseMap)
                allDoseNames = [allDoseNames nameMapS(i).allDoseNames(nameMapS(i).doseMap(1))];
            end
            [jnk,fName,ext] = fileparts(nameMapS(i).fullFileName);
            allFilenames = [allFilenames [fName,ext]];
        end
        allStructureNames = unique(lower(allStructureNames));
        allDoseNames = unique(lower(allDoseNames));
        structures_to_extract = [];
        for i=1:length(ud.scanDir.strNamC)
            structures_to_extract = [structures_to_extract, ', ', strtrim(ud.scanDir.strNamC{i})];
        end
        structures_to_extract(1) = [];
        dose_to_extract = ud.scanDir.doseName;
        
        set(ud.handles.resultsH.structureNames_txt2,'string',structures_to_extract)
        set(ud.handles.resultsH.doseNames_txt2,'string',dose_to_extract)
        set(ud.handles.resultsH.planNames_list,'string',allFilenames,'value',ud.scanDir.planNum)
        set(ud.handles.resultsH.allStruct_list, 'string',allStructureNames,'value',1)
        set(ud.handles.resultsH.allDoses_list, 'string',allDoseNames,'value',1)
        
    case 'FIX_SELECTED_PLAN'
        
        selection_type = get(hFig,'SelectionType');
        if strcmpi(selection_type,'normal')
            return
        end
        
        ud.scanDir.planNum = get(ud.handles.resultsH.planNames_list,'value');
        set(hFig,'userdata',ud)
        set(ud.handles.tabH.fix_names,'value',1)
        structureNameMapGUI('FIX_NAMES')
        
        
    case 'DONE_SELECTING_DIR'
        scanDirH = ud.handles.scanDirH;
        
        %Get directory to look for CERR plans
        ud.scanDir.directoryName = get(scanDirH.dir_edit,'string');
        
        %Get structure names
        structNames = get(scanDirH.struct_edit,'string');
        indPipe = strfind(structNames,'|');
        if isempty(indPipe)
            strNameC{1} = structNames;
        else
            strNameC{1} = strtrim(structNames(1:indPipe(1)-1));
        end
        for i=1:length(indPipe)-1
            strNameC{end+1} = strtrim(structNames(indPipe(i)+1:indPipe(i+1)-1));
        end
        if ~isempty(indPipe)
            strNameC{end+1} = strtrim(structNames(indPipe(end)+1:end));
        end
        ud.scanDir.strNamC = strNameC;
        
        %Get dose names
        doseName = get(scanDirH.dose_edit,'string');
        indPipe = strfind(doseName,'|');
        if isempty(indPipe)
            ud.scanDir.doseName = strtrim(doseName);
        else
            errordlg('Only one dose allowed.','Error in dose string','modal')
        end
        
        %Turn on waitbar
        set([scanDirH.waitbar_status_text,scanDirH.percent_text,scanDirH.waitbar_status_frame1,scanDirH.waitbar_status_frame2],'visible','on')
        
        [nameMapS, doseMap] = StructNameMap(ud.scanDir.directoryName, ud.scanDir.strNamC, ud.scanDir.doseName, scanDirH.waitbar_status_frame2, scanDirH.percent_text);
        
        ud.nameMapS = nameMapS;
        ud.newNameMapS = nameMapS;
        
        ud.sumDose.doseMapS = doseMap;
        
        set(hFig,'userdata',ud)
        
        
    case 'REFRESH_SUM_DOSE'
        
        %nameMapS = ud.newNameMapS;
        nameMapS = ud.nameMapS;
        planNum = ud.sumDose.planNum;
        
        if isempty(nameMapS)
            return
        end
        
        % Plan-Name text handle
        [jnk,filenameStr] = fileparts(nameMapS(planNum).fullFileName);
        set(ud.handles.sumDosesH.plan_name, 'string',['Plan ',int2str(planNum),' of ',int2str(length(nameMapS)),': ', filenameStr]);
        
        %Get all dose names for this plan
        allDoseC = '';
        for doseNum = 1:length([nameMapS(planNum).allDoseNames])
            allDoseC{doseNum} = [num2str(doseNum),' (',num2str(ud.sumDose.doseMapS(planNum).maxDose{doseNum}),') ', nameMapS(planNum).allDoseNames{doseNum}];
        end
        
        if isempty(ud.sumDose.doseMapS(planNum).DosesToSum)
            doseIndex = ud.nameMapS(planNum).doseMap;
        else
            doseIndex = ud.sumDose.doseMapS(planNum).DosesToSum;            
        end
        
        set(ud.handles.sumDosesH.dose_list,'string',allDoseC,'value',doseIndex)
        
        fractType = ud.sumDose.doseMapS(planNum).AdjustmentType;
        set(ud.handles.sumDosesH.radbioCorrect_dose_popup,'value',fractType)
        if fractType == 3
            set(ud.handles.sumDosesH.radbioCorrect_dose_popup,'visible','on');
            set(ud.handles.sumDosesH.numFraction_edit,'visible','on');
            set(ud.handles.sumDosesH.stdFraction_edit,'visible','on');
            set(ud.handles.sumDosesH.abRatio_edit,'visible','on');
            set(ud.handles.sumDosesH.numFraction_str,'visible','on');
            set(ud.handles.sumDosesH.stdFraction_str,'visible','on');
            set(ud.handles.sumDosesH.abRatio_str,'visible','on');
            set(ud.handles.sumDosesH.applyAll_check,'visible','on');            
            abRatio = ud.sumDose.doseMapS(planNum).abRatio;
            numFractions = ud.sumDose.doseMapS(planNum).numFractions;
            stdFracSiz = ud.sumDose.doseMapS(planNum).stdFractionSize;
            set(ud.handles.sumDosesH.numFraction_edit,'string',numFractions);
            set(ud.handles.sumDosesH.stdFraction_edit,'string',stdFracSiz);
            set(ud.handles.sumDosesH.abRatio_edit,'string',abRatio);
        else
            set(ud.handles.sumDosesH.numFraction_edit,'visible','off');
            set(ud.handles.sumDosesH.stdFraction_edit,'visible','off');
            set(ud.handles.sumDosesH.abRatio_edit,'visible','off');
            set(ud.handles.sumDosesH.numFraction_str,'visible','off');
            set(ud.handles.sumDosesH.stdFraction_str,'visible','off');            
            set(ud.handles.sumDosesH.abRatio_str,'visible','off');
            set(ud.handles.sumDosesH.applyAll_check,'visible','off');
        end
        
        if isempty(ud.sumDose.doseMapS(planNum).AdjustmentType)
            set(ud.handles.sumDosesH.new_dose_edit, 'string',ud.scanDir.doseName)
        else
            set(ud.handles.sumDosesH.new_dose_edit, 'string',ud.sumDose.doseMapS(planNum).NewDoseName)
        end
        
        set(ud.handles.sumDosesH.save_to_disk_chk, 'value',ud.sumDose.doseMapS(planNum).save_to_disk)
        
        
    case 'DOSES_TO_SUM_SELECTED'
        
        planNum = ud.sumDose.planNum;
        
        dosesToSum_value = get(ud.handles.sumDosesH.dose_list,'value');
        
        adjustment_value = get(ud.handles.sumDosesH.radbioCorrect_dose_popup,'value');
        
        doseName = get(ud.handles.sumDosesH.new_dose_edit, 'string');
        
        save_to_disk_val = get(ud.handles.sumDosesH.save_to_disk_chk,'value');
        
        ud.newNameMapS(planNum) = ud.nameMapS(planNum);
        ud.newNameMapS(planNum).allDoseNames = ud.nameMapS(planNum).allDoseNames;
        
        if length(dosesToSum_value) > 1
            ud.sumDose.doseMapS(planNum).DosesToSum = dosesToSum_value;
            ud.sumDose.doseMapS(planNum).NewDoseName = doseName;
            ud.sumDose.doseMapS(planNum).AdjustmentType = adjustment_value;
            ud.sumDose.doseMapS(planNum).maxDose{end+1} = [];
            ud.sumDose.doseMapS(planNum).save_to_disk = save_to_disk_val;
            ud.newNameMapS(planNum) = ud.nameMapS(planNum);
            ud.newNameMapS(planNum).allDoseNames{end+1} = doseName;
        end
        
        dose_to_extract = ud.scanDir.doseName;
        
        if ~isempty(ud.newNameMapS(planNum).allDoseNames) || ~isequal(ud.newNameMapS(planNum).allDoseNames,ud.nameMapS(planNum).allDoseNames)
            doseNameC = ud.newNameMapS(planNum).allDoseNames;
        else
            doseNameC = ud.nameMapS(planNum).allDoseNames;
        end
        if length(doseNameC) == 1
            ud.newNameMapS(planNum).doseMap = 1;
        else
            ud.newNameMapS(planNum).doseMap = getMatchingIndex(dose_to_extract,doseNameC);            
        end
        
        set(hFig,'userdata',ud)
        
        
    case 'SUM_SELECTED_DOSES'
        
        %Load CERR plan
        for planNum = 1:length(ud.sumDose.doseMapS)
            
            %             dosesToSumV = ud.sumDose.doseMapS(planNum).DosesToSum;
            
            %             if length(dosesToSumV) == 1
            %                 continue;
            %             end
            %
            %             try
            %                 planC = loadPlanC(ud.nameMapS(planNum).fullFileName,tempdir);
            %             catch
            %                 disp([fileC{iFile}, ' failed to load'])
            %                 continue
            %             end
            %
            %             %QA
            %             planC = updatePlanFields(planC);
            %             indexS = planC{end};
            %
            %             %Check for mesh representation and load meshes into memory
            %             currDir = cd;
            %             meshDir = fileparts(which('libMeshContour.dll'));
            %             cd(meshDir)
            %             for strNum = 1:length(planC{indexS.structures})
            %                 if isfield(planC{indexS.structures}(strNum),'meshRep') && ~isempty(planC{indexS.structures}(strNum).meshRep) && planC{indexS.structures}(strNum).meshRep
            %                     try
            %                         calllib('libMeshContour','loadSurface',planC{indexS.structures}(strNum).strUID,planC{indexS.structures}(strNum).meshS)
            %                     catch
            %                         planC{indexS.structures}(strNum).meshRep    = 0;
            %                         planC{indexS.structures}(strNum).meshS      = [];
            %                     end
            %                 end
            %             end
            %             cd(currDir)
            %
            %             %Check dose-grid
            %             for doseNum = 1:length(planC{indexS.dose})
            %                 if planC{indexS.dose}(doseNum).zValues(2) - planC{indexS.dose}(doseNum).zValues(1) < 0
            %                     planC{indexS.dose}(doseNum).zValues = flipud(planC{indexS.dose}(doseNum).zValues);
            %                     planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,3);
            %                 end
            %             end
            %
            %             %Check whether uniformized data is in cellArray format.
            %             if ~isempty(planC{indexS.structureArray}) && iscell(planC{indexS.structureArray}(1).indicesArray)
            %                 planC = setUniformizedData(planC,planC{indexS.CERROptions});
            %                 indexS = planC{end};
            %             end
            %
            %             if length(planC{indexS.structureArrayMore}) ~= length(planC{indexS.structureArray})
            %                 for saNum = 1:length(planC{indexS.structureArray})
            %                     if saNum == 1
            %                         planC{indexS.structureArrayMore} = struct('indicesArray', {[]},...
            %                             'bitsArray', {[]},...
            %                             'assocScanUID',{planC{indexS.structureArray}(saNum).assocScanUID},...
            %                             'structureSetUID', {planC{indexS.structureArray}(saNum).structureSetUID});
            %
            %                     else
            %                         planC{indexS.structureArrayMore}(saNum) = struct('indicesArray', {[]},...
            %                             'bitsArray', {[]},...
            %                             'assocScanUID',{planC{indexS.structureArray}(saNum).assocScanUID},...
            %                             'structureSetUID', {planC{indexS.structureArray}(saNum).structureSetUID});
            %                     end
            %                 end
            %             end
            %
            %             %QA ends
            %
            %             %RadBio Correction
            %             ud.sumDose.doseMapS(planNum).AdjustmentType;
            
            %New dose name
            doseNameStr = ud.sumDose.doseMapS(planNum).NewDoseName;
            
            %             assocScan = 1;
            %
            %             planC = sumDose(dosesToSumV,dosesToSumV.^0,assocScan,doseNameStr,planC);
            %
            %             save_planC(planC,[], 'passed', ud.nameMapS(planNum).fullFileName);
            
            %Update doseMap and nameMap
            doseMapInitS = struct('DosesToSum',1,'NewDoseName','','AdjustmentType',1, 'maxDose',[],'save_to_disk',0);
            ud.sumDose.doseMapS(planNum) = doseMapInitS;
            
            ud.nameMapS(planNum).allDoseNames{end+1} = doseNameStr;
            
        end
        
        set(hFig,'userdata',ud)
        
        structureNameMapGUI('refresh_sum_dose')
        
        
    case 'REFRESH'
        
        nameMapS = ud.newNameMapS;
        structures_to_extract = ud.scanDir.strNamC;
        dose_to_extract = ud.scanDir.doseName;
        planNum = ud.scanDir.planNum;
        
        if isempty(nameMapS)
            return
        end
        
        % Plan-Name text handle
        [jnk,filenameStr] = fileparts(nameMapS(planNum).fullFileName);
        set(ud.handles.fixNamesH.plan_name, 'string',['Plan ',int2str(planNum),' of ',int2str(length(nameMapS)),': ', filenameStr]);
        
        ambigStructV = [];
        for i=1:length(nameMapS(planNum).structMap)
            if isempty(nameMapS(planNum).structMap{i}) || length(nameMapS(planNum).structMap{i})>1
                ambigStructV = [ambigStructV i];
            end
        end
        ambigDoseNum = [];
        if isempty(nameMapS(planNum).doseMap) || length(nameMapS(planNum).doseMap)>1
            ambigDoseNum = 1;
        end
        
        %Get all structure names for this plan
        allStructNamesC = [nameMapS(planNum).allStructureNames];
        
        %Get all dose names for this plan
        allDoseC = [nameMapS(planNum).allDoseNames];
        for doseNum = 1:length(allDoseC)
            if isempty(allDoseC{doseNum})
                allDoseC{doseNum} = [num2str(doseNum),'. (No Name)'];
            else
                allDoseC{doseNum} = [num2str(doseNum),'. ',allDoseC{doseNum}];
            end
        end
        
        %         % Ambigious Structure and Dose message handle
        %         msgTxt = '';
        %         if ~isempty(ambigStructV)
        %             msgTxt = [int2str(length(ambigStructV)),' strutures '];
        %         end
        %         if ~isempty(ambigDoseNum) && ~isempty(ambigStructV)
        %             msgTxt = [msgTxt, 'and 1 dose '];
        %         elseif ~isempty(ambigDoseNum)
        %             msgTxt = [msgTxt, '1 dose '];
        %         end
        %         if ~isempty(msgTxt)
        %             msgTxt = [msgTxt, 'could not be located in this plan. Please select structure / dose from the list below, then double click the matching name from list.'];
        %         else
        %             msgTxt = 'All structures and doses have been selected. Proceed to extract metrics';
        %         end
        %         set(ud.handles.fixNamesH.plan_message,'string',msgTxt)
        
        % Assign Structure Name handle
        %         set(ud.handles.fixNamesH.structure_popup, 'string',['- - -', structures_to_extract(ambigStructV)],'value',1,'userData',ambigStructV)
        %         set(ud.handles.fixNamesH.structure_list,'string',['- - -', allStructNamesC],'value',1)
        desired_struct_val = get(ud.handles.fixNamesH.desired_structure_list,'value');
        available_struct_val = get(ud.handles.fixNamesH.available_structure_list,'value');
        if desired_struct_val > length(structures_to_extract)+1
            desired_struct_val = 1;
        end
        if available_struct_val > length(allStructNamesC)+1
            available_struct_val = 1;
        end
        set(ud.handles.fixNamesH.desired_structure_list, 'string',['- - -', structures_to_extract],'value',desired_struct_val)
        set(ud.handles.fixNamesH.available_structure_list,'string',['- - -', allStructNamesC],'value',available_struct_val)
        
        % Assign Dose Name handle
        if ~iscell(dose_to_extract)
            dose_to_extract = {dose_to_extract};
        end
        if isempty(nameMapS(planNum).doseMap) || length(nameMapS(planNum).doseMap)>1
            set(ud.handles.fixNamesH.dose_popup, 'string', ['- - -', dose_to_extract],'value',2)
        else
            set(ud.handles.fixNamesH.dose_popup, 'string', ['- - -', dose_to_extract],'value',1)
        end
        set(ud.handles.fixNamesH.dose_list, 'string', ['- - -', allDoseC],'value',1)
        
        %Set text for assigned structures
        structures_to_extract = ud.scanDir.strNamC;
        
        if isempty(ud.newNameMapS)
            return
        end
        
        %Get all structure names for this plan
        allStructNamesC = [ud.newNameMapS(planNum).allStructureNames];
        
        strC = {};
        for i=1:length(ud.newNameMapS(planNum).structMap)
            if ~isempty(ud.newNameMapS(planNum).structMap{i}) && length(ud.newNameMapS(planNum).structMap{i}) == 1
                strC{end+1} = [structures_to_extract{i}, ' --> ', allStructNamesC{ud.newNameMapS(planNum).structMap{i}}];
            end
        end
        
        set(ud.handles.fixNamesH.structure_assign_txt5, 'string',strC)
        
        %Display assigned dose
        %Display text of assigned doses
        %Get all dose names for this plan
        allDoseC = [ud.newNameMapS(planNum).allDoseNames];
        for doseNum = 1:length(allDoseC)
            if isempty(allDoseC{doseNum})
                allDoseC{doseNum} = '(No Name)';
            else
                allDoseC{doseNum} = allDoseC{doseNum};
            end
        end
        
        dose_to_extract = ud.scanDir.doseName;
        
        strC = {};
        if ~isempty(ud.newNameMapS(planNum).doseMap) && length(ud.newNameMapS(planNum).doseMap) == 1
            strC = [dose_to_extract, ' --> ', num2str(ud.newNameMapS(planNum).doseMap), '. ', allDoseC{ud.newNameMapS(planNum).doseMap}];
        end
        
        set(ud.handles.fixNamesH.dose_assign_txt5, 'string',strC)
        
        set(ud.handles.fixNamesH.available_structure_list,'value',1)
        set(ud.handles.fixNamesH.dose_list,'value',1)
        
        
    case 'NEXT_PLAN'
        if ud.scanDir.planNum < length(ud.newNameMapS)
            ud.scanDir.planNum = ud.scanDir.planNum + 1;
            set(hFig,'userdata',ud)
            structureNameMapGUI('refresh')
        end
        
    case 'PREVIOUS_PLAN'
        if ud.scanDir.planNum > 1
            ud.scanDir.planNum = ud.scanDir.planNum - 1;
            set(hFig,'userdata',ud)
            structureNameMapGUI('refresh')
        end
        
    case 'SUM_DOSE_NEXT_PLAN'
        if ud.sumDose.planNum < length(ud.sumDose.doseMapS)
            structureNameMapGUI('DOSES_TO_SUM_SELECTED')
            ud = get(hFig,'userdata');
            ud.sumDose.planNum = ud.sumDose.planNum + 1;
            set(hFig,'userdata',ud)
            structureNameMapGUI('refresh_sum_dose')
        end
        
    case 'SUM_DOSE_PREVIOUS_PLAN'
        if ud.sumDose.planNum > 1
            structureNameMapGUI('DOSES_TO_SUM_SELECTED')
            ud = get(hFig,'userdata');
            ud.sumDose.planNum = ud.sumDose.planNum - 1;
            set(hFig,'userdata',ud)
            structureNameMapGUI('refresh_sum_dose')
        end
        
        
    case 'UPDATE_STRUCTURE_MAP'
        %         selection_type = get(hFig,'SelectionType');
        %         if strcmpi(selection_type,'normal')
        %             return
        %         end
        
        %         %get structure from the list
        %         structureExtractIndex = get(ud.handles.fixNamesH.structure_popup, 'value');
        %         structurePopUD = get(ud.handles.fixNamesH.structure_popup, 'userData');
        %         structurePlanIndex = get(ud.handles.fixNamesH.structure_list, 'value');
        
        planNum = ud.scanDir.planNum;
        
        %get structure from the list
        structureExtractIndex = get(ud.handles.fixNamesH.desired_structure_list,'value');
        structurePlanIndex = get(ud.handles.fixNamesH.available_structure_list,'value');
        
        %Update mapping
        if structureExtractIndex > 1
            if structurePlanIndex == 1
                ud.newNameMapS(planNum).structMap{(structureExtractIndex-1)} = [];
            else
                ud.newNameMapS(planNum).structMap{(structureExtractIndex-1)} = structurePlanIndex - 1;
            end
        else
            return
        end
        
        %Update list of assigned structures
        structures_to_extract = ud.scanDir.strNamC;
        
        if isempty(ud.newNameMapS)
            return
        end
        
        %Get all structure names for this plan
        allStructNamesC = [ud.newNameMapS(planNum).allStructureNames];
        
        strC = {};
        for i=1:length(ud.newNameMapS(planNum).structMap)
            if ~isempty(ud.newNameMapS(planNum).structMap{i}) && length(ud.newNameMapS(planNum).structMap{i}) == 1
                strC{end+1} = [structures_to_extract{i}, ' --> ', allStructNamesC{ud.newNameMapS(planNum).structMap{i}}];
            end
        end
        
        set(ud.handles.fixNamesH.structure_assign_txt5, 'string',strC)
        
        %Save userdata
        set(hFig,'userdata',ud)
        
        %Refresh
        structureNameMapGUI('refresh')
        
        
    case 'UPDATE_DOSE_MAP'
        
        doseExtractIndex = get(ud.handles.fixNamesH.dose_popup, 'value');
        dosePlanIndex = get(ud.handles.fixNamesH.dose_list, 'value');
        planNum = ud.scanDir.planNum;
        if doseExtractIndex > 1
            if dosePlanIndex == 1 && ~isempty(ud.newNameMapS(planNum).doseMap)
                ud.newNameMapS(planNum).doseMap(doseExtractIndex-1) = [];
            elseif dosePlanIndex > 1 && isempty(ud.newNameMapS(planNum).doseMap)
                ud.newNameMapS(planNum).doseMap = dosePlanIndex - 1;
            else
                ud.newNameMapS(planNum).doseMap(doseExtractIndex-1) = dosePlanIndex - 1;
            end
        else
            return
        end
        
        %Display text of assigned doses
        %Get all dose names for this plan
        allDoseC = [ud.newNameMapS(planNum).allDoseNames];
        for doseNum = 1:length(allDoseC)
            if isempty(allDoseC{doseNum})
                allDoseC{doseNum} = '(No Name)';
            else
                allDoseC{doseNum} = allDoseC{doseNum};
            end
        end
        
        dose_to_extract = ud.scanDir.doseName;
        
        strC = {};
        if ~isempty(ud.newNameMapS(planNum).doseMap) && length(ud.newNameMapS(planNum).doseMap) == 1 && ud.newNameMapS(planNum).doseMap ~= 0
            strC = [dose_to_extract, ' --> ', allDoseC{ud.newNameMapS(planNum).doseMap}];
        end
        
        set(ud.handles.fixNamesH.dose_assign_txt5, 'string',strC)
        
        
        %Save userdata
        set(hFig,'userdata',ud)
        
        %Refresh
        structureNameMapGUI('refresh')
        
        
    case 'UNDO'
        planNum = ud.scanDir.planNum;
        ud.newNameMapS(planNum) = ud.nameMapS(planNum);
        
        %Save userdata
        set(hFig,'userdata',ud)
        
        %Refresh
        structureNameMapGUI('refresh')
        
    case 'LOAD_CERR'
        CERR('CERRSLICEVIEWER')
        planNum = ud.scanDir.planNum;
        sliceCallBack('OPENNEWPLANC',ud.nameMapS(planNum).fullFileName)
        
    case 'COHORT_VIEVER'
        
        nameMapS = ud.newNameMapS;
        if isempty(nameMapS)
            return
        end
        
        planIndicesV = get(ud.handles.reviewPlansH.allPlans_list,'value');
        
        structureIndex = get(ud.handles.reviewPlansH.allStruct_list,'value');
        
        for i=1:length(planIndicesV)
            fileNamesC{i} = nameMapS(planIndicesV(i)).fullFileName;
        end
        
        for i=1:length(planIndicesV)
            structures_to_extractC{i} = nameMapS(planIndicesV(i)).structMap{structureIndex};
            dose_to_extractC{i} = nameMapS(planIndicesV(i)).doseMap;
        end
        
        createPlanCFromFiles(fileNamesC, structures_to_extractC, dose_to_extractC);
        
        
    case 'NEXT_COHORT'
        planNamesC = get(ud.handles.reviewPlansH.allPlans_list,'string');
        planIndicesV = get(ud.handles.reviewPlansH.allPlans_list,'value');
        newPlanIndicesV = planIndicesV + 16;
        if newPlanIndicesV(end) > length(planNamesC)
            newPlanIndicesV = newPlanIndicesV - (newPlanIndicesV(end)-length(planNamesC));
        end
        set(ud.handles.reviewPlansH.allPlans_list,'value',newPlanIndicesV);
        
        
    case 'PREV_COHORT'
        planIndicesV = get(ud.handles.reviewPlansH.allPlans_list,'value');
        newPlanIndicesV = planIndicesV - 16;
        if newPlanIndicesV(1) < 1
            newPlanIndicesV = 1:16;
        end
        set(ud.handles.reviewPlansH.allPlans_list,'value',newPlanIndicesV);
        
        
    case 'GET_DREES_FILENAME'
        [fname, pname] = uiputfile({'*.mat','DREES Plans (*.mat)'; '*.xlsx','SPSS (MS-Excel)';},'Saved Filename');
        drees_fileName = fullfile(pname,fname);
        set(ud.handles.extractMetricsH.drees_fileName_push,'string',[fname, ' (',pname,')'],'fontsize',9)
        ud.drees_fileName = drees_fileName;
        set(hFig,'userdata',ud)
        
    case 'GET_EXCEL_DATA'
        try
            %Get Excel File
            [fName,pName] = uigetfile('.xls','Select Excel file containing data');
            if isnumeric(fName)
                return;
            end
            xlFile = fullfile(pName,fName);
            [num,txt,raw] = xlsread(xlFile);
            
            columnNameRawC = {};
            indNaN = [];
            for i = 1:length(raw(1,:))
                if ~isnan(raw{1,i})
                    columnNameRawC{end+1} = raw{1,i};
                else
                    indNaN = [indNaN i];
                end
            end
            
            raw(:,indNaN) = [];
            
            %Get FileNames to match with DVH extraction
            [selIndFileName, OK] = listdlg('ListString',columnNameRawC,'SelectionMode','single','PromptString','Select Column that matches CERR fileNames','listSize',[250 400]);
            if OK && (length(selIndFileName) == 1)
                rowIndicesV = [];
                for j=1:size(raw,1)-1
                    if ~isnan(raw{j+1,selIndFileName})
                        excel_fileNameC{j} = raw{j+1,selIndFileName};
                        rowIndicesV = [rowIndicesV j];
                    end
                end
            else
                error('Please select ONE column and try again')
            end
            
            ud.ExcelDataS.excel_fileNameC = excel_fileNameC;
            
            %             ddbs_fileNameC = {ddbs(:).fileName};
            %             ddbs_fileNameC = strtok(ddbs_fileNameC,'.');
            %
            %             [jnk,indexMapV] = ismember(ddbs_fileNameC,excel_fileNameC);
            
            %replace spaces with underscores
            for i=1:size(raw,2)
                raw{1,i} = repSpaceHyp(raw{1,i});
            end
            
            %     %removes columns with non-numeric data
            %     indToRemove  = [];
            %     for i=1:size(raw,2)
            %         if ~isnumeric([raw{2:size(raw,1),i}]) || all(isnan([raw{2:size(raw,1),i}]))
            %             indToRemove = [indToRemove i];
            %         end
            %     end
            %     raw(:,indToRemove) = [];
            
            %get variables from the selection list
            [selMetricsIndV, OK] = listdlg('ListString',raw(1,:),'PromptString','Select Metrics');
            
            %get outcome from the selection list
            [selOutcomesIndV, OK] = listdlg('ListString',raw(1,:),'PromptString','Select Outcome/s');
            
            ud.ExcelDataS.raw = raw;
            ud.ExcelDataS.selMetricsIndV = selMetricsIndV;
            ud.ExcelDataS.selOutcomesIndV = selOutcomesIndV;
            
            set(hFig,'userdata',ud)
            
            %             %set metrics fields
            %             for i=1:length(selMetricsIndV)
            %                 for j = 1:length(indexMapV)
            %                     if isnumeric(raw{indexMapV(j)+1,selMetricsIndV(i)})
            %                         ddbs(j).(raw{1,selMetricsIndV(i)}) = raw{indexMapV(j)+1,selMetricsIndV(i)};
            %                     else
            %                         ddbs(j).(raw{1,selMetricsIndV(i)}) = NaN;
            %                     end
            %                 end
            %             end
            %
            %             %set outcomes field
            %             for i=1:length(selOutcomesIndV)
            %                 for j = 1:length(indexMapV)
            %                     if isnumeric(raw{indexMapV(j)+1,selOutcomesIndV(i)})
            %                         ddbs(j).outcome.(raw{1,selOutcomesIndV(i)}) = raw{indexMapV(j)+1,selOutcomesIndV(i)};
            %                     else
            %                         ddbs(j).outcome.(raw{1,selOutcomesIndV(i)}) = NaN;
            %                     end
            %                 end
            %             end
            
        catch
            errordlg('There was an errror reading the DVH data. Please check the data format and try again.','DVH Import error','modal')
        end
        
        return;
        
        
    case 'FRACTIONATION_CORRECTION_SELECTED'
        
        fractionType = get(ud.handles.sumDosesH.radbioCorrect_dose_popup,'value');
        if fractionType == 3
            set([ud.handles.sumDosesH.numFraction_str, ud.handles.sumDosesH.numFraction_edit, ...
                ud.handles.sumDosesH.stdFraction_str, ud.handles.sumDosesH.stdFraction_edit, ...
                ud.handles.sumDosesH.abRatio_str, ud.handles.sumDosesH.abRatio_edit, ud.handles.sumDosesH.applyAll_check],...
                'visible','on')
        else
            set([ud.handles.sumDosesH.numFraction_str, ud.handles.sumDosesH.numFraction_edit, ...
                ud.handles.sumDosesH.stdFraction_str, ud.handles.sumDosesH.stdFraction_edit, ...
                ud.handles.sumDosesH.abRatio_str, ud.handles.sumDosesH.abRatio_edit, ud.handles.sumDosesH.applyAll_check],...
                'visible','off')

        end

        
    case 'APPLY_FRACT_CORRECT_TO_ALL'
        
        abRatio = get(ud.handles.sumDosesH.abRatio_edit,'string');  
        numFractions = get(ud.handles.sumDosesH.numFraction_edit,'string');
        stdFracSiz = get(ud.handles.sumDosesH.stdFraction_edit,'string'); 
        abRatio = str2double(abRatio);        
        numFractions = str2double(numFractions);
        stdFracSiz = str2double(stdFracSiz);        
        for planNum=1:length(ud.newNameMapS)
            ud.sumDose.doseMapS(planNum).AdjustmentType = 3;
            ud.sumDose.doseMapS(planNum).abRatio = abRatio;
            ud.sumDose.doseMapS(planNum).numFractions = numFractions;
            ud.sumDose.doseMapS(planNum).stdFractionSize = stdFracSiz;
        end
        set(hFig,'userdata',ud)
        
    case 'APPLY_FRACT_CORRECT_VALS'
        planNum = ud.sumDose.planNum;        
        abRatio = get(ud.handles.sumDosesH.abRatio_edit,'string');  
        numFractions = get(ud.handles.sumDosesH.numFraction_edit,'string');
        stdFracSiz = get(ud.handles.sumDosesH.stdFraction_edit,'string');        
        abRatio = str2double(abRatio);        
        numFractions = str2double(numFractions);
        stdFracSiz = str2double(stdFracSiz);
        ud.sumDose.doseMapS(planNum).AdjustmentType = 3;
        ud.sumDose.doseMapS(planNum).abRatio = abRatio;
        ud.sumDose.doseMapS(planNum).numFractions = numFractions;        
        ud.sumDose.doseMapS(planNum).stdFractionSize = stdFracSiz;
        
        set(hFig,'userdata',ud)
        
        
    case 'SAVE_EXTRACTED_METRICS'
        
        %get export format (drees, oqa ...)
        exportFormatVal = get(ud.handles.extractMetricsH.export_format_popup,'value');

        
        if ~isfield(ud,'drees_fileName') && exportFormatVal < 4
            errordlg('Please select DREES fileName to store data','FileName Required','modal')
            return
        end
        
        %get user-defined metrics
        additionalMetricsStr = get(ud.handles.extractMetricsH.additonal_metrics_edit,'string');
        additionalMetricsC = {};
        if ~isempty(additionalMetricsStr)
            indComma = strfind(additionalMetricsStr,',');
            if isempty(indComma)
                additionalMetricsC{1} = additionalMetricsStr;
            else
                additionalMetricsC{1} = strtrim(additionalMetricsStr(1:indComma(1)-1));
            end
            for i=1:length(indComma)-1
                additionalMetricsC{end+1} = strtrim(additionalMetricsStr(indComma(i)+1:indComma(i+1)-1));
            end
            if ~isempty(indComma)
                additionalMetricsC{end+1} = strtrim(additionalMetricsStr(indComma(end)+1:end));
            end
            
        end
                
        %Get waitbar handles
        waitbarH = ud.handles.extractMetricsH.waitbar_status_frame2;
        statusStrH = ud.handles.extractMetricsH.percent_text;
        
        if exportFormatVal == 1 || exportFormatVal == 3 %DREES or SPSS format
            if isempty(ud.drees_fileName)
                error('Please select a path/name for DREES file')
            end
            ddbs = [];
            ddbsIndex = 1;
            for planNum=1:length(ud.newNameMapS)
                
                %Update Waitbar
                drawnow
                set(waitbarH,'position',[0.05 0.15 0.9*planNum/length(ud.newNameMapS) 0.04])
                set(statusStrH,'string',['Exporting ',int2str(planNum),' out of ',int2str(length(ud.newNameMapS))])
                
                %Load CERR plan
                try
                    planC = loadPlanC(ud.newNameMapS(planNum).fullFileName, tempdir);
                    planC = updatePlanFields(planC);                    
                    planC = quality_assure_planC(ud.newNameMapS(planNum).fullFileName, planC);
                    indexS = planC{end};                                       
                    
                    %Sum doses if required
                    dosesToSumV = ud.sumDose.doseMapS(planNum).DosesToSum;
                    
                    if length(dosesToSumV) > 1
                        
                        %New dose name
                        doseNameStr = ud.sumDose.doseMapS(planNum).NewDoseName;
                        assocScan = 1;
                        planC = sumDose(dosesToSumV,dosesToSumV.^0,assocScan,doseNameStr,planC);
                        
                        %Save dose to plan on disk
                        if ud.sumDose.doseMapS(planNum).save_to_disk
                            save_planC(planC,[], 'passed', ud.nameMapS(planNum).fullFileName);
                        end
                        
                    end
                    
                    %Get Dose-units and convert to Gy
                    if ~isempty(ud.newNameMapS(planNum).doseMap) && (strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGy') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGys') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGray') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGrays'))
                        planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseArray = planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseArray * 0.01;
                        planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits = 'Grays';
                    end  
                    
                    % Fractionation correction
                    adjustType = ud.sumDose.doseMapS(planNum).AdjustmentType;
                    if adjustType == 3 % Nf
                        numFractions = ud.sumDose.doseMapS(planNum).numFractions;
                        abRatio      = ud.sumDose.doseMapS(planNum).abRatio;
                        fractionSize = ud.sumDose.doseMapS(planNum).stdFractionSize;
                        correctedDoseM = planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseArray;
                        % BED
                        correctedDoseM = correctedDoseM .* ...
                            (1+correctedDoseM/numFractions/abRatio);
                        % EQD2
                        correctedDoseM = correctedDoseM / (1+fractionSize/abRatio);
                        
                        planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseArray = ...
                            correctedDoseM;                        
                    end

                    
                catch
                    disp([ud.newNameMapS(planNum).fullFileName, ' failed to load'])
                    continue
                end
                %Extract Metrics for each plan
                %ddbsIndex = 1;
                [jnk, fileName] = fileparts(ud.newNameMapS(planNum).fullFileName);
                ddbs(ddbsIndex).fileName = fileName;
                patientName = planC{indexS.scan}(1).scanInfo(1).patientName;
                if iscell(patientName)
                    patientName = patientName{1};
                end
                indReplaceV = strfind(patientName,'^');
                if ~isempty(indReplaceV)  
                    patientName(indReplaceV) = ',';
                end
                ddbs(ddbsIndex).patientName = patientName;
                for j=1:length(ud.scanDir.strNamC)
                    if ~isempty(ud.newNameMapS(planNum).structMap{j}) && length(ud.newNameMapS(planNum).structMap{j}) == 1   % Do not check for dose % && ~isempty(ud.newNameMapS(planNum).doseMap)
                        if  ~isempty(ud.newNameMapS(planNum).doseMap)
                            try
                                numBins = 500;
                                if exportFormatVal == 1
                                    [planC, d, v] = getDVHMatrix(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap);
                                else
                                    [planC, d, v] = getDVHMatrix(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, numBins);
                                end   
                                %d = d*(perFractionDose+abRatio)/(2+abRatio);
                                ddbs(ddbsIndex).(['dvh_',repSpaceHyp(ud.scanDir.strNamC{j})]) = [d(:)';v(:)'];
                              
                            catch
                                warning('Could not extract DVH')
                            end
                        end
                        
                        % Extract user-defined metrics
                        for k = 1:length(additionalMetricsC)
                            try
                                ddbs(ddbsIndex).([additionalMetricsC{k},'_',repSpaceHyp(ud.scanDir.strNamC{j})]) = feval(additionalMetricsC{k}, planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap);
                            catch
                                warning(['Could not extract ', additionalMetricsC{k}, ' metric'])
                            end
                        end
                        
                    end
                end
                
                ddbsIndex = ddbsIndex + 1;
                
            end
            
            %Populate data from Excel file
            try
                raw = ud.ExcelDataS.raw;
                selMetricsIndV = ud.ExcelDataS.selMetricsIndV;
                selOutcomesIndV = ud.ExcelDataS.selOutcomesIndV;
                excel_fileNameC = ud.ExcelDataS.excel_fileNameC;
                
                ddbs_fileNameC = {ddbs(:).fileName};
                ddbs_fileNameC = strtok(ddbs_fileNameC,'.');
                excel_fileNameC = strtok(excel_fileNameC,'.');
                for ex_ind = 1:length(excel_fileNameC)
                    excel_fileNameC{ex_ind} = num2str(excel_fileNameC{ex_ind});
                end
                [jnk,indexMapV] = ismember(strtok(lower(ddbs_fileNameC),'_'),lower(excel_fileNameC));
                
                %set metrics fields
                for i=1:length(selMetricsIndV)
                    for j = 1:length(indexMapV)
                        if indexMapV(j) ~= 0
                            if isnumeric(raw{indexMapV(j)+1,selMetricsIndV(i)})
                                ddbs(j).(raw{1,selMetricsIndV(i)}) = raw{indexMapV(j)+1,selMetricsIndV(i)};
                            else
                                ddbs(j).(raw{1,selMetricsIndV(i)}) = NaN;
                            end
                        end
                    end
                end
                
                %set outcomes field
                for i=1:length(selOutcomesIndV)
                    for j = 1:length(indexMapV)
                        if isfield(ddbs,'outcome') && ~isstruct(ddbs(j).outcome)
                            ddbs(j).outcome = struct();
                        elseif ~isfield(ddbs,'outcome')
                            ddbs(j).outcome = struct();
                        end
                        if isnumeric(raw{indexMapV(j)+1,selOutcomesIndV(i)}) || islogical(raw{indexMapV(j)+1,selOutcomesIndV(i)})
                            ddbs(j).outcome.(raw{1,selOutcomesIndV(i)}) = double(raw{indexMapV(j)+1,selOutcomesIndV(i)});
                        else
                            ddbs(j).outcome.(raw{1,selOutcomesIndV(i)}) = NaN;
                        end
                    end
                end
                
            catch
                
            end
            
            
            
            %Get file name to store
            %[dreesFileName, dreesPathName] = uiputfile('*.mat', 'Name DREES file');
            %save(fullfile(dreesPathName,dreesFileName), 'ddbs');
            if exportFormatVal == 1
                save(ud.drees_fileName, 'ddbs');
                set(statusStrH,'string','DREES-file written to disk.')
            elseif exportFormatVal == 3
                % Find fields containing DVHs
                fieldNms = fieldnames(ddbs);
                dvhFieldsC = strfind(fieldNms,'dvh_');
                dvhFieldIndV = find(~cellfun('isempty',dvhFieldsC));
                numDVHs = length(dvhFieldIndV);
                for planNum = 1:length(ddbs)
                    %Update Waitbar
                    drawnow
                    set(waitbarH,'position',[0.05 0.15 0.9*planNum/length(ud.newNameMapS) 0.04])
                    set(statusStrH,'string',['Exporting ',int2str(planNum),' out of ',int2str(length(ud.newNameMapS))])
                    
                    
                    MRN = ddbs(planNum).fileName;
                    MRN = strtok(fliplr(MRN),'\');
                    MRN = fliplr(MRN);
                    patientName = ddbs(planNum).patientName;
                    colStart = (planNum-1)*numDVHs*2 + 1;
                    colPtNameStr = xlsColNum2Str(colStart);
                    rowPtNameStr = num2str(1);
                    colMRNStr = xlsColNum2Str(colStart);
                    rowMRNStr = num2str(2);
                    xlswrite(ud.drees_fileName,{patientName},'Sheet1',[colPtNameStr{:},rowPtNameStr,':',colPtNameStr{:},rowPtNameStr]);
                    xlswrite(ud.drees_fileName,{MRN},'Sheet1',[colMRNStr{:},rowMRNStr,':',colMRNStr{:},rowMRNStr]);
                    
                    for fieldNum = 1:length(dvhFieldIndV)
                        structureName = fieldNms{dvhFieldIndV(fieldNum)};
                        structureName = structureName(5:end);                       
                        dvhColStart = xlsColNum2Str(colStart + (fieldNum-1)*2);
                        rowDVHStr = num2str(3);
                        xlswrite(ud.drees_fileName,{structureName},'Sheet1',[dvhColStart{:},rowDVHStr,':',dvhColStart{:},rowDVHStr]);
                        dvh = ddbs(planNum).(fieldNms{dvhFieldIndV(fieldNum)});
                        if ~isempty(dvh)
                            dvh = dvh';
                            dvh(:,1) = dvh(:,1) * 100; % convert to cGy for SPSS
                            numDVHpts = size(dvh,1);
                            clear dvh_to_write;
                            dvh_to_write(1:2:numDVHpts*2,:) = dvh;
                            dvh_to_write(2:2:numDVHpts*2,:) = dvh;
                            dvh_to_write(1:2:numDVHpts*2,1) = dvh_to_write(1:2:numDVHpts*2,1) - dvh(1,1);
                            dvh_to_write(2:2:numDVHpts*2,1) = dvh_to_write(2:2:numDVHpts*2,1) + dvh(1,1);
                            dvh_to_write(numDVHpts*2+1,1) = dvh_to_write(numDVHpts*2,1);
                            dvh_to_write(numDVHpts*2+1,2) = 0;
                            if size(dvh_to_write,1) > 2*numBins+1
                                dvh_to_write(2*numBins-1:2*numBins,1) =  dvh_to_write(end-1:end,1);
                                dvh_to_write(2*numBins-1:2*numBins+1,2) =  dvh_to_write(end-2:end,2);
                                dvh_to_write(2*numBins+2:end,:) = [];
                            end
                            dvhColEnd = xlsColNum2Str(colStart + (fieldNum-1)*2 + 1);
                            dvhRowStart = num2str(4);
                            dvhRowEnd = num2str(4+size(dvh_to_write,1)-1);
                            xlswrite(ud.drees_fileName,dvh_to_write,'Sheet1',[dvhColStart{:},dvhRowStart,':',dvhColEnd{:},dvhRowEnd]); 
                        end
                    end
                    
                end
                set(statusStrH,'string','SPSS-file written to disk.')
            end
            
            
        elseif exportFormatVal == 2 %OQA format
            
            %Connect to OQA database
            feature jit off
            setpref('Internet','SMTP_Server','128.252.17.80');
            setpref('Internet','E_mail','aapte@radonc.wustl.edu');
            
            %Load database driver
            javaaddpath('R:\OQA\MySqlConnector\mysql-connector-java-3.0.17-ga-bin.jar')
            
            %Extablish Database connection
            setdbprefs({'NullStringRead';'NullNumberRead';'DataReturnFormat'},{'';'';'numeric'})
            %OAQ  Development
            %conn = database('oqa_dev','aapte','aa#9135','com.mysql.jdbc.Driver','jdbc:mysql://10.39.68.225:3306/oqa_dev');
            %OAQIN  Development
            conn = database('oqain_dev','aapte','aa#9135','com.mysql.jdbc.Driver','jdbc:mysql://10.39.68.225:3306/oqain_dev');
            
            
            javaaddpath('/Volumes/HOME/Projects/CERR/CERR4pt0beta2_25_Jan_2011/CERR_Data_Extraction/postgresql84jdbc3.jar')
            
            conn = database('cerr','cerr','cerr~data','org.postgresql.Driver','jdbc:postgresql://128.9.132.88:5432/cerr');
            
            doseCutoffV = 0:0.25:100;
            
            unsuccssfulPlans = {};
            
            %Loop thru all patients, find matching id in database and store dvh data
            for planNum=1:length(ud.newNameMapS)
                
                %Update Waitbar
                drawnow
                set(waitbarH,'position',[0.05 0.18 0.9*planNum/length(ud.newNameMapS) 0.04])
                set(statusStrH,'string',['Exporting ',int2str(planNum),' out of ',int2str(length(ud.newNameMapS))])
                
                %Get RT number from filename
                [pathStr,fileStr] = fileparts(ud.newNameMapS(planNum).fullFileName);
                indUscore = strfind(fileStr,'_');
                indRT = strfind(fileStr,'RT');
                IDStr = fileStr(indRT+2:indUscore(1)-1);
                
                
                %Find the match in database
                sqlq_find_patient = ['Select id from patients where (jid_pt like ''%', IDStr, '%''', ' or mid_pt like ''%', IDStr, '%'')'];
                pat_raw = exec(conn, sqlq_find_patient);
                pat = fetch(pat_raw);
                pat = pat.Data;
                if isempty(pat)
                    disp(['Could not find this patient with ID = ', IDStr, ' in database'])
                    unsuccssfulPlans{end+1,1} = IDStr;
                    unsuccssfulPlans{end,2} = 'Could not find this patient with this ID';
                    continue
                elseif size(pat,1) > 1
                    disp(['Multiple matches found for ID = ', IDStr, ' in database'])
                    unsuccssfulPlans{end+1,1} = IDStr;
                    unsuccssfulPlans{end,2} = 'Multiple matches found for ID';
                    continue
                end
                
                %Load CERR plan
                try
                    planC = loadPlanC(ud.newNameMapS(planNum).fullFileName, tempdir);
                    planC = updatePlanFields(planC);
                    % Quality Assurance
                    planC = quality_assure_planC(ud.newNameMapS(planNum).fullFileName, planC);
                    
                    indexS = planC{end};                    
                   
                    %Sum doses if required
                    dosesToSumV = ud.sumDose.doseMapS(planNum).DosesToSum;
                    
                    if length(dosesToSumV) > 1
                        
                        %New dose name
                        doseNameStr = ud.sumDose.doseMapS(planNum).NewDoseName;
                        assocScan = 1;
                        planC = sumDose(dosesToSumV,dosesToSumV.^0,assocScan,doseNameStr,planC);
                        
                        %Save dose to plan on disk
                        if ud.sumDose.doseMapS(planNum).save_to_disk
                            save_planC(planC,[], 'passed', ud.nameMapS(planNum).fullFileName);
                        end
                        
                    end
                    
                catch
                    disp([ud.newNameMapS(planNum).fullFileName, ' failed to load'])
                    unsuccssfulPlans{end+1,1} = IDStr;
                    unsuccssfulPlans{end,2} = 'CERR plan failed to load';
                    continue
                end
                
                %Store Dx,Vx values
                colnames = {'patients_id','therapy_instance_q71','plan_instance_q71','structure_name_q71','std_structure_name_q71','dosebin_q71','vol_cc_q71','vol_pct_q71','vol_pct_bin_q71','dose_for_vol_bin_q71'};
                colnamesStats = {'patients_id','therapy_instance_q72','plan_instance_q72','structure_name_q72','std_structure_name_q72','mean_dose_q72','max_dose_q72','min_dose_q72','max_dose_hot2cc_q72'};
                
                %                 for i=1:length(doseCutoffV)
                %                     x = doseCutoffV(i);
                %                     if floor(x) == x
                %                         colnames = [colnames, ['d',num2str(x)]];
                %                     else
                %                         if (x-floor(x))*100 == 50
                %                             colnames = [colnames, ['d',num2str(floor(x)),'pt5']];
                %                         else
                %                             colnames = [colnames, ['d',num2str(floor(x)),'pt',num2str((x-floor(x))*100)]];
                %                         end
                %                     end
                %                 end
                %                 for i=1:length(doseCutoffV)
                %                     x = doseCutoffV(i);
                %                     if floor(x) == x
                %                         colnames = [colnames, ['v',num2str(x)]];
                %                     else
                %                         if (x-floor(x))*100 == 50
                %                             colnames = [colnames, ['v',num2str(floor(x)),'pt5']];
                %                         else
                %                             colnames = [colnames, ['v',num2str(floor(x)),'pt',num2str((x-floor(x))*100)]];
                %                         end
                %                     end
                %                 end
                
                %                 colnames = [colnames, 'mean_dose'];
                %                 colnames = [colnames, 'max_dose'];
                %                 colnames = [colnames, 'min_dose'];
                %                 colnames = [colnames, 'dvh_dose_units_q57'];
                
                %Get Dose-units and convert to Gy
                if ~isempty(ud.newNameMapS(planNum).doseMap) && (strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGy') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGys') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGray') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGrays'))
                    planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseArray = planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseArray * 0.01;
                    planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits = 'Grays';
                end
                
                %Get therapy instance, if possible
                indP = strfind(pathStr,'P-');
                if isempty(indP)
                    plan_instance = 'P-1';
                else
                    plan_instance = pathStr(indP:indP+2);
                end
                
                %Get plan instance, if possible
                indT = strfind(pathStr,'T-');
                if isempty(indT)
                    therapy_instance = pathStr(indT:indT+2);
                else
                    therapy_instance = 'T-1';
                end
                
                for j=1:length(ud.scanDir.strNamC)
                    
                    %                     sqlq = 'select max(id) from dvh_values';
                    %                     curs = exec(conn, sqlq);
                    %                     if curs.data ~= 0
                    %                         curs = fetch(curs);
                    %                     end
                    
                    if isempty(ud.newNameMapS(planNum).structMap{j}) || isempty(ud.newNameMapS(planNum).doseMap) || length(ud.newNameMapS(planNum).structMap{j})>1
                        continue
                    end
                    
                    newRecC = {};
                    
                    newRecC{1,1} = pat;
                    newRecC{1,2} = therapy_instance;
                    newRecC{1,3} = plan_instance;
                    newRecC{1,4} = planC{indexS.structures}(ud.newNameMapS(planNum).structMap{j}).structureName;
                    newRecC{1,5} = ud.scanDir.strNamC{j};
                    
                    %setdbprefs('DataReturnFormat','cellarray');
                    setdbprefs({'NullStringRead';'NullStringWrite';'NullNumberRead';'NullNumberWrite'},...
                        {'';'';'';''});
                    
                    %Compute DVH if not already present in planC
                    try
                        [planC] = getDVHMatrix(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap);
                    catch
                        disp(['Could not compute DVH for ',ud.newNameMapS(planNum).fullFileName])
                        if ~isempty(unsuccssfulPlans) && strcmpi(unsuccssfulPlans{end,1},IDStr) && strcmpi(unsuccssfulPlans{end,2},'Could not compute DVH')
                        else
                            unsuccssfulPlans{end+1,1} = IDStr;
                            unsuccssfulPlans{end,2} = 'Could not compute DVH';
                        end
                        continue
                    end
                    
                    for xIndex = 1:length(doseCutoffV)
                        newRecWithDVHC = newRecC;
                        %DVH values
                        newRecWithDVHC{end+1} = doseCutoffV(xIndex);
                        newRecWithDVHC{end+1} = Vx(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, doseCutoffV(xIndex), 'Absolute');
                        newRecWithDVHC{end+1} = Vx(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, doseCutoffV(xIndex), 'Percent');
                        newRecWithDVHC{end+1} = doseCutoffV(xIndex);
                        newRecWithDVHC{end+1} = Dx(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, doseCutoffV(xIndex));
                        insert(conn,'dose_volume_values',colnames,newRecWithDVHC);
                    end
                    
                    %DVH Stats
                    newRecWithDVHStatsC = newRecC;
                    newRecWithDVHStatsC{end+1} = meanDose(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, 'Absolute');
                    newRecWithDVHStatsC{end+1} = maxDose(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, 'Absolute');
                    newRecWithDVHStatsC{end+1} = minDose(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, 'Absolute');
                    structVolume = getStructureVol(ud.newNameMapS(planNum).structMap{j},planC);
                    pctVolume = 2/structVolume*100;
                    newRecWithDVHStatsC{end+1} = Dx(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, pctVolume);
                    insert(conn,'dose_volume_stats',colnamesStats,newRecWithDVHStatsC);
                    
                    %                     mean_mertic = meanDose(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, 'Absolute');
                    %                     newRecC{1,end+1} = mean_mertic;
                    %
                    %                     max_mertic = maxDose(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, 'Absolute');
                    %                     newRecC{1,end+1} = max_mertic;
                    %
                    %                     min_mertic = minDose(planC, ud.newNameMapS(planNum).structMap{j}, ud.newNameMapS(planNum).doseMap, 'Absolute');
                    %                     newRecC{1,end+1} = min_mertic;
                    
                    %d0 = maxDose
                    %newRecC{1,6} = max_mertic;
                    
                    %                     %Dose Units (Gy)
                    %                     newRecC{end+1} = 'Gy';
                    
                    %insert new DVH
                    %insert(conn,'dvh_values',colnames,newRecC);
                    
                end
                
                clear global planC
                
            end
            
            %Open-up excel file with unsuccessful plans.
            unsuccssfulPlans = [{'ID','Reason Failed'}; unsuccssfulPlans];
            
            fName = [tempdir,'OQA_DVH_fill.xls'];
            try
                delete(fName)
            end
            xlswrite(fName,unsuccssfulPlans)
            winopen(fName);
            
        elseif exportFormatVal == 4 %RADRESEARCH Database
            
            feature jit off
            
            %Connect to RADRESEARCH database
            driver = 'com.mysql.jdbc.Driver';
            databaseurl = 'jdbc:mysql://MMPH0005:3306/';
            username = 'root';
            password = '';
            instance = 'radresearch';
            setdbprefs({'NullStringRead';'NullNumberRead';'DataReturnFormat';'errorhandling'},{'';'NaN';'structure';'report'})
            
            %javaaddpath('G:\Projects\mysql_connector\mysql-connector-java-5.1.36-bin.jar')
            conn = database(instance,username,password,driver,databaseurl);
            
            for planNum=1:length(ud.newNameMapS)
                
                %Update Waitbar
                drawnow
                set(waitbarH,'position',[0.05 0.18 0.9*planNum/length(ud.newNameMapS) 0.04])
                set(statusStrH,'string',['Exporting ',int2str(planNum),' out of ',int2str(length(ud.newNameMapS))])
                
                %Load CERR plan
                try
                    planC = loadPlanC(ud.newNameMapS(planNum).fullFileName, tempdir);
                    planC = updatePlanFields(planC);
                    planC = quality_assure_planC('', planC);
                catch
                    continue;
                end
                
                [~,fnam] = fileparts(ud.newNameMapS(planNum).fullFileName);
                mrn = strtok(fnam,'-');
                
                %Find the matching patient in the database
                sqlq_find_patient = ['Select id from patient where MRN = ''', mrn,''''];
                pat_raw = exec(conn, sqlq_find_patient);
                pat = fetch(pat_raw);
                pat = pat.Data;
                if isstruct(pat)
                    patient_id = pat.id;
                    continue; % duplicate upload!
                else
                    patient_id = [];
                end
                
                %Insert New patient to database
                if isempty(patient_id)
                    institution = 'MSKCC';
                    insert(conn,'patient',{'MRN','institution','cerr_file_location'},{mrn,institution,ud.newNameMapS(planNum).fullFileName});
                    sqlq_find_patient = ['Select id from patient where MRN = ''', mrn,''''];
                    pat_raw = exec(conn, sqlq_find_patient);
                    pat = fetch(pat_raw);
                    pat = pat.Data;
                    if isstruct(pat)
                        patient_id = pat.id;
                    end
                end

                strNum = ud.newNameMapS(planNum).structMap{1};

                %Write "cooccurance features" to database
                [energy,contrast,Entropy,Homogeneity,standard_dev,Ph,Slope] = getHaralicParams(strNum, planC);
                insert(conn,'coOccur',{'patient_id','energy','entropy','homogenity','contrast'},{patient_id,energy,Entropy,Homogeneity,contrast});
                
                %Write "shape features" database
                [Eccentricity,EulerNumber,Solidity,Extent] = getShapeParams(strNum,planC);
                insert(conn,'shape',{'patient_id','eccentricity','eulerNumber','solidity','extent'},{patient_id,Eccentricity,EulerNumber,Solidity,Extent});
                                
                %Write "zone size features" database
                numLevels = 16;
                [SRE,LRE,IV,RLV,RP,LIRE,HIRE,LISRE,HISRE,LILRE,HILRE] = ...
                getSizeParams(strNum,numLevels,planC);
                insert(conn,'zoneSize',{'patient_id','SRE','LRE','IV','RLV',...
                    'RP','LIRE','HIRE','LISRE','HISRE','LILRE','HILRE'},...
                    {patient_id,SRE,LRE,IV,RLV,RP,LIRE,HIRE,LISRE,HISRE,LILRE,HILRE});

                %Write "statistics features" database
                [RadiomicsFirstOrder] = radiomics_first_order_stats(planC,strNum);             
                insert(conn,'statistics',{'patient_id','min', 'max', 'mean',...
                    'scanRange', 'std', 'var', 'median', 'skewness', 'kurtosis',...
                    'RMS', 'totalEnergy', 'MD'},{patient_id,RadiomicsFirstOrder.min RadiomicsFirstOrder.max RadiomicsFirstOrder.mean RadiomicsFirstOrder.range ...
                    RadiomicsFirstOrder.std RadiomicsFirstOrder.var RadiomicsFirstOrder.median RadiomicsFirstOrder.skewness ...
                    RadiomicsFirstOrder.kurtosis RadiomicsFirstOrder.rms RadiomicsFirstOrder.totalEnergy RadiomicsFirstOrder.MD});
                

            end
            
            close(conn)
            
            
        elseif exportFormatVal == 5 %BIRN Database
            
            %Connect to BIRN database
            feature jit off
            
            %Load database driver
            %javaaddpath('/Volumes/HOME/Projects/CERR/CERR4pt0beta2_25_Jan_2011/CERR_Data_Extraction/postgresql84jdbc3.jar')
           
            %Extablish Database connection
            setdbprefs({'NullStringRead';'NullNumberRead';'DataReturnFormat';'errorhandling'},{'';'NaN';'structure';'report'})
            %BIRN Postgressql (Development)
            conn = database('cerr','cerr','cerr~data','org.postgresql.Driver','jdbc:postgresql://128.9.132.88:5432/cerr');
                       
            unsuccssfulPlans = {};
            
            %Loop thru all patients, find matching id in database and store dvh data
            for planNum=1:length(ud.newNameMapS)
                
                %Update Waitbar
                drawnow
                set(waitbarH,'position',[0.05 0.18 0.9*planNum/length(ud.newNameMapS) 0.04])
                set(statusStrH,'string',['Exporting ',int2str(planNum),' out of ',int2str(length(ud.newNameMapS))])
                
                %Load CERR plan
                try
                    planC = loadPlanC(ud.newNameMapS(planNum).fullFileName, tempdir);
                    planC = updatePlanFields(planC);
                    indexS = planC{end};
                    % Quality Assurance
                    planC = quality_assure_planC('', planC);
                    
                    %Sum doses if required
                    dosesToSumV = ud.sumDose.doseMapS(planNum).DosesToSum;
                    
                    if length(dosesToSumV) > 1
                        
                        %New dose name
                        doseNameStr = ud.sumDose.doseMapS(planNum).NewDoseName;
                        assocScan = 1;
                        planC = sumDose(dosesToSumV,dosesToSumV.^0,assocScan,doseNameStr,planC);
                        
                        %Save dose to plan on disk
                        if ud.sumDose.doseMapS(planNum).save_to_disk
                            save_planC(planC,[], 'passed', ud.nameMapS(planNum).fullFileName);
                        end
                        
                    end
                    
                catch
                    disp([ud.newNameMapS(planNum).fullFileName, ' failed to load'])
                    unsuccssfulPlans{end+1,1} = IDStr;
                    unsuccssfulPlans{end,2} = 'CERR plan failed to load';
                    continue
                end                
                
                for scanNum = 1:length(planC{indexS.scan})
                    
                    scanUID = planC{indexS.scan}(1).scanUID;
                    
                    %Find the matching patient in the database
                    sqlq_find_patient = ['Select patient_id from scan where scan_uid = ''', scanUID,''''];
                    pat_raw = exec(conn, sqlq_find_patient);
                    pat = fetch(pat_raw);
                    pat = pat.Data;
                    if isstruct(pat)
                        patient_id = pat.patient_id{1};
                        break;
                    else
                       patient_id = []; 
                    end
                    
                end                
                
                %Insert New patient to database
                if ~isempty(patient_id)
                    patient_id = char(java.util.UUID.randomUUID);
                    insert(conn,'patient',{'patient_id','study_id','first_name','last_name','cerr_file_location'},{patient_id,'4cd0969a-a64f-46af-905e-d015f2c193bf','','',ud.newNameMapS(planNum).fullFileName});
                end

                %Write "scan" to database
                write_scan_to_db(conn,patient_id)
                
                %Write "structure" database
                write_structure_to_db(conn,patient_id)
                
                %Write "dose" database
                write_dose_to_db(patient_id)
                
                %Write "DVH" to database
                write_dvh_to_db(patient_id)
                
                
                %Store Dx,Vx values
                colnames = {'patients_id','therapy_instance_q71','plan_instance_q71','structure_name_q71','std_structure_name_q71','dosebin_q71','vol_cc_q71','vol_pct_q71','vol_pct_bin_q71','dose_for_vol_bin_q71'};
                colnamesStats = {'patients_id','therapy_instance_q72','plan_instance_q72','structure_name_q72','std_structure_name_q72','mean_dose_q72','max_dose_q72','min_dose_q72','max_dose_hot2cc_q72'};
                
                %                 for i=1:length(doseCutoffV)
                %                     x = doseCutoffV(i);
                %                     if floor(x) == x
                %                         colnames = [colnames, ['d',num2str(x)]];
                %                     else
                %                         if (x-floor(x))*100 == 50
                %                             colnames = [colnames, ['d',num2str(floor(x)),'pt5']];
                %                         else
                %                             colnames = [colnames, ['d',num2str(floor(x)),'pt',num2str((x-floor(x))*100)]];
                %                         end
                %                     end
                %                 end
                %                 for i=1:length(doseCutoffV)
                %                     x = doseCutoffV(i);
                %                     if floor(x) == x
                %                         colnames = [colnames, ['v',num2str(x)]];
                %                     else
                %                         if (x-floor(x))*100 == 50
                %                             colnames = [colnames, ['v',num2str(floor(x)),'pt5']];
                %                         else
                %                             colnames = [colnames, ['v',num2str(floor(x)),'pt',num2str((x-floor(x))*100)]];
                %                         end
                %                     end
                %                 end
                
                %                 colnames = [colnames, 'mean_dose'];
                %                 colnames = [colnames, 'max_dose'];
                %                 colnames = [colnames, 'min_dose'];
                %                 colnames = [colnames, 'dvh_dose_units_q57'];
                
                %Get Dose-units and convert to Gy
                if ~isempty(ud.newNameMapS(planNum).doseMap) && (strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGy') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGys') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGray') || strcmpi(planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits,'CGrays'))
                    planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseArray = planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseArray * 0.01;
                    planC{indexS.dose}(ud.newNameMapS(planNum).doseMap).doseUnits = 'Grays';
                end
                
                %Get therapy instance, if possible
                indP = strfind(pathStr,'P-');
                if isempty(indP)
                    plan_instance = 'P-1';
                else
                    plan_instance = pathStr(indP:indP+2);
                end
                
                %Get plan instance, if possible
                indT = strfind(pathStr,'T-');
                if isempty(indT)
                    therapy_instance = pathStr(indT:indT+2);
                else
                    therapy_instance = 'T-1';
                end
                
                % Insert User
                
                newRecC = {};  
                uuid = java.util.UUID.randomUUID;
                newRecC{1,1} = char(uuid);
                newRecC{1,2} = '';
                newRecC{1,3} = '';
                newRecC{1,4} = 'Aditya';
                newRecC{1,5} = 'Apte';
                colnames = {'user_id','study_id','institution_id','first_name','last_name'};
                colnames = {'first_name','last_name'};
                insert(conn,'user',colnames,newRecC);
                
                insert(conn,'institution',{'institution_id','institution_name','contact'},{char(uuid),'Washington University','deasyj@mskcc.org'});
                
                
                sqlq_find_user = ['Select user_id from user where (first_name like ''', 'Aditya', '''', ' or last_name like ''', 'Apte', ''')'];
                usr_raw = exec(conn, sqlq_find_user);
                usr = fetch(usr_raw);
                usr_id = usr.Data;                
                
                
               
                
                clear global planC
                
            end
            
            %Open-up excel file with unsuccessful plans.
            unsuccssfulPlans = [{'ID','Reason Failed'}; unsuccssfulPlans];
            
            fName = [tempdir,'OQA_DVH_fill.xls'];
            try
                delete(fName)
            end
            xlswrite(fName,unsuccssfulPlans)
            winopen(fName);
            
            
        end
        
    case 'QUIT'
        set(findobj('Tag','ReviewMode'),'Value',1);
        closereq
        
end

return;

% --------- supporting sub-functions
function str = repSpaceHyp(str)
indSpace = strfind(str,' ');
indDot = strfind(str,'.');
str(indDot) = [];
indOpenParan = strfind(str,'(');
indCloseParan = strfind(str,')');
indPlus = strfind(str,'+');
indMinus = strfind(str,'-');
indPercent = strfind(str,'%');
indComma = strfind(str,',');
indBackSlash = strfind(str,'\');
indFwdSlash = strfind(str,'/');
indEqualTo = strfind(str,'=');
indQuestion = strfind(str,'?');
indAnd = strfind(str,'&');
indColon = strfind(str,':');
indToReplace = [indSpace indOpenParan indCloseParan indPlus indMinus indPercent indComma indBackSlash indFwdSlash indEqualTo indQuestion indAnd indColon];
str(indToReplace) = '_';
indGreaterThan = strfind(str,'>');
indLessThan = strfind(str,'<');
str(indGreaterThan) = 'G';
str(indLessThan) = 'L';
indNum = strfind(str,'1');
if indNum == 1
    str(indNum) = 'A';
end
indNum = strfind(str,'2');
if indNum == 1
    str(indNum) = 'B';
end
indNum = strfind(str,'3');
if indNum == 1
    str(indNum) = 'C';
end
indNum = strfind(str,'4');
if indNum == 1
    str(indNum) = 'D';
end
indNum = strfind(str,'5');
if indNum == 1
    str(indNum) = 'E';
end
indNum = strfind(str,'6');
if indNum == 1
    str(indNum) = 'F';
end
indNum = strfind(str,'7');
if indNum == 1
    str(indNum) = 'G';
end
indNum = strfind(str,'8');
if indNum == 1
    str(indNum) = 'H';
end
indNum = strfind(str,'9');
if indNum == 1
    str(indNum) = 'I';
end
indNum = strfind(str,'0');
if indNum == 1
    str(indNum) = 'Z';
end
while isequal(str(end),'_')
    str(end) = [];
end
while isequal(str(1),'_')
    str(1) = [];
end
return;

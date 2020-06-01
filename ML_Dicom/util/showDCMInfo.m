function [selectedPatient] = showDCMInfo(dcmdirS)

% this is a frame to show the patient structures in the dcm directory
% WY
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

selectedPatient = [];

units = 'pixels';
screenSize = get(0,'ScreenSize');
w = 800; h = 700;
h = figure('name', 'DICOM Import', 'units', units, ...
    'position',[(screenSize(3)-w)/2 (screenSize(4)-h)/2 w h], ...
    'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', ...
    'Tag', 'regMainframe', 'DoubleBuffer', 'on', 'WindowStyle', 'normal', ...
    'CloseRequestFcn',@closeFigure);

wtree = 0.33;cw = 0.1;
htree = createTree(dcmdirS, h, [0 0 wtree 1], 'Dicom Dataset');

cx = wtree+0.001;
col1 = uicontrol('String', 'Name:', 'Units', 'normalized', 'Style', 'Text',...
    'Position', [cx .95 cw .03], 'BackgroundColor',  [.925 .914 .847]);
col2 = uicontrol('String', 'Class:', 'Units', 'normalized', 'Style', 'Text',...
    'Position', [cx .90 cw .03], 'BackgroundColor',  [.925 .914 .847]);
col3 = uicontrol('String', 'Value:', 'Units', 'normalized', 'Style', 'Text',...
    'Position', [cx .85 cw .03], 'BackgroundColor',  [.925 .914 .847]);
tx = cx+cw+0.01; tw = 1-tx-0.01;
txt1 = uicontrol('String', '', 'Units', 'normalized', 'Style', 'Edit',...
    'Position', [tx .949 tw .034], 'BackgroundColor',  [.925 .914 .847]);
txt2 = uicontrol('String', '', 'Units', 'normalized', 'Style', 'Edit',...
    'Position', [tx .899 tw .034], 'BackgroundColor',  [.925 .914 .847]);
txt3 = uicontrol('String', '', 'Units', 'normalized', 'Style', 'Edit',...
    'Max',2,'Min',0,...
    'Position', [tx .849-0.06 tw 0.034+0.06], 'BackgroundColor',  [.925 .914 .847]);

haxes = axes('Units', 'normalized','Position', [cx .1 1-cx-0.005 .68], 'Box', 'on', 'XTick', [], 'YTick', []);
axis off;

importBtn = uicontrol('String', 'Import Selected Patient', 'Units', 'normalized',...
    'Position', [0.4 0.02 0.16 .03] , 'callback', @import_cb,...
    'TooltipString', ' Import Current Selected Patient');

importAllBtn = uicontrol('String', 'Import All', 'Units', 'normalized',...
    'Position', [0.61 0.02 0.1 .03] , 'callback', @import_all,...
    'TooltipString', ' Import all dicom series');

str1(1) = {'Select a Patient from the tree or import all series in one CERR plan'};
%str1(2) = {'and then Click the Import Button ...'};
col4 = uicontrol('String', str1, 'Units', 'normalized', 'Style', 'Text',...
    'Position', [0.33 0.05 0.6 .03], 'ForegroundColor',  [.925 0 0]);

cancelBtn = uicontrol('String', 'Cancel', 'Units', 'normalized',...
    'Position', [0.75 0.02 0.1 .03] , 'callback', @cancel_cb,...
    'TooltipString', 'Cancel');
uiwait;



    function import_cb(handle, ev)
        if ~isempty(selectedPatient)
            delete(gcf);
            pause(0.1);
        else
            msgbox('Please select a patient from the list.','','help');
        end
    end

    function import_all(handle, ev)
        selectedPatient = 'all';
        delete(gcf);
        pause(0.1);        
    end

    function cancel_cb(handle, ev)
        selectedPatient = [];
        delete(gcf);
    end

    function closeFigure(handle, ev)
        drawnow;
        uiresume;
    end

    function [tree,expFcn] = createTree(str, hFrame, position, name)

        if ~isstruct(str)
            msgerror = strcat('''',inputname(1),''''' is not a structure!!');
            error(msgerror);
        end

        import javax.swing.*;
        import java.awt.*;

        %pth = 'C:\Z\Mat_Frame\gif\';
        iconpath =which('datasource.gif');
        
        if getMLVersion > 7.10
            figure(hFrame)
            root = uitreenode('v0', name, name, iconpath, false);
            figure(hFrame)
            [tree, container] = uitree('v0', 'Root', root,'ExpandFcn', @myExpfcn, 'parent', hFrame);
            figure(hFrame)
            set(container, 'Parent', hFrame)
        else
            root = uitreenode(name, name, iconpath, false);
            tree = uitree(hFrame,'Root', root,'ExpandFcn', @myExpfcn);            
        end
        set(tree, 'Units', 'normalized', 'position', position);
        set(tree, 'NodeWillExpandCallback', @nodeWillExpand_cb);
        set(tree, 'NodeSelectedCallback', @nodeSelected_cb);
        tree.expand(root);
        %     set(tree, 'Font', 10);

        tmp = tree.Parent;
        cell_Data = cell(2,1);
        cell_Data{1} = str;
        set(tmp, 'UserData', cell_Data);

        tree.getFigureComponent.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
        set(tree.getTree, 'Font', Font('Dialog', Font.PLAIN, 12));
        %         set(tree.getTree, 'background', [0.753 0.753 0.753]);

        %         tree.getFigureComponent.setBorder(BorderFactory.createLineBorder(Color.red));

        %         t = tree.Parent;
        %         color = java.awt.Color(0.753,0.753,0.753);
        %         t.setBackground(color);
        %         t.setForeground(color);

        %         tree.getFigureComponent.setFont(Font('Dialog', Font.PLAIN, 12))
        %         BorderFactory.createEtchedBorder(EtchedBorder.RAISED);
        %         BorderFactory.createEtchedBorder(EtchedBorder.LOWERED);
        %         tree.getFigureComponent.setBorder(BorderFactory.createLineBorder(Color.red));
        %
        %set(t, 'MousePressedCallback', @mouse_cb);

        expFcn = @myExpfcn;
    end
%--------------------------------------------------------

    function cNode = nodeSelected_cb(tree,ev)
        cNode = ev.getCurrentNode;
        tmp = tree.Parent;
        cell_Data =get(tmp, 'UserData');
        cell_Data{2} = cNode;
        s = cell_Data{1};
        val = s;
        plotted = cNode.getValue;
        selected = plotted;

        [val, plotted, cNode] = getcNodevalue(cNode, val);
        ii = strfind(plotted, '.');
        if ~isempty(ii)
            selectedPatient = plotted(1:ii-1);
        else
            if strfind(plotted, 'patient_')
                selectedPatient = plotted(1:end);
            end
        end

        try
            set(txt1, 'string', plotted);
            set(txt2, 'string', class(val));
            set(txt3, 'string', val);
        catch
            if strcmp(class(val), 'org.dcm4che3.data.Attributes')
                set(txt3, 'string', char(val));
            else
                set(txt3, 'string', '');
            end
        end
        set(tmp, 'UserData', cell_Data);

        if strfind(selected, 'Data')
            %show the image
            try
                im = squeeze(dicomread(val.file));
            catch
                return;
            end
            axes(haxes);axis off;
            if (size(im,1)>0)
                if size(im,3)>1
                    im_h = imagesc(im(:,:,1));
                else
                    im_h = imshow(im, []); %'DisplayRange',[min(im(:)) max(im(:))]);
                    %                    im_h = imagesc(im);
                end
            end
            colormap('gray'); %jet
        end
    end

    function [val, displayed, cNode] = getcNodevalue(cNode, s)

        fields = {};
        while cNode.getLevel ~=0
            fields = [fields; cNode.getValue];
            c = strfind(cNode.getValue, '(');
            if ~isempty(c) && cNode.getLevel ~=0
                cNode = cNode.getParent;
            end

            if  cNode.getLevel ==0, break; end
            cNode = cNode.getParent;
        end
        val = s;
        if ~isempty(fields)
            L=length(fields);
            displayed = fields{L};
            for j = L-1:-1:1, displayed = strcat(displayed, '.', fields{j}); end
            for i=L:-1:1
                field = fields{i};
                d1 = strfind(field,'(');
                d2 = strfind(field,')');
                if ~isempty(d1)
                    idx = str2double(field(d1+1:d2-1));
                    field = field(1:d1-1);
                    if (strcmp(field, cNode.getValue))
                        val = val(idx);
                    else
                        val = getfield(val, field, {idx});
                    end
                else
                    val = val.(field);
                end
            end
        else
            displayed = cNode.getValue;
            return;
        end
    end

% function mouse_cb(h, ev)
%     if ev.getModifiers() == ev.META_MASK
%         pUpMenu.show(t, ev.getX, ev.getY);
%         pUpMenu.repaint;
%     end

    function cNode = nodeWillExpand_cb(tree,ev)
        cNode = ev.getCurrentNode;
        tmp = tree.Parent;
        cell_Data =get(tmp, 'UserData');
        cell_Data{2} = cNode;
        set(tmp, 'UserData', cell_Data);
    end

    function nodes = myExpfcn(tree,value)
        %         try
        tmp = tree.Parent;
        S= get(tmp, 'UserData');
        s = S{1};
        cNode = S{2};
        if isempty(cNode) %init
            val = s;
        else %expanded
            [val,str] = getcNodevalue(cNode, s);
        end
        fnames = fieldnames(val);

        %pth = 'C:\Z\Mat_Frame\gif\';

        L = length(val);
        count = 0;
        if L > 1
            iconpath = which('structarray_icon.GIF');
            for J = 1:L
                count = count + 1;
                cNode = S{2};
                fname = strcat(cNode.getValue, '(', num2str(J),')');
                if strfind(fname, 'patient'), iconpath = which('patient.gif'); end;
                if strfind(fname, 'STUDY'), iconpath = which('studies.gif'); end;
                if strfind(fname, 'SERIES'), iconpath = which('series.gif'); end;
                if strfind(fname, 'Data'), iconpath = which('data.gif'); end;
                if getMLVersion > 7.10
                    nodes(count) =  uitreenode('v0', fname, fname, iconpath, 0);
                else
                    nodes(count) =  uitreenode(fname, fname, iconpath, 0);
                end
            end
        else
            %%
            for i=1:length(fnames)
                count = count + 1;
                x = val.(fnames{i});
                if isstruct(x)
                    if length(x) > 1
                        iconpath = which('structarray_icon.GIF');
                    else
                        iconpath = which('struct_icon.GIF');
                    end
                elseif isnumeric(x)
                    iconpath = which('double_icon.GIF');
                elseif iscell(x)
                    iconpath = which('cell_icon.GIF');
                elseif ischar(x)
                    iconpath = which('char_icon.GIF');
                elseif islogical(x)
                    iconpath = which('logic_icon.GIF');
                elseif isobject(x)
                    iconpath = which('obj_icon.GIF');
                else
                    iconpath = which('unknown_icon.GIF');
                end

                value = fnames{i};
                string = fnames{i};
                if strfind(value, 'patient_')
                    patientName = char(x.info.getString(hex2dec('00100010')));
                    patientName = strrep(patientName, '^', ' ');
                    string = strcat(string, '(', patientName, ')');
                    iconpath = which('patient.gif');
                end
                if strcmp(fnames{i}, 'STUDY')
                    string = 'STUDIES';
                    iconpath = which('studiesFolder.gif');
                end
                if strcmp(fnames{i}, 'SERIES')
                    iconpath = which('seriesFolder.gif');
                end
                if strcmp(fnames{i}, 'Data')
                    iconpath = which('dataFolder.gif');
                end
                if strcmp(fnames{i}, 'Modality')
                    string = x; 
                end
                
                if getMLVersion > 7.10
                    nodes(count) = uitreenode('v0', value, string, iconpath, ~isstruct(x));
                else
                    nodes(count) = uitreenode(value, string, iconpath, ~isstruct(x));
                end
            end
        end

        %         catch
        %             error(['The uitree node type is not recognized. ' ...
        %                 ' You may need to define an ExpandFcn for the nodes.']);
        %         end

        if (count == 0)
            nodes = [];
        end

    end



end

function expFcn = createParaTree(varargin)
%
% Create a java treelist to view registration algorithm list
%
% example:
% window = figure('units', 'normalized', 'Name', 'Example');
% tree_root = uitreenode('root', 'Root', [], false);
% tree = uitree('Root', tree_root);
% set(tree, 'Units', 'normalized', 'position', [0 0 1.0 1.0]);
% 
% nodes(1) = uitreenode('child 1', 'Child 1', '', 1);
% nodes(2) = uitreenode('child 2', 'Child 2', '', 1);
% 
% tree.add(tree_root, nodes);
% tree.expand(tree_root);
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


    if ~isstruct(varargin{1})
        msgerror = strcat('''',inputname(1),''''' is not a structure!!');
        error(msgerror);
    end

    import javax.swing.*;
    import java.awt.*;

%     name = inputname(1);
%     if isempty(name)
%         name = 'SysInfo';  
%     end
    handles = varargin{2};
    position = varargin{3};
            
    pth = [pwd, '\IconsReg\'];
    iconpath =[pth, 'obj_icon.GIF'];
    name = 'Registration Profile';
    
    root = uitreenode(name, name, iconpath, false);
    tree = uitree(handles.mainframe,'Root', root,'ExpandFcn', @myExpfcn);
    set(tree, 'Units', 'normalized', 'position', position);
    set(tree, 'NodeWillExpandCallback', @nodeWillExpand_cb);
    set(tree, 'NodeSelectedCallback', @nodeSelected_cb);
    tree.expand(root);
%     set(tree, 'Font', 10);
    
    tmp = tree.FigureComponent;
    cell_Data = cell(2,1);
    cell_Data{1} = varargin{1};
    set(tmp, 'UserData', cell_Data);
%     t = tree.Tree;
%     color = java.awt.Color(0.753,0.753,0.753);
%     t.setBackground(color);
%     t.setForeground(color);
%     set(t, 'MousePressedCallback', @mouse_cb);

%     val = varargin{1};
%     fnames = fieldnames(val);
% 
%     pth = [pwd, '\icons\'];
% 
%     count = 0;
%     for i=1:length(fnames)           
%         count = count + 1;
%         x = getfield(val,fnames{i});
%         if isstruct(x)
%             iconpath =[pth,'struct_icon.GIF'];
%         else
%             iconpath =[pth,'pin_icon.gif'];
%         end
%         nodes(count) = uitreenode(fnames{i}, fnames{i}, iconpath, ~isstruct(x));
%         
%     end
    
%   save handles to gui
    handles.FTreeView = tree;
    handles.state.filterSelected = name;
    guidata(handles.mainframe, handles);

    expFcn = @myExpfcn;

%--------------------------------------------------------

    function cNode = nodeSelected_cb(tree,ev)
        cNode = ev.getCurrentNode;
        tmp = tree.FigureComponent;
        cell_Data =get(tmp, 'UserData');
        cell_Data{2} = cNode;
        s = cell_Data{1};
        val = s;
        plotted = cNode.getValue;
        selected = plotted;
        
        handles = guidata(handles.mainframe);
        clearToolPanel(handles);
        handles = guidata(handles.mainframe);
        
        createParaPanel(handles, selected);
        handles = guidata(handles.mainframe);
        
        handles.para.profileSelected = selected;
        guidata(handles.mainframe, handles);
        set(tmp, 'UserData', cell_Data);
    end

    % function mouse_cb(h, ev)        
    %     if ev.getModifiers() == ev.META_MASK
    %         pUpMenu.show(t, ev.getX, ev.getY);
    %         pUpMenu.repaint;
    %     end

    function cNode = nodeWillExpand_cb(tree,ev)
        cNode = ev.getCurrentNode;
        tmp = tree.FigureComponent;
        cell_Data =get(tmp, 'UserData');
        cell_Data{2} = cNode;
        set(tmp, 'UserData', cell_Data);
    end

    function nodes = myExpfcn(tree,value)    
        try
            tmp = tree.FigureComponent;
            S= get(tmp, 'UserData');
            s = S{1};
            cNode = S{2};
            if isempty(cNode) %init
                val = s;
            else %expanded
                [val,str] = getcNodevalue(cNode, s);
            end
            fnames = fieldnames(val);

            pth = [pwd, '\iconsReg\'];
            
            count = 0;
            for i=1:length(fnames)           
                count = count + 1;
                x = getfield(val,fnames{i});
                if isstruct(x)
                    iconpath =[pth,'struct_icon.GIF'];
                else
                    iconpath =[pth,'pin_icon.gif'];
                end
                nodes(count) = uitreenode(fnames{i}, fnames{i}, iconpath, ~isstruct(x));

            end
            
        catch
            error(['The uitree node type is not recognized. ' ...
                ' You may need to define an ExpandFcn for the nodes.']);
        end

        if (count == 0)
            nodes = [];
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
                d = strfind(field,'(');
                if ~isempty(d)
                    idx = str2num(field(d+1));
                    field = field(1:d-1);
                    if (strcmp(field, cNode.getValue))
                        val = val(idx);
                    else
                        val = getfield(val, field, {idx});
                    end
                else
                    val = getfield(val, field);
                end
            end
        else
            displayed = cNode.getValue;
            return;
        end
    end

end









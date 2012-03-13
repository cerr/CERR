function CERRRegistrationRigidSetup(command, varargin)
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

% msgbox('This functionality is under development for compiled version of CERR. Please use the source code version to use this functionality.','Under Development','modal')
% return;

global planC stateS;

indexS = planC{end};

hViewer = stateS.handle.CERRSliceViewer;

    switch command

        case 'init'
            try 
                if strcmp(stateS.regMainframe, 'on')
                    figure(stateS.handle.RigidRegistrationMenuFigure);
                    return; 
                end
            catch
            end
            units = 'pixels';
            screenSize = get(0,'ScreenSize');
            w = 600; h = 600;

            %Initialize size of figure in pixels. Figure scales fairly well.
            hFig = figure('name', 'Registration Setup', 'units', units, ...
                            'position',[(screenSize(3)-w)/4 (screenSize(4)-h)/4 w h], ...
                            'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', ...
                            'Tag', 'regMainframe', 'DoubleBuffer', 'on', ...
                            'DeleteFcn', 'CERRRegistrationRigidSetup(''close'', [])');
            axis(gca,'off')
            set(gca,'nextPlot','add')

            stateS.handle.RigidRegistrationMenuFigure = hFig;
            handles.mainframe = hFig;
            handles.para.profileSelected = '';

            createBasePanel(handles);
            handles = guidata(handles.mainframe);
            

            stateS.regMainframe = 'on';
            
%             path = getCERRPath;
%             path = [path 'Mex\WindowsMex'];
%             cd(path);
            drawnow;

        case 'auto_registration'

            handles = guidata(gcbf);

            contents = get(handles.transform, 'string');
            transform = contents{get(handles.transform, 'value')};
            
            contents = get(handles.metric, 'string');
            metric = contents{get(handles.metric, 'value')};
            metric = lower(metric);
                    
            switch handles.para.profileSelected

%                 case {'Rigid_Single_Modality'}
%                     
%                     drawRegField_Rd('init');
%                     ret = getappdata(stateS.handle.CERRSliceViewer, 'isClip');
%                     close(findobj('tag', 'FieldFig'));
%                     if strcmp(ret, 'on')
%                         switch transform
% 
%                             case 'Similarity Transform'
%                                 RegMeanSquareSimilarity(handles, 'mr', metric);
%                             case 'Versor3D Transform'
%                                 RegMeanSquareVersor(handles, metric);
%                             case 'Euler Transform'
%                                 RegMeanSquareEuler(handles, metric);
%                             case 'Affine Transform'
%                                 RegMeanSquareAffine(handles, metric);
%                         end
%                     end
%     ---------------------------------------------------------------------
%     ---------------------------------------------------------------------
                case {'Rigid'}
                    
                    switch transform
                        
                        case 'Similarity Transform'
                            drawRegField_Rd('init');
                            ret = getappdata(stateS.handle.CERRSliceViewer, 'isClip');
                            close(findobj('tag', 'FieldFig'));
                            set(gcbf,'Pointer','watch');
                            drawnow;
                            pause(0.1);
                            
                            if strcmp(ret, 'on')
                                RegMISimilarity(handles, metric);
                                
                            end
                            set(gcbf,'Pointer','arrow');
                            %RegMISimilarity(handles, metric);
                        case 'Versor3D Transform'

                        case 'Euler Transform'

                        case 'Affine Transform'

                    end

                    
%     ---------------------------------------------------------------------
%     ---------------------------------------------------------------------
                case 'OpticalFlow'
                    drawRegField('init');
                    ret = getappdata(stateS.handle.CERRSliceViewer, 'isClip');
                    delete(findobj('tag', 'FieldFig'));
                    if strcmp(ret, 'on')
                        RegOpticalFlow(handles, uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox')));
                    end
                                                          
                case 'Demons3D'
                    drawRegField('init');
                    ret = getappdata(stateS.handle.CERRSliceViewer, 'isClip');
                    delete(findobj('tag', 'FieldFig'));
                    if strcmp(ret, 'on')
                        RegDemons3D(handles, 0, uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox')));
                    end
                    
                    
                case 'LevelSetMethod'
                    drawRegField('init');
                    ret = getappdata(stateS.handle.CERRSliceViewer, 'isClip');
                    delete(findobj('tag', 'FieldFig'));
                    if strcmp(ret, 'on')
                        RegDemons3D(handles, 1, uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox')));
                    end
                                    
                case 'SymmetricDemons3D'
                    drawRegField('init');
                    ret = getappdata(stateS.handle.CERRSliceViewer, 'isClip');
                    delete(findobj('tag', 'FieldFig'));
                    if strcmp(ret, 'on')
                        RegDemons3D(handles, 2, uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox')));
                    end
                    
                case 'BSplineMethod'
                    drawRegField('init');
                    ret = getappdata(stateS.handle.CERRSliceViewer, 'isClip');
                    delete(findobj('tag', 'FieldFig'));
                    if strcmp(ret, 'on')
                        RegDemons3D(handles, 3, uint16(getappdata(stateS.handle.CERRSliceViewer, 'clipBox')));
                    end
                    
                    
            end
        
        case 'close'
            stateS.regMainframe = 'off';

    end




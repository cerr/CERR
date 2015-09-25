function createParaPanel(handles, selected)
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
    
    clearToolPanel(handles);
    
    switch selected
        
        case {'Registration Profile', 'Non_Rigid'}
            return;

%%%%%%%%%%%%%%%%%%%%%%%  general rigid single  %%%%%%%%%%%%%%%%%
        case {'Rigid_Single_Modality'}
            set(handles.transform, 'value', 1, 'backgroundcolor', [.65 .79 .94], 'enable', 'on', ...
                'string', {'Similarity Transform'; 'Versor3D Transform'; 'Euler Transform';}); %'Affine Transform' 
            set(handles.interpolater, 'value', 1, 'backgroundcolor', [.945 .956 .509], 'enable', 'on', ...
                'string', {'Linear Interpolate'}); 
            set(handles.metric, 'value', 1, 'backgroundcolor', [.721 .905 .776], 'enable', 'on', ...
                'string', {'Mean Squares'; 'Normalized Correlation' }); 
            set(handles.optimizer, 'value', 1, 'backgroundcolor', [.984 .686 .635], 'enable', 'on', ...
                'string', {'RegularStepGradientDescent'}); 

            CreateSimilarityPanel(handles, 'mr');
%             CreateOptimizerPanel(handles);
        
        case 'transform_advance'
            contents = get(handles.transform, 'string');
            transform = contents{get(handles.transform, 'value')};
            switch transform
                case 'Translation'
                    CreateOptimizerPanel(handles);
                case 'Similarity Transform'
                    CreateSimilarityPanel(handles, 'mr');
                case 'Versor3D Transform'
                    CreateVersorPanel(handles);
                case 'Euler Transform'
                    CreateEulerPanel(handles);
                case 'Affine Transform'
                    CreateAffinePanel(handles);
            end
                   
%%%%%%%%%%%%%%%%%%%%%%%%%  mutual information %%%%%%%%%%%%%%%%%%%%%%%%%%%       
        case {'Rigid'}
            set(handles.transform, 'value', 2, 'backgroundcolor', [.65 .79 .94], 'enable', 'inactive',...
                'string', {'Translation'; 'Similarity Transform'; 'Versor3D Transform'; 'Euler Transform'; 'Affine Transform' }); 
            set(handles.interpolater, 'value', 1, 'backgroundcolor', [.945 .956 .509],  'enable', 'inactive',...
                'string', {'Linear Interpolate'; 'Nearest Interpolate'}); 
            set(handles.metric, 'value', 1, 'backgroundcolor', [.721 .905 .776],  'enable', 'off', ...
                'string', {'Mutual Information'}); 
            set(handles.optimizer, 'value', 1, 'backgroundcolor', [.984 .686 .635], 'enable', 'on', ...
                'string', {'RegularStepGradientDescent'}); 
            
            CreateMattesPanel(handles);
            
        case 'MM_transform_advance'
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%% deformable  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
        case 'OpticalFlow'
            disableGeneralPanel();            
            CreateOpticalFlowPanel(handles);
        
        case 'Demons3D'
            disableGeneralPanel();
            CreateDemonsPanel(handles);
            
        case 'SymmetricDemons3D'
            disableGeneralPanel();
            CreateDemonsPanel(handles);
            disp('symmetric');
            
        case 'BSplineMethod'
            disableGeneralPanel();
            CreateBSplineMethodPanel(handles);
            disp('bspline');
                
        case 'LevelSetMethod'
            disableGeneralPanel();
            CreateDemonsPanel(handles);
            disp('levelset');
                        
                    
%%%%%%%%%%%%%%%%%%% QA %%%%%%%%%%%%%%%%%%%%%%%%%%            
            
        case 'BlockMatch'
            
        case 'CheckerBoard'
            
%%%%%%%%%%%%%%%%%%%%%% segmentation  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

        case {'NeighborhoodConnected', 'ConfidenceConnected'}
%             set(handles.NeighborhoodConnectedPanel, 'visible', 'on', 'parent', handles.toolPanel, 'units', 'normalized');
%             set(handles.NeighborhoodConnectedPanel, 'position', [0 1-.6 1 .6]); 
          
        otherwise
            
           
    end
    
    function disableGeneralPanel()
        set(handles.transform, 'value', 2, 'backgroundcolor', [.65 .79 .94], 'enable', 'off',...
                'string', {'Translation'; 'Similarity Transform'; 'Versor3D Transform'; 'Euler Transform'; 'Affine Transform' }); 
        set(handles.interpolater, 'value', 1, 'backgroundcolor', [.945 .956 .509],  'enable', 'off',...
            'string', {'Linear Interpolate'; 'Nearest Interpolate'}); 
        set(handles.metric, 'value', 1, 'backgroundcolor', [.721 .905 .776],  'enable', 'off', ...
            'string', {'Mutual Information'}); 
        set(handles.optimizer, 'value', 1, 'backgroundcolor', [.984 .686 .635], 'enable', 'off', ...
            'string', {'RegularStepGradientDescent'}); 
    end        

    
end        

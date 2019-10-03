function [scanC,maskC] = transformView(scanC,maskC,view)
%transformView.m
%
% Returns cell array of images transformed to the input view.
% ----------------------------------------------------------------------
% INPUTS
% scanC : Cell array of scans
% view  : May be 'axial' (default), 'coronal' or 'sagittal'.
% ----------------------------------------------------------------------
% AI 10/2/19


%% Transform images as required
switch view
    
    case 'coronal'
        for n = 1:length(scanC)
            scan3M = scanC{n};
            scan3M = permute(scan3M,[3,2,1]);
            scanC{n} = scan3M;
            
            mask3M = maskC{n};
            mask3M = permute(mask3M,[3,2,1]);
            maskC{n} = mask3M;
            
        end
        
    case 'sagittal'
        for n = 1:length(scanC)
            scan3M = scanC{n};
            scan3M = permute(scan3M,[3,1,2]);
            scanC{n} = scan3M;
            
            mask3M = maskC{n};
            mask3M = permute(mask3M,[3,1,2]);
            maskC{n} = mask3M;
            
            
        end
        
    case 'axial'
        %Do nothing
        
    otherwise
        error(['Transformation to view ', view, 'is not supported'])
end


end
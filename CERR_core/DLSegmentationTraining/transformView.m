function [scanOutC,maskOutC] = transformView(scanC,maskC,viewC)
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
scanOutC = cell(length(viewC),1);
maskOutC = cell(length(viewC),1);

for i = 1:length(viewC)
    
    tempScanC = cell(size(scanC));
    tempMaskC = cell(size(maskC));
    
    switch viewC{i}
        case 'coronal'
            for n = 1:length(scanC)
                scan3M = scanC{n};
                scan3M = permute(scan3M,[3,2,1]);
                tempScanC{n} = scan3M;
                
                mask3M = maskC{n};
                mask3M = permute(mask3M,[3,2,1]);
                tempMaskC{n} = mask3M;
            end
            scanOutC{i} = tempScanC;
            maskOutC{i} = tempMaskC;
            
        case 'sagittal'
            for n = 1:length(scanC)
                scan3M = scanC{n};
                scan3M = permute(scan3M,[3,1,2]);
                tempScanC{n} = scan3M;
                
                mask3M = maskC{n};
                mask3M = permute(mask3M,[3,1,2]);
                tempMaskC{n} = mask3M;
            end
            scanOutC{i} = tempScanC;
            maskOutC{i} = tempMaskC;
            
        case 'axial'
            %Do nothing
            scanOutC{i} = scanC;
            maskOutC{i} = maskC;
            
        otherwise
            error(['Transformation to view ', viewC{i}, 'is not supported'])
    end
end

end
function [scanOutC,maskOutC] = transformView(scan3M,mask3M,viewC)
%transformView.m
%
% Returns cell array of images transformed to the input view.
% ----------------------------------------------------------------------
% INPUTS
% scan3M : Scan array
% mask3M : Mask
% view   : May be 'axial' (default), 'coronal' or 'sagittal'.
% ----------------------------------------------------------------------
% AI 10/2/19


%% Transform images as required
scanOutC = cell(length(viewC),1);
maskOutC = cell(length(viewC),1);

for i = 1:length(viewC)

    switch viewC{i}
        case 'coronal'
            
            corScan3M = permute(scan3M,[3,2,1]);
            corMask3M = permute(mask3M,[3,2,1]);
            scanOutC{i} = corScan3M;
            maskOutC{i} = corMask3M;
            
        case 'sagittal'
            
            sagScan3M = permute(scan3M,[3,1,2]);
            sagMask3M = permute(mask3M,[3,1,2]);
            scanOutC{i} = sagScan3M;
            maskOutC{i} = sagMask3M;
            
        case 'axial'
            %Do nothing
            scanOutC{i} = scan3M;
            maskOutC{i} = mask3M;
            
        otherwise
            error(['Transformation to view ', viewC{i}, 'is not supported'])
    end
end

end
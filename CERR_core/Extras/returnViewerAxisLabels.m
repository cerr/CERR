function [axisLabelCell,orientationStr,iop] = returnViewerAxisLabels(planC,scanNum)

indexS = planC{end};

if ~exist('scanNum','var') || isempty(scanNum)
    scanNum = 1;
end

try
    iop = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
    
    if isempty(iop)
        iop = [1,0,0,0,1,0]'; % temporary. assign this during loading planC
    end
    
    [~,idx2] = max(abs(iop(1:3)));
    [~,idx1] = max(abs(iop(4:end)));
    
    iopProj = zeros(size(iop));
    iopProj(idx1 + 3) = iop(idx1 + 3);
    iopProj(idx2) = iop(idx2);
    
    iopProjSign = iopProj ./ abs(iop);
    
    iopProjSign(isnan(iopProjSign)) = 0;
    
    if isequal(abs(iopProjSign),[1; 0; 0; 0; 1; 0])
        sliceType = 'axial';
    elseif isequal(abs(iopProjSign),[1; 0; 0; 0; 0; 1])
        sliceType = 'coronal';
    else
        sliceType = 'sagittal';
    end
    
    switch sliceType
        
        case 'axial'
            % definitions            
            HFS = [1; 0; 0; 0; 1; 0];
            HFP = [-1; 0; 0; 0; -1; 0];
            FFS = [-1; 0; 0; 0; 1; 0];
            FFP = [1; 0; 0; 0; -1; 0];
            
            if isequal(iopProjSign(:), HFS)
                axisLabelCell = {'A','P';'R','L';'S','I'};
                orientationStr = 'HFS';
            elseif isequal(iopProjSign(:), HFP)
                axisLabelCell = {'P','A';'L','R';'S','I'};
                orientationStr = 'HFP';
            elseif isequal(iopProjSign(:), FFS)
                axisLabelCell = {'A','P';'L','R';'S','I'};
                orientationStr = 'FFS';
            else %FFP
                axisLabelCell = {'P','A';'R','L';'S','I'};
                orientationStr = 'FFP';
            end
        case 'coronal'
            HFS = [1; 0; 0; 0; 0; 1];
            HFP = [-1; 0; 0; 0; 0; 1];
            FFS = [-1; 0; 0; 0; 0; -1];
            FFP = [1; 0; 0; 0; 0; -1];
            
            if isequal(iopProjSign(:), HFS)
                axisLabelCell = {'S','I';'R','L';'A','P'};
                orientationStr = 'HFS';
            elseif isequal(iopProjSign(:), HFP)
                axisLabelCell = {'S','I';'R','L';'A','P'};
                orientationStr = 'HFP';
            elseif isequal(iopProjSign(:), FFS)
                axisLabelCell = {'S','I';'R','L';'A','P'};
                orientationStr = 'FFS';
            else %FFP
                axisLabelCell = {'S','I';'R','L';'A','P'};
                orientationStr = 'FFP';
            end
            
        case 'sagittal' % eg [0; 1; 0; 0; 0; -1]
            HFS = [0; 1; 0; 0; 0; 1];
            HFP = [0; -1; 0; 0; 0; 1];
            FFS = [0; -1; 0; 0; 0; -1];
            FFP = [0; 1; 0; 0; 0; -1];
            
            if isequal(iopProjSign(:), HFS)
                axisLabelCell = {'A','P';'S','I';'R','L'};
                orientationStr = 'HFS';
            elseif isequal(iopProjSign(:), HFP)
                axisLabelCell = {'A','P';'I','S';'R','L'};
                orientationStr = 'HFP';
            elseif isequal(iopProjSign(:), FFS)
                axisLabelCell = {'P','A';'S','I';'R','L'};
                orientationStr = 'FFS';
            else %FFP
                axisLabelCell = {'P','A';'I','S';'R','L'};
                orientationStr = 'FFP';
            end
    end
catch err
    %default HFS
    disp(err);
    disp('Defaulting to HFS orientation');
    axisLabelCell = {'A','P';'R','L';'S','I'};
    orientationStr = 'HFS';
end

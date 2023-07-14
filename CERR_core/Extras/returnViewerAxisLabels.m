function [axisLabelCell,orientationStr,imgOriV] = returnViewerAxisLabels(planC,scanNum)

indexS = planC{end};

if ~exist('scanNum','var') || isempty(scanNum)
    scanNum = 1;
end

try
    imgOriV = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
    
    if isempty(imgOriV)
        imgOriV = [1,0,0,0,1,0]'; % temporary. assign this during loading planC
    end
    
    % Dominant direction for image row
    [~,idx2] = max(abs(imgOriV(1:3)));
    
    % Dominant direction for image column
    [~,idx1] = max(abs(imgOriV(4:end)));
    
    iopProj = zeros(size(imgOriV));
    iopProj(idx1 + 3) = imgOriV(idx1 + 3);
    iopProj(idx2) = imgOriV(idx2);
    
    iopProjSign = iopProj ./ abs(imgOriV);
    
    iopProjSign(isnan(iopProjSign)) = 0;
        
    positiveRCS = {'L','P','S'};
    negativeRCS = {'R','A','I'};
    if any(iopProjSign(4:6) > 0)
        colDir{1} = negativeRCS{iopProjSign(4:6) > 0};
        colDir{2} = positiveRCS{iopProjSign(4:6) > 0};
    else
        colDir{1} = negativeRCS{iopProjSign(4:6) < 0};
        colDir{2} = positiveRCS{iopProjSign(4:6) < 0};
    end
    if any(iopProjSign(1:3) > 0)
        rowDir{1} = negativeRCS{iopProjSign(1:3) > 0};
        rowDir{2} = positiveRCS{iopProjSign(1:3) > 0};
    else
        rowDir{1} = negativeRCS{iopProjSign(1:3) < 0};
        rowDir{2} = positiveRCS{iopProjSign(1:3) < 0};
    end
    sliceNormV = imgOriV([2 3 1]) .* imgOriV([6 4 5]) ...
            - imgOriV([3 1 2]) .* imgOriV([5 6 4]);
    [~,idx3] = max(abs(sliceNormV));
    
    imgpos1 = planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient;
    imgpos2 = planC{indexS.scan}(scanNum).scanInfo(end).imagePositionPatient;
    z1 = - sum(sliceNormV .* imgpos1);
    zlast = - sum(sliceNormV .* imgpos2);    
    if z1 < zlast
        slcDir{1} = positiveRCS{idx3};
        slcDir{2} = negativeRCS{idx3};
    else
        slcDir{1} = positiveRCS{idx3};
        slcDir{2} = negativeRCS{idx3};
    end
    
    axisLabelCell = [colDir;rowDir;slcDir];
    orientationStr = '';
    
catch err
    %default HFS
    disp(err);
    disp('Defaulting to HFS orientation');
    axisLabelCell = {'A','P';'R','L';'S','I'};
    orientationStr = 'HFS';
end

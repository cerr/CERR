function axisLabelCell = returnViewerAxisLabels(planC,scanNum)

indexS = planC{end};

if ~exist('scanNum','var') || isempty(scanNum)
    scanNum = 1;
end

iop = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;

if isempty(iop)
    iop = [1,0,0,0,1,0]; % temporary. assign this during loading planC
end

[~,idx2] = max(abs(iop(1:3)));
[~,idx1] = max(abs(iop(4:end)));

iopProj = zeros(size(iop));
iopProj(idx1 + 3) = iop(idx1 + 3);
iopProj(idx2) = iop(idx2);

iopProjSign = iopProj ./ abs(iop);

iopProjSign(isnan(iopProjSign)) = 0;

% definitions

HFS = [1; 0; 0; 0; 1; 0];
HFP = [-1; 0; 0; 0; -1; 0];
FFS = [-1; 0; 0; 0; 1; 0];
FFP = [1; 0; 0; 0; -1; 0];

if isequal(iopProjSign, HFS)
        axisLabelCell = {'A','P';'R','L';'S','I'};
elseif isequal(iopProjSign, HFP)
        axisLabelCell = {'P','A';'L','R';'S','I'};
elseif isequal(iopProjSign, FFS)
        axisLabelCell = {'A','P';'L','R';'S','I'};
else %FFP
        axisLabelCell = {'P','A';'R','L';'S','I'};
end
            
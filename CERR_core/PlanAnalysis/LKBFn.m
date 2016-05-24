function [EUDv,ntcpV,conf] = LKBFn(EUDv,paramS,varargin)

global planC;

%Get parameters
D50 = paramS.D50;
m = paramS.m;
a = paramS.a;

% EUD for selected struct/dose
if isempty(EUDv)
    structNum = varargin{1};
    doseNum = varargin{2};
    scale = varargin{3};
    [planC, doseBinsV, volsHistV] = getDVHMatrix(planC,structNum,doseNum);
    doseBinsV = scale * doseBinsV;
    EUDv = calc_EUD(doseBinsV, volsHistV, a);
end

%Compute NTCP
tmpv = (EUDv - D50)/(m*D50);
ntcpV = 1/2 * (1 + erf(tmpv/2^0.5));

%Model confidence
conf = []; %%TO DO

end
function [EUDv,ntcpV,conf] = LKB(varargin)

global planC;

%Get parameters
D50 = varargin{3};
m = varargin{4};
a = varargin{5};

%Calculate EUD
EUDv = 0;
% doseNum = varargin{1};
% structNum = varargin{2};
% [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum);
% EUDv = calc_EUD(doseBinsV, volsHistV, a);

%Compute NTCP
tmpv = (EUDv - D50)/(m*D50);
ntcpV = 1/2 * (1 + erf(tmpv/2^0.5));
%Model confidence
conf = []; %%TO DO

end
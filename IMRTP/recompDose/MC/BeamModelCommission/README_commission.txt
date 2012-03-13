load 6MV_50by50_FS5_2 planC
load Varian_MDA_6MV_FS10x10.mat
energy = 6,
numBin = 24,
extraBin = 4,

% LB =   [ 0.6000   -0.1000    1.2000  100.0000    2.0000    0.1000    0.0100    0.0050  0.5]
%UB =   [1.5 0.1   10  1000 4  0.2   0.05  0.04]
% No Horn, LB(7) =0
% LB =   [ 0.6000   -0.1000    1.2000  100.0000    2.0000    0.1000    0.0    0.0050 0.5 ]
% UB =   [1.5 0.1   10  1000 4  0.2   0.0  0.04 2]

LB = [6.0000e-01  -2.5000e-01   1.2000e+00   1.0000e+02   2.0000e+00   9.0000e-01   0   4.0000e-03   3.0000e-01];
UB = [4.0000e+00   2.5000e-01   1.0000e+01   1.0000e+03   5.0000e+00   1.4000e-01   0   1.0000e-02   3.0000e+00];

    
[p ener a enerFF aFF max_doseV doseV_wt] = optSourceModel(planC, energy, numBin, extraBin, FS10x10.PDD(:,1), FS10x10.PDD(:,2), ...
  FS10x10.profile1.depth, FS10x10.profile1.profile(:,1), FS10x10.profile1.profile(:,2),... 
 FS10x10.profile2.depth, FS10x10.profile2.profile(:,1), FS10x10.profile2.profile(:,2),...
 FS10x10.profile3.depth, FS10x10.profile3.profile(:,1), FS10x10.profile2.profile(:,2),...
 FS10x10.profile4.depth, FS10x10.profile4.profile(:,1), FS10x10.profile4.profile(:,2), LB, UB);

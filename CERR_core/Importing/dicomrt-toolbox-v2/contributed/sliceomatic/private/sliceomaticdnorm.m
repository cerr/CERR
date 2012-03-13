function appdata = sliceomaticdnorm(d,norm)
% SLICEOMATICDNORM(rawdata,norm) - Normalize relevant data.

% Simplify the isonormals
d.reduce=d.reduce./norm.*100;
d.reducesmooth=d.reducesmooth./norm.*100;
d.smooth=d.smooth./norm.*100;
d.data=d.data./norm.*100;  
appdata = d;
function [newVOI]=dicomrt_closevoi(VOI)
% dicomrt_closevoi(VOI)
%
% Close VOI contours.
%
% VOI contains VOI contours.
%
% See also: dicomrt_close3dvoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[voi_temp,type,label]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(voi_temp);

newVOI=VOI;
for k=1:size(VOI,1) % loop through the number of VOIs
    for j=1:size(VOI{k,2},1) % loop through the number of slices/VOI
        temp=VOI{k,2}{j};
        isequalx=isequal(temp(1,1,1),temp(end,1,1));
        isequaly=isequal(temp(1,2,1),temp(end,2,1));
        if or(~isequalx,~isequaly)
            temp(end+1,:)=temp(1,:);
            newVOI{k,2}{j}=temp;
        end
    end
end

[newVOI]=dicomrt_restorevarformat(voi_temp,newVOI);
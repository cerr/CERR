function [temp2VOI]=dicomrt_validatevoi(VOI,xmesh,ymesh,zmesh)
% dicomrt_validatevoi(VOI,xmesh,ymesh,zmesh)
% 
% Performs the following operations: 
%  
%  1. delete segments with less than 3 points (which do not define a
%     polygon);
%  2. make sure that segments are defined within CT matrix edges.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[voi_temp,type,label]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(voi_temp);

temp1VOI=VOI;

for k=1:size(VOI,1) % loop through the number of VOIs
    % check for non lines and points
    indToRemove = [];
    for j=1:size(VOI{k,2},1) % loop through the number of segments
       if size(VOI{k,2}{j},1)<3
           warning([VOI{k,1},': contains a segment with less than 3 points. Segment deleted']);
           if size(VOI{k,2},1)<=1
               temp1VOI{k,2}=[];
           else
               indToRemove = [indToRemove j];               
           end
       end
    end
    if ~isempty(temp1VOI{k,2})
        temp1VOI{k,2}(indToRemove)=[];
    end
    if isempty(temp1VOI{k,2})
        temp1VOI{k,2} = [];
    end
end

temp2VOI=temp1VOI;

for k=1:size(VOI,1) % loop through the number of VOIs
   modifyxy=0;
   % check in the XY plane
   for j=1:size(temp1VOI{k,2},1) % loop through the number of segments
       xtemp=temp1VOI{k,2}{j}(:,1);
       ytemp=temp1VOI{k,2}{j}(:,2);
       [minvalx,minlocx]=min(xtemp);
       [maxvalx,maxlocx]=max(xtemp);
       [minvaly,minlocy]=min(ytemp);
       [maxvaly,maxlocy]=max(ytemp);
       while minvalx<min(xmesh)
           temp2VOI{k,2}{j}(minlocx,1)=min(xmesh);
           xtemp=temp2VOI{k,2}{j}(:,1);
           [minvalx,minlocx]=min(xtemp);
           modifyxy=1;
       end
       while maxvalx>max(xmesh)
           temp2VOI{k,2}{j}(maxlocx,1)=max(xmesh);
           xtemp=temp2VOI{k,2}{j}(:,1);
           [maxvalx,maxlocx]=max(xtemp);
           modifyxy=1;
       end
       while minvaly<min(ymesh)
           temp2VOI{k,2}{j}(minlocy,2)=min(ymesh);
           ytemp=temp2VOI{k,2}{j}(:,2);
           [minvaly,minlocy]=min(ytemp);
           modifyxy=1;
       end
       while maxvaly>max(ymesh)
           temp2VOI{k,2}{j}(maxlocy,2)=max(ymesh);
           ytemp=temp2VOI{k,2}{j}(:,2);
           [maxvaly,maxlocy]=max(ytemp);
           modifyxy=1;
       end
   end
end

% Restore variable format
[temp2VOI]=dicomrt_restorevarformat(voi_temp,temp2VOI);
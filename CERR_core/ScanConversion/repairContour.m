function [repairedM, flag] = repairContour(edgeM, optS, offsetV)
%This function fixes the problem of small overlaps
%in contours.  It works by 'excision repair' a la
%DNA excision repair: all regions
%between edges which cross - including the crossing edges,
%are snipped out, and the ends are rejoined in a straight
%line.
%
%
%J.O.Deasy, 27 Feb 02.
%Latest modifications:  11 Mar 02, JOD.
%                  23 Jan 03, JOD, replaced wavelet toolbox routine wshift with vshift.
%                                  Also, made startIDV a double array instead of logical.  This
%                                  fixed a bug when there were two
%                                  excisions on the same contour.
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

flag = 0; %any repairs?

eps = 10^-11;  %to avoid numerical roundoff problems; see below.

numEdges = size(edgeM,1);

cutV = zeros(1, numEdges);

%We find pairs of edges which cross, and always mark the intervals
%inside the pairs (including the endpoints) for excision!
%'Inside' is always taken to the be
%the shortest distance between the edges, in terms of numbers of
%edges between them (not distance, which would be much slower).

for i = 1 : numEdges

   x11 = edgeM(i,1);
   y11 = edgeM(i,2);
   x21 = edgeM(i,3);
   y21 = edgeM(i,4);
   x1mid = (x11 + x21)/2;
   y1mid = (y11 + y21)/2;
   r = ((x21-x11)^2+(y21-y11)^2)^0.5;

   %Get rotation data: theta is the counterclockwise angle by which the i'th
   %edge must be rotated to become vertical.
   if y11 ~= y1mid
     tant = (x11 - x1mid)/(y11 - y1mid);
     t = atan(tant);
     sint = sin(t);
     cost = cos(t);
   elseif x11 < x21  %-90 deg rotation
     sint = 0;
     cost = -1;
   else
     sint = 0;      % + 90 deg rotation
     cost = 1;
   end

   x11 = x11 - x1mid;
   x21 = x21 - x1mid;
   y11 = y11 - y1mid;
   y21 = y21 - y1mid;

   x11p =  x11 * cost - y11 * sint;
   y11p =  x11 * sint + y11 * cost;
   x21p =  x21 * cost - y21 * sint;
   y21p =  x21 * sint + y21 * cost;

   if i ~= 1
     indicesV = i + 2 : numEdges;  %don't include the neighboring edge
   else
     indicesV = i + 2 : numEdges - 1;
   end

   x12V = edgeM(indicesV,1) - x1mid;
   y12V = edgeM(indicesV,2) - y1mid;
   x22V = edgeM(indicesV,3) - x1mid;
   y22V = edgeM(indicesV,4) - y1mid;

   %rotate them:
   x12pV =  x12V * cost - y12V * sint;
   y12pV =  x12V * sint + y12V * cost;
   x22pV =  x22V * cost - y22V * sint;
   y22pV =  x22V * sint + y22V * cost;

   for j = 1 : length(x12V)

     ymax = max(y11p, y21p);
     %ymax = double(single(ymax));
     ymin = min(y11p, y21p);
     %ymin =  double(single(ymin));

     %Do they overlap?  Get the y intercept:
     if x12pV(j) ~= x22pV(j)

       m = (y22pV(j) - y12pV(j)) / (x22pV(j) - x12pV(j)) ;
       b = y12pV(j)  - m * x12pV(j);

       %b =  double(single(b));
       xmin = min(x22pV(j),x12pV(j));
       %xmin =  double(single(xmin));
       xmax = max(x22pV(j),x12pV(j));
       %xmax =  double(single(xmax));

       if b < ymax - eps & b > ymin + eps ...
               & xmin < 0 - eps & xmax > 0 + eps

           p = min(i,indicesV(j));
           q = max(i,indicesV(j));
           d1 = q - p;
           d2 = numEdges - d1;
           if d1 < d2
             %No wrapping - typical case
             cutV(p:q) = 1;
           else
             cutV(q:end) = 1;
             cutV(1:p)   = 1;
           end
       end

     elseif x12pV(j) == 0 & x22pV(j) == 0 &  ...
            ( ( min(y22pV(j), y12pV(j)) < max(y11p, y21p) & min(y22pV(j), y12pV(j)) > min(y11p, y21p) ) ...
             | (max(y22pV(j), y12pV(j)) < max(y11p, y21p) & max(y22pV(j), y12pV(j)) > min(y11p, y21p) ) )%vertical line which overlaps

       %excise
       p = min(i,indicesV(j));
       q = max(i,indicesV(j));
       d1 = q - p;
       d2 = numEdges - d1;
       if d1 <= d2
         %No wrapping - typical case
         cutV(p:q) = 1;
       else
         cutV(q:end) = 1;
         cutV(1:p)   = 1;
       end

     end   %elsif

  end  %second edge

end  %first edge



%-----------Excision repair------------%
%We just (1) eliminate all edges marked for excision, and
%        (2) check to make sure that all the ends are joined by a new inserted edge.

if any(cutV == 1)

  disp('Repairing self-intersecting contour...')

  diffV  = diff([cutV(numEdges), cutV]);
  dV = [diffV == 1];
  startIndexV = find(dV); %marks left end of excised section

  startIDV = double(vshift(dV, 1)); %marks the left edge of remaining sections
                                    %the double is here to startIDV is not
                                    %made a logical array.

  indV = find(startIDV);
  startIDV(indV) = 1:length(indV);   %Use this to number and index the edges to be rejoined.

  numEdges2 = numEdges - find(cutV == 1);

  %--------------Excision--------------%

  indV = [cutV == 0];  %keep these

  %Now remove the same edges from the startID:
  startIDV = startIDV(indV(:));

  %-----------Break rejoining------------%

  repairedM    = edgeM(indV(:),:);
  numEdges2 = size(repairedM,1);

  len = length(startIndexV);
  for i = 1 : len

    ind = find(startIDV == i); %where is the break end?

    [ind2] = cycle(ind+1, numEdges2);
    %Add an edge:
    newEdgeV = [repairedM(ind,3:4), repairedM(ind2,1:2)];
    %insert it
    repairedM = [repairedM(1:ind,:); newEdgeV; repairedM(ind+1:numEdges2,:)];

    %update startIDV:
    startIDV = [startIDV(1:ind), 0, startIDV(ind+1:numEdges2)];

    numEdges2 = numEdges2 + 1;

  end

  flag = 1;  %edges have been repaired.

else

  repairedM = edgeM;

end


if isempty(edgeM)
  %disp('dummy')
  disp('edgeM is empty') % ES Aug 2003
end


%-----------end---------------------%







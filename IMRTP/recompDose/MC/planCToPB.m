function [xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, beamGeometry]=...
planCToPB(planC, beamNumber, bResx, bResy);

indexS=planC{end};
% assume the words Isocenter Coordinates are enclosed by quotes
% look for the end quotes to denote the begining of the actual numbers
s=planC{indexS.beamGeometry}(beamNumber).file{1};
ind=max(strfind(s, '"'));
isocenter=str2num(s(ind+1:end));
indiceJaws = 2;

% Note: In the RTOG files export by Pinnacle, the isocenter is defined at
% the first three field of 
% planC{indexS.beamGeometry}(beamNumber).file
% Not the the first field only.
if (length(isocenter) == 1) 
isocenter(1)=str2num(s(ind+1:end));
isocenter(2)=str2num(planC{indexS.beamGeometry}(beamNumber).file{2});
isocenter(3)=str2num(planC{indexS.beamGeometry}(beamNumber).file{3});
indiceJaws = 4;
end

gantryAngle=planC{indexS.beamGeometry}(beamNumber).gantryAngle;
isoDistance=planC{indexS.beamGeometry}(beamNumber).nominalIsocenterDistance;
beamEnergy = planC{indexS.beamGeometry}(beamNumber).beamEnergyMeV;


% if planC{indexS.beamGeometry}(beamNumber).file has only 
% 3 entries, then this is a square field defined by collimator
  s=planC{indexS.beamGeometry}(beamNumber).file{indiceJaws};
  ind=max(strfind(s, '"'));
  xjaws=str2num(s(ind+1:end));
  if(length(xjaws)==1), 
      xjaws = [xjaws/2 xjaws/2];
  end
  
  s=planC{indexS.beamGeometry}(beamNumber).file{indiceJaws+1};
  ind=max(strfind(s, '"'));
  yjaws=str2num(s(ind+1:end));
  if(length(yjaws)==1), 
      yjaws = [yjaws/2 yjaws/2];
  end
  
  xjaws(1)=-xjaws(1);
  % by symmetry with the below(line 45),
  % I think I should swap the positive and negative y jaws) ??
  yjaws(3)=yjaws(1);
  yjaws(1)=-yjaws(2);
  yjaws(2)=yjaws(3);
  yjaws(3)=[];

if(length(planC{indexS.beamGeometry}(beamNumber).file)<7), 
  % no MLC or block shapes
  % field is formed by the collimator jaws
  MLC = 0;
%   for i=1:yjaws(2)-yjaws(1), 
%      x1(i)=xjaws(1);
%      xend(i)=xjaws(2);
%      vertices_y(i)=yjaws(1)-1+i;
%      vertices_ywidth(i) = 1;
%    end
   beamletInput.miny=yjaws(1);
  beamletInput.maxy=yjaws(2);
%   input = [];
%   input(:,1) = [x1'; xend'];
%   input(:,2) = [vertices_y'; vertices_y'];
  beamletInput.xjaws=xjaws;
  beamletInput.yjaws=yjaws;

else
  MLC = 1;
  s=planC{indexS.beamGeometry}(beamNumber).file{7};
  ind=max(strfind(s, '"'));
  numPairs=str2num(s(ind+1:end));
  for i=1:numPairs, 
    input(i, :)=str2num(planC{indexS.beamGeometry}(beamNumber).file{7+i});
  end
  
  % +Y towards head, -Y towards feet (looking from BEV)
  input(:, 2)=-1*input(:,2);

 % now, calculate the intersect between the jaws and the MLC/block
  % taking into account the collimator rotation
  % jaws and collimator are both rotated EXACTLY the same way, so this is
  % just stupid!
  
  midPointx = xjaws(2) - (xjaws(2) - xjaws(1))/2;
  midPointy = yjaws(2) - (yjaws(2) - yjaws(1))/2;
  
 ind = find(input(:,1)>=midPointx & input(:,1)>xjaws(2));
  if(~isempty(ind)), 
    input(ind, 1) = xjaws(2);
  end
  ind = find(input(:,1)<midPointx & input(:,1)<xjaws(1));
  if(~isempty(ind)), 
    input(ind, 1) = xjaws(1);
  end
  
  ind = find(input(:,2)>=midPointy & input(:,2)>yjaws(2));
  if(~isempty(ind)), 
    input(ind, 2) = yjaws(2);
  end
  ind = find(input(:,2)<midPointy & input(:,2)<yjaws(1));
  if(~isempty(ind)), 
    input(ind, 2) = yjaws(1);
  end
end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % input is list of 2xn points that form the corners of the polygon
  % want to sort this into rectangles, with lower-left corners (x, y) and
  % width and height (w, h)
  
  
  % assume plan is MLC

  
  beamGeometry.isoDistance = isoDistance;
  beamGeometry.beamEnergy = beamEnergy;
  beamGeometry.isocenter=isocenter;
  beamGeometry.gantryAngle=gantryAngle;
  beamGeometry.collimatorAngle=planC{indexS.beamGeometry}(beamNumber).collimatorAngle;
  beamGeometry.couchAngle=planC{indexS.beamGeometry}(beamNumber).couchAngle;  
  
  
  
  beamN=planC{indexS.beamGeometry}(beamNumber);
  if(MLC==0), 
      % different function if the field shaping is done just by the
      % collimator jaws
      nBeamletx = ceil(diff(beamletInput.xjaws)/bResx)+1;
      nBeamlety = ceil(diff(beamletInput.yjaws)/bResy)+1;
      xvals = linspace(beamletInput.xjaws(1), beamletInput.xjaws(2), nBeamletx); 
      yvals = linspace(beamletInput.yjaws(1), beamletInput.yjaws(2), nBeamlety); 
      for i=1:length(yvals)-1, 
          beamlets{i} = xvals;
          beamletsy{i} = yvals(i);
          beamletsDeltay{i} = yvals(i+1) - yvals(i);
      end
      
  else   
      [x1, xend, vertices_y, vertices_ywidth]=cornersMLC(input);
      % redo setting y-vertices based on jaws
      if(vertices_y(1)<yjaws(1))
          vertices_y(1) = yjaws(1);
          vertices_ywidth(1) = vertices_y(2) -vertices_y(1);
      end
      if(vertices_y(end)+vertices_ywidth(end)>yjaws(2))
          vertices_ywidth(end) = yjaws(2) - vertices_y(end);
      end
      
      beamletInput.input=input;
      beamletInput.miny=min(input(:,2));
      beamletInput.maxy=max(input(:,2));
      beamletInput.x1=x1;
      beamletInput.xend=xend;
      beamletInput.vertices_y=vertices_y;
      beamletInput.vertices_ywidth=vertices_ywidth;
      beamletInput.xjaws=xjaws;
      beamletInput.yjaws=yjaws;
      
      numBeamlets=ceil((xend-x1)/bResx)+1;
      %numBeamlets_y=ceil(length(vertices_y)/bResy);
      
      numcopies = ceil(vertices_ywidth/bResy);
      % still need to deal with "fractional" number of copies
      
      for i=1:length(x1), 
          beamlets{i}=linspace(x1(i), xend(i), numBeamlets(i));
      end
      
      cntr=1;
      
      beamletsOrig = beamlets;
      beamlets = [];
      
      for i=1:length(beamletsOrig), 
          if(numcopies(i)==1), 
              y=vertices_y(i);
              beamletsy{cntr} = y;
              ynext = vertices_y(i)+vertices_ywidth(i);
              beamletsDeltay{cntr} = ynext - y;
              beamlets{cntr} = beamletsOrig{i};
              cntr = cntr+1;
          else     
              for k=1:numcopies(i)
                  y=vertices_y(i) + bResy*(k-1);
                  beamletsy{cntr} = y;
                  ynext=y+bResy;
                  beamletsDeltay{cntr} = ynext -y;
                  beamlets = insertCellEntry(beamlets, cntr, beamletsOrig{i});
                  cntr=cntr+1;
              end
          end
      end
      
  end
  
  xPosV = [];
  yPosV = [];
  beamlet_delta_x = [];
  beamlet_delta_y = [];
  
  for i = 1:length(beamlets)
      n = length(beamlets{i})-1;
      xPosV = [xPosV beamlets{i}(1:n)];
      beamlet_delta_x = [beamlet_delta_x diff(beamlets{i})];
      yPosV = [yPosV ones(1, n)*beamletsy{i}];
      beamlet_delta_y = [beamlet_delta_y ones(1, n)*beamletsDeltay{i}];
  end
  
  % need to move the position to the center of the voxel?
  xPosV = xPosV + beamlet_delta_x/2;
  yPosV = yPosV + beamlet_delta_y/2;
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [x1, xend, vertices_y, vertices_ywidth]=cornersMLC(input);
  
  input(:,1) = round(input(:,1)*10)/10;
  % assume 0.5 cm leaf width as the narrowest
  input(:,2) = round(input(:,2)*2)/2;
  
  input = checkInputPoints(input);
  miny=min(input(:,2));
  maxy=max(input(:,2));
  
  yvalues=sort(unique(input(:,2)));
  
  % Have to deal with the case that the 1st and/or last MLC positions 
  % are caused by collimator jaws not MLC
  
  % still assuming 1 cm leaf widths, so
  
  %if((mod(miny, 1)~=0) | mod(maxy, 1)~=0)
  
  % miny1=floor(miny);
  % maxy1=ceil(maxy);
  % input(input(:,2)==miny, 2)=miny1;
  % input(input(:,2)==maxy, 2)=maxy1;
  % 
  % miny=miny1;
  % maxy=maxy1;
  
  % numRect=maxy-miny+1;
  % 
  % for i=1:numRect
  %     vertices{i}=sort(input(input(:,2)==i+miny-1, 1));
  %     vertices_y(i)=i+miny-1;
  % end
  
  numRect=length(yvalues);
  
  for i=1:numRect
      vertices{i}=sort(input(input(:,2)==yvalues(i), 1));
      vertices_y(i)=yvalues(i);
  end
  
  if(length(vertices{1}>2)), 
      vertices{1} = unique(vertices{1});
  end
  if(length(vertices{end}>2)), 
      vertices{end} = unique(vertices{end});
  end
  
  for i = 2:length(vertices)-1, 
      if(length(vertices{i})>4) 
          vertices{i} = unique(vertices{i});
      end
  end
  
  % for i = 2:length(vertices)-1, 
  %     if(length(vertices{i}==2)), 
  %         % either left or right side MLC positions not given because leaf
  %         % same as leaf above and below
  %         
  
  
  
  x1(1)=vertices{1}(1);
  xend(1)=vertices{1}(end);
  
  
  %find the points in each line which are also in the next line
  % because the vertices are sorted, 1:2 will be left, and 3:4 will be right
  % vertices
  
  % june30, 2005, if it's a straight vertical line, there may be only 2
  % vertices!
  
  for i=2:numRect-1
      %     if(length(vertices{i} == 2)), 
      %         x1(i) = vertices{i}(1);
      %         xend(i) = vertices{i}(2);
      %     else
      
      t=vertices{i}(1:2);
      if(t(1)==t(2)), 
          x1(i)=t(1);
      else   
          x1(i)=t(t~=x1(i-1));
      end
      t=vertices{i}(3:4); 
      if(t(1)==t(2)),
          xend(i)=t(1);
      else
          xend(i)=t(t~=xend(i-1));
      end
      % end
      
  end
  
  vertices_ywidth = diff(vertices_y);
  vertices_y=vertices_y(1:end-1);
  

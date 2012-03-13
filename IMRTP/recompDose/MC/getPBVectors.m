function [xPosV,yPosV,beamlet_delta_x,beamlet_delta_y,w_field] = getPBVectors(PBX,rowLeafPositions,xV,yV,inflMap);

f = 1;

for k = 1:length(PBX),
    for j = 1:length(PBX(k).vectorXTresh)-1,
        beamlet_delta_yF(f) = yV(rowLeafPositions(k+1)) - yV(rowLeafPositions(k));
        beamlet_delta_xF(f) = PBX(k).vectorXTresh(j+1) - PBX(k).vectorXTresh(j);
        xPosVF(f) = PBX(k).vectorXTresh(j) + (PBX(k).vectorXTresh(j+1) - PBX(k).vectorXTresh(j))/2;
        yPosVF(f) = yV(rowLeafPositions(k)) + (yV(rowLeafPositions(k+1)) - yV(rowLeafPositions(k)))/2;
        f = f+1;
    end
end


BeamletLeftDivider = interp1(xV, 1:length(xV), xPosVF-beamlet_delta_xF/2);
BeamletRightDivider = interp1(xV, 1:length(xV), xPosVF+beamlet_delta_xF/2);
BeamletTopDivider = interp1(yV, 1:length(yV), yPosVF-beamlet_delta_yF/2);
BeamletBottomDivider = interp1(yV, 1:length(yV), yPosVF+beamlet_delta_yF/2);


if ~isempty( find(isnan(BeamletTopDivider)))
    if min(find(isnan(BeamletTopDivider))) == 1
        BeamletTopDivider(find(isnan(BeamletTopDivider))) = 1;
    elseif max(find(isnan(BeamletTopDivider))) == length(BeamletTopDivider)
        BeamletTopDivider(find(isnan(BeamletTopDivider))) = length(yV);
    end
end

if ~isempty( find(isnan(BeamletBottomDivider)))
    if min(find(isnan(BeamletBottomDivider))) == 1
        BeamletButtomDivider(find(isnan(BeamletBottomDivider))) = 1;
    elseif max(find(isnan(BeamletBottomDivider))) == length(BeamletBottomDivider)
        BeamletBottomDivider(find(isnan(BeamletBottomDivider))) = length(yV);
    end
end

if ~isempty( find(isnan(BeamletLeftDivider)))
    if min(find(isnan(BeamletLeftDivider))) == 1
        BeamletLeftDivider(find(isnan(BeamletLeftDivider))) = 1;
    elseif max(find(isnan(BeamletLeftDivider))) == length(BeamletLeftDivider)
        BeamletLeftDivider(find(isnan(BeamletLeftDivider))) = length(xV);
    end
end

if ~isempty( find(isnan(BeamletRightDivider)))
    if min(find(isnan(BeamletRightDivider))) == 1
        BeamletRightDivider(find(isnan(BeamletRightDivider))) = 1;
    elseif max(find(isnan(BeamletRightDivider))) == length(BeamletRightDivider)
        BeamletRightDivider(find(isnan(BeamletRightDivider))) = length(xV);
    end
end

if ~isempty( find(isnan(BeamletRightDivider)))
    if (xPosVF(find(isnan(BeamletRightDivider)))+beamlet_delta_xF(find(isnan(BeamletRightDivider)))/2) == max(xPosVF+beamlet_delta_xF/2)
       BeamletRightDivider(find(isnan(BeamletRightDivider))) = length(xV);
    end
end

s = size(inflMap);
%Edge correction for Right Leaf
for k = 1:length(xPosVF),  
    if BeamletRightDivider(k) > s(2)
        zi = inflMap(uint32(BeamletTopDivider(k):(BeamletBottomDivider(k)-1)), uint32(BeamletLeftDivider(k):(BeamletRightDivider(k)-1)));
    else
        zi = inflMap(uint32(BeamletTopDivider(k):(BeamletBottomDivider(k)-1)), uint32(BeamletLeftDivider(k):(BeamletRightDivider(k))));
    end
    
    if ~isempty(zi)
        w(k) = mean(zi(:));
    else
        w(k) = 0;
    end 
    if isnan(w(k))
        disp('1');
    end
end

w_ind = find(w);
w_field = w(w_ind);

beamlet_delta_y = beamlet_delta_yF(w_ind);
beamlet_delta_x = beamlet_delta_xF(w_ind);
xPosV = xPosVF(w_ind);
yPosV = yPosVF(w_ind);
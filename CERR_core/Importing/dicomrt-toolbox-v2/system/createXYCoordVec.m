function [xyVec] = createXYCoordVec(start,pix,dim,dir)
% createXYCoordVec
%
% Create one dimensional vector

if strcmpi(dir,'pos')% positive direction
    for i=1:dim
        xyVec(i)=start+(pix.*i)-pix;
    end
    
elseif strcmpi(dir,'neg')% negative direction
    for i=1:dim
        xyVec(i)=start-(pix.*i)+pix;
    end
end
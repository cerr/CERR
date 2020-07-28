function planC = annotatePlanCForXNAT(planC, xhost,xexp,xproj,xsubj)
% function planC = annotatePlanCForXNAT(planC, xhost,xexp,xproj,xsubj)
%
% This function adds XNAT addressing metadata to an existing planC

if nargin < 3 || isempty(xproj)
    xproj = '';
    if isempty(xsubj)
        xsubj = '';
    end
end

indexS = planC{end};
planC{indexS.header}.xnatInfo = struct('host',xhost,'experiment_id',xexp,'project_id',xproj,'subject_id',xsubj);

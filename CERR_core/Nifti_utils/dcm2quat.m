
%% Subfunction, Convert 3x3 direction cosine matrix to quaternion
% Simplied from Quaternions by Przemyslaw Baranski 
function [q, proper] = dcm2quat(R)
% [q, proper] = dcm2quat(R)
% Retrun quaternion abcd from normalized matrix R (3x3)
proper = sign(det(R));
if proper<0, R(:,3) = -R(:,3); end

q = sqrt([1 1 1; 1 -1 -1; -1 1 -1; -1 -1 1] * diag(R) + 1) / 2;
if ~isreal(q(1)), q(1) = 0; end % if trace(R)+1<0, zero it
[mx, ind] = max(q);
mx = mx * 4;

if ind == 1
    q(2) = (R(3,2) - R(2,3)) /mx;
    q(3) = (R(1,3) - R(3,1)) /mx;
    q(4) = (R(2,1) - R(1,2)) /mx;
elseif ind ==  2
    q(1) = (R(3,2) - R(2,3)) /mx;
    q(3) = (R(1,2) + R(2,1)) /mx;
    q(4) = (R(3,1) + R(1,3)) /mx;
elseif ind == 3
    q(1) = (R(1,3) - R(3,1)) /mx;
    q(2) = (R(1,2) + R(2,1)) /mx;
    q(4) = (R(2,3) + R(3,2)) /mx;
elseif ind == 4
    q(1) = (R(2,1) - R(1,2)) /mx;
    q(2) = (R(3,1) + R(1,3)) /mx;
    q(3) = (R(2,3) + R(3,2)) /mx;
end
if q(1)<0, q = -q; end % as MRICron
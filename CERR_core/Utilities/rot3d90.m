function B = rot3d90(A, X, K)
% ROT3D90 - rotate 3D array 90 degrees around a specific axis
%
%   B = rot3D90(A, X) is the 90 degree counterclockwise rotation of the 3D
%   array A along a specific axis. X denotes the plane of rotation,
%   according to the table below. For instance, when X is 1 the plane of
%   rotation is formed by the 2nd and 3rd dimension.
%
%   rot3d90(A, X, K) is the K*90 degree rotation of A, K = +-1,+-2,...
%
%   If A has a dimension of [N, M, L], the dimensions of the rotation
%   depend on X. For value of X, the subindex in the X-th dimension will be
%   unaffected. Therefore, specific vectors will be unaffected.
%   Note that rot3d90(A,3) and rot90(A) produce the same result.
%
%      X    Rotation plane    Dimension of B   Unaffected vectors
%     - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%      1    dims 2 & 3        [N, L, M]        N-by-1 (row)
%      2    dims 1 & 3        [L, M, N]        1-by-N (column)
%      3    dims 1 & 2        [M, N, L]        1-by-1-by-N (plane)
%
%   Example:
%      A = cat(3,[1 2 ; 3 4],[5 6 ; 7 8])
%      B = rot3d90(A, 2) % rotation in plane formed by 1st and 3rd dimension
%      % B(:,:,1) = 5  6
%      %            1  2
%      % B(:,:,2) = 7  8
%      %            3  4
%
%   See also ROT90, FLIP

% version 3.1, jan 2018
% (c) Jos van der Geest
% email: samelinoa@gmail.com
% FEX: http://www.mathworks.nl/matlabcentral/fileexchange/authors/10584

% 1.0 (jan 2018) created, using rot90 and permute
% 2.0 (jan 2018) replaced calls to rot90 by direct permuting and flipping
% 3.0 (jan 2018) added K, specifiying the number of rotations
% 3.1 (jan 2018) fixed an error for 2D arrays inputs

narginchk(2, 3)

if nargin == 2
    K = 1 ;
else
    if ~isscalar(K) || fix(K) ~= K
        error('rot3d90:KInvalid', 'K should be a scalar integer.');
    end
    K = mod(K, 4) ; % after 4 rotations we are back to A
end

B = A ;
for j = 1:K 
    switch X
        case 1
            % rotation in the plane formed by the 2nd and 3rd dimension
            % N-by-1-by-1 (column) vectors stay the same
            % for all elements, the subindex in the 1st dim does not change
            B = permute(B, [1 3 2 4:ndims(B)]);
            B = flip(B,2);
        case 2
            % rotation in the plane formed by 1st and 3rd dimension
            % 1-by-N-by-1 (row) vectors stay the same
            % for all elements, the subindex in the 2nd dim does not change
            B = permute(B, [2 3 1 4:ndims(B)]) ;
            B = flip(B, 2);
            B = permute(B, [2 1 3:ndims(B)]);
        case 3
            % rotate in the plane formed by 1st and 2nd dimension
            % 1-by-1-by-N vectors stay the same
            % for all elements, the subindex in the 3rd dim does not change
            B = flip(B, 2);
            B = permute(B, [2 1 3:ndims(B)]);
        otherwise
            error('rot3d90:XInvalid', 'Invalid rotation axis. X should be 1, 2, or 3.') ;
    end
end




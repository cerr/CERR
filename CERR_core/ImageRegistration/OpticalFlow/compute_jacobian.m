function jac = compute_jacobian(v,u,w)
%
% To compute Jacobian determinant for the image deformation field
% Usage: jac = compute_jacobian(vy,vx,vz);
%
[a11,a12,a13] = gradient_3d_by_mask(u); clear u;
[a21,a22,a23] = gradient_3d_by_mask(v); clear v;
[a31,a32,a33] = gradient_3d_by_mask(w); clear w;
a11 = a11+1;
a22 = a22+1;
a33 = a33+1;

jac = a11.*a22.*a33-a11.*a23.*a32-a21.*a12.*a33+a21.*a13.*a32+a31.*a12.*a23-a31.*a13.*a22;

function [locxmesh,locymesh,loczmesh] = dicomrt_rebuildmatrix(locxmesh_lv,locymesh_lv,loczmesh_lv)
% dicomrt_rebuildmatrix(locxmesh_lv,locymesh_lv,loczmesh_lv)
%
% Build 3D matrices from vectors using meshgrid.
% 
% locxmesh_lv,locymesh_lv,loczmesh_lv are vectors. 
% locxmesh,locymesh,loczmesh are 3D matrices built for use with algorithm 
%     which work on matrices instead of vectors.
%
% User should not need to call this function
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Rebuild 3d mesh matrices
[locxmesh,locymesh,loczmesh]=meshgrid(locxmesh_lv,locymesh_lv,loczmesh_lv);
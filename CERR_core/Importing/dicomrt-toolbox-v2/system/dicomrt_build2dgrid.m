function [locxmesh,locymesh] = dicomrt_build2dgrid(locxmesh_lv,locymesh_lv)
% dicomrt_build2dgrid(locxmesh_lv,locymesh_lv)
%
% Build 2D grid.
%
% User should not need to call this function
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Rebuild 2d mesh matrices
[locxmesh,locymesh]=meshgrid(locxmesh_lv,locymesh_lv);
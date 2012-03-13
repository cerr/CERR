function [tags] = dicomrt_d2c_rtogtags
% dicomrt_d2c_rtogtags
%
% Create RTOG tags used by d2c functions to share information while
% converting data from DICOM to RTOG 
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Construct the scan structure
tags.hio                    = [];
tags.pos                    = [];
tags.xOffset                = [];
tags.yOffset                = [];
tags.coord1OFFirstPoint     = [];
tags.coord2OFFirstPoint     = [];
tags.horizontalGridInterval = [];
tags.verticalGridInterval   = [];
tags.xcoordOfNormaliznPoint = [];
tags.ycoordOfNormaliznPoint = [];
tags.zcoordOfNormaliznPoint = [];
tags.grid1Units             = [];
tags.grid2Units             = [];
tags.originalCTxmesh        = [];
tags.originalCTymesh        = [];
tags.originalCTzmesh        = [];
tags.dicomPatientPosition   = [];
tags.nimages                = [];
function V1 = accumulate(V1,V2,indV)
%Accumulate a histogram.  Put elements
%of V2 into V1 according to the indices indV.
%JOD.
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
for i = 1 : length(V2)
  V1(indV(i)) = V1(indV(i)) + V2(i);
end


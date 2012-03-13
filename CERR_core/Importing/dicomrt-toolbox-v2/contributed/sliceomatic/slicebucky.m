function slicebucky
% SLICEBUCKY - Make a bucky ball approximation for sliceomatic

% Written by Eric Ludlam <eludlam@mathworks.com>
% Copyright 2002 The MathWorks Inc

  disp('Creating bucky ball approximation...');
  [b,v]=bucky;
  centers=32+20*v;
  v=blinnblob(centers,64,64,64);
  
  disp('Starting Sliceomatic');
  sliceomatic(v)
  
  daspect([1 1 1]);
  xlim([1 64]);
  ylim([1 64]);
  zlim([1 64]);

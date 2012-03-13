function appdata = sliceomaticsetdata(d,xmesh,ymesh,zmesh)
% SLICEOMATICSETDATA(rawdata) - Create the data used for
% sliceomatic in the appdata D.

% Check variables
error(nargchk(1,4,nargin))

% Simplify the isonormals
  disp('Smoothing for IsoNormals...');
  d.smooth=smooth3(d.data);  % ,'box',5);
  d.reducenumbers=[floor(size(d.data,2)/20)...
          floor(size(d.data,1)/20)...
          floor(size(d.data,3)/20) ];
  d.reducenumbers(d.reducenumbers==0)=1;


  if nargin == 4
      % Reorder vectors: make them horizontal (prepare to flipdim)
      if size(xmesh,1)>size(xmesh,2) 
          xmesh=xmesh';
      end
      if size(ymesh,1)>size(ymesh,2) 
          ymesh=ymesh';
      end
      if size(zmesh,1)>size(zmesh,2) 
          zmesh=zmesh';
      end
      % Set axis orientation
      xdir='normal';
      ydir='normal';
      zdir='normal';
      if issorted(xmesh)~=1
          xmesh=flipdim(xmesh,2);
          xdir='reverse';
          d.xlim = [xmesh(1) xmesh(end)];
          xmesh=flipdim(xmesh,2);
      else
          d.xlim = [xmesh(1) xmesh(end)];
      end
      if issorted(ymesh)~=1
          ymesh=flipdim(ymesh,2);
          ydir='reverse';
          d.ylim = [ymesh(1) ymesh(end)];
          ymesh=flipdim(ymesh,2);
      else
          d.ylim = [ymesh(1) ymesh(end)];
      end
      % This should not be the case for medical images
      if issorted(zmesh)~=1
          zmesh=flipdim(zmesh,2);
          zdir='reverse';
          d.zlim = [zmesh(1) zmesh(end)];
          zmesh=flipdim(zmesh,2);
      else
          d.zlim = [zmesh(1) zmesh(end)];
      end
      
      % Vol vis suite takes numbers in X/Y form.
      ly = 1:d.reducenumbers(1):size(d.data,2);
      lx = 1:d.reducenumbers(2):size(d.data,1);
      lz = 1:d.reducenumbers(3):size(d.data,3);
      
      for i = 1:length(ly)
          ly(i) = xmesh(ly(i));
      end
      for i = 1:length(lx)
          lx(i) = ymesh(lx(i));
      end
      for i = 1:length(lz)
          lz(i) = zmesh(lz(i));
      end
        
      d.reducelims={ ly lx lz };
      disp('Generating reduction volume...');
      d.reduce= reducevolume(d.data,d.reducenumbers);
      d.reducesmooth=smooth3(d.reduce,'box',5);
      % Set axis
      %d.xlim = [xmesh(1) xmesh(end)];
      %d.ylim = [ymesh(1) ymesh(end)];
      %d.zlim = [zmesh(1) zmesh(end)];
      d.xmesh = xmesh;
      d.ymesh = ymesh;
      d.zmesh = zmesh;
        d.xdir = xdir;
        d.ydir = ydir;
        d.zdir = zdir;
      
  else
        % Vol vis suite takes numbers in X/Y form.
        ly = 1:d.reducenumbers(1):size(d.data,2);
        lx = 1:d.reducenumbers(2):size(d.data,1);
        lz = 1:d.reducenumbers(3):size(d.data,3);
        
        d.reducelims={ ly lx lz };
        disp('Generating reduction volume...');
        d.reduce= reducevolume(d.data,d.reducenumbers);
        d.reducesmooth=smooth3(d.reduce,'box',5);

        d.xlim = [1 size(d.data,2)];
        d.ylim = [1 size(d.data,1)];
        d.zlim = [1 size(d.data,3)];
        d.xmesh = nan;
        d.ymesh = nan;
        d.zmesh = nan;
        d.xdir = 'normal';
        d.ydir = 'normal';
        d.zdir = 'normal';
    end
  
  appdata = d;
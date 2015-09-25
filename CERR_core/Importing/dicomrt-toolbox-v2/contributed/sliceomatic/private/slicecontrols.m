function slicecontrols(fig,onoff,xmesh,ymesh,zmesh,xdir,ydir,zdir)
% Convert figure to contain controls for manipulating slices.

% Check variables
error(nargchk(2,8,nargin))

  d = getappdata(fig, 'sliceomatic');
  
  if onoff
      
      if nargin==8
          set(0,'currentfigure',fig);
          set([d.axx d.axy d.axz] ,'handlevisibility','on');
          
          set(fig,'currentaxes',d.axx);
          set(d.axx, 'xlim',[xmesh(1) xmesh(end)],...
              'ylim',[1 5]);
          set(d.pxx, 'vertices',[ xmesh(1) xmesh(1) -1; xmesh(end) xmesh(1) -1; xmesh(end) 5 -1; xmesh(1) 5 -1],...
              'faces',[ 1 2 3 ; 1 3 4]);
          
          title('X Slice Controller');
          
          set(fig,'currentaxes',d.axy);
          set(d.axy, 'xlim',[1 5],...
              'ylim',[ymesh(1) ymesh(end)]);
          set(d.pxy, 'vertices',[ ymesh(1) ymesh(1) -1; ymesh(1) ymesh(end) -1; 5 ymesh(end) -1; 5 ymesh(1) -1],...
              'faces',[ 1 2 3 ; 1 3 4]);
          title('Y Slice');

          set(fig,'currentaxes',d.axz);
          set(d.axz, 'xlim',[1 5],...
              'ylim',[zmesh(1) zmesh(end)]);
          set(d.pxz, 'vertices',[ zmesh(1) zmesh(1) -1; zmesh(1) zmesh(end) -1; 5 zmesh(end) -1; 5 zmesh(1) -1],...
              'faces',[ 1 2 3 ; 1 3 4]);
          title('Z Slice');
          
          set([d.axx d.axy d.axz] ,'handlevisibility','off');
          
          set(d.axx,'xdir',xdir);
          set(d.axy,'ydir',ydir);
          set(d.axz,'zdir',zdir);
    
      else
          
    set(0,'currentfigure',fig);
    set([d.axx d.axy d.axz] ,'handlevisibility','on');
    
    set(fig,'currentaxes',d.axx);
    set(d.axx, 'xlim',[1 size(d.data,2)],...
               'ylim',[1 5]);
    set(d.pxx, 'vertices',[ 1 1 -1; size(d.data,2) 1 -1; size(d.data,2) 5 -1; 1 5 -1],...
               'faces',[ 1 2 3 ; 1 3 4]);
    title('X Slice Controller');
    
    set(fig,'currentaxes',d.axy);
    set(d.axy, 'xlim',[1 5],...
               'ylim',[1 size(d.data,1)]);
    set(d.pxy, 'vertices',[ 1 1 -1; 1 size(d.data,1) -1; 5 size(d.data,1) -1; 5 1 -1],...
               'faces',[ 1 2 3 ; 1 3 4]);
    title('Y Slice');

    set(fig,'currentaxes',d.axz);
    set(d.axz, 'xlim',[1 5],...
               'ylim',[1 size(d.data,3)]);
    set(d.pxz, 'vertices',[ 1 1 -1; 1 size(d.data,3) -1; 5 size(d.data,3) -1; 5 1 -1],...
               'faces',[ 1 2 3 ; 1 3 4]);
    title('Z Slice');

    set([d.axx d.axy d.axz] ,'handlevisibility','off');
    
end

  else
    
    % Disable these controls.  Perhaps hide all slices?
    
  end
                   

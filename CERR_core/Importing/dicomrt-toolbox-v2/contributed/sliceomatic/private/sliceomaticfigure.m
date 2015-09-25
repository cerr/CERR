function appdata=sliceomaticfigure(d,xmesh,ymesh,zmesh)
% FIG=SLICEOMATICFIGURE (D) - 
% Create the figure window to be used by the sliceomatic GUI.
% D is the app data to attach to the figure

% Check variables
error(nargchk(1,4,nargin))

% Init sliceomatic
  figure('name','Slicematic','toolbar','none');
  lim=[min(min(min(d.data))) max(max(max(d.data)))];
  if nargin==4
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
      end
      if issorted(ymesh)~=1
          ymesh=flipdim(ymesh,2);
          ydir='reverse';
      end
      % This should not be the case for medical images
      if issorted(zmesh)~=1
          zmesh=flipdim(zmesh,2);
          zdir='reverse';
      end
      % Update data structure
      d.axmain = axes('units','normal','pos',[.2  .2 .6 .6],'box','on',...
          'ylim',[ymesh(1) ymesh(end)],...
          'xlim',[xmesh(1) xmesh(end)],...
          'zlim',[zmesh(1) zmesh(end)],...
          'clim',lim,...
          'alim',lim);
      % Set axes direction
      set(gca,'XDir',xdir,'YDir',ydir,'ZDir',zdir);
    else
      d.axmain = axes('units','normal','pos',[.2  .2 .6 .6],'box','on',...
          'ylim',[1 size(d.data,1)],...
          'xlim',[1 size(d.data,2)],...
          'zlim',[1 size(d.data,3)],...
          'clim',lim,...
          'alim',lim);
  end
  
  xlabel X
  ylabel Y
  zlabel Z
  daspect([1 1 1]);
  view(3);
  axis tight vis3d;
  hold on;
  grid on;
  
  % Set up the four controller axes.
  d.axx    = axes('units','normal','pos',[.2  .81 .6 .1],'box','on',...
                  'ytick',[],'xgrid','on','xaxislocation','top',...
                  'zlim',[-2 1 ],...
                  'layer','top',...
                  'color','none');
  d.pxx    = patch('facecolor',[1 1 1],...
                   'facealpha',.6,...
                   'edgecolor','none',...
                   'hittest','off');
  setappdata(d.axx,'motionpointer','SOM bottom');
  d.axy    = axes('units','normal','pos',[.05 .05 .1 .75],'box','on',...
                  'xtick',[],'ygrid','on',...
                  'zlim',[-2 1 ],...
                  'layer','top',...
                  'color','none');
  d.pxy    = patch('facecolor',[1 1 1],...
                   'facealpha',.6,...
                   'edgecolor','none',...
                   'hittest','off');
  setappdata(d.axy,'motionpointer','SOM right');
  d.axz    = axes('units','normal','pos',[.85 .05 .1 .75],'box','on',...
                  'xtick',[],'ygrid','on','yaxislocation','right',...
                  'zlim',[-2 1 ],...
                  'layer','top',...
                  'color','none');
  d.pxz    = patch('facecolor',[1 1 1],...
                   'facealpha',.6,...
                   'edgecolor','none',...
                   'hittest','off');
  setappdata(d.axz,'motionpointer','SOM left');
  d.axiso  = axes('units','normal','pos',[.2 .05 .6 .1],'box','on',...
                  'ytick',[],'xgrid','off','ygrid','off',...
                  'xaxislocation','bottom',...
                  'zlim',[-1 1],...
                  'color','none',...
                  'layer','top');
  setappdata(d.axiso,'motionpointer','SOM top');
  set([d.axx d.axy d.axz d.axiso],'handlevisibility','off');

  setappdata(gcf,'sliceomatic',d);
  
  % Set up the default sliceomatic controllers
  if nargin == 4 
      slicecontrols(gcf,1,xmesh,ymesh,zmesh,xdir,ydir,zdir);
  else
      slicecontrols(gcf,1);
  end
      
  isocontrols(gcf,1);

  % Button Down Functions
  set(d.axx,'buttondownfcn','sliceomatic Xnew');
  set(d.axy,'buttondownfcn','sliceomatic Ynew');
  set(d.axz,'buttondownfcn','sliceomatic Znew');
  set(d.axiso,'buttondownfcn','sliceomatic ISO');

  % Set up our motion function before cameratoolbar is active.
  d.motionmetaslice = [];
  set(gcf,'windowbuttonmotionfcn',@sliceomaticmotion);
  
  % Try setting up the camera toolbar
  try
    cameratoolbar('show');
    cameratoolbar('togglescenelight');
    %cameratoolbar('setmode','orbit');
  end
  
  d = figmenus(d);
  
  % Color and alph maps
  uicontrol('style','text','string','ColorMap',...
            'units','normal','pos',[0 .9 .19 .1]);
  uicontrol('style','popup','string',...
            {'jet','hsv','cool','hot','pink','bone','copper','flag','prism','rand','custom'},...
            'callback','sliceomatic colormap',...
            'units','normal','pos',[0 .85 .19 .1]);

  uicontrol('style','text','string','AlphaMap',...
            'units','normal','pos',[.81 .9 .19 .1]);
  uicontrol('style','popup','string',{'rampup','rampdown','vup','vdown','rand'},...
            'callback','sliceomatic alphamap',...
            'units','normal','pos',[.81 .85 .19 .1]);

  % Data tip thingydoo
  d.tip = text('visible','off','fontname','helvetica','fontsize',10,'color','black');
  try
    % Try R13 new feature
    set(d.tip,'backgroundcolor',[1 1 .8],'edgecolor',[.5 .5 .5],'margin',5);
  end
  
  appdata = d;
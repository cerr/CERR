function sliceomatic(p1,p2,xmesh,ymesh,zmesh)
% SLICEOMATIC - Slice and isosurface volume exploration GUI
%
% SLICEOMATIC(DATA) - Use 3D double matrix DATA as a volume data
%
% Example:
%
%       [x,y,z] = meshgrid(-2:.2:2, -2:.25:2, -2:.16:2);
%       v = x .* exp(-x.^2 - y.^2 - z.^2);
%       sliceomatic(v)
%
% Using SLICEOMATIC with no arguments is equivalent to the above
% example.
%
% Using the GUI:
% -------------
% The white bars on the top, left, and right allow insertion of
% new slices on the X, Y, and Z planes.  Click in an empty area to
% add a new slice or surface.  Click on a control arrow to add a
% new slice or surface.
%
% The colored bar at the bottom is used to place and position an
% isosurface.  The color in the bar indicates a position (as seen
% in the slice) where the isosurface will go.
%
% When the rotate camera button is on, the popup menu will control
% the camera.  Turn off camera rotation in order to get individual
% control over properties of the slices and isosurfaces.
%
% The defaults menu provides default features of newly created
% slices and surfaces.  The AllSlices menu controls properties of
% all the slices and surfaces in the scene.  Use popup menus on the
% objects themselves, or the control arrows to change indivudual
% properties.
%
% If the data is very large, a reduced model of the data is created.
% This reduced data set is used for interactivly positioning
% isosurfaces.
%
% The Colormap popdown controls the currenlty active colormap.
% This map is used to color the slices.  The Alphamap popdown
% controls the alphamap used on the slices.
%
% Doing Cool Stuff:
% ----------------
%
% Exploration:
% You can get a quick feel of the current data set by adding a
% slice using the ColorTexture option.  Such a slice can be dragged
% through the data very quickly.
%
% Highlight an Area:
% If certain values in your data are interesting (very large, very
% small, or very median values) you can use transparency to make
% parts of your slices disappear.  Choose AlphaTexture options from
% the defaults, and sweep some slices across your data.  Use the
% AlphaMap to pick out certain data sets.  The exaple given here
% looks best with the `vdown' alphamap.
%
% You can also add a contour onto a slice to further extract shapes
% from the data you are exploring.
%
% Hidden Shapes:
% Use the isosurface control bar to create an isosurface.  Be
% patient with this control.  It often takes a while for the
% surface to be created.  Click and hold the mouse button down
% until the first surface appears.  Drag the surface through the
% values until you get something you like, then let go.  If your
% data set is very large, you will need to wait while the new and
% more accurate isosurface is created.
%
% Volumes:
% You can simulate a volume object by creating lots of stacked
% slices.  Simply use the proper Alphamap and transparent textures
% to highlight the correct data, and a large stack of slices will
% let you simulate a volume object.
%
% BUGS:
% ----
%
% 1) Sliceomatic does not use the `slice' command.  All slices are
%    created by explicitly extracting data from the volume.  As such,
%    only slices at integer values are allowed.
% 
%
% See Also: SLICE, ISOSURFACE, ISOCAPS, CONTOURC, COLORMAP, SURFACE
  
% This is version 2.0 of sliceomatic.
%
% Sliceomatic is a tool I wrote for fun.  There are no warrenties
% expressed or implied.

% Written by Eric Ludlam <eludlam@mathworks.com>
% Copyright 2000, 2001, 2002 The MathWorks Inc
%
% Modified by Emiliano Spezi <emiliano.spezi@physics.org>
% Added capability: axes limits control 
% Last modified: 10 May 2003


  if nargin==0
    [x,y,z] = meshgrid(-2:.2:2, -2:.25:2, -2:.16:2);
    v = x .* exp(-x.^2 - y.^2 - z.^2);
    sliceomatic(v)
    return
  end

  if isa(p1,'double')
% $$$     if nargin==4
% $$$       d.Xv=p1;
% $$$       d.Yv=p2;
% $$$       d.Zv=p3
% $$$       p1=p4;
% $$$     else
% $$$       d.Yv=1:size(p1,1);
% $$$       d.Xv=1:size(p1,2);
% $$$       d.Zv=1:size(p1,3);
% $$$     end
    
    d.data=p1;
    
    if nargin==5
        d = sliceomaticfigure(d,xmesh,ymesh,zmesh);
        d = sliceomaticsetdata(d,xmesh,ymesh,zmesh);
    else
        d = sliceomaticfigure(d);
        d = sliceomaticsetdata(d);
    end
    
    setappdata(gcf,'sliceomatic',d);

  else
    % Interpret commands
    d=getappdata(gcf,'sliceomatic');
    try
      switch p1
       case 'Xnew'
        if strcmp(get(gcf,'selectiontype'),'normal')
          pt=get(gcbo,'currentpoint');
          axis(gcbo);
          X=pt(1,1);
          newa=arrow(gcbo,'down',[X 0]);
          set(gcf,'currentaxes',d.axmain);
          new=localslice(d.data, X, [], []);
          setappdata(new,'controlarrow',newa);
          setappdata(newa(2),'arrowslice',new);
          set(new,'alphadata',get(new,'cdata'),'alphadatamapping','scaled');
          set(newa,'buttondownfcn','sliceomatic Xmove');
          set([new newa],'uicontextmenu',d.uic);
          % Make sure whatever buttonupfcn on the figure is run now to "turn
          % off" whatever was going on before we got our callback on the
          % arrow.
          buf = get(gcf,'windowbuttonupfcn');
          if ~strcmp(buf,'')
            eval(buf);
          end
          d.draggedarrow=newa(2);
          dragprep(newa(2));
          setpointer(gcf,'SOM leftright');
          set(d.motionmetaslice,'visible','off');
        end
       case 'Ynew'
        if strcmp(get(gcf,'selectiontype'),'normal')
          pt=get(gcbo,'currentpoint');
          Y=pt(1,2);
          newa=arrow(gcbo,'right',[0 Y]);
          set(gcf,'currentaxes',d.axmain);
          new=localslice(d.data, [], Y, []);
          setappdata(new,'controlarrow',newa);
          setappdata(newa(2),'arrowslice',new);
          set(new,'alphadata',get(new,'cdata'),'alphadatamapping','scaled');
          set(newa,'buttondownfcn','sliceomatic Ymove');
          set([new newa],'uicontextmenu',d.uic);
          % Make sure whatever buttonupfcn on the figure is run now to "turn
          % off" whatever was going on before we got our callback on the
          % arrow.
          buf = get(gcf,'windowbuttonupfcn');
          if ~strcmp(buf,'')
            eval(buf);
          end
          d.draggedarrow=newa(2);
          dragprep(newa(2));
          setpointer(gcf,'SOM topbottom');
          set(d.motionmetaslice,'visible','off');
        end % if strcmp(get(gcf,
       case 'Znew'
        if strcmp(get(gcf,'selectiontype'),'normal')
          pt=get(gcbo,'currentpoint');
          Y=pt(1,2);
          newa=arrow(gcbo,'left', [0 Y]);
          set(gcf,'currentaxes',d.axmain);
          new=localslice(d.data, [], [], Y);
          set(new,'alphadata',get(new,'cdata'),'alphadatamapping','scaled');
          setappdata(new,'controlarrow',newa);
          setappdata(newa(2),'arrowslice',new);
          set(newa,'buttondownfcn','sliceomatic Zmove');
          set([new newa],'uicontextmenu',d.uic);
          % Make sure whatever buttonupfcn on the figure is run now to "turn
          % off" whatever was going on before we got our callback on the
          % arrow.
          buf = get(gcf,'windowbuttonupfcn');
          if ~strcmp(buf,'')
            eval(buf);
          end
          d.draggedarrow=newa(2);
          dragprep(newa(2));
          setpointer(gcf,'SOM topbottom');
          set(d.motionmetaslice,'visible','off');
        end % if strcmp(get(gcf,
       case 'ISO'
        if strcmp(get(gcf,'selectiontype'),'normal')
          pt=get(gcbo,'currentpoint');
          V=pt(1,1);
          newa=arrow(gcbo,'up',[V 0]);
          set(gcf,'currentaxes',d.axmain);
          new=localisosurface(d.reducelims,d.reduce,d.reducesmooth,V);
          set([newa new],'uicontextmenu',d.uiciso);
          setappdata(new,'controlarrow',newa);
          setappdata(new,'reduced',1);
          setappdata(newa(2),'arrowiso',new);
          set(newa,'buttondownfcn','sliceomatic ISOmove');
          % Make sure whatever buttonupfcn on the figure is run now to "turn
          % off" whatever was going on before we got our callback on the
          % arrow.
          buf = get(gcf,'windowbuttonupfcn');
          if ~strcmp(buf,'')
            eval(buf);
          end	
          d.draggedarrow=newa(2);
          dragprep(newa(2));
          setpointer(gcf,'SOM leftright');
        end % if strcmp(get(gcf,
       case 'Xmove'
        if strcmp(get(gcf,'selectiontype'),'normal')
          [a s]=getarrowslice;
          d.draggedarrow=a;
          dragprep(a);
        end
       case 'Ymove'
        if strcmp(get(gcf,'selectiontype'),'normal')
          [a s]=getarrowslice;
          d.draggedarrow=a;
          dragprep(a);
        end
       case 'Zmove'
        if strcmp(get(gcf,'selectiontype'),'normal')
          [a s]=getarrowslice;
          d.draggedarrow=a;
          dragprep(a);
        end
       case 'ISOmove'
        if strcmp(get(gcf,'selectiontype'),'normal')
          [a s]=getarrowslice;
          d.draggedarrow=a;
          dragprep(a);
        end      
       case 'up'
        if strcmp(get(gcf,'selectiontype'),'normal')
          dragfinis(d.draggedarrow);
        end
       case 'motion'
        % Make sure our cursor is ok
        a=d.draggedarrow;			% The arrow being dragged
        s=getappdata(a,'arrowslice');	% The slice to 'move'
        if isempty(s)
          s=getappdata(a,'arrowiso');	% or the isosurface
        end
        aa=get(a,'parent');		% arrow's parent axes
        pos=getappdata(a,'arrowcenter');	% the line the arrow points at.
        apos=get(aa,'currentpoint');
        if aa==d.axx | aa==d.axiso
          % We are moving an X slice
          xdiff=apos(1,1)-pos(1,1);
          v=get(a,'vertices');
          v(:,1)=v(:,1)+xdiff;
          set([a getappdata(a,'arrowedge')],'vertices',v);
          np=[ apos(1,1) 0 ];
          % This might be a slice, or an isosurface!
          if aa==d.axiso
            new=localisosurface(d.reducelims,d.reduce,d.reducesmooth,...
                                apos(1,1),s);
            setappdata(new,'reduced',1);
            movetipforarrow(d.tip, aa, apos(1,1), [ apos(1,1) 6 ], 'bottom','center')
          else
            if round(apos(1,1))~=round(pos(1,1))
                localslice(d.data, apos(1,1), [], [],s);
            end
            movetipforarrow(d.tip, aa, apos(1,1), [ apos(1,1) .5 ],'top','center')
          end
        else
          % We are moving a Y or Z slice
          ydiff=apos(1,2)-pos(1,2);
          v=get(a,'vertices');
          v(:,2)=v(:,2)+ydiff;
          set([a getappdata(a,'arrowedge')],'vertices',v);
          np=[ 0 apos(1,2) ];
          if aa==d.axy
            if round(apos(1,2))~=round(pos(1,2))
                localslice(d.data, [], apos(1,2), [], s);
            end
            movetipforarrow(d.tip, aa, apos(1,2), [ 5.5 apos(1,2) ], 'middle','left');
          else
            if round(apos(1,2))~=round(pos(1,2))
                localslice(d.data, [], [], apos(1,2), s);
            end
            movetipforarrow(d.tip, aa, apos(1,2), [ .5 apos(1,2) ], 'middle','right');
          end
        end
        setappdata(a,'arrowcenter',np);
        drawnow;
        %
        % IsoSurface context menu items
        %
       case 'isotogglevisible'
        [a s]=getarrowslice;
        if propcheck(s,'visible','on')
          set(s,'visible','off');
        else
          set(s,'visible','on');
        end
       case 'isodelete'
        [a s]=getarrowslice;
        if numel(a)==1
          delete(getappdata(a,'arrowedge'));
        end
        cap=getappdata(s,'sliceomaticisocap');
        if ~isempty(cap)
          delete(cap);
        end
        delete(s);
        delete(a);
       case 'isoflatlight'
        [a s]=getarrowslice;
        set(s,'facelighting','flat');
       case 'isosmoothlight'
        [a s]=getarrowslice;
        set(s,'facelighting','phong');
       case 'isocolor'
        [a s]=getarrowslice;
        c=uisetcolor(get(s,'facecolor'));
        set(s,'facecolor',c);
       case 'isoalpha'
        [a s]=getarrowslice;
        if nargin ~= 2
          error('Not enough arguments to sliceomatic.');
        end
        set(s,'facealpha',eval(p2));
       case 'isocaps'
        [a s]=getarrowslice;
        cap=getappdata(s,'isosurfacecap');
        if isempty(cap)
          new=localisocaps(s);
          set(new,'uicontextmenu',d.uiciso);
        else
          delete(cap);
          setappdata(s,'isosurfacecap',[]);
        end
        %
        % Now for slice context menu items
        %
       case 'togglevisible'
        [a s]=getarrowslice;
        switch get(s,'visible')
         case 'on'
          set(s,'visible','off');
          pushset(a,'facealpha',.2);
         case 'off'
          set(s,'visible','on');
          popset(a,'facealpha');
        end
       case 'setfaceted'
        [a s]=getarrowslice;
        set(s,'edgec','k','facec','flat');
        if ischar(get(s,'facea')) & strcmp(get(s,'facea'),'texturemap')
          set(s,'facea','flat');
        end
        textureizeslice(s,'off');
       case 'setflat'
        [a s]=getarrowslice;
        set(s,'edgec','n','facec','flat');
        if ischar(get(s,'facea')) & strcmp(get(s,'facea'),'texturemap')
          set(s,'facea','flat');
        end
        textureizeslice(s,'off');
       case 'setinterp'
        [a s]=getarrowslice;
        set(s,'edgec','n','facec','interp');
        if ischar(get(s,'facea')) & strcmp(get(s,'facea'),'texturemap')
          set(s,'facea','interp');
        end
        textureizeslice(s,'off');
       case 'settexture'
        [a s]=getarrowslice;
        set(s,'facecolor','texture','edgec','none');
        if ischar(get(s,'facea'))
          set(s,'facealpha','texturemap');
        end
        textureizeslice(s,'on');
       case 'setnone'
        [a s]=getarrowslice;
        set(s,'facecolor','none','edgec','none');
        textureizeslice(s,'off');
       case 'setalphanone'
        [a s]=getarrowslice;
        set(s,'facealpha',1);
       case 'setalphapoint5'
        [a s]=getarrowslice;
        set(s,'facealpha',.5);
       case 'setalphaflat'
        [a s]=getarrowslice;
        set(s,'facealpha','flat');
        if ischar(get(s,'facec')) & strcmp(get(s,'facec'),'texturemap')
          set(s,'facecolor','flat');
          textureizeslice(s,'off');
        end
       case 'setalphainterp'
        [a s]=getarrowslice;
        set(s,'facealpha','interp');
        if ischar(get(s,'facec')) & strcmp(get(s,'facec'),'texturemap')
          set(s,'facecolor','interp');
          textureizeslice(s,'off');
        end
       case 'setalphatexture'
        [a s]=getarrowslice;
        set(s,'facealpha','texturemap');
        if ischar(get(s,'facec'))
          set(s,'facecolor','texturemap');
          textureizeslice(s,'on');
        end
       case 'slicecontour'
        [a s]=getarrowslice;
          localcontour(s, getappdata(s,'contour'));
       case 'slicecontour_select'
        [a s]=getarrowslice;
        dlg_title = 'Sliceomatic contour select';
        prompt = 'Enter contour values:';
        answer = inputdlg(prompt,dlg_title);
        if isempty(answer)~=1 & isequal(answer{1},'')~=1
            levels = str2num(answer{1});
            if isempty(levels)==1
                warndlg('Contour values must be numeric: data not accepted.');
            end
        else
            warndlg('Empty value: data not accepted.');
        end
        setappdata(s, 'contourlevels', levels);
        addcontour(s, getappdata(s,'contour'),levels);
       case 'deleteslice'
        [a s]=getarrowslice;
        if prod(size(a))==1
          delete(getappdata(a,'arrowedge'));
        end
        if ~isempty(getappdata(s,'contour'))
          delete(getappdata(s,'contour'));
        end
        delete(s);
        delete(a);
        case 'deleteslicecontour'
        [a s]=getarrowslice;
        if ~isempty(getappdata(s,'contour'))
          delete(getappdata(s,'contour'));
        end
        temp=getappdata(s);
        try 
            tempcl=temp.contourlevels;
            setappdata(s,'contourlevels',[]);
        end
        setappdata(s,'contour',[]);
       case 'slicecontourflat'
        [a s]=getarrowslice;
        c = getappdata(s,'contour');
        if ~isempty(c)
          set(c,'edgecolor','flat');
        end
       case 'slicecontourinterp'
        [a s]=getarrowslice;
        c = getappdata(s,'contour');
        if ~isempty(c)
          set(c,'edgecolor','interp');
        end
       case 'slicecontourblack'
        [a s]=getarrowslice;
        c = getappdata(s,'contour');
        if ~isempty(c)
          set(c,'edgecolor','black');
        end
       case 'slicecontourwhite'
        [a s]=getarrowslice;
        c = getappdata(s,'contour');
        if ~isempty(c)
          set(c,'edgecolor','white');
        end
       case 'slicecontourcolor'
        [a s]=getarrowslice;
        c = getappdata(s,'contour');
        if ~isempty(c)
          inputcolor = get(c,'edgecolor');
          if isa(inputcolor,'char')
            inputcolor=[ 1 1 1 ];
          end
          set(c,'edgecolor',uisetcolor(inputcolor));
        end
       case 'slicecontourlinewidth'
        [a s]=getarrowslice;
        c = getappdata(s,'contour');
        if ~isempty(c)
          if isa(p2,'char')
            set(c,'linewidth',str2num(p2));
          else
            set(c,'linewidth',p2);
          end
        end
        %
        % Menu All Slices
        %
       case 'allfacet'
        s=allSlices;
        set(s,'facec','flat','edgec','k');
        textureizeslice(s,'off');
       case 'allflat'
        s=allSlices;
        set(s,'facec','flat','edgec','none');
        textureizeslice(s,'off');
       case 'allinterp'
        s=allSlices;
        set(s,'facec','interp','edgec','none');
        textureizeslice(s,'off');
       case 'alltex'
        s=allSlices;
        set(s,'facec','texturemap','edgec','none');
        textureizeslice(s,'on');
       case 'allnone'
        s=allSlices;
        set(s,'facec','none','edgec','none');
        textureizeslice(s,'off');
       case 'alltnone'
        s=allSlices;
        set(s,'facea',1);
        textureizeslice(s,'off');
       case 'alltp5'
        s=allSlices;
        set(s,'facea',.5);
        textureizeslice(s,'off');
       case 'alltflat'
        s=allSlices;
        set(s,'facea','flat');
        textureizeslice(s,'off');
       case 'alltinterp'
        s=allSlices;
        set(s,'facea','interp');
        textureizeslice(s,'off');
       case 'allttex'
        s=allSlices;
        set(s,'facea','texturemap');
        textureizeslice(s,'on');
	    %
        % Menu About
        %
       case 'showabout_dicomrt_explore'
        showhelp('showabout_dicomrt_explore');
       case 'showabout_sliceomatic'
        showhelp('showabout_sliceomatic');
        %
        % Menu Defaults callbacks
        %
       case	'defaultfaceted'
        d.defcolor='faceted';
       case	'defaultflat'
        d.defcolor='flat';
       case	'defaultinterp'
        d.defcolor='interp';
       case	'defaulttexture'
        d.defcolor='texture';
        if strcmp(d.defalpha,'flat') | strcmp(d.defalpha,'interp')
          d.defalpha='texture';
        end
       case	'defaultinterp'
        d.defcolor='none';
       case	'defaulttransnone'
        d.defalpha='none';
       case	'defaulttransflat'
        d.defalpha='flat';
       case	'defaulttransinterp'
        d.defalpha='interp';
       case	'defaulttranstexture'
        d.defalpha='texture';
        d.defcolor='texture';
       case      'defaultlightflat'
        d.deflight='flat';
       case      'defaultlightsmooth'
        d.deflight='smooth';
       case 'defaultcontourflat'
        d.defcontourcolor='flat';
       case 'defaultcontourinterp'
        d.defcontourcolor='interp';
       case 'defaultcontourblack'
        d.defcontourcolor='black';
       case 'defaultcontourwhite'
        d.defcontourcolor='white';
       case 'defaultcontourlinewidth'
        if isa(p2,'char')
          d.defcontourlinewidth=str2num(p2);
        else
          d.defcontourlinewidth=p2;
        end
        %
        % Camera toolbar Toggling
        %
       case 'cameratoolbar'
        cameratoolbar('Toggle');
        %
        % Controler Preferences
        %
       case 'controlalpha'
        val=str2num(p2);
        iso=findobj(d.axiso,'type','image');
        if val == 0
          set([d.pxx d.pxy d.pxz iso],'visible','off');
        else
          set([d.pxx d.pxy d.pxz iso],'visible','on');
          set([d.pxx d.pxy d.pxz] , 'facealpha',val);
          set(iso,'alphadata',val);
        end
       case 'controllabels'
        l = get(d.axx,'xticklabel');
        if isempty(l)
          set([d.axx d.axiso],'xticklabelmode','auto');
          set([d.axy d.axz],'yticklabelmode','auto');
        else
          set([d.axx d.axiso],'xticklabel',[]);
          set([d.axy d.axz],'yticklabel',[]);
        end
       case 'controlvisible'
        objs=findobj([d.axiso d.axx d.axy d.axz]);
        if strcmp(get(d.axx,'visible'),'on')
          set(objs,'visible','off');
          set(d.axmain,'pos',[.1 .1 .9 .8]);
        else
          set(objs,'visible','on');
          set(d.axmain,'pos',[.2  .2 .6 .6]);
        end
        %
        % UICONTROL callbacks
        %
       case 'colormap'
        str=get(gcbo,'string');
        val=str{get(gcbo,'value')};
        size(val);
        if strcmp(val,'custom')
          cmapeditor
        else
          colormap(val);
        end
       case 'alphamap'
        str=get(gcbo,'string');
        alphamap(str{get(gcbo,'value')});
        %
        % Commands
        %
       case 'copy'
        copyobj(gca,figure);set(gca,'pos',[.1 .1 .9 .8]);
       case 'print'
        newf=figure('visible','off','renderer',get(gcf,'renderer'));
        copyobj(d.axmain,newf);
        set(gca,'pos',[.1 .1 .9 .8])
        printdlg(newf);
        close(newf);
       otherwise
        error('Bad slice-o-matic command.');
      end
    catch
      disp(get(0,'errormessage'));
    end
    setappdata(gcf,'sliceomatic',d);
  end

function dragprep(arrowtodrag)

  arrows=findall(gcf,'tag','sliceomaticarrow');

  pushset(arrows,'facecolor','r');
  pushset(arrows,'facealpha',.2);

  pushset(arrowtodrag,'facecolor','g');
  pushset(arrowtodrag,'facealpha',.7);

  slices=allSlices;

  for i=1:length(slices)
    fa=get(slices(i),'facea');
    if isa(fa,'double') & fa>.3
      pushset(slices(i),'facealpha',.3);
      pushset(slices(i),'edgecolor','n');
    else
      pushset(slices(i),'facealpha',fa);
      pushset(slices(i),'edgecolor',get(slices(i),'edgec'));
    end
  end

  isosurfs=allIsos;

  for i=1:length(isosurfs)
    fa=get(isosurfs(i),'facea');
    if isa(fa,'double') & fa>.3
      pushset(isosurfs(i),'facealpha',.3);
      pushset(isosurfs(i),'edgecolor','n');
    else
      pushset(isosurfs(i),'facealpha',fa);
      pushset(isosurfs(i),'edgecolor',get(isosurfs(i),'edgec'));
    end
    cap=getappdata(isosurfs(i),'isosurfacecap');
    if ~isempty(cap)
      pushset(cap,'visible','off');
    end
  end

  ss=getappdata(arrowtodrag,'arrowslice');

  if isempty(ss)
    ss=getappdata(arrowtodrag,'arrowiso');
  end

  popset(ss,'facealpha');
  popset(ss,'edgecolor');

  pushset(gcf,'windowbuttonupfcn','sliceomatic up');
  pushset(gcf,'windowbuttonmotionfcn','sliceomatic motion');

  d=getappdata(gcf,'sliceomatic');
  
  % Doing this makes the tip invisible when visible is on.
  set(d.tip,'string','');
  pushset(d.tip,'visible','on');
  
function dragfinis(arrowtodrag)

  arrows=findall(gcf,'tag','sliceomaticarrow');

  popset(arrowtodrag,'facecolor');
  popset(arrowtodrag,'facealpha');

  popset(arrows,'facecolor');
  popset(arrows,'facealpha');

  ss=getappdata(arrowtodrag,'arrowslice');
  if isempty(ss)
    ss=getappdata(arrowtodrag,'arrowiso');
  end

  % These pushes are junk which will be undone when all slices or
  % isosurfs are reset below.
  pushset(ss,'facealpha',1);
  pushset(ss,'edgecolor','k');

  slices=allSlices;

  if ~isempty(slices)
    popset(slices,'facealpha');
    popset(slices,'edgecolor');
  end

  isosurfs=allIsos;

  if ~isempty(isosurfs)
    popset(isosurfs,'facealpha');
    popset(isosurfs,'edgecolor');
  end

  d=getappdata(gcf,'sliceomatic');
  
  if isnan(d.xmesh)==1
      for i=1:length(isosurfs)
          cap=getappdata(isosurfs(i),'isosurfacecap');
          if ~isempty(cap)
              popset(cap,'visible');
              localisocaps(isosurfs(i),cap);
          end
          if getappdata(isosurfs(i), 'reduced')
              setappdata(isosurfs(i),'reduced',0);
              localisosurface({},d.data,d.smooth,...
                  getappdata(isosurfs(i),'isosurfacevalue'),...
                  isosurfs(i));
          end
      end
  else
      for i=1:length(isosurfs)
          cap=getappdata(isosurfs(i),'isosurfacecap');
          if ~isempty(cap)
              popset(cap,'visible');
              localisocaps(isosurfs(i),cap);
          end
          if getappdata(isosurfs(i), 'reduced')
              setappdata(isosurfs(i),'reduced',0);
              realvolume={d.xmesh d.ymesh d.zmesh};
              localisosurface(realvolume,d.data,d.smooth,...
                  getappdata(isosurfs(i),'isosurfacevalue'),...
                  isosurfs(i));
          end
      end
  end

  popset(gcf,'windowbuttonupfcn');
  popset(gcf,'windowbuttonmotionfcn');

  popset(d.tip,'visible');
  
  % Make sure whatever buttonupfcn on the figure is run now to "turn
  % off" whatever was going on before we got our callback on the
  % arrow.

  buf = get(gcf,'windowbuttonupfcn');
  if ~strcmp(buf,'')
    eval(buf);
  end

function movetipforarrow(tip, ax, value, position, va, ha)
% Setup the current data tip for a slice arrow, and show it's
% control value
  set(tip,'parent',ax, ...
          'string',sprintf('Value: %1.3f',value),...
          ... 'string','o', ...
          'units','data', ...
          'position', position, ...
          'verticalalignment', va,...
          'horizontalalignment', ha);
  set(tip,'units','pixels');
  % Put it onto d.axisiso so that
  % it always appears on top.
  %set(t,'parent',d.axiso);
  
function p=arrow(parent,dir,pos)

%   21012    21012      12345     12345
% 5  *-*   5   *     2   *     2   *  
% 4  | |   4  / \    1 *-*\    1  /*-*
% 3 ** **  3 ** **   0 |   *   0 *   |
% 2  \ /   2  | |   -1 *-*/   -1  \*-*
% 1   *    1  *-*   -2   *    -2   *  

  switch dir
   case 'down'
    pts=[ 0 1; -2 3; -1 3; -1 5; 1 5; 1 3; 2 3 ];
    mp = 'SOM leftright';
   case 'up'
    pts=[ 0 5; 2 3; 1 3; 1 1; -1 1; -1 3; -2 3; ];
    mp = 'SOM leftright';
   case 'right'
    pts=[ 5 0; 3 -2; 3 -1; 1 -1; 1 1; 3 1; 3 2 ];
    mp = 'SOM topbottom';
   case 'left'
    pts=[ 1 0; 3 2; 3 1; 5 1; 5 -1; 3 -1; 3 -2 ];
    mp = 'SOM topbottom';
  end

  f=[1 2 7; 3 4 5; 3 5 6 ];

  % Modify the arrows to look good no matter what
  % the data aspect ratio may be.
  if pos(1)
    lim=get(parent,'xlim');
    fivep=abs(lim(1)-lim(2))/15/5;
    pts(:,1)=pts(:,1)*fivep+pos(1);
  elseif pos(2)
    lim=get(parent,'ylim');
    fivep=abs(lim(1)-lim(2))/15/5;
    pts(:,2)=pts(:,2)*fivep+pos(2);
  end

  % Create the patches, and add app data to them to remember what
  % They are associated with.
  p(1)=patch('vertices',pts,'faces',1:size(pts,1),'facec','n','edgec','k',...
             'linewidth',2,'hittest','off',...
             'parent',parent);
  p(2)=patch('vertices',pts,'faces',f,'facec','g','facea',.5,'edgec','n',...
             'parent',parent,'tag','sliceomaticarrow');
  setappdata(p(2),'arrowcenter',pos);
  setappdata(p(2),'arrowedge',p(1));
  setappdata(p(2),'motionpointer',mp);

  
function p=localisocaps(isosurface,isocap)
% Isocap management
  
% Get relevant info from the isosurface.
  if nargin<2 | ~strcmp(get(isocap,'visible'),'off')
      d=getappdata(gcf,'sliceomatic');
      data=getappdata(isosurface,'isosurfacedata');
      if isnan(d.xmesh)==1
          caps=isocaps(data,getappdata(isosurface,'isosurfacevalue'));
      else
          caps=isocaps(d.xmesh,d.ymesh,d.zmesh,data,getappdata(isosurface,'isosurfacevalue'));
      end
  end

  if nargin==2
    if ~strcmp(get(isocap,'visible'),'off')
      set(isocap,caps);
    end
    p=isocap;
  else
    p=patch(caps,'edgecolor','none','facecolor','flat',...
            'facelighting','none',...
            'tag','sliceomaticisocap');

    setappdata(p,'isosurface',isosurface);
    setappdata(isosurface,'isosurfacecap',p);
    
    d=getappdata(gcf,'sliceomatic');
    
    switch d.defcolor
     case 'faceted'
      set(p,'facec','flat','edgec','black');
     case 'flat'
      set(p,'facec','flat','edgec','none');
     case 'interp'
      set(p,'facec','interp','edgec','none');
     case 'texture'
      set(p,'facec','flat','edgec','none');
     case 'none'
      set(p,'facec','none','edgec','none');
    end
    switch d.defalpha
     case 'none'
      set(p,'facea',1);
     case 'flat'
      set(p,'facea','flat');
     case 'interp'
      set(p,'facea','interp');
     case 'texture'
      set(p,'facea','flat');
    end    
  end


function p=localisosurface(volume, data, datanormals, value, oldiso)
% Isosurface management
  
  pushset(gcf, 'pointer','watch');

  d=getappdata(gcf,'sliceomatic');
  fv = isosurface(volume{:},data, value);
  
  clim=get(gca,'clim');
  cmap=get(gcf,'colormap');
  clen=clim(2)-clim(1);
  idx=floor((value-clim(1))*length(cmap)/clen);

  if nargin==5
      set(oldiso,fv,'facecolor',cmap(idx,:));
      p=oldiso;
      cap=getappdata(p,'isosurfacecap');
      if ~isempty(cap)
          localisocaps(p,cap);
      end
  else
      if isnan(d.xmesh)==1
          p=patch(fv,'edgecolor','none','facecolor',cmap(idx,:),...
              'tag', 'sliceomaticisosurface');
      else
          p=patch(fv,'edgecolor','none','facecolor',cmap(idx,:),...
              'tag', 'sliceomaticisosurface');
      end
    % d=getappdata(gcf,'sliceomatic');
    switch d.deflight
     case 'flat'
      set(p,'facelighting','flat');
     case 'smooth'
      set(p,'facelighting','phong');
    end
    setappdata(p,'isosurfacecap',[]);
  end

  setappdata(p,'isosurfacevalue',value);
  setappdata(p,'isosurfacedata',data);

  reducepatch(p,10000);
  isonormals(volume{:},datanormals,p);

  popset(gcf,'pointer');

function s=localslice(data, X, Y, Z, oldslice)
% Slice Management.  Uses specialized slicomatic slices, not slices
% created with the SLICE command.

  s=[];
  d=getappdata(gcf,'sliceomatic');

  ds=size(data);
  
  if ~isempty(X)
    xi=round(X);
    if isnan(d.xmesh) == 1
        if xi > 0 & xi < ds(2)
            cdata=reshape(data(:,xi,:),ds(1),ds(3));
            [xdata ydata zdata]=meshgrid(X,1:ds(1),1:ds(3));
            st = 'X';
        else
            return
        end
    else
        if isequal(d.xdir,'reverse')==1
            locate_xi=histc(xi,flipdim(d.xmesh,2));
            slice_number=find(locate_xi);
            slice_number=length(d.xmesh)-slice_number+1;
        else 
            locate_xi=histc(xi,d.xmesh);
            slice_number=find(locate_xi);
        end
        if slice_number > 0 & slice_number < ds(2)
            cdata=reshape(data(:,slice_number,:),ds(1),ds(3));
            [xdata ydata zdata]=meshgrid(X,d.ymesh,d.zmesh);
            st = 'X';
        else
            return
        end
    end
        
  elseif ~isempty(Y)
    yi=round(Y);
    if isnan(d.ymesh) == 1
        if yi > 0 & yi < ds(1)
            cdata=reshape(data(yi,:,:),ds(2),ds(3));
            [xdata ydata zdata]=meshgrid(1:ds(2),Y,1:ds(3));
            st = 'Y';
        else
            return    
        end
    else
        if isequal(d.ydir,'reverse')==1
            locate_yi=histc(yi,flipdim(d.ymesh,2));
            slice_number=find(locate_yi);
            slice_number=length(d.ymesh)-slice_number+1;
        else 
            locate_yi=histc(yi,d.ymesh);
            slice_number=find(locate_yi);
        end
        if slice_number > 0 & slice_number < ds(1)
            cdata=reshape(data(slice_number,:,:),ds(2),ds(3));
            [xdata ydata zdata]=meshgrid(d.xmesh,Y,d.zmesh);
            st = 'Y';
        else
            return
        end
    end
  elseif ~isempty(Z)
    zi=round(Z);
    if isnan(d.zmesh) == 1
        if zi > 0 & zi < ds(3)
            cdata=reshape(data(:,:,zi),ds(1),ds(2));
            [xdata ydata zdata]=meshgrid(1:ds(2),1:ds(1),Z);
            st = 'Z';
        else
            return
        end
    else
        if isequal(d.zdir,'reverse')==1
            locate_zi=histc(zi,flipdim(d.zmesh,2));
            slice_number=find(locate_zi);
            slice_number=length(d.zmesh)-slice_number+1;
        else 
            locate_zi=histc(zi,d.zmesh);
            slice_number=find(locate_zi);
        end
        if slice_number > 0 & slice_number < ds(3)
            cdata=reshape(data(:,:,slice_number),ds(1),ds(2));
            [xdata ydata zdata]=meshgrid(d.xmesh,d.ymesh,Z);
            st = 'Z';
        else
            return
        end
    end
  else
    error('Nothing was passed into LOCALSLICE.');
  end

  cdata=squeeze(cdata);
  xdata=squeeze(xdata);
  ydata=squeeze(ydata);
  zdata=squeeze(zdata);

if nargin == 5
    % Recycle the old slice
    set(oldslice,'cdata',cdata,'alphadata',cdata, 'xdata',xdata, ...
                 'ydata',ydata, 'zdata',zdata);
    s=oldslice;
    %delete(news);
    if propcheck(s,'facec','texturemap')
      textureizeslice(s,'on');
    end
    setappdata(s,'slicetype',st);
  else
    % setup the alphadata
    news=surface('cdata',cdata,'alphadata',cdata, 'xdata',xdata, ...
                 'ydata',ydata, 'zdata',zdata);
    set(news,'alphadata',cdata,'alphadatamapping','scaled','tag','sliceomaticslice',...
             'facelighting','none',...
             'uicontextmenu',d.uic);
    s=news;
    setappdata(s,'slicetype',st);
    switch d.defcolor
     case 'faceted'
      set(s,'facec','flat','edgec','k');
     case 'flat'
      set(s,'facec','flat','edgec','n');
     case 'interp'
      set(s,'facec','interp','edgec','n');
     case 'texture'
      set(s,'facec','texture','edgec','n');
    end
    switch d.defalpha
     case 'none'
      set(s,'facea',1);
     case 'flat'
      set(s,'facea','flat');
     case 'interp'
      set(s,'facea','interp');
     case 'texture'
      set(s,'facea','texture');
    end    
 end

 contour = getappdata(s,'contour');
  if ~isempty(contour)
      try 
          levels = getappdata(s, 'contourlevels');
          if isempty(levels)~=1
              addcontour(s,contour,levels);
          else
              localcontour(s, contour);
          end
      catch
          localcontour(s, contour);
      end
 end
  

function textureizeslice(slice,onoff)
% Convert a regular slice into a texture map slice, or a texture
% slice into a regular slice.
  
  for k=1:prod(size(slice))

    d=getappdata(slice(k),'textureoptimizeations');

    switch onoff
     case 'on'
      d.xdata=get(slice(k),'xdata');
      d.ydata=get(slice(k),'ydata');
      d.zdata=get(slice(k),'zdata');
      setappdata(slice(k),'textureoptimizeations',d);
      if max(size(d.xdata)==1)
        nx=[d.xdata(1) d.xdata(end)];
      else
        nx=[d.xdata(1,1)   d.xdata(1,end);
            d.xdata(end,1) d.xdata(end,end)];
      end
      if max(size(d.ydata)==1)
        ny=[d.ydata(1) d.ydata(end)];
      else
        ny=[d.ydata(1,1)   d.ydata(1,end);
            d.ydata(end,1) d.ydata(end,end)];
      end
      if max(size(d.zdata)==1)
        nz=[d.zdata(1) d.zdata(end)];
      else
        nz=[d.zdata(1,1)   d.zdata(1,end);
            d.zdata(end,1) d.zdata(end,end)];
      end
      set(slice(k),'xdata',nx, 'ydata', ny, 'zdata', nz,...
                   'facec','texturemap');
      if ischar(get(slice(k),'facea'))
        set(slice(k),'facea','texturemap');
      end
      if ischar(get(slice(k),'facec'))
        set(slice(k),'facec','texturemap');
      end
     case 'off'
      if ~isempty(d)
        set(slice(k),'xdata',d.xdata,'ydata',d.ydata,'zdata',d.zdata);
        setappdata(slice(k),'textureoptimizeations',[]);
      end
      if ischar(get(slice(k),'facea')) & strcmp(get(slice(k),'facea'),'texturemap')
        set(slice(k),'facea','flat');
      end
      if ischar(get(slice(k),'facec')) & strcmp(get(slice(k),'facec'),'texturemap')
        set(slice(k),'facec','flat');
      end
    end
  end


function localcontour(slice,oldcontour)
% Create a contour on SLICE
% When OLDCONTROUR, recycle that contour patch.
% This does not use the CONTOURSLICE command, but instead uses a
% specialized slice created for sliceomantic.

  d=getappdata(gcf,'sliceomatic');
  st=getappdata(slice,'slicetype');
  
  cdata = get(slice,'cdata');
  st = getappdata(slice,'slicetype');

  % Calculate the new contour for CDATA's values.
  if isnan(d.zmesh)==1
      c = contourc(cdata);
  else
      if st=='X'
          [c, h] = contour(d.zmesh,d.ymesh,cdata);
          delete(h); % this is necessary as we want to use contour to handle
          % non monotonically increasing axes limits (limitation of contourc)
      elseif st=='Y'
          [c, h] = contour(d.zmesh,d.xmesh,cdata);
          delete(h);
      elseif st=='Z'
          [c, h] = contour(d.xmesh,d.ymesh,cdata);
          delete(h);
      end
  end

  newvertices = [];
  newfaces = {};
  longest = 1;
  cdata = [];
  
  limit = size(c,2);
  i = 1;
  h = [];
  color_h = [];
  while(i < limit)
    z_level = c(1,i);
    npoints = c(2,i);
    nexti = i+npoints+1;

    xdata = c(1,i+1:i+npoints);
    ydata = c(2,i+1:i+npoints);

    switch st
     case 'X'
      xv = get(slice,'xdata');
      lzdata = xv(1,1) + 0*xdata;
      vertices = [[lzdata].', [ydata].', [xdata].'];
     case 'Y'
      yv = get(slice,'ydata');
      lzdata = yv(1,1) + 0*xdata;
      vertices = [[ydata].', [lzdata].', [xdata].'];
     case 'Z'
      zv = get(slice,'zdata');
      lzdata = zv(1,1) + 0*xdata;
      vertices = [[xdata].', [ydata].', [lzdata].'];
    end    
    
    faces = 1:length(vertices);
    faces = faces + size(newvertices,1);

    longest=max(longest,size(faces,2));
    
    newvertices = [ newvertices ; vertices ];
    newfaces{end+1} = faces;
    
    tcdata =  (z_level + 0*xdata).';
    
    cdata = [ cdata; tcdata ]; % need to be same size as faces
    
    i = nexti;
  end

  % Fix up FACES, which is a cell array.
  faces = [];
  for i = 1:size(newfaces,2)
    faces = [ faces;
              newfaces{i} ones(1,longest-size(newfaces{i},2))*nan nan ];
    % Nans don't work in patches in OpenGL with trailing NaNs, but
    % if I fake it out, edges with breaks in them don't work.
    % Bummer!  I tried filling in with the last data point, but
    % then unbroken segmets would fill in again.    
  end
  
  if isempty(oldcontour)
    oldcontour = patch('facecolor','none', 'edgecolor',d.defcontourcolor,...
                       'linewidth',d.defcontourlinewidth);
    setappdata(slice,'contour',oldcontour);
  end

  set(oldcontour,'vertices',newvertices,...
                 'faces',faces,...
                 'facevertexcdata',cdata);
             
function addcontour(slice,oldcontour,levels)
% Add contour on SLICE
% When OLDCONTROUR, recycle that contour patch.
% This does not use the CONTOURSLICE command, but instead uses a
% specialized slice created for sliceomantic.
% Emiliano Spezi May 2003

  d=getappdata(gcf,'sliceomatic');
  st=getappdata(slice,'slicetype');
  
  cdata = get(slice,'cdata');
  st = getappdata(slice,'slicetype');

  % Calculate the new contour for CDATA's values.
  if isnan(d.zmesh)==1
      c = contourc(cdata);
  else
      if st=='X'
          for i=1:length(levels)
              [ctemp, htemp] = contour(d.zmesh,d.ymesh,cdata,[levels(i) levels(i)]);
              delete(htemp); % this is necessary as we want to use contour to handle
              % non monotonically increasing axes limits (limitation of contourc)
              if length(levels)>1 & i>1
                  c=horzcat(c,ctemp);
                  h=vertcat(h,htemp);
              else
                  c=ctemp;
                  h=htemp;
              end
          end
      elseif st=='Y'
          for i=1:length(levels)
              [ctemp, htemp] = contour(d.zmesh,d.xmesh,cdata,[levels(i) levels(i)]);
              delete(htemp);
              if length(levels)>1 & i>1
                  c=horzcat(c,ctemp);
                  h=vertcat(h,htemp);
              else
                  c=ctemp;
                  h=htemp;
              end
          end
      elseif st=='Z'
          for i=1:length(levels)
              [ctemp, htemp] = contour(d.xmesh,d.ymesh,cdata,[levels(i) levels(i)]);
              delete(htemp);
              if length(levels)>1 & i>1
                  c=horzcat(c,ctemp);
                  h=vertcat(h,htemp);
              else
                  c=ctemp;
                  h=htemp;
              end
          end
      end
  end
  
  newvertices = [];
  newfaces = {};
  longest = 1;
  cdata = [];
  
  limit = size(c,2);
  i = 1;
  h = [];
  color_h = [];
  while(i < limit)
    z_level = c(1,i);
    npoints = c(2,i);
    nexti = i+npoints+1;

    xdata = c(1,i+1:i+npoints);
    ydata = c(2,i+1:i+npoints);

    switch st
     case 'X'
      xv = get(slice,'xdata');
      lzdata = xv(1,1) + 0*xdata;
      vertices = [[lzdata].', [ydata].', [xdata].'];
     case 'Y'
      yv = get(slice,'ydata');
      lzdata = yv(1,1) + 0*xdata;
      vertices = [[ydata].', [lzdata].', [xdata].'];
     case 'Z'
      zv = get(slice,'zdata');
      lzdata = zv(1,1) + 0*xdata;
      vertices = [[xdata].', [ydata].', [lzdata].'];
    end    
    
    faces = 1:length(vertices);
    faces = faces + size(newvertices,1);

    longest=max(longest,size(faces,2));
    
    newvertices = [ newvertices ; vertices ];
    newfaces{end+1} = faces;
    
    tcdata =  (z_level + 0*xdata).';
    
    cdata = [ cdata; tcdata ]; % need to be same size as faces
    
    i = nexti;
  end

  % Fix up FACES, which is a cell array.
  faces = [];
  for i = 1:size(newfaces,2)
    faces = [ faces;
              newfaces{i} ones(1,longest-size(newfaces{i},2))*nan nan ];
    % Nans don't work in patches in OpenGL with trailing NaNs, but
    % if I fake it out, edges with breaks in them don't work.
    % Bummer!  I tried filling in with the last data point, but
    % then unbroken segmets would fill in again.    
  end
  
  if isempty(oldcontour)
    oldcontour = patch('facecolor','none', 'edgecolor',d.defcontourcolor,...
                       'linewidth',d.defcontourlinewidth);
    setappdata(slice,'contour',oldcontour);
  end

  set(oldcontour,'vertices',newvertices,...
                 'faces',faces,...
                 'facevertexcdata',cdata);
  
             
function ss=allSlices
  ss=findobj(gcf,'type','surface','tag','sliceomaticslice');

function ss=allIsos
  ss=findobj(gcf,'type','patch','tag','sliceomaticisosurface');

function ss=allCaps
  ss=findobj(gcf,'type','patch','tag','sliceomaticisocap');

function working(onoff)

  ax=getappdata(gcf,'workingaxis');

  if isempty(ax)
    ax=axes('units','norm','pos',[.3 .4 .4 .2],...
            'box','on','ytick',[],'xtick',[],...
            'xlim',[-1 1],'ylim',[-1 1],...
            'color','none','handlevis','off');
    text('parent',ax,'string','Working...','fontsize',64,...
         'pos',[0 0], ...
         'horizontalalignment','center',...
         'verticalalignment','middle',...
         'erasemode','xor');
    setappdata(gcf,'workingaxis',ax);
  end

  disp(['Working...' onoff]);
  set([ax get(ax,'children')],'vis',onoff);

function showhelp(item)
if strcmp(item,'showabout_sliceomatic') | strcmp(item,'showabout_dicomrt_explore')
    dicomrt_showabout(item);
end
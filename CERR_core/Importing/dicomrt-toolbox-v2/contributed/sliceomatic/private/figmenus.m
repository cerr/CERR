function outd = figmenus(d)
% Set up sliceomatic's gui menus within structure D
  
% Main Figure Menu
  set(gcf,'menubar','none');
  
  % File menu
  d.filemenu = uimenu(gcf,'label','File');
  d.fcopy = uimenu(d.filemenu, 'label', 'Copy figure','callback', 'sliceomatic copy');
  d.fprint  = uimenu(d.filemenu,'label','Print...','callback','sliceomatic print');
  % How do get these props onto the print figure?
  %d.fprints = uimenu(d.filemenu,'label','Print Setup...','callback','printdlg -setup');
  % ---
  d.fexit = uimenu(d.filemenu, 'label', 'Close','callback','closereq',...
                   'separator','on');

  % Controls Menu
  d.defcontrols = uimenu(gcf,'label','Controls', 'callback',@controlmenu);
  d.camtoolbar = uimenu(d.defcontrols,'label','Camera toolbar','callback', 'sliceomatic cameratoolbar');
  d.dcalpha = uimenu(d.defcontrols,'label','Controls Transparency');
  d.dcalpha1= uimenu(d.dcalpha,'label','1','callback','sliceomatic controlalpha 1');
  d.dcalpha8= uimenu(d.dcalpha,'label','.8','callback','sliceomatic controlalpha .8');
  d.dcalpha6= uimenu(d.dcalpha,'label','.6','callback','sliceomatic controlalpha .6');
  d.dcalpha5= uimenu(d.dcalpha,'label','.5','callback','sliceomatic controlalpha .5');
  d.dcalpha4= uimenu(d.dcalpha,'label','.4','callback','sliceomatic controlalpha .4');
  d.dcalpha2= uimenu(d.dcalpha,'label','.2','callback','sliceomatic controlalpha .2');
  d.dcalpha0= uimenu(d.dcalpha,'label','0','callback','sliceomatic controlalpha 0');
  d.dclabels= uimenu(d.defcontrols','label','Tick Labels','callback','sliceomatic controllabels');
  d.dcvis   = uimenu(d.defcontrols','label','Visible','callback','sliceomatic controlvisible');
  %  d.dcslice = uimenu(d.defcontrols,'label','Slice Controls','callback','sliceomatic useslicecontrols');
%  d.dciso   = uimenu(d.defcontrols,'label','Iso Surface Control','callback','sliceomatic useisocontrols','separator','on');

  % Remove this once we have more controls to enable and disable.
%  set(d.defcontrols,'vis','off');
  
  % Default for new slices menu
  d.defmenu = uimenu(gcf,'label','Object_Defaults', 'callback', @defaultmenu);
  d.dfacet  = uimenu(d.defmenu,'label','Slice Color Faceted','callback','sliceomatic defaultfaceted');
  d.dflat   = uimenu(d.defmenu,'label','Slice Color Flat',   'callback','sliceomatic defaultflat');
  d.dinterp = uimenu(d.defmenu,'label','Slice Color Interp', 'callback','sliceomatic defaultinterp');
  d.dtex    = uimenu(d.defmenu,'label','Slice Color Texture','callback','sliceomatic defaulttexture');
  d.dcnone  = uimenu(d.defmenu,'label','Slice Color None','callback','sliceomatic defaultcolornone');
  d.dtnone  = uimenu(d.defmenu,'label','Slice Transparency None','callback','sliceomatic defaulttransnone','separator','on');
  d.dtflat  = uimenu(d.defmenu,'label','Slice Transparency Flat','callback','sliceomatic defaulttransflat');
  d.dtinterp= uimenu(d.defmenu,'label','Slice Transparency Interp','callback','sliceomatic defaulttransinterp');
  d.dttex   = uimenu(d.defmenu,'label','Slice Transparency Texture','callback','sliceomatic defaulttranstexture');
  d.dlflat  = uimenu(d.defmenu,'label','IsoSurface Lighting Flat','callback','sliceomatic defaultlightflat','separator','on');
  d.dlsmooth= uimenu(d.defmenu,'label','IsoSurface Lighting Smooth','callback','sliceomatic defaultlightsmooth');
  d.dcflat  = uimenu(d.defmenu,'label','Contour Color Flat',   'callback','sliceomatic defaultcontourflat','separator','on');
  d.dcinterp= uimenu(d.defmenu,'label','Contour Color Interp', 'callback','sliceomatic defaultcontourinterp');
  d.dcblack = uimenu(d.defmenu,'label','Contour Color Black',  'callback','sliceomatic defaultcontourblack');
  d.dcwhite = uimenu(d.defmenu,'label','Contour Color White',  'callback','sliceomatic defaultcontourwhite');
  d.dclinew = uimenu(d.defmenu,'label','Contour Line Width');
  d.dcl1    = uimenu(d.dclinew,'label','1','callback','sliceomatic defaultcontourlinewidth 1');
  d.dcl2    = uimenu(d.dclinew,'label','2','callback','sliceomatic defaultcontourlinewidth 2');
  d.dcl3    = uimenu(d.dclinew,'label','3','callback','sliceomatic defaultcontourlinewidth 3');
  d.dcl4    = uimenu(d.dclinew,'label','4','callback','sliceomatic defaultcontourlinewidth 4');
  d.dcl5    = uimenu(d.dclinew,'label','5','callback','sliceomatic defaultcontourlinewidth 5');
  d.dcl6    = uimenu(d.dclinew,'label','6','callback','sliceomatic defaultcontourlinewidth 6');
  
  d.defcolor='texture';
  d.defalpha='none';
  d.deflight='smooth';
  d.defcontourcolor='black';
  d.defcontourlinewidth=1;

  % Set props for all slices menu
  d.allmenu = uimenu(gcf,'label','AllSlices');
  uimenu(d.allmenu,'label','Color Faceted','callback','sliceomatic allfacet');
  uimenu(d.allmenu,'label','Color Flat','callback','sliceomatic allflat');
  uimenu(d.allmenu,'label','Color Interp','callback','sliceomatic allinterp');
  uimenu(d.allmenu,'label','Color Texture','callback','sliceomatic alltex');
  uimenu(d.allmenu,'label','Color None','callback','sliceomatic allnone');
  uimenu(d.allmenu,'label','Transparency None','callback','sliceomatic alltnone','separator','on');
  uimenu(d.allmenu,'label','Transparency .5','callback','sliceomatic alltp5');
  uimenu(d.allmenu,'label','Transparency Flat','callback','sliceomatic alltflat');
  uimenu(d.allmenu,'label','Transparency Interp','callback','sliceomatic alltinterp');
  uimenu(d.allmenu,'label','Transparency Texture','callback','sliceomatic allttex');

  % Set Help menu
  d.Help = uimenu(gcf,'label','Help');
  uimenu(d.Help,'label','About dicomrt_explore','callback','sliceomatic showabout_dicomrt_explore');
  uimenu(d.Help,'label','About sliceomatic','callback','sliceomatic showabout_sliceomatic');

  % Context Menus
  % Slice Context Menu
  d.uic=uicontextmenu('callback', @slicecontextmenu);
  d.vistog = uimenu(d.uic,'label','Visible','callback','sliceomatic togglevisible');
  d.uicdelete = uimenu(d.uic,'label','Delete','callback','sliceomatic deleteslice');
  d.smfacet   = uimenu(d.uic,'label','Color Faceted','callback','sliceomatic setfaceted','separator','on');
  d.smflat    = uimenu(d.uic,'label','Color Flat','callback','sliceomatic setflat');
  d.sminterp  = uimenu(d.uic,'label','Color Interp','callback','sliceomatic setinterp');
  d.smtex     = uimenu(d.uic,'label','Color Texture','callback','sliceomatic settexture');
  d.smnone    = uimenu(d.uic,'label','Color None','callback','sliceomatic setnone');
  d.smtnone   = uimenu(d.uic,'label','Transparency None','callback','sliceomatic setalphanone','separator','on');
  d.smtp5     = uimenu(d.uic,'label','Transparency .5','callback','sliceomatic setalphapoint5');
  d.smtflat   = uimenu(d.uic,'label','Transparency Flat','callback','sliceomatic setalphaflat');
  d.smtinterp = uimenu(d.uic,'label','Transparency Interp','callback','sliceomatic setalphainterp');
  d.smttex    = uimenu(d.uic,'label','Transparency Texture','callback','sliceomatic setalphatexture');
  d.smcontour = uimenu(d.uic,'label','Add Contour','separator','on');
  d.smcont0   = uimenu(d.smcontour,'label','Auto','callback','sliceomatic slicecontour');
  d.smcont1   = uimenu(d.smcontour,'label','Select','callback','sliceomatic slicecontour_select','separator','on');
  d.smrcontour= uimenu(d.uic,'label','Remove Contour','callback','sliceomatic deleteslicecontour');
  d.smcflat   = uimenu(d.uic,'label','Contour Flat','callback','sliceomatic slicecontourflat','separator','on');
  d.smcinterp = uimenu(d.uic,'label','Contour Interp','callback','sliceomatic slicecontourinterp');
  d.smcblack  = uimenu(d.uic,'label','Contour Black','callback','sliceomatic slicecontourblack');
  d.smcwhite  = uimenu(d.uic,'label','Contour White','callback','sliceomatic slicecontourwhite');
  d.smccolor  = uimenu(d.uic,'label','Contour Color','callback','sliceomatic slicecontourcolor');
  d.smclinew  = uimenu(d.uic,'label','Contour Line Width');
  d.smcl1     = uimenu(d.smclinew,'label','1','callback','sliceomatic slicecontourlinewidth 1');
  d.smcl2     = uimenu(d.smclinew,'label','2','callback','sliceomatic slicecontourlinewidth 2');
  d.smcl3     = uimenu(d.smclinew,'label','3','callback','sliceomatic slicecontourlinewidth 3');
  d.smcl4     = uimenu(d.smclinew,'label','4','callback','sliceomatic slicecontourlinewidth 4');
  d.smcl5     = uimenu(d.smclinew,'label','5','callback','sliceomatic slicecontourlinewidth 5');
  d.smcl6     = uimenu(d.smclinew,'label','6','callback','sliceomatic slicecontourlinewidth 6');
  
  % Isosurface Context Menu
  d.uiciso=uicontextmenu('callback',@isocontextmenu);
  d.vistogiso = uimenu(d.uiciso,'label','Visible','callback','sliceomatic isotogglevisible');
  d.isodelete = uimenu(d.uiciso,'label','Delete','callback','sliceomatic isodelete');
  d.isoflatlight=uimenu(d.uiciso,'label','Lighting Flat','callback','sliceomatic isoflatlight','separator','on');
  d.isosmoothlight=uimenu(d.uiciso,'label','Lighting Smooth','callback','sliceomatic isosmoothlight');
  d.isocolor = uimenu(d.uiciso,'label','Change Color','callback','sliceomatic isocolor','separator','on');
  d.isoalpha=uimenu(d.uiciso,'label','Change Transparency');
  uimenu(d.isoalpha,'label','.2','callback','sliceomatic isoalpha .2');
  uimenu(d.isoalpha,'label','.5','callback','sliceomatic isoalpha .5');
  uimenu(d.isoalpha,'label','.8','callback','sliceomatic isoalpha .8');
  uimenu(d.isoalpha,'label','1','callback','sliceomatic isoalpha 1');
  d.isocap=uimenu(d.uiciso,'label','Add IsoCaps','callback','sliceomatic isocaps','separator','on');
  
  outd = d;
  
function controlmenu(fig, action)  
% Handle doing things to the CONTROLS menu
  
  d=getappdata(gcf,'sliceomatic');

  if cameratoolbar('getvisible')
    set(d.camtoolbar,'checked','on');
  else
    set(d.camtoolbar,'checked','off');
  end
  
  set([d.dcalpha1 d.dcalpha8 d.dcalpha6 d.dcalpha5 d.dcalpha6 d.dcalpha2 d.dcalpha0...
       d.dclabels d.dcvis ],...
      'checked','off');

  switch get(d.pxx,'facealpha')
   case 1,  set(d.dcalpha1,'checked','on');
   case .8, set(d.dcalpha8,'checked','on');
   case .6, set(d.dcalpha6,'checked','on');
   case .5, set(d.dcalpha5,'checked','on');
   case .4, set(d.dcalpha4,'checked','on');
   case .2, set(d.dcalpha2,'checked','on');
   case 0,  set(d.dcalpha0,'checked','on');
  end
  
  if ~isempty(get(d.axx,'xticklabel'))
    set(d.dclabels,'checked','on');
  end
  
  if strcmp(get(d.axx,'visible'),'on')
    set(d.dcvis,'checked','on');
  end
  
  if 0
    xt = get(get(d.axx,'title'),'string');
    switch xt
     case 'X Slice Controller'
      set(d.dcslice,'checked','on');
    end
    
    xt = get(get(d.axiso,'title'),'string');
    switch xt
     case 'Iso Surface Controller'
      set(d.dciso,'checked','on');
    end
  end
  
function defaultmenu(fig, action)
% Handle toggling bits on the slice defaults menu
  
  d=getappdata(gcf,'sliceomatic');
  
  set([d.dfacet d.dflat d.dinterp d.dtex d.dtnone d.dtflat d.dtinterp ...
       d.dttex d.dcflat d.dcinterp d.dcblack d.dcwhite d.dcnone ...
       d.dlflat d.dlsmooth ...
       d.smcl1 d.smcl2 d.smcl3 d.smcl4 d.smcl5 d.smcl6 ], 'checked','off');
  switch d.defcolor
   case 'faceted'
    set(d.dfacet,'checked','on');
   case 'flat'
    set(d.dflat,'checked','on');
   case 'interp'
    set(d.dinterp,'checked','on');
   case 'texture'
    set(d.dtex,'checked','on');
   case 'none'
    set(d.dcnone,'checked','on');
  end
  switch d.defalpha
   case 'none'
    set(d.dtnone,'checked','on');
   case 'flat'
    set(d.dtflat,'checked','on');
   case 'interp'
    set(d.dtinterp,'checked','on');
   case 'texture'
    set(d.dttex,'checked','on');
  end
  switch d.deflight
   case 'flat'
    set(d.dlflat,'checked','on');
   case 'smooth'
    set(d.dlsmooth,'checked','on');
  end
  switch d.defcontourcolor
   case 'flat'
    set(d.dcflat,'checked','on');
   case 'interp'
    set(d.dcinterp,'checked','on');
   case 'black'
    set(d.dcblack,'checked','on');
   case 'white'
    set(d.dcwhite,'checked','on');
  end
  switch d.defcontourlinewidth
   case 1, set(d.dcl1,'checked','on');
   case 2, set(d.dcl2,'checked','on');
   case 3, set(d.dcl3,'checked','on');
   case 4, set(d.dcl4,'checked','on');
   case 5, set(d.dcl5,'checked','on');
   case 6, set(d.dcl6,'checked','on');
  end

function slicecontextmenu(fig,action)
% Context menu state for slices

  d=getappdata(gcf,'sliceomatic');

  [a s]=getarrowslice;
  set([d.smfacet d.smflat d.sminterp d.smtex d.smtnone d.smtp5 ...
       d.smtflat d.smtinterp d.smttex d.smnone],'checked','off');
  set(d.vistog,'checked',get(s,'visible'));
  
  if propcheck(s,'edgec',[0 0 0])
    set(d.smfacet,'checked','on');
  elseif propcheck(s,'facec','flat')
    set(d.smflat,'checked','on');
  end
  if propcheck(s,'facec','interp')
    set(d.sminterp,'checked','on');
  end
  if propcheck(s,'facec','texturemap')
    set(d.smtex,'checked','on');
  end
  if propcheck(s,'facec','none')
    set(d.smnone,'checked','on');
  end
  if propcheck(s,'facea',1)
    set(d.smtnone,'checked','on');
  end
  if propcheck(s,'facea',.5)
    set(d.smtp5,'checked','on');
  end
  if propcheck(s,'facea','flat')
    set(d.smtflat,'checked','on');
  end
  if propcheck(s,'facea','interp')
    set(d.smtinterp,'checked','on');
  end
  if propcheck(s,'facea','texturemap')
    set(d.smttex,'checked','on');
  end
  cm = [d.smcflat d.smcinterp d.smcblack d.smcwhite d.smccolor ...
       d.smcl1 d.smcl2 d.smcl3 d.smcl4 d.smcl5 d.smcl6 ];
  set(cm,'checked','off');
  if isempty(getappdata(s,'contour'))
    set(d.smcontour,'enable','on');
    set(d.smrcontour,'enable','off');
    set(cm,'enable','off');
  else
    set(d.smcontour,'enable','off')
    set(d.smrcontour,'enable','on')
    set(cm,'enable','on')
    c = getappdata(s,'contour');
    ec = get(c,'edgecolor');
    if isa(ec,'char')
      switch ec
       case 'flat'
        set(d.smcflat,'checked','on');
       case 'interp'
        set(d.smcinterp,'checked','on');
      end
    else
      if ec == [ 1 1 1 ]
        set(d.smcwhite,'checked','on');
      elseif ec == [ 0 0 0 ]
        set(d.smcblack,'checked','on');
      else
        set(d.smccolor,'checked','on');
      end
    end
    clw = get(c,'linewidth');
    switch clw
     case 1, set(d.smcl1,'checked','on');
     case 2, set(d.smcl2,'checked','on');
     case 3, set(d.smcl3,'checked','on');
     case 4, set(d.smcl4,'checked','on');
     case 5, set(d.smcl5,'checked','on');
     case 6, set(d.smcl6,'checked','on');
    end
  end
  
function isocontextmenu(fig,action)
% Context menu state for isosurfaces

  d=getappdata(gcf,'sliceomatic');
  
  [a s]=getarrowslice;
  if propcheck(s,'facelighting','flat')
    set(d.isoflatlight,'checked','on');
    set(d.isosmoothlight,'checked','off');
  else
    set(d.isoflatlight,'checked','off');
    set(d.isosmoothlight,'checked','on');
  end
  set(d.vistogiso,'checked',get(s,'visible'));
  if ~isempty(getappdata(s,'isosurfacecap'))
    set(d.isocap,'checked','on');
  else
    set(d.isocap,'checked','off');
  end

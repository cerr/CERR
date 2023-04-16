function varargout = nii_viewer(fname, varargin)
% Basic tool to visualize NIfTI images.
% 
%  NII_VIEWER('/data/subj2/fileName.nii.gz')
%  NII_VIEWER('background.nii', 'overlay.nii')
%  NII_VIEWER('background.nii', {'overlay1.nii' 'overlay2.nii'})
% 
% If no input is provided, the viewer will load included MNI_2mm brain as
% background NIfTI. Although the preferred format is NIfTI, NII_VIEWER accepts
% any files that can be converted into NIfTI by dicm2nii, including NIfTI,
% dicom, PAR/REC, etc. In case of CIfTI file, it will show both the volume and 
% surface view if GIfTI is available.
% 
% Here are some features and usage.
% 
% The basic use is to open a NIfTI file to view. When a NIfTI (background) is
% open, the display always uses the image plane close to xyz axes (voxel space)
% even for oblique acquisition. The possible confusion arises if the acquisition
% was tilted with a large angle, and then the orientation labels will be less
% accurate. The benefit is that no interpolation is needed for the background
% image, and there is no need to switch coordinate system when images with
% different systems are overlaid. The display is always in correct scale at
% three vies even with non-isotropic voxels. The displayed IJK always correspond
% to left -> right, posterior -> anterior and inferior -> superior directions,
% while the NIfTI data may not be saved in this order or along these directions.
% The I-index is increasing from left to right even when the display is flipped
% as radiological convention (right on left side).
% 
% Navigation in 4D can be by mouse click, dialing IJK and volume numbers, or
% using keys (arrow keys and [ ] for 3D, and < > for volume).
% 
% After the viewer is open, one can drag-and-drop a NIfTI file into the viewer
% to open as background, or drop a NIfTI with Control key down to add it as
% overlay.
% 
% By default, the viewer shows full view of the background image data. The
% zoom-in always applies to three views together, and enlarges around the
% location of the crosshair. To zoom around a different location, set the
% crosshair to the interested location, and apply zoom again either by View ->
% Zoom in, or pressing Ctrl (Cmd) and +/-. View -> Set crosshair at -> center of
% view (or pressing key C) can set the crosshair to the center of display for
% all three views.
% 
% Overlays are always mapped onto the coordinate of background image, so
% interpolation (nearest/linear/cubic/spline) is usually involved. The overlay
% makes sense only when it has the same coordinate system as the background
% image, while the resolution and dimension can be different. The viewer tries
% to match any of sform and qform between the images. If there is no match, a
% warning message will show up.
% 
% A special overlay feature "Add aligned overlay" can be used to check the
% effect of registration, or overlay an image to a different coordinate system
% without creating a transformed file. It will ask for two files. The first is
% the overlay NIfTI file, and the second is either a transformation matrix file
% which aligns the overlay to the background image, or a warp file which
% transforms the overlay into the background reference.
% 
% Here is an example to check FSL alignment. From a .feat/reg folder, Open
% "highres" as background image. "Add overlay" for "example_func". If there is
% head movement between the highres and the functional scans, the overlap will
% be off. Now "Add aligned overlay" for "example_func", and use
% example_func2highres.mat as the matrix. The two dataset should overlap well if
% the alignment matrix is accurate.
% 
% Here is another example to overlay to a different coordinate system for FSL
% result. Open .feat/reg/standard.nii.gz as background. If an image like
% .feat/stats/zstat1.nii.gz is added as an overlay, a warning message will say
% inconsistent coordinate system since the zstat image is in Scanner Anat. The
% correct way is to "Add aligned overlay" for zstat1, and either use
% .feat/reg/example_func2standard.mat for linear transformation or better use
% .feat/reg/example_func2standard_warp.nii.gz if available for alignment.
% 
% When the mouse pointer is moved onto a voxel, the x/y/z coordinates and voxel
% value will show on the panel. If there is an overlay, the overlay voxel value
% will also show up, unless its display is off. When the pointer moves onto the
% panel or out of an image, the information for the voxel at crosshair will be
% displayed. The display format is as following with val of the top image
% displayed first:
%  (x,y,z): val_1 val_2 val_3 ...
%
% Note that although the x/y/z coordinates are shared by background and overlay
% images, IJK indices are always for background image (name shown on title bar).
% 
% The mouse-over display can be turned on/off from Help -> Preferences ...
% 
% If there is a .txt label file in the same folder as the NIfTI file, like for
% AAL, the labels will be shown instead of voxel value. The txt file should have
% a voxel value and ROI label pair per line, like
%  1 Precentral_L
%  2 Precentral_R
%  3 ...
% 
% Image display can be smoothed in 3D (default is off). The smooth is slow when
% the image dimension is large, even when the current implementation of smooth
% does not consider voxel size.
% 
% Background image and overlays are listed at the top-left of the panel. All
% parameters of the bottom row of the panel are for the highlighted image. This
% feature is indicated by the highlighted frame the parameters. Each NIfTI file
% has its own set of parameters (display min and max value, LUT, alpha, whether
% to smooth, interpolation method, and volume number) to control its display.
% Moving the mouse onto a parameter will show the meaning of the parameter.
% 
% The lastly added overlay is on the top of display and top of the file list.
% This also applies in case there is surface figure for CIfTI files. The
% background and overlay order can be changed by the two small arrows next to
% the list, or from Overlay -> Move selected image ...
% 
% Each NIfTI display can be turned on/off by clicking the small checkbox at the
% left side of the file (or pressing spacebar for the selected NIfTI). This
% provides a way to turn on/off an overlay to view the overlap. Most operations
% are applied to the selected NIfTI in the list, such as Show NIfTI hdr/ext
% under Window menu, Move/Close overlay under Overlay menu, and most operations
% under File menu.
% 
% A NIfTI mask can be applied to the selected image. Ideally, the mask should be
% binary, and the image corresponding to the non-zero part of the mask will be
% displayed. If non-binary mask is detected, a threshold to binarize will be
% asked. If the effect is not satisfied with the threshold, one can apply the
% mask with a different threshold without re-loading image. The way to remove a
% mask is to Remove, then Add overlay again. In case one likes to modulate the
% selected image with another NIfTI image (multiply two images), File -> Apply
% modulation will do it. If the mask image is not within 0 and 1, the lower and
% upper bound will be asked to normalize the range to [0 1]. A practical use of
% modulation is to use dti_FA map as weight for dti_V1 RGB image.
% 
% For multi-volume data, one can change the Volume Number (the parameter at
% rightmost of the panel) to check the head motion. Click in the number dialer
% or press < or > key, to simulate movie play. It is better to open the 4D data
% as background, since it may be slower to map it to the background image.
% 
% Popular LUT options are implemented. Custom LUT can be added by Overlay ->
% Load LUT for selected overlay. The custom LUT file can be in text format (each
% line represents an RGB triplet, while the first line corresponds to the value
% 0 in the image data), or binary format (uint8 for all red, then green then
% blue). The color coding can be shown by View -> Show colorbar. There are
% several special LUTs. The "two-sided" allows to show both positive and
% negative data in one view. For example, if the display range is 3 to 10 for a
% t-map, positive T above 3 will be coded as red-yellow, and T below -3 will be
% coded as blue-green. This means the absolute display range values are used.
% 
% One of the special LUT is "lines". This is for normalized vector display,
% e.g. for diffusion vector. The viewer will refuse the LUT selection if
% the data is not normalized vector. Under this LUT, all other parameters
% for the display are ignored. The color of the "lines" is the max color of
% previous LUT. For example, if one likes to show blue vector lines, choose
% LUT "blue" first, then change it to "lines".
% 
% In case of complex image, most LUTs will display only the magnitude of the
% data, except the following three phase LUTs, where the magnitude is used as
% mask. Here is how the 3 phase LUTs encodes phase from 0 to 360 degree:
%  phase:  red-yellow monotonically,
%  phase3: red-yellow-green-yellow-red circularly, and 
%  phase6: red-yellow-green/violet-blue-cyan, with sharp change at 180 degree. 
% These LUTs are useful to visualize activation of periodic stimulus, such as
% those by expanding/shrinking ring or rotating wedge for retinotopy. To use
% this feature, one can save an complex NIfTI storing the Fourier component at
% the stimulus frequency.
% 
% Note that, for RGB NIfTI, the viewer always displays the data as color
% regardless of the LUT option. The display min and max value also have no
% effect on RGB image. There is a special LUT, RGB, which is designed to display
% non-RGB NIfTI data as RGB, e.g. FSL-style 3-volome data. 
% 
% The viewer figure can be copied into clipboard (not available for Linux) or
% saved as variety of image format. For high quality picture, one can increase
% the output resolution by Help -> Preferences -> Resolution. Higher resolution
% will take longer time to copy or save, and result in larger file. If needed,
% one can change to white background for picture output. With white background,
% the threshold for the background image needs to be carefully selected to avoid
% strange effect with some background images. For this reason, white background
% is intended only for picture output.
% 
% The selected NIfTI can also be saved as different format from File -> Save
% NIfTI as. For example, a file can be saved as a different resolution. With a
% transformation matrix, a file can also be saved into a different template. The
% latter is needed for FSLview since it won't allow overlay with different
% resolution or dimension at least till version 5.0.8.
% 
% See also NII_TOOL DICM2NII NII_XFORM

%% By Xiangrui Li (xiangrui.li at gmail.com)
% History(yymmdd):
% 151021 Almost ready to publish.
% 151104 Include drag&drop by Maarten van der Seijs.
% 151105 Bug fix for Show NIfTI hdr/ext.
% 151106 Use p.interp to avoid unnecessary interp for overlay;
%        Use check mark for colorbar/crosshair/background menu items.
% 151111 Take care of slope/inter of img; mask applies to DTI lines.
% 151114 Avoid see-thu for white background.
% 151119 Make smooth faster by using only 3 slices; Allow flip L/R.
% 151120 Implement key navigation and zoom in/out.
% 151121 Implement erode for white background; Add 'Show NIfTI essentials'. 
% 151122 Bug fix for background img with sform=0.
% 151123 Show coordinate system in fig title; show masked/aligned in file list;
%        Bug fix for alpha (0/1 only); Bug fix for background image R change.
% 151125 Avoid recursion for white background (failed under Linux).
% 151128 Change checkbox to radiobutton: looks better;
%        Fix the bug in reorient dim(perm), introduced in last revision.
% 151129 Correct Center crosshair (was off by 0.5); Use evt.Key & add A/C/X/F1. 
% 151201 Keep fig location & pref when 'open' & dnd: more user friendly.
% 151202 java robot trick allows to add overlay by Ctrl-dnd.
% 151207 Implement 'Add modulation'.
% 151208 Add xyz display for each view.
% 151217 Callback uses subfunc directly, and include fh as input.
% 151222 Show ROI labels (eg AAL) if .txt file with same name exists.
% 151224 Implement more matlab LUTs and custom LUT.
% 151230 Use listbox for files; Add stack buttons; file order reversed.
% 160102 Store p.R0 if need interp; No coordinate change for background.
% 160104 set_cdata: avoid indexing for single vol img: may be much faster!
%        jscroll_handle from findjobj.m to set vertical scoll bar as needed.
% 160107 Rename XYZ label to IJK, implement "Set crosshair at XYZ".
% 160108 Fix the case of 2-form_code for background and addMask.
% 160109 Allow to turn off mouse-over display from Preferences;
%        Implement Help -> Check update for easy update;
%        Use Matlab built-in pref method for all files in the package.
% 160111 Use image ButtonDownFcn; Mouse down&move now is same as mouse move.
% 160112 Change back to line for crosshair: quiver is slow;
%        Bug fix for white backgrnd & saveas backgrnd due to list order reverse.
% 160113 Implement time course for a cube.
% 160114 Figure visible avoids weird hanging problem for some matlab versions.
% 160119 Allow adding multiple overlays with cellstr as 2nd input.
% 160131 set_file: bug fix for cb(j); dnd: restore mouse location.
% 160208 Allow moving background image in stack.
% 160209 RGBA data supported; Background image can use lut "lines".
% 160218 "lines": Fix non-isovoxel display; Same-dim background not required.
% 160402 nii_xform_mat: make up R for possible Analyze file.
% 160506 phase LUT to map complex img: useful for retinotopy.
% 160509 Have 3 phase LUTs; Implement 'Open in new window'.
% 160512 KeyPressFcn bug fix: use the smallest axis dim when zoom in.
% 160517 KeyPressFcn: avoid double-dlg by Ctrl-A; phase6: bug fix for blue b3.
% 160531 use handle() for fh & others: allow dot convention for early matlab.
% 160601 Add cog and to image center, re-organize 'Set crosshair at' menu.
% 160602 bug fix for 'closeAll' files.String(ib); COG uses abs and excludes NaN.
% 160605 Add 'RGB' LUT to force RGB display: DTI_V1 or fsl style RGB file.
% 160608 javaDropFcn: 2 more method for ctlDn; bug fix for fh.xxx in Resize.
% 160620 Use JIDE CheckBoxList; Simplify KeyFcn by not focusing on active items. 
% 160627 javaDropFcn: robot-click drop loc to avoid problem with vnc display. 
% 160701 Implement hist for current volume; hs.value show top overlay first.
% 160703 bug fix for 'Add aligned' complex img: set p.phase after re-orient.
% 160710 Implement 'Create ROI file'; Time coure is for sphere, not cube.
% 160713 javaDropFnc for Linux: Robot key press replaces mouse click;
%        Implement 'Set crosshair at' 'Smoothed maximum'.
% 160715 lut2img: bug fix for custom LUT; custom LUT uses rg [0 255]; add gap=0.
% 160721 Implement 'Set crosshair at' & 'a point with value of'.
% 160730 Allow to load single volume for large dataset.
% 161003 Add aligned overlay: accept FSL warp file as transformation.
% 161010 Implement 'Save volume as'; xyzr2roi: use valid q/sform.
% 161018 Take care of issue converting long file name to var name.
% 161103 Fix qform-only overlay, too long fig title, overlay w/o valid formCode.
% 161108 Implement "Crop below crosshair" to remove excessive neck tissue.
% 161115 Use .mat file for early spm Analyze file.
% 161216 Show more useful 4x4 R for both s/q form in nii essentials.
% 170109 bug fix: add .phase for background nifti.
% 170130 get_range: use nii as input, so always take care of slope/inter.
% 170210 Use flip for flipdim if available (in multiple files).
% 170212 Can open nifti-convertible files; Add Save NIfTI as -> a copy.
% 170421 java_dnd() changed as func, ControlDown OS independent by ACTION_LINK.
% 170515 Use area to normalize histogram.
% 171031 Implement layout. axes replace subplot to avoid overlap problem.
% 171129 bug fix save_nii_as(): undo img scale for no_save_nii.
% 171214 Try to convert back to volume in case of CIfTI (need anatomical gii).
% 171226 Store all info into sag img handle (fix it while it aint broke :)
% 171228 Surface view for gii (include HCP gii template).
% 171229 combine into one overlay for surface view.
% 180103 Allow inflated surface while mapping to correct location in volume.
% 180108 set_file back to nii_viewer_cb for cii_view_cb convenience.
% 180128 Preference stays for current window, and applies to new window only.
% 180228 'Add overlay' check nii struct in base workspace first.
% 180309 Implement 'Standard deviation' like for 'time course'.
% 180522 set_xyz: bug fix for display val >2^15.
% Later update history can be found at github.
%%
if nargin==2 && ischar(fname) && strcmp(fname, 'func_handle')
    varargout{1} = str2func(varargin{1});
    return;
elseif nargin>1 && ischar(fname) && strcmp(fname, 'LocalFunc')
    [varargout{1:nargout}] = feval(varargin{:});
    return;
end

if nargin<1 || isempty(fname) % open the included standard_2mm
    fname = fullfile(fileparts(mfilename('fullpath')), 'example_data.mat'); 
    fname = load(fname, 'nii'); fname = fname.nii;
end

nii = get_nii(fname);
[p, hs.form_code, rg, dim] = read_nii(nii); % re-oriented
p.Ri = inv(p.R);
nVol = size(p.nii.img, 4);
hs.bg.R   = p.R;
hs.bg.Ri  = p.Ri;
hs.bg.hdr = p.hdr0;
if ~isreal(p.nii.img)
    p.phase = angle(p.nii.img); % -pi to pi
    p.phase = mod(p.phase/(2*pi), 1); % 0~1
    p.nii.img = abs(p.nii.img); % real now
end
hs.dim = single(dim); % single saves memory for ndgrid
hs.pixdim = p.pixdim;
hs.gap = min(hs.pixdim) ./ hs.pixdim * 3; % in unit of smallest pixdim

p.lb = rg(1); p.ub = rg(2);
p = dispPara(p);
[pName, niiName, ext] = fileparts(p.nii.hdr.file_name);
if strcmpi(ext, '.gz'), [~, niiName] = fileparts(niiName); end

if nargin>1 && any(ishandle(varargin{1})) % called by Open or dnd
    fh = varargin{1};
    hsN = guidata(fh);
    pf = hsN.pref.UserData; % use the current pref for unless new figure
    fn = get(fh, 'Number');
    close(fh);
else
    pf = getpref('nii_viewer_para');
    if isempty(pf) || ~isfield(pf, 'layout') % check lastly-added field
        pf = struct('openPath', pwd, 'addPath', pwd, 'interp', 'linear', ...
            'extraV', NaN, 'dpi', '0', 'rightOnLeft', false, ...
            'mouseOver', true, 'layout', 2);
        setpref('nii_viewer_para', fieldnames(pf), struct2cell(pf));
    end
    
    a = handle(findall(0, 'Type', 'figure', 'Tag', 'nii_viewer'));
    if isempty(a)
        fn = 'ni' * 256.^(1:2)'; % start with a big number for figure
    elseif numel(a) == 1
        fn = get(a, 'Number') + 1; % this needs handle() to work
        if isempty(fn), fn = 'ni' * 256.^(1:2)'; end
    else
        fn = max(cell2mat(get(a, 'Number'))) + 1;
    end
end
[siz, axPos, figPos] = plot_pos(dim.*hs.pixdim, pf.layout);

fh = figure(fn);
if nargout, varargout{1} = fh; end
hs.fig = handle(fh); % have to use numeric for uipanel for older matlab
figNam = p.nii.hdr.file_name;
if numel(figNam)>40, figNam = [figNam(1:40) '...']; end
figNam = ['nii_viewer - ' figNam ' (' formcode2str(hs.form_code(1)) ')'];
set(fh, 'Toolbar', 'none', 'Menubar', 'none', ... % 'Renderer', 'opengl', ...
    'NumberTitle', 'off', 'Tag', 'nii_viewer', 'DockControls', 'off', ...
    'Position', [figPos siz+[2 66]], 'Name', figNam);
cb = @(cmd) {@nii_viewer_cb cmd hs.fig}; % callback shortcut
xyz = [0 0 0]; % start cursor location
c = round(p.Ri * [xyz 1]'); c = c(1:3)' + 1; % 
ind = c<=1 | c>=dim;
c(ind) = round(dim(ind)/2);
% c = round(dim/2); % start cursor at the center of images
xyz = round(p.R * [c-1 1]'); % take care of rounding error

%% control panel
pos = getpixelposition(fh); pos = [1 pos(4)-64 pos(3) 64];
hs.panel = uipanel(fh, 'Units', 'pixels', 'Position', pos, 'BorderType', 'none');
hs.focus = uicontrol(hs.panel, 'Style', 'text'); % dummy uicontrol for focus

% file list by JIDE CheckBoxList: check/selection independent
mdl = handle(javax.swing.DefaultListModel, 'CallbackProperties'); % dynamic item
mdl.add(0, niiName);
mdl.IntervalAddedCallback   = cb('width');
mdl.IntervalRemovedCallback = cb('width');
mdl.ContentsChangedCallback = cb('width'); % add '(mask)' etc
h = handle(com.jidesoft.swing.CheckBoxList(mdl), 'CallbackProperties');
h.setFont(java.awt.Font('Tahoma', 0, 11));
% h.ClickInCheckBoxOnly = true; % it's default
h.setSelectionMode(0); % single selection
h.setSelectedIndex(0); % 1st highlighted
h.addCheckBoxListSelectedIndex(0); % check it
h.ValueChangedCallback = cb('file'); % selection change
h.MouseReleasedCallback = @(~,~)uicontrol(hs.focus); % move focus away
% h.Focusable = false;
h.setToolTipText(['<html>Select image to show/modify its display ' ...
    'parameters.<br>Click checkbox to turn on/off image']);
jScroll = com.mathworks.mwswing.MJScrollPane(h); %#ok<*JAPIMATHWORKS>
width = h.getPreferredScrollableViewportSize.getWidth;
width = max(60, min(width+20, pos(3)-408)); % 20 pixels for vertical scrollbar
warning('off', 'MATLAB:ui:javacomponent:FunctionToBeRemoved');
[~, hs.scroll] = javacomponent(jScroll, [2 4 width 60], hs.panel); %#ok<*JAVCM>
hCB = handle(h.getCheckBoxListSelectionModel, 'CallbackProperties');
hCB.ValueChangedCallback = cb('toggle'); % check/uncheck
hs.files = javaObjectEDT(h); % trick to avoid java error by Yair

% panel for controls except hs.files
pos = [width 1 pos(3)-width pos(4)];
ph = uipanel(hs.panel, 'Units', 'pixels', 'Position', pos, 'BorderType', 'none');
clr = get(ph, 'BackgroundColor');
hs.params = ph;

feature('DefaultCharacterSet', 'UTF-8'); % for old matlab to show triangles
hs.overlay(1) = uicontrol(ph, 'Style', 'pushbutton', 'FontSize', 7, ...
    'Callback', cb('stack'), 'Enable', 'off', 'SelectionHighlight', 'off', ...
    'String', char(9660), 'Position', [1 37 16 15], 'Tag', 'down', ...
    'TooltipString', 'Move selected image one level down');
hs.overlay(2) = copyobj(hs.overlay(1), ph);
set(hs.overlay(2), 'Callback', cb('stack'), ...
    'String', char(9650), 'Position', [1 50 16 15], 'Tag', 'up', ...
    'TooltipString', 'Move selected image one level up');

hs.value = uicontrol(ph, 'Style', 'text', 'Position', [208 40 pos(3)-208 20], ...
    'BackgroundColor', clr, 'FontSize', 8+(~ispc && ~ismac), ...
    'TooltipString', '(x,y,z): top ... bottom');

% IJK java spinners
labls = 'IJK';
str = {'Left to Right' 'Posterior to Anterior' 'Inferior to Superior'};
pos = [42 44 22]; posTxt = [40 10 20];
for i = 1:3
    loc = [(i-1)*64+34 pos];
    txt = sprintf('%s, 1:%g', str{i}, dim(i));
    hs.ijk(i) = java_spinner(loc, [c(i) 1 dim(i) 1], ph, cb('ijk'), '#', txt);
    uicontrol(ph, 'Style', 'text', 'String', labls(i), 'BackgroundColor', clr, ...
        'Position', [loc(1)-11 posTxt], 'TooltipString', txt, 'FontWeight', 'bold');
end

% Controls for each file
h = hs.files.SelectionBackground; fClr = [h.getRed h.getGreen h.getBlue]/255;
uicontrol(ph, 'Style', 'frame', 'Position', [1 5 412 32], 'ForegroundColor', fClr);
hs.lb = java_spinner([7 10 48 22], [p.lb -inf inf p.lb_step], ph, ...
    cb('lb'), '#.##', 'min value (threshold)');
hs.ub = java_spinner([59 10 56 22], [p.ub -inf inf p.ub_step], ph, ...
    cb('ub'), '#.##', 'max value (clipped)');
hs.lutStr = {'grayscale' 'red' 'green' 'blue' 'violet' 'yellow' 'cyan' ...
    'red-yellow' 'blue-green' 'two-sided'  '<html><font color="red">lines' ...
    'parula' 'jet' 'hsv' 'hot' 'cool' 'spring' 'summer' 'autumn' 'winter' ...
    'bone' 'copper' 'pink' 'prism' 'flag' 'phase' 'phase3' 'phase6' 'RGB' 'custom'};
hs.lut = uicontrol(ph, 'Style', 'popup', 'Position', [113 10 74 22], ...
    'String', hs.lutStr, 'BackgroundColor', 'w', 'Callback', cb('lut'), ...
    'Value', p.lut, 'TooltipString', 'Lookup table options for non-RGB data');
if p.lut==numel(hs.lutStr), set(hs.lut, 'Enable', 'off'); end

hs.alpha = java_spinner([187 10 44 22], [1 0 1 0.1], ph, cb('alpha'), '#.#', ...
    'Alpha: 0 transparent, 1 opaque');

hs.smooth = uicontrol(ph, 'Style', 'checkbox', 'Value', p.smooth, ...
    'Position', [231 10 60 22], 'String', 'smooth', 'BackgroundColor', clr, ...
    'Callback', cb('smooth'), 'TooltipString', 'Smooth image in 3D');
hs.interp = uicontrol(ph, 'Style', 'popup', 'Position', [291 10 68 22], ...
    'String', {'nearest' 'linear' 'cubic' 'spline'}, 'Value', p.interp, ...
    'Callback', cb('interp'), 'Enable', 'off', 'BackgroundColor', 'w', ... 
    'TooltipString', 'Interpolation method for overlay');
hs.volume = java_spinner([361 10 44 22], [1 1 nVol 1], ph, cb('volume'), '#', ...
    ['Volume number, 1:' num2str(nVol)]);
hs.volume.setEnabled(nVol>1);

%% Three views: sag, cor, tra
% this panel makes resize easy: axes relative to panel
hs.frame = uipanel(fh, 'Units', 'pixels', 'Position', [2 2 siz], ...
    'BorderType', 'none', 'BackgroundColor', 'k');

for i = 1:3
    j = 1:3; j(j==i) = [];
    hs.ax(i) = axes('Position', axPos(i,:), 'Parent', hs.frame);
    hs.hsI(i) = handle(image(zeros(dim(j([2 1])), 'single')));
    set(hs.ax(i), 'DataAspectRatio', [1./hs.pixdim(j) 1]);
    hold(hs.ax(i), 'on');
    
    x = [c(j(1))+[-1 1 0 0]*hs.gap(j(1)); 0 dim(j(1))+1 c(j(1))*[1 1]];
    y = [c(j(2))+[0 0 -1 1]*hs.gap(j(2)); c(j(2))*[1 1] 0 dim(j(2))+1];
    hs.cross(i,:) = line(x, y);

    hs.xyz(i) = text(0.02, 0.96, num2str(xyz(i)), 'Parent', hs.ax(i), ...
        'Units', 'normalized', 'FontSize', 12);
end
set(hs.hsI, 'ButtonDownFcn', cb('mousedown'));
p.hsI = hs.hsI; % background img
p.hsI(1).UserData = p; % store everything in sag img UserData

labls='ASLSLP'; 
pos = [0.95 0.5; 0.47 0.96; 0 0.5; 0.47 0.96; 0 0.5; 0.47 0.05]; 
for i = 1:numel(labls)
    hs.ras(i) = text(pos(i,1), pos(i,2), labls(i), 'Units', 'normalized', ...
        'Parent', hs.ax(ceil(i/2)), 'FontSize', 12, 'FontWeight', 'bold');
end

% early matlab's colormap works only for axis, so ax(4) is needed.
hs.ax(4) = axes('Position', axPos(4,:), 'Parent', hs.frame);
try
    hs.colorbar = colorbar(hs.ax(4), 'YTicks', [0 0.5 1], 'Color', [1 1 1], ...
        'Location', 'West', 'PickableParts', 'none', 'Visible', 'off');
catch % for early matlab
    colorbar('peer', hs.ax(4), 'Location', 'West', 'Units', 'Normalized');
    hs.colorbar = findobj(fh, 'Tag', 'Colorbar'); 
    set(hs.colorbar, 'Visible', 'off', 'HitTest', 'off', 'EdgeColor', [1 1 1]);
end

% image() reverses YDir. Turn off ax and ticks
set(hs.ax, 'YDir', 'normal', 'Visible', 'off');
set([hs.ras hs.cross(:)' hs.xyz], 'Color', 'b', 'UIContextMenu', '');
try set([hs.ras hs.cross(:)' hs.xyz], 'PickableParts', 'none'); % new matlab
catch, set([hs.ras hs.cross(:)' hs.xyz], 'HitTest', 'off'); % old ones
end

%% menus
h = uimenu(fh, 'Label', '&File');
uimenu(h, 'Label', 'Open', 'Accelerator', 'O', 'UserData', pName, 'Callback', cb('open'));
uimenu(h, 'Label', 'Open in new window', 'Callback', cb('open'));
uimenu(h, 'Label', 'Apply mask', 'Callback', @addMask);
uimenu(h, 'Label', 'Apply modulation', 'Callback', @addMask);
h_savefig = uimenu(h, 'Label', 'Save figure as');
h_saveas = uimenu(h, 'Label', 'Save NIfTI as');
uimenu(h, 'Label', 'Save volume as ...', 'Callback', cb('saveVolume'));
uimenu(h, 'Label', 'Crop below crosshair', 'Callback', cb('cropNeck'));
uimenu(h, 'Label', 'Create ROI file ...', 'Callback', cb('ROI'));
uimenu(h, 'Label', 'Close window', 'Accelerator', 'W', 'Callback', 'close gcf');

uimenu(h_saveas, 'Label', 'SPM 3D NIfTI (one file/pair per volume)', 'Callback', @save_nii_as);
uimenu(h_saveas, 'Label', 'NIfTI standard RGB (for AFNI, later mricron)', ...
    'Callback', @save_nii_as, 'Separator', 'on');
uimenu(h_saveas, 'Label', 'FSL style RGB (RGB saved in dim 4)', 'Callback', @save_nii_as);
uimenu(h_saveas, 'Label', 'Old mricron style RGB (RGB saved in dim 3)', 'Callback', @save_nii_as);
uimenu(h_saveas, 'Label', 'a copy', 'Callback', @save_nii_as, 'Separator', 'on');
uimenu(h_saveas, 'Label', 'file with a new resolution', 'Callback', @save_nii_as);
uimenu(h_saveas, 'Label', 'file matching background', 'Callback', @save_nii_as);
uimenu(h_saveas, 'Label', 'file in aligned template space', 'Callback', @save_nii_as);

fmt = {'png' 'jpg' 'tif' 'bmp' 'pdf' 'eps'};
if ispc, fmt = [fmt 'emf']; end
for i = 1:numel(fmt)
    uimenu(h_savefig, 'Label', fmt{i}, 'Callback', cb('save'));
end

if ispc || ismac
    h = uimenu(fh, 'Label', '&Edit');
    uimenu(h, 'Label', 'Copy figure', 'Callback', cb('copy'));
end

h_over = uimenu(fh, 'Label', '&Overlay');
uimenu(h_over, 'Label', 'Add overlay', 'Accelerator', 'A', 'Callback', cb('add'));
uimenu(h_over, 'Label', 'Add aligned overlay', 'Callback', cb('add'));

h = uimenu(h_over, 'Label', 'Move selected image', 'Enable', 'off');
uimenu(h, 'Label', 'to top',         'Callback', cb('stack'), 'Tag', 'top');
uimenu(h, 'Label', 'to bottom',      'Callback', cb('stack'), 'Tag', 'bottom');
uimenu(h, 'Label', 'one level up',   'Callback', cb('stack'), 'Tag', 'up');
uimenu(h, 'Label', 'one level down', 'Callback', cb('stack'), 'Tag', 'down');
hs.overlay(3) = h;

hs.overlay(5) = uimenu(h_over, 'Label', 'Remove overlay', 'Accelerator', 'R', ...
    'Callback', cb('close'), 'Enable', 'off');
hs.overlay(4) = uimenu(h_over, 'Label', 'Remove overlays', ...
    'Callback', cb('closeAll'), 'Enable', 'off');
uimenu(h_over, 'Label', 'Load LUT for current overlay', 'Callback', cb('custom'));

h_view = uimenu(fh, 'Label', '&View');
h = uimenu(h_view, 'Label', 'Zoom in by');
for i = [1 1.2 1.5 2 3 4 5 8 10 20]
    uimenu(h, 'Label', num2str(i), 'Callback', cb('zoom'));
end
h = uimenu(h_view, 'Label', 'Layout', 'UserData', pf.layout);
uimenu(h, 'Label', 'one-row', 'Callback', cb('layout'), 'Tag', '1');
uimenu(h, 'Label', 'two-row sag on right', 'Callback', cb('layout'), 'Tag', '2');
uimenu(h, 'Label', 'two-row sag on left', 'Callback', cb('layout'), 'Tag', '3');
uimenu(h_view, 'Label', 'White background', 'Callback', cb('background'));
hLR = uimenu(h_view, 'Label', 'Right on left side', 'Callback', cb('flipLR'));
uimenu(h_view, 'Label', 'Show colorbar', 'Callback', cb('colorbar'));
uimenu(h_view, 'Label', 'Show crosshair', 'Separator', 'on', ...
    'Checked', 'on', 'Callback', cb('cross'));
h = uimenu(h_view, 'Label', 'Set crosshair at');
uimenu(h, 'Label', 'center of view', 'Callback', cb('viewCenter'));
uimenu(h, 'Label', 'center of image', 'Callback', cb('center'));
uimenu(h, 'Label', 'COG of image', 'Callback', cb('cog'));
uimenu(h, 'Label', 'Smoothed maximum', 'Callback', cb('maximum'));
uimenu(h, 'Label', 'a point [x y z] ...', 'Callback', cb('toXYZ'));
uimenu(h, 'Label', 'a point with value of ...', 'Callback', cb('toValue'));
uimenu(h_view, 'Label', 'Crosshair color', 'Callback', cb('color'));
h = uimenu(h_view, 'Label', 'Crosshair gap');
for i = [0 1 2 3 4 5 6 8 10 20 40]
    str = num2str(i); if i==6, str = [str ' (default)']; end %#ok
    uimenu(h, 'Label', str, 'Callback', cb('gap'));
end
h = uimenu(h_view, 'Label', 'Crosshair thickness');
uimenu(h, 'Label', '0.5 (default)', 'Callback', cb('thickness'));
for i = [0.75 1 2 4 8]
    uimenu(h, 'Label', num2str(i), 'Callback', cb('thickness'));
end

h = uimenu(fh, 'Label', '&Window');
uimenu(h, 'Label', 'Show NIfTI essentials', 'Callback', cb('essential'));
uimenu(h, 'Label', 'Show NIfTI hdr', 'Callback', cb('hdr'));
uimenu(h, 'Label', 'Show NIfTI ext', 'Callback', cb('ext'));
uimenu(h, 'Label', 'DICOM to NIfTI converter', 'Callback', 'dicm2nii', 'Separator', 'on');
th = uimenu(h, 'Label', 'Time course ...', 'Callback', cb('tc'), 'Separator', 'on');
setappdata(th, 'radius', 6);
th = uimenu(h, 'Label', 'Standard deviation ...', 'Callback', cb('tc'));
setappdata(th, 'radius', 6);
uimenu(h, 'Label', 'Histogram', 'Callback', cb('hist'));

h = uimenu(fh, 'Label', '&Help');
hs.pref = uimenu(h, 'Label', 'Preferences', 'UserData', pf, 'Callback', @pref_dialog);
uimenu(h, 'Label', 'Key shortcut', 'Callback', cb('keyHelp'));
uimenu(h, 'Label', 'Show help text', 'Callback', 'doc nii_viewer');
checkUpdate = dicm2nii('', 'checkUpdate', 'func_handle');
uimenu(h, 'Label', 'Check update', 'Callback', @(~,~)checkUpdate('nii_viewer'));
uimenu(h, 'Label', 'About', 'Callback', cb('about'));

%% finalize gui
if isnumeric(fh) % for older matlab
    fh = handle(fh);
    schema.prop(fh, 'Number', 'mxArray'); fh.Number = fn;
    hs.lut = handle(hs.lut);
    hs.frame = handle(hs.frame);
    hs.value = handle(hs.value);
    hs.panel = handle(hs.panel);
    hs.params = handle(hs.params);
    hs.scroll = handle(hs.scroll);
    hs.pref = handle(hs.pref);
end
guidata(fh, hs); % store handles and data

%% java_dnd based on dndcontrol at matlabcentral/fileexchange/53511
try % panel has JavaFrame in later matlab
    warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved');
    jFrame = handle(hs.frame.JavaFrame.getGUIDEView, 'CallbackProperties');
catch
    warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    jFrame = fh.JavaFrame.getAxisComponent; %#ok<*JAVFM>
end
try java_dnd(jFrame, cb('drop')); catch me, disp(me.message); end

% iconPNG = fullfile(fileparts(mfilename('fullpath')), 'nii_viewer.png'); 
% fh.JavaFrame.setFigureIcon(javax.swing.ImageIcon(iconPNG)); % windows only
set(fh, 'ResizeFcn', cb('resize'), ... % 'SizeChangedFcn' for later matlab
    'WindowKeyPressFcn', @KeyPressFcn, 'CloseRequestFcn', cb('closeFig'), ...
    'PaperPositionMode', 'auto', 'InvertHardcopy', 'off', 'HandleVisibility', 'Callback');
nii_viewer_cb(fh, [], 'resize', fh); % avoid some weird problem

if pf.mouseOver, set(fh, 'WindowButtonMotionFcn', cb('mousemove')); end
if pf.rightOnLeft, nii_viewer_cb(hLR, [], 'flipLR', fh); end
set_cdata(hs);
set_xyz(hs);

if nargin>1
    if ischar(varargin{1}) || isstruct(varargin{1})
        addOverlay(varargin{1}, fh);
    elseif iscell(varargin{1})
        for i=1:numel(varargin{1}), addOverlay(varargin{1}{i}, fh); end
    end
end

if hs.form_code(1)<1
    warndlg(['There is no valid form code in NIfTI. The orientation ' ...
        'labeling is likely meaningless.']);
end
if isfield(p.nii, 'cii'), cii_view(hs); end

%% Get info from sag img UserData
function p = get_para(hs, iFile)
if nargin<2, iFile = hs.files.getSelectedIndex + 1; end
hsI = findobj(hs.ax(1), 'Type', 'image', '-or', 'Type', 'quiver');
p = get(hsI(iFile), 'UserData');

%% callbacks
function nii_viewer_cb(h, evt, cmd, fh)
hs = guidata(fh);
switch cmd
    case 'ijk' % IJK spinner
        ix = find(h == hs.ijk);
        set_cdata(hs, ix);
        set_cross(hs, ix);
        xyz = set_xyz(hs);
        for i = 1:3, set(hs.xyz(i), 'String', xyz(i)); end % need 3 if oblique
    case 'mousedown' % image clicked
        % if ~strcmp(get(fh, 'SelectionType'), 'normal'), return; end
        ax = gca;
        c = get(ax, 'CurrentPoint');
        c = round(c(1, 1:2));
        i = 1:3;
        i(ax==hs.ax(1:3)) = [];
        hs.ijk(i(1)).setValue(c(1));
        hs.ijk(i(2)).setValue(c(2));
    case {'lb' 'ub' 'lut' 'alpha' 'smooth' 'interp' 'volume'}
        if ~strcmp(cmd, 'volume'), uicontrol(hs.focus); end % move away focus
        p = get_para(hs);
        val = get(h, 'Value');
        
        if strcmp(cmd, 'smooth')
            if val==1 && numel(p.nii.img(:,:,:,1))<2
                set(h, 'Value', 0); return;
            end
        elseif strcmp(cmd, 'lut')
            err = false;
            if val == 11 % error check for vector lines
                if p.lut~=11, hs.lut.UserData = p.lut; end % remember old lut
                err = true;
                if size(p.nii.img,4)~=3
                    errordlg('Not valid vector data: dim4 is not 3');
                else
                    a = sum(p.nii.img.^2, 4); a = a(a(:)>1e-4);
                    if any(abs(a-1)>0.1)
                        errordlg('Not valid vector data: squared sum is not 1');
                    else, err = false; % passed all checks
                    end
                end
            elseif any(val == 26:28) % error check for phase img
                err = ~isfield(p, 'phase');
                if err, warndlg('Seleced image is not complex data.'); end
            elseif val == 29 % RGB
                err = size(p.nii.img,4)~=3;
                if err, errordlg('RGB LUT requries 3-volume data.'); end
            elseif val == numel(hs.lutStr)
                err = true;
                errordlg('Custom LUT is used be NIfTI itself');
            end
            if err, hs.lut.Value = p.lut; return; end % undo selection
        end
        
        p.hsI(1).UserData.(cmd) = val;
        if any(strcmp(cmd, {'lut' 'lb' 'ub' 'volume'})), set_colorbar(hs); end
        if strcmp(cmd, 'volume'), set_xyz(hs); end
        set_cdata(hs);
    case 'resize'
        if isempty(hs), return; end        
        htP = hs.panel.Position(4); % get old height in pixels
        posF = getpixelposition(fh); % asked size by user
        hs.panel.Position(2:3) = posF([4 3]) - [htP 2]; % control panel
        hs.frame.Position(3:4) = posF(3:4) - [2 htP]; % image panel
        nii_viewer_cb([], [], 'width', fh);
    case 'toggle' % turn on/off NIfTI
        i = h.getAnchorSelectionIndex+1;
        if i<1, return; end
        checked = hs.files.getCheckBoxListSelectedIndices+1;
        p = get_para(hs, i);
        if p.show == any(checked==i), return; end % no change
        p.show = ~p.show;
        p.hsI(1).UserData = p;

        states = {'off' 'on'};
        try %#ok<*TRYNC>
            set(p.hsI, 'Visible', states{p.show+1});
            if p.show, set_cdata(hs); end
            set_xyz(hs);
        end
    case 'mousemove'
        % if ~strcmp(get(fh, 'SelectionType'), 'normal'), return; end
        c = cell2mat(get(hs.ax(1:3), 'CurrentPoint'));
        c = c([1 3 5], 1:2); % 3x2
        x = cell2mat(get(hs.ax(1:3), 'XLim')); 
        y = cell2mat(get(hs.ax(1:3), 'YLim')); 
        I = cell2mat(get(hs.ijk, 'Value'))';
        if     c(1,1)>x(1,1) && c(1,1)<x(1,2) && c(1,2)>y(1,1) && c(1,2)<y(1,2)%sag
            I = [I(1) c(1,:)];
        elseif c(2,1)>x(2,1) && c(2,1)<x(2,2) && c(2,2)>y(2,1) && c(2,2)<y(2,2)%cor
            I = [c(2,1) I(2) c(2,2)];
        elseif c(3,1)>x(3,1) && c(3,1)<x(3,2) && c(3,2)>y(3,1) && c(3,2)<y(3,2)%tra
            I = [c(3,:) I(3)];
        end
        set_xyz(hs, I);
    case 'open' % open on current fig or new fig
        pName = hs.pref.UserData.openPath;
        [fname, pName] = uigetfile([pName '/*.nii; *.hdr;*.nii.gz; *.hdr.gz'], ...
            'Select a NIfTI to view', 'MultiSelect', 'on');
        if isnumeric(fname), return; end
        fname = strcat([pName '/'], fname);
        if strcmp(get(h, 'Label'), 'Open in new window'), nii_viewer(fname);
        else, nii_viewer(fname, fh);
        end
        return;
    case 'add' % add overlay
        vars = evalin('base', 'who');
        is_nii = @(v)evalin('base', ...
            sprintf('isstruct(%s) && all(isfield(%s,{''hdr'',''img''}))', v, v));
        for i = numel(vars):-1:1, if ~is_nii(vars{i}), vars(i) = []; end; end
        if ~isempty(vars)
            a = listdlg('SelectionMode', 'single', 'ListString', vars, ...
                'ListSize', [300 100], 'CancelString', 'File dialog', ...
            	'Name', 'Select a NIfTI in the list or click File dialog');
            if ~isempty(a), fname = evalin('base', vars{a}); end
        end
        
        pName = hs.pref.UserData.addPath;
        label = get(h, 'Label');
        if strcmp(label, 'Add aligned overlay')
            if ~exist('fname', 'var')
                [fname, pName] = uigetfile([pName '/*.nii; *.hdr;*.nii.gz;' ...
                    '*.hdr.gz'], 'Select overlay NIfTI');
                if ~ischar(fname), return; end
                fname = fullfile(pName, fname);
            end
            [mtx, pName] = uigetfile([pName '/*.mat;*_warp.nii;*_warp.nii.gz'], ...
                'Select FSL mat file or warp file transforming the nii to background');
            if ~ischar(mtx), return; end
            mtx = fullfile(pName, mtx);
            addOverlay(fname, fh, mtx);
        else
            if ~exist('fname', 'var')
                [fname, pName] = uigetfile([pName '/*.nii; *.hdr;*.nii.gz;' ...
                    '*.hdr.gz'], 'Select overlay NIfTI', 'MultiSelect', 'on');
                if ~ischar(fname) && ~iscell(fname), return; end
                fname = get_nii(strcat([pName filesep], fname));
            end
            addOverlay(fname, fh);
        end
        setpref('nii_viewer_para', 'addPath', pName);
    case 'closeAll' % close all overlays
        for j = hs.files.getModel.size:-1:1
            p = get_para(hs, j);
            if p.hsI(1) == hs.hsI(1), continue; end
            delete(p.hsI); % remove image
            hs.files.getModel.remove(j-1);
        end
        hs.files.setSelectedIndex(0);
        set_xyz(hs);
    case 'close' % close selected overlay
        jf = hs.files.getSelectedIndex+1;
        p = get_para(hs, jf);
        if p.hsI(1) == hs.hsI(1), return; end % no touch to background
        delete(p.hsI); % 3 view
        hs.files.getModel.remove(jf-1);
        hs.files.setSelectedIndex(max(0, jf-2));
        set_xyz(hs);
    case {'hdr' 'ext' 'essential'} % show hdr ext or essential
        jf = hs.files.getSelectedIndex+1;
        p = get_para(hs, jf);
        if strcmp(cmd, 'hdr')
            hdr = p.hdr0;
        elseif strcmp(cmd, 'ext')
            if ~isfield(p.nii, 'ext')
                errordlg('No extension for the selected NIfTI'); 
                return;
            end
            hdr = {};
            for i = 1:numel(p.nii.ext)
                if ~isfield(p.nii.ext(i), 'edata_decoded'), continue; end
                hdr{end+1} = p.nii.ext(i).edata_decoded; %#ok
            end
            if isempty(hdr)
                errordlg('No known extension for the selected NIfTI'); 
                return;
            elseif numel(hdr) == 1, hdr = hdr{1};
            end
        elseif strcmp(cmd, 'essential')
            hdr = nii_essential(p);
        end
        nam = hs.files.getModel.get(jf-1);
        if ~isstrprop(nam(1), 'alpha'), nam = ['x' nam]; end % like genvarname
        nam(~isstrprop(nam, 'alphanum')) = '_'; % make it valid for var name
        nam = [nam '_' cmd];
        nam = strrep(nam, '__', '_');
        n = numel(nam); nm = namelengthmax;
        if n>nm, nam(nm-4:n-4) = ''; end
        assignin('base', nam, hdr);
        evalin('base', ['openvar ' nam]);
    case 'cross' % show/hide crosshairs and RAS labels
        if strcmp(get(h, 'Checked'), 'on')
            set(h, 'Checked', 'off');
            set([hs.cross(:)' hs.ras hs.xyz], 'Visible', 'off');
        else
            set(h, 'Checked', 'on');
            set([hs.cross(:)' hs.ras hs.xyz], 'Visible', 'on');
        end
    case 'color' % crosshair color
        c = uisetcolor(get(hs.ras(1), 'Color'), 'Pick crosshair color');
        if numel(c) ~= 3, return; end
        set([hs.cross(:)' hs.ras hs.xyz], 'Color', c);
    case 'thickness' % crosshair thickness
        c = strtok(get(h, 'Label'));
        set(hs.cross(:)', 'LineWidth', str2double(c));
    case 'gap' % crosshair gap
        c = str2double(strtok(get(h, 'Label')));
        hs.gap = min(hs.pixdim) ./ hs.pixdim * c / 2;
        guidata(fh, hs);
        set_cross(hs, 1:3);
    case 'copy' % copy figure into clipboard
        fh1 = ancestor(h, 'figure');
        if strncmp(get(fh1, 'Name'), 'nii_viewer', 10)
            set(hs.panel, 'Visible', 'off');
            clnObj = onCleanup(@() set(hs.panel, 'Visible', 'on'));
        end
        print(fh1, '-dbitmap', '-noui', ['-r' hs.pref.UserData.dpi]);
%         print('-dmeta', '-painters');
    case 'save' % save figure as picture
        ext = get(h, 'Label');
        fmt = ext;
        if strcmp(ext, 'jpg'), fmt = 'jpeg';
        elseif strcmp(ext, 'tif'), fmt = 'tiff';
        elseif strcmp(ext, 'eps'), fmt = 'epsc';
        elseif strcmp(ext, 'emf'), fmt = 'meta';
        end
        [fname, pName] = uiputfile(['*.' ext], 'Input file name to save figure');
        if ~ischar(fname), return; end
        fname = fullfile(pName, fname);
        if any(strcmp(ext, {'eps' 'pdf' 'emf'})), render = '-painters';
        else, render = '-opengl';
        end
        fh1 = ancestor(h, 'figure');
        if strncmp(get(fh1, 'Name'), 'nii_viewer', 10)
            set(hs.panel, 'Visible', 'off');
            clnObj = onCleanup(@() set(hs.panel, 'Visible', 'on'));
        end
        print(fh1, fname, render, '-noui', ['-d' fmt], ['-r' hs.pref.UserData.dpi], '-cmyk');
    case 'colorbar' % colorbar on/off
        if strcmpi(get(hs.colorbar, 'Visible'), 'on')
            set(hs.colorbar, 'Visible', 'off'); 
            set(h, 'Checked', 'off');
        else
            set(hs.colorbar, 'Visible', 'on'); 
            set(h, 'Checked', 'on');
            set_colorbar(hs);
        end
    case 'about'
        getVersion = dicm2nii('', 'getVersion', 'func_handle');
        str = sprintf(['nii_viewer.m by Xiangrui Li\n\n' ...
            'Last updated on %s\n\n', ...
            'Feedback to: xiangrui.li@gmail.com\n'], getVersion());
        helpdlg(str, 'About nii_viewer')
    case 'stack'
        uicontrol(hs.focus); % move focus out of buttons
        jf = hs.files.getSelectedIndex+1;
        p = get_para(hs, jf);
        n = hs.files.getModel.size;
        switch get(h, 'Tag') % for both uimenu and pushbutton
            case 'up' % one level up
                if jf==1, return; end
                for j = 1:3, uistack(p.hsI(j)); end
                ind = [1:jf-2 jf jf-1 jf+1:n]; jf = jf-1;
            case 'down' % one level down
                if jf==n, return; end
                for j = 1:3, uistack(p.hsI(j), 'down'); end
                ind = [1:jf-1 jf+1 jf jf+2:n]; jf = jf+1;
            case 'top'
                if jf==1, return; end
                for j = 1:3, uistack(p.hsI(j), 'up', jf-1); end
                ind = [jf 1:jf-1 jf+1:n]; jf = 1;
            case 'bottom'
                if jf==n, return; end
                for j = 1:3, uistack(p.hsI(j), 'down', n-jf); end
                ind = [1:jf-1 jf+1:n jf]; jf = n;
            otherwise
                error('Unknown stack level: %s', get(h, 'Tag'));
        end
        
        str = cell(hs.files.getModel.toArray);
        str = str(ind);
        for j = 1:n, hs.files.getModel.set(j-1, str{j}); end

        chk = false(1,n);
        chk(hs.files.getCheckBoxListSelectedIndices+1) = true;
        chk = find(chk(ind)) - 1;
        if ~isempty(chk), hs.files.setCheckBoxListSelectedIndices(chk); end
        hs.files.setSelectedIndex(jf-1);        
        set_xyz(hs);
    case 'zoom'
        m = str2double(get(h, 'Label'));
        a = min(hs.dim) / m;
        if a<1, m = min(hs.dim); end
        set_zoom(m, hs);
    case 'background'
        if strcmp(get(h, 'Checked'), 'on')
            set(h, 'Checked', 'off');
            hs.frame.BackgroundColor = [0 0 0];
            set(hs.colorbar, 'EdgeColor', [1 1 1]);
        else
            set(h, 'Checked', 'on');
            hs.frame.BackgroundColor = [1 1 1];
            set(hs.colorbar, 'EdgeColor', [0 0 0]);
        end
        set_cdata(hs);
    case 'flipLR'
        hs.pref.UserData.rightOnLeft = strcmp(get(h, 'Checked'), 'on');
        if hs.pref.UserData.rightOnLeft
            set(h, 'Checked', 'off');
            set(hs.ax([2 3]), 'XDir', 'normal');
            set(hs.ras([3 5]), 'String', 'L');
        else
            set(h, 'Checked', 'on');
            set(hs.ax([2 3]), 'XDir', 'reverse');
            set(hs.ras([3 5]), 'String', 'R');
        end
    case 'layout'
        layout = str2double(get(h, 'Tag'));
        parent = get(h, 'Parent');
        if get(parent, 'UserData') == layout, return; end
        set(parent, 'UserData', layout);
        htP = hs.panel.Position(4);
        [siz, axPos, figPos] = plot_pos(hs.dim.*hs.pixdim, layout);
        hs.fig.Position = [figPos siz+[2 htP+2]];
        hs.frame.Position(3:4) = siz;
        hs.panel.Position(2:3) = [hs.fig.Position(4)-htP siz(1)+2];
        for i = 1:4, set(hs.ax(i), 'Position', axPos(i,:)); end
    case 'keyHelp'
        str = sprintf([ ...
           'Key press available when focus is not in a number dialer:\n\n' ...
           'Left or Right arrow key: Move crosshair left or right.\n\n' ...
           'Up or Down arrow key: Move crosshair superior or inferior.\n\n' ...
           '[ or ] key: Move crosshair posterior or anterior.\n\n' ...
           '< or > key: Decrease or increase volume number.\n\n' ...
           'Ctrl + or - key: Zoom in or out by 10%% around crosshair.\n\n' ...
           'A: Toggle on/off crosshair.\n\n' ...
           'C: Crosshair to view center.\n\n' ...
           'Space: Toggle on/off selected image.\n\n' ...
           'F1: Show help text.\n']);
        helpdlg(str, 'Key Shortcut');
    case 'center' % image center
        p = get_para(hs);
        dim = p.nii.hdr.dim(2:4);
        c = round(hs.bg.Ri * (p.R * [dim/2-1 1]')) + 1;
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'viewCenter'
        c(1) = mean(get(hs.ax(2), 'XLim'));
        c(2) = mean(get(hs.ax(1), 'XLim'));
        c(3) = mean(get(hs.ax(1), 'YLim'));
        c = round(c-0.5);
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'toXYZ'
        c0 = cell2mat(get(hs.ijk, 'Value'));
        c0 = hs.bg.R * [c0-1; 1];
        c0 = sprintf('%g %g %g', round(c0(1:3)));
        str = 'X Y Z coordinates in mm';
        while 1
            a = inputdlg(str, 'Crosshair to xyz', 1, {c0});
            if isempty(a), return; end
            c = sscanf(a{1}, '%g %g %g');
            if numel(c) == 3, break; end
        end
        c = round(hs.bg.Ri * [c(:); 1]) + 1;
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'toValue'
        def = getappdata(h, 'Value');
        if isempty(def), def = 1; end
        def = num2str(def);
        str = 'Input the voxel value';
        while 1
            a = inputdlg(str, 'Crosshair to a value', 1, {def});
            if isempty(a), return; end
            val = sscanf(a{1}, '%g');
            if ~isnan(val), break; end
        end
        setappdata(h, 'Value', val);
        jf = hs.files.getSelectedIndex+1;
        p = get_para(hs, jf);
        img = p.nii.img(:,:,:, hs.volume.getValue);
        c = find(img(:)==val, 1);
        if isempty(c)
            nam = strtok(hs.files.getModel.get(jf-1), '(');
            errordlg(sprintf('No value of %g found in %s', val, nam));
            return;
        end
        dim = size(img); dim(numel(dim)+1:3) = 1;
        [c(1), c(2), c(3)] = ind2sub(dim, c); % ijk+1
        c = round(hs.bg.Ri * (p.R * [c(:)-1; 1])) + 1;
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'cog' % crosshair to img COG
        p = get_para(hs);
        img = p.nii.img(:,:,:, hs.volume.getValue);
        c = img_cog(img);
        if any(isnan(c)), errordlg('No valid COG found'); return; end
        c = round(hs.bg.Ri * (p.R * [c-1; 1])) + 1;
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'maximum' % crosshair to img max
        p = get_para(hs);
        img = p.nii.img(:,:,:,hs.volume.getValue);
        if sum(img(:)~=0) < 1
            errordlg('All value are the same. No maximum!');
            return;
        end
        img = smooth23(img, 'gaussian', 5);
        img(isnan(img)) = 0;
        img = abs(img);
        [~, I] = max(img(:));
        dim = size(img); dim(end+1:3) = 1;
        c = zeros(3, 1);
        [c(1), c(2), c(3)] = ind2sub(dim, I);
        c = round(hs.bg.Ri * (p.R * [c-1; 1])) + 1;
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'custom' % add custom lut
        p = get_para(hs);
        pName = fileparts(p.nii.hdr.file_name);
        [fname, pName] = uigetfile([pName '/*.lut'], 'Select LUT file for current overlay');
        if ~ischar(fname), return; end
        fid = fopen(fullfile(pName, fname));
        p.map = fread(fid, '*uint8');
        fclose(fid);
        if mod(numel(p.map),3)>0 || sum(p.map<8)<3 % guess text file
            try, p.map = str2num(char(p.map'));
            catch, errordlg('Unrecognized LUT file'); return;
            end
            if max(p.map(:)>1), p.map = single(p.map) / 255; end
        else
            p.map = reshape(p.map, [], 3);
            p.map = single(p.map) / 255;
        end
        if isequal(p.nii.img, round(p.nii.img))
            try, p.map = p.map(1:max(p.nii.img(:))+1, :); end
        end
        p.lut = numel(hs.lutStr);
        p.hsI(1).UserData = p;
        set(hs.lut, 'Value', p.lut, 'Enable', 'off');
        set_cdata(hs);
        set_colorbar(hs);
    case 'tc' % time course or std
        jf = hs.files.getSelectedIndex+1;
        p = get_para(hs, jf);
        nam = strtok(hs.files.getModel.get(jf-1), '(');
        
        labl = strrep(get(h, 'Label'), ' ...', '');
        r = num2str(getappdata(h, 'radius'));
        r = inputdlg('Radius around crosshair (mm):', labl, 1, {r});
        if isempty(r), return; end
        r = str2double(r{1});
        setappdata(h, 'radius', r);
        for j = 3:-1:1, c(j) = get(hs.ijk(j), 'Value'); end % ijk for background
        c = hs.bg.R * [c-1 1]'; % in mm now
        c = c(1:3);
        
        b = xyzr2roi(c, r, p.nii.hdr); % overlay space        
        img = p.nii.img;
        dim = size(img);
        img = reshape(img, [], prod(dim(4:end)))';
        img = img(:, b(:));
        fh1 = figure;
        if strcmp(labl, 'Time course')
            img = mean(single(img), 2);
        else
            img = std(single(img), [], 2);
        end
        plot(img);
        xlabel('Volume number');
        c = sprintf('(%g,%g,%g)', round(c));
        set(fh1, 'Name', [nam ' ' lower(labl) ' around voxel ' c]);
    case 'hist' % plot histgram
        jf =hs.files.getSelectedIndex+1;
        if jf<1, return; end
        p = get_para(hs, jf);
        img = p.nii.img(:,:,:, hs.volume.getValue);
        img = sort(img(:));
        img(isnan(img)) = [];
        img(img<hs.lb.getValue) = [];
        img(img>hs.ub.getValue) = [];
        nv = numel(img);
        img0 = unique(img);
        nu = numel(img0);
        n = max([nv/2000 nu/20 10]);
        n = min(round(n), nu);
        if n == nu, edges = img0;
        else, edges = linspace(0,1,n)*double(img(end)-img(1)) + double(img(1));
        end
        nam = strtok(hs.files.getModel.get(jf-1), '(');
        fh1 = figure(mod(fh.Number,10)+jf);
        set(fh1, 'NumberTitle', 'off', 'Name', nam);
        [y, x] = hist(img, edges); %#ok
        bar(x, y/sum(y)/(x(2)-x(1)), 'hist'); % probability density
        xlabel('Voxel values'); ylabel('Probability density');
        title('Histogram between min and max values');
    case 'width' % adjust hs.scroll width
        hs.files.updateUI;
        width = hs.panel.Position(3);
        x = hs.files.getPreferredScrollableViewportSize.getWidth;
        x = max(60, min(x+20, width-408)); % 408 width of the little panel
        hs.scroll.Position(3) = x;
        hs.params.Position([1 3]) = [x+2 width-x-2];
        hs.value.Position(3) = max(1, width-x-hs.value.Position(1));
    case 'saveVolume' % save 1 or more volumes as a nifti
        p = get_para(hs);
        nam = p.nii.hdr.file_name;
        t = p.volume;
        while 1
            a = inputdlg('Volume indice to save (2:4 for example)', ...
                'Save Volume', 1, {num2str(t)});
            if isempty(a), return; end
            t = str2num(a{1});
            if ~isempty(t), break; end
        end
        pName = fileparts(nam);
        [fname, pName] = uiputfile([pName '/*.nii;*.nii.gz'], ...
            'Input name to save volume as');
        if ~ischar(fname), return; end
        fname = fullfile(pName, fname);
        
        nii = nii_tool('load', nam); % re-load to be safe
        nii.img =  nii.img(:,:,:,t);
        nii_tool('save', nii, fname);
    case 'ROI' % save sphere
        c0 = cell2mat(get(hs.ijk, 'Value'));
        c0 = hs.bg.R * [c0-1; 1];
        c0 = sprintf('%g %g %g', round(c0(1:3)));
        str = {'X Y Z coordinates in mm' 'Radius in mm'};
        while 1
            a = inputdlg(str, 'Sphere ROI', 1, {c0 '6'});
            if isempty(a), return; end
            c = sscanf(a{1}, '%g %g %g');
            r = sscanf(a{2}, '%g');
            if numel(c) == 3, break; end
        end
        
        p = get_para(hs);
        pName = fileparts(p.nii.hdr.file_name);
        [fname, pName] = uiputfile([pName '/*.nii;*.nii.gz'], ...
            'Input file name to save ROI into');
        if ~ischar(fname), return; end
        fname = fullfile(pName, fname);
        
        b = xyzr2roi(c, r, p.nii.hdr);        
        p.nii.img = single(b); % single better supported by FSL
        nii_tool('save', p.nii, fname);
    case 'cropNeck'
        k0 = get(hs.ijk(3), 'Value') - 1;
        p = get_para(hs);
        nam = p.nii.hdr.file_name;
        pName = fileparts(nam);
        [fname, pName] = uiputfile([pName '/*.nii;*.nii.gz'], ...
            'Input file name to save cropped image');
        if ~ischar(fname), return; end
        fname = fullfile(pName, fname);
                
        R = nii_xform_mat(p.hdr0, hs.form_code); % original R
        k = hs.bg.Ri * R * grid3(p.hdr0.dim(2:4)); % background ijk
        
        nii = nii_tool('load', nam);
        d = size(nii.img);
        nii.img = reshape(nii.img, prod(d(1:3)), []);
        nii.img(k(3,:)<k0, :) = -nii.hdr.scl_inter / nii.hdr.scl_slope;
        nii.img = reshape(nii.img, d);
        nii_tool('save', nii, fname);
    case 'closeFig'
        try close(fh.UserData); end % cii_view
        delete(fh); return;
    case 'file'
        if ~isempty(evt) && evt.getValueIsAdjusting, return; end
        p = get_para(hs);
        
        nam = {'lb' 'ub' 'alpha' 'volume' 'lut' 'smooth' 'interp'};
        cb = cell(4,1);
        for j = 1:4 % avoid firing spinner callback
            cb{j} = hs.(nam{j}).StateChangedCallback;
            hs.(nam{j}).StateChangedCallback = '';
        end
        
        for j = 1:numel(nam)
            set(hs.(nam{j}), 'Value', p.(nam{j}));
        end
        set(hs.lb.Model, 'StepSize', p.lb_step);
        set(hs.ub.Model, 'StepSize', p.ub_step);
        nVol = size(p.nii.img, 4);
        str = sprintf('Volume number, 1:%g', nVol);
        set(hs.volume, 'Enable', nVol>1, 'ToolTipText', str);
        set(hs.volume.Model, 'Maximum', nVol);
        
        for j = 1:4 % restore spinner callback
            hs.(nam{j}).StateChangedCallback = cb{j};
        end
        set_colorbar(hs);
        
        off_on = {'off' 'on'};
        set(hs.interp, 'Enable', off_on{isfield(p, 'R0')+1});
        set(hs.overlay(1:4), 'Enable', off_on{(hs.files.getModel.size>1)+1}); % stack & Close overlays
        set(hs.overlay(5), 'Enable', off_on{(p.hsI(1) ~= hs.hsI(1))+1}); % Close overlay
        set(hs.lut, 'Enable', off_on{2-(p.lut==numel(hs.lutStr))});
    case 'drop'
        try
            nii = get_nii(evt.Data);
            if evt.ControlDown, addOverlay(nii, fh); % overlay
            else, nii_viewer(nii, fh); return; % background
            end
        catch me
            errordlg(me.message);
        end
    otherwise
        error('Unknown Callback: %s', cmd);
end
try, cii_view_cb(fh.UserData, [], cmd); end

%% zoom in/out with a factor
function set_zoom(m, hs)
c = hs.dim(:) / 2;
if m <= 1, I = c; % full view regardless of crosshair location
else, I = cell2mat(get(hs.ijk, 'Value'));
end
lim = round([I I] + c/m*[-1 1]) + 0.5;
axis(hs.ax(1), [lim(2,:) lim(3,:)]);
axis(hs.ax(2), [lim(1,:) lim(3,:)]);
axis(hs.ax(3), [lim(1,:) lim(2,:)]);

%% WindowKeyPressFcn for figure
function KeyPressFcn(fh, evt)
if any(strcmp(evt.Key, evt.Modifier)), return; end % only modifier
hs = guidata(fh);
if ~isempty(intersect({'control' 'command'}, evt.Modifier))
    switch evt.Key
        case {'add' 'equal'}
            [dim, i] = min(hs.dim);
            if     i==1, d = get(hs.ax(2), 'XLim');
            elseif i==2, d = get(hs.ax(1), 'XLim');
            else,        d = get(hs.ax(1), 'YLim');
            end
            d = abs(diff(d'));
            if d<=3, return; end % ignore
            m = dim / d * 1.1;
            if round(dim/2/m)==d/2, m = dim / (d-1); end
            set_zoom(m, hs);
        case {'subtract' 'hyphen'}
            d = abs(diff(get(hs.ax(2), 'XLim')));
            m = hs.dim(1) / d;
            if m<=1, return; end
            m = m / 1.1;
            if round(hs.dim(1)/2/m)==d/2, m = hs.dim(1) / (d+1); end
            if m<1.01, m = 1; end
            set_zoom(m, hs);
    end
    return;
end

switch evt.Key
    case 'leftarrow'
        val = max(get(hs.ijk(1), 'Value')-1, 1);
        hs.ijk(1).setValue(val);
    case 'rightarrow'
        val = min(get(hs.ijk(1), 'Value')+1, hs.dim(1));
        hs.ijk(1).setValue(val);
    case 'uparrow'
        val = min(get(hs.ijk(3),'Value')+1, hs.dim(3));
        hs.ijk(3).setValue(val);
    case 'downarrow'
        val = max(get(hs.ijk(3),'Value')-1, 1);
        hs.ijk(3).setValue(val);
    case 'rightbracket' % ]
        val = min(get(hs.ijk(2),'Value')+1, hs.dim(2));
        hs.ijk(2).setValue(val);
    case 'leftbracket' % [
        val = max(get(hs.ijk(2),'Value')-1, 1);
        hs.ijk(2).setValue(val);
    case 'period' % . or >
        val = min(get(hs.volume,'Value')+1, get(hs.volume.Model,'Maximum'));
        hs.volume.setValue(val);
    case 'comma' % , or <
        val = max(get(hs.volume,'Value')-1, 1);
        hs.volume.setValue(val);
    case 'c'
        nii_viewer_cb([], [], 'viewCenter', hs.fig);
    case {'x' 'space'}
        i = hs.files.getSelectedIndex;
        checked = hs.files.getCheckBoxListSelectedIndices;
        if any(i == checked)
            hs.files.removeCheckBoxListSelectedIndex(i);
        else
            hs.files.addCheckBoxListSelectedIndex(i);
        end
    case 'a'
        h = findobj(hs.fig, 'Type', 'uimenu', 'Label', 'Show crosshair');
        nii_viewer_cb(h, [], 'cross', hs.fig);
    case 'f1'
        doc nii_viewer;
    case 'tab' % prevent tab from cycling uicontrol
        mousexy = get(0, 'PointerLocation'); % for later restore
        posF = getpixelposition(fh);
        posA = getpixelposition(hs.ax(4), true); % relative to figure
        c = posF(1:2) + posA(1:2) + posA(3:4)/2; % ax(4) center xy
        res = screen_pixels;
        rob = java.awt.Robot();
        rob.mouseMove(c(1), res(2)-c(2));
        rob.mousePress(16); rob.mouseRelease(16); % BUTTON1
        set(0, 'PointerLocation', mousexy); % restore mouse location
end

%% update CData/AlphaData for 1 or 3 of the sag/cor/tra views
function set_cdata(hs, iaxis)
if nargin<2, iaxis = 1:3; end
interStr = get(hs.interp, 'String');

for i = 1:hs.files.getModel.size
    p = get_para(hs, i);
    if ~p.show, continue; end % save time, but need to update when enabled
    lut = p.lut;
    if lut == 11 % "lines" special case: do it separately
        vector_lines(hs, i, iaxis); continue; 
    elseif ~strcmpi(p.hsI(1).Type, 'image') % was "lines"
        delete(p.hsI); % delete quiver
        p.hsI = copyimg(hs);
        p.hsI(1).UserData = p; % update whole UserData
        if i>1, for j=1:3; uistack(p.hsI(j), 'down', i-1); end; end
    end
    t = round(p.volume);
    img = p.nii.img;
    isRGB = size(img, 8)>2;
    if isRGB % avoid indexing for single vol img: could speed up a lot
        img = permute(img(:,:,:,t,:,:,:,:), [1:3 8 4:7]);
    elseif size(img,4)>1 && lut~=29
        img = img(:,:,:,t);
    end    
    if ~isfloat(img)
        img = single(img);
        if isfield(p, 'scl_slope')
            img = img * p.scl_slope + p.scl_inter;
        end
    end
    
    if isfield(p, 'mask')
        img = bsxfun(@times, img, p.mask);
    end
    if isfield(p, 'modulation')
        img = bsxfun(@times, img, p.modulation);
    end

    if any(lut == 26:28) % interp/smooth both mag and phase
        img(:,:,:,2) = p.phase(:,:,:,t);
    end
    
    dim4 = size(img, 4);
    for ix = iaxis
        ind = round(hs.ijk(ix).Value);
        if ind<1 || ind>hs.dim(ix), continue; end
        ii = {':' ':' ':'};
        io = ii;
        d = hs.dim;
        d(ix) = 1; % 1 slice at dim ix
        im = zeros([d dim4], 'single');
        
        if isfield(p, 'R0') % interp, maybe smooth
            I = grid3(d);
            I(ix,:) = ind-1;
            
            if isfield(p, 'warp')
                iw = {':' ':' ':' ':'}; iw{ix} = ind;
                warp = p.warp(iw{:});
                warp = reshape(warp, [], 3)'; warp(4,:) = 0;
                I = p.Ri * (p.R0 * I + warp) + 1;
            else
                I = p.Ri * p.R0 * I + 1; % ijk+1 for overlay img
            end
            
            for j = 1:dim4
                if p.smooth
                    ns = 3; % number of voxels (odd) used for smooth
                    d3 = d; d3(ix) = ns; % e.g. 3 slices
                    b = zeros(d3, 'single');
                    I0 = I(1:3,:);
                    for k = 1:ns % interp for each slice
                        I0(ix,:) = I(ix,:) - (ns+1)/2 + k;
                        a = interp3a(img(:,:,:,j), I0, interStr{p.interp});
                        ii{ix} = k; b(ii{:}) = reshape(a, d);
                    end
                    b = smooth23(b, 'gaussian', ns);
                    io{ix} = (ns+1)/2;
                    im(:,:,:,j) = b(io{:}); % middle one
                else
                    a = interp3a(img(:,:,:,j), I, interStr{p.interp});
                    im(:,:,:,j) = reshape(a, d);
                end
            end
        elseif p.smooth % smooth only
            ns = 3; % odd number of slices to smooth
            ind1 = ind - (ns+1)/2 + (1:ns); % like ind+(-1:1)
            if any(ind1<1 | ind1>hs.dim(ix)), ind1 = ind; end % 2D
            ii{ix} = ind1;
            io{ix} = mean(1:numel(ind1)); % middle slice
            for j = 1:dim4
                a = smooth23(img(ii{:},j), 'gaussian', ns);
                im(:,:,:,j) = a(io{:});
            end
        else % no interp or smooth
            io{ix} = ind;
            im(:) = img(io{:}, :);
        end
        
        if     ix == 1, im = permute(im, [3 2 4 1]);
        elseif ix == 2, im = permute(im, [3 1 4 2]);
        elseif ix == 3, im = permute(im, [2 1 4 3]);
        end
        
        if ~isRGB % not NIfTI RGB
            [im, alfa] = lut2img(im, p, hs.lutStr{p.lut});
        elseif dim4 == 3 % NIfTI RGB
            if max(im(:))>2, im = im / 255; end % guess uint8
            im(im>1) = 1; im(im<0) = 0;
            alfa = sum(im,3) / dim4; % avoid mean
        elseif dim4 == 4 % NIfTI RGBA
            if max(im(:))>2, im = im / 255; end % guess uint8
            im(im>1) = 1; im(im<0) = 0;
            alfa = im(:,:,4);
            im = im(:,:,1:3);
        else
            error('Unknown data type: %s', p.nii.hdr.file_name);
        end
        
        if p.hsI(1) == hs.hsI(1) && isequal(hs.frame.BackgroundColor, [1 1 1])
            alfa = img2mask(alfa);
        elseif dim4 ~= 4
            alfa = alfa > 0;
        end
        alfa = p.alpha * alfa;
        set(p.hsI(ix), 'CData', im, 'AlphaData', alfa);
    end
end

%% Add an overlay
function addOverlay(fname, fh, mtx)
hs = guidata(fh);
frm = hs.form_code;
aligned = nargin>2;
R_back = hs.bg.R;
R0 = nii_xform_mat(hs.bg.hdr, frm(1)); % original background R
[~, perm, flp] = reorient(R0, hs.bg.hdr.dim(2:4), 0);
if aligned % aligned mtx: do it in special way
    [p, ~, rg, dim] = read_nii(fname, frm, 0); % no re-orient
    try
        if any(regexpi(mtx, '\.mat$'))
            R = load(mtx, '-ascii');
            if ~isequal(size(R), [4 4])
                error('Invalid transformation matrix file: %s', mtx);
            end
        else % see nii_xform
            R = eye(4);
            warp = nii_tool('img', mtx); % FSL warp nifti
            if ~isequal(size(warp), [hs.bg.hdr.dim(2:4) 3])
                error('warp file and template file img size don''t match.');
            end
            if det(R0(1:3,1:3))<0, warp(:,:,:,1) = -warp(:,:,:,1); end
            if ~isequal(perm, 1:3)
                warp = permute(warp, [perm 4]);
            end
            for j = 1:3
                if flp(j), warp = flip(warp, j); end
            end
            p.warp = warp;
            p.R0 = R_back; % always interp
        end
    catch me
        errordlg(me.message);
        return;
    end

    % see nii_xform for more comment on following method
    R = R0 / diag([hs.bg.hdr.pixdim(2:4) 1]) * R * diag([p.pixdim 1]);
    [~, i1] = max(abs(p.R(1:3,1:3)));
    [~, i0] = max(abs(R(1:3,1:3)));
    flp = sign(R(i0+[0 4 8])) ~= sign(p.R(i1+[0 4 8]));
    if any(flp)
        rotM = diag([1-flp*2 1]);
        rotM(1:3,4) = (dim-1).* flp;
        R = R / rotM;
    end
            
    [p.R, perm, p.flip] = reorient(R, dim); % in case we apply mask to it
    if ~isequal(perm, 1:3)
        dim = dim(perm);
        p.pixdim = p.pixdim(perm);
        p.nii.img = permute(p.nii.img, [perm 4:8]);
    end
    for j = 1:3
        if p.flip(j), p.nii.img = flip(p.nii.img, j); end
    end
    p.alignMtx = mtx; % info only for NIfTI essentials
else % regular overlay
    [p, frm, rg, dim] = read_nii(fname, frm);

    % Silently use another background R_back matching overlay: very rare
    if frm>0 && frm ~= hs.form_code(1) && any(frm == hs.form_code)
        R = nii_xform_mat(hs.bg.hdr, frm); % img alreay re-oriented
        R_back = reorient(R, hs.bg.hdr.dim(2:4));
    elseif frm==0 && isequal(p.hdr0.dim(2:4), hs.bg.hdr.dim(2:4))
        p.R = hs.bg.R; % best guess: use background xform
        p.perm = perm;
        p.nii.img = permute(p.nii.img, [p.perm 4:8]);
        for i = 1:3
            if p.flip(i) ~= flp(i)
                p.nii.img = flip(p.nii.img, i);
            end
        end
        p.flip = flp;
        warndlg(['There is no valid coordinate system for the overlay. ' ...
         'The viewer supposes the same coordinate as the background.'], ...
         'Missing valid tranformation');
    elseif frm ~= 2 && ~any(frm == hs.form_code)
        warndlg(['There is no matching coordinate system between the overlay ' ...
         'image and the background image. The overlay is likely meaningless.'], ...
         'Transform Inconsistent');
    end
end

singleVol = 0;
nv = size(p.nii.img, 4);
if nv>1 && numel(p.nii.img)>1e7 % load all or a single volume
    if isfield(p.nii, 'NamedMap')
        nams = cell(1, numel(p.nii.NamedMap));
        for i = 1:numel(nams), nams{i} = p.nii.NamedMap{i}.MapName; end
        a = listdlg('PromptString', 'Load "All" or one of the map:', ...
            'SelectionMode', 'single', 'ListString', ['All' nams]);
        if a==1, a = 'All'; else, a = a - 1; end
    else
        str = ['Input ''all'' or a number from 1 to ' num2str(nv)];
        while 1
            a = inputdlg(str, 'Volumes to load', 1, {'all'});
            if isempty(a), return; end
            a = strtrim(a{1});
            if ~isstrprop(a, 'digit'), break; end
            a = str2num(a);
            if isequal(a,1:nv) || (numel(a)==1 && a>=1 && a<=nv && mod(a,1)==0)
                break;
            end
        end
    end
    if isnumeric(a) && numel(a)==1
    	singleVol = a;
        p.nii.img = p.nii.img(:,:,:,a);
        if isfield(p.nii, 'cii')
            p.nii.cii{1} = p.nii.cii{1}(:,a);
            p.nii.cii{2} = p.nii.cii{2}(:,a);
        end
        if isfield(p.nii, 'NamedMap')
            try,   p.nii.NamedMap = p.nii.NamedMap(a); %#ok<*NOCOM>
            catch, p.nii.NamedMap = p.nii.NamedMap(1);
            end
            try, p.map = p.nii.NamedMap{1}.map; end
        end
        rg = get_range(p.nii);
    end
end

ii = [1 6 11 13:15]; % diag and offset: avoid large ratio due to small value
if ~isequal(hs.dim, dim) || any(abs(R_back(ii)./p.R(ii)-1) > 0.01)
    p.R0 = R_back;
end
p.Ri = inv(p.R);

if ~isreal(p.nii.img)
    p.phase = angle(p.nii.img); % -pi to pi
    p.phase = mod(p.phase/(2*pi), 1); % 0~1
    p.nii.img = abs(p.nii.img); % real now
end

mdl = hs.files.getModel;
luts = zeros(1, mdl.size);
for i = 1:mdl.size % overlay added
    p0 = get_para(hs, i);
    luts(i) = p0.lut;
end

p.hsI = copyimg(hs); % duplicate image obj for overlay: will be at top
p.lb = rg(1); p.ub = rg(2);
p = dispPara(p, luts);
p.hsI(1).UserData = p;

[pName, niiName, ext] = fileparts(p.nii.hdr.file_name);
if strcmpi(ext, '.gz'), [~, niiName] = fileparts(niiName); end
if aligned, niiName = [niiName '(aligned)']; end
if singleVol, niiName = [niiName '(' num2str(singleVol) ')']; end

try
    checked = [0; hs.files.getCheckBoxListSelectedIndices+1];
    mdl.insertElementAt(niiName, 0);
    hs.files.setCheckBoxListSelectedIndices(checked);
    hs.files.setSelectedIndex(0); hs.files.updateUI;
catch me
    delete(p.hsI);
    errordlg(me.message);
    return;
end
hs.pref.UserData.addPath = pName;

set_cdata(hs);
set_xyz(hs);
if isfield(p.nii, 'cii'), cii_view(hs); end

%% Reorient 4x4 R
function [R, perm, flp] = reorient(R, dim, leftHand)
% [R, perm, flip] = reorient(R, dim, leftHand)
% Re-orient transformation matrix R (4x4), so it will be diagonal major and
% positive at diagonal, unless the optional third input is true, which requires
% left-handed matrix, where R(1,1) will be negative. 
% The second input is the img space dimension (1x3). 
% The perm output, like [1 2 3] or a permutation of it, indicates if input R was
% permuted for 3 axis. The third output, flp (1x3 logical), indicates an axis 
% (AFTER perm) is flipped if true.
a = abs(R(1:3,1:3));
[~, ixyz] = max(a);
if ixyz(2) == ixyz(1), a(ixyz(2),2) = 0; [~, ixyz(2)] = max(a(:,2)); end
if any(ixyz(3) == ixyz(1:2)), ixyz(3) = setdiff(1:3, ixyz(1:2)); end
[~, perm] = sort(ixyz);
R(:,1:3) = R(:,perm);
flp = diag(R(1:3, 1:3))' < 0;
if nargin>2 && leftHand, flp(1) = ~flp(1); end
rotM = diag([1-flp*2 1]);
rotM(1:3, 4) = (dim(perm)-1) .* flp; % 0 or dim-1
R = R / rotM; % xform matrix after flip

%% Load, re-orient nii, extract essential nii stuff
% nifti may be re-oriented, p.hdr0 stores original nii.hdr
function [p, frm, rg, dim] = read_nii(fname, ask_code, reOri)
if nargin<2, ask_code = []; end
if ischar(fname), p.nii = nii_tool('load', fname);
else, p.nii = fname; fname = p.nii.hdr.file_name;
end
p.hdr0 = p.nii.hdr; % original hdr
c = p.nii.hdr.intent_code;
if c>=3000 && c<=3099 && isfield(p.nii, 'ext') && any([p.nii.ext.ecode] == 32)
    p.nii = cii2nii(p.nii);
end

if nargin<3 || reOri
	[p.nii, p.perm, p.flip] = nii_reorient(p.nii, 0, ask_code);
else
    p.perm = 1:3;
    p.flip = false(1,3);
end

dim = p.nii.hdr.dim(2:8);
dim(dim<1 | mod(dim,1)~=0) = 1;
if p.nii.hdr.dim(1)>4 % 4+ dim, put all into dim4
    if sum(dim(4:7)>1)>1
        warndlg([fname ' has 5 or more dimension. Dimension above 4 are ' ...
            'all treated as volumes for visualization']);        
    end
    dim(4) = prod(dim(4:7)); dim(5:7) = 1;
    p.nii.img = reshape(p.nii.img, [dim size(p.nii.img, 8)]);
end

[p.R, frm] = nii_xform_mat(p.nii.hdr, ask_code);
dim = dim(1:3);
p.pixdim = p.nii.hdr.pixdim(2:4);

if size(p.nii.img,4)<4 && ~isfloat(p.nii.img)
    p.nii.img = single(p.nii.img); 
end
if p.nii.hdr.scl_slope==0, p.nii.hdr.scl_slope = 1; end
if p.nii.hdr.scl_slope~=1 || p.nii.hdr.scl_inter~=0
    if isfloat(p.nii.img)
        p.nii.img = p.nii.img * p.nii.hdr.scl_slope + p.nii.hdr.scl_inter;
    else
        p.scl_slope = p.nii.hdr.scl_slope;
        p.scl_inter = p.nii.hdr.scl_inter;
    end
end

% check if ROI labels available: the same file name with .txt extension
if c == 1002 % Label
    [pth, nam, ext] = fileparts(p.nii.hdr.file_name);
    nam1 = fullfile(pth, [nam '.txt']);
    if strcmpi(ext, '.gz') && ~exist(nam1, 'file')
        [~, nam] = fileparts(nam);
        nam1 = fullfile(pth, [nam '.txt']);
    end
    if exist(nam1, 'file') % each line format: 1 ROI_1
        fid = fopen(nam1);
        while 1
            ln = fgetl(fid);
            if ~ischar(ln), break; end
            [ind, a] = strtok(ln);
            ind = str2double(ind);
            try p.labels{ind} = strtrim(a); catch, end
        end
        fclose(fid);
    end
end
rg = get_range(p.nii, isfield(p, 'labels'));
try, p.map = p.nii.NamedMap{1}.map; end

%% Return xform mat and form_code: form_code may have two if not to ask_code
function [R, frm] = nii_xform_mat(hdr, ask_code)
% [R, form] = nii_xform_mat(hdr, asked_code);
% Return the transformation matrix from a NIfTI hdr. By default, this returns
% the sform if available. If the optional second input, required form code, is
% provided, this will try to return matrix for that form code. The second
% optional output is the form code of the actually returned matrix.
fs = [hdr.sform_code hdr.qform_code]; % sform preferred
if fs(1)==fs(2), fs = fs(1); end % sform if both are the same
f = fs(fs>=1 & fs<=4); % 1/2/3/4 only
if isempty(f) || ~strncmp(hdr.magic, 'n', 1) % treat it as Analyze
    frm = 0;
    try % try spm style Analyze
        [pth, nam, ext] = fileparts(hdr.file_name);
        if strcmpi(ext, '.gz'), [~, nam] = fileparts(nam); end
        R = load(fullfile(pth, [nam '.mat']));
        R = R.M;
    catch % make up R for Analyze: suppose xyz order with left storage 
        R = [diag(hdr.pixdim(2:4)) -(hdr.dim(2:4).*hdr.pixdim(2:4)/2)'; 0 0 0 1];
        R(1,:) = -R(1,:); % use left handed
    end
    return;
end

if numel(f)==1 || nargin<2 || isempty(ask_code) % only 1 avail or no ask_code
    frm = f;
else % numel(f) is 2, numel(ask_code) can be 1 or 2
    frm = f(f == ask_code(1));
    if isempty(frm) && numel(ask_code)>1, frm = f(f == ask_code(2)); end
    if isempty(frm) && any(f==2), frm = 2; end % use confusing code 2
    if isempty(frm), frm = f(1); end % no match to ask_code, use sform
end

if frm(1) == fs(1) % match sform_code or no match
    R = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
else % match qform_code
    R = quat2R(hdr);
end

%%
function R = quat2R(hdr)
% Return 4x4 qform transformation matrix from nii hdr.
b = hdr.quatern_b;
c = hdr.quatern_c;
d = hdr.quatern_d;
a = sqrt(1-b*b-c*c-d*d);
if ~isreal(a), a = 0; end % avoid complex due to precision
R = [1-2*(c*c+d*d)  2*(b*c-d*a)     2*(b*d+c*a);
     2*(b*c+d*a)    1-2*(b*b+d*d)   2*(c*d-b*a);
     2*(b*d-c*a )   2*(c*d+b*a)     1-2*(b*b+c*c)];
if hdr.pixdim(1)<0, R(:,3) = -R(:,3); end % qfac
R = R * diag(hdr.pixdim(2:4));
R = [R [hdr.qoffset_x hdr.qoffset_y hdr.qoffset_z]'; 0 0 0 1];

%% Create java SpinnerNumber
function h = java_spinner(pos, val, parent, callback, fmt, helpTxt)
% h = java_spinner(pos, val, parent, callback, fmt, helpTxt)
%  pos: [left bottom width height]
%  val: [curVal min max step]
%  parent: figure or panel
%  fmt: '#' for integer, or '#.#', '#.##'
mdl = javax.swing.SpinnerNumberModel(val(1), val(2), val(3), val(4));
% jSpinner = javax.swing.JSpinner(mdl);
jSpinner = com.mathworks.mwswing.MJSpinner(mdl);
h = javacomponent(jSpinner, pos, parent);
set(h, 'StateChangedCallback', callback, 'ToolTipText', helpTxt);
jEditor = javaObject('javax.swing.JSpinner$NumberEditor', h, fmt);
h.setEditor(jEditor);
h.setFont(java.awt.Font('Tahoma', 0, 11));

%% Estimate lower and upper bound of img display
function rg = get_range(nii, isLabel)
if size(nii.img, 8)>2 || any(nii.hdr.datatype == [128 511 2304]) % RGB / RGBA
    if max(nii.img(:))>2, rg = [0 255]; else, rg = [0 1]; end
    return;
elseif nii.hdr.cal_max~=0 && nii.hdr.cal_max>min(nii.img(:))
    rg = [nii.hdr.cal_min nii.hdr.cal_max];
    return;
end

img = nii.img(:,:,:,1);
img = img(:);
img(isnan(img) | isinf(img)) = [];
if ~isreal(img), img = abs(img); end
if ~isfloat(img)
    slope = nii.hdr.scl_slope; if slope==0, slope = 1; end
    img = single(img) * slope + nii.hdr.scl_inter;
end

mi = min(img); ma = max(img);
if nii.hdr.intent_code > 1000 || (nargin>1 && isLabel)
    rg = [mi ma]; return;
elseif nii.hdr.intent_code == 2 % correlation
    rg = [0.3 1]; return;
end

ind = abs(img)>50;
if sum(ind)<numel(img)/10, ind = abs(img)>std(img)/2; end
im = img(ind);
mu = mean(im);
sd = std(im);
rg = mu + [-2 2]*sd;
if rg(1)<=0, rg(1) = sd/5; end
if rg(1)<mi || isnan(rg(1)), rg(1) = mi; end
if rg(2)>ma || isnan(rg(2)), rg(2) = ma; end
if rg(1)==rg(2), rg(1) = mi; if rg(1)==rg(2), rg(1) = 0; end; end
% rg = round(rg, 2, 'significant'); % since 2014b
rg = str2num(sprintf('%.2g ', rg)); %#ok<*ST2NM>
if rg(1)==rg(2), rg(1) = mi; end
if abs(rg(1))>10, rg(1) = floor(rg(1)/2)*2; end % even number
if abs(rg(2))>10, rg(2) = ceil(rg(2)/2)*2; end % even number

%% Draw vector lines, called by set_cdata
function vector_lines(hs, i, iaxis)
p = get_para(hs, i);
d = single(size(p.nii.img));
pixdim = hs.bg.hdr.pixdim(2:4); % before reorient
if strcmpi(get(p.hsI(1), 'Type'), 'image') % just switched to "lines"
    delete(p.hsI);
    lut = hs.lut.UserData; % last lut
    if isempty(lut), lut = 2; end % default red
    clr = lut2map(p, hs.lutStr{lut}); clr = clr(end,:);
    cb = get(hs.hsI(1), 'ButtonDownFcn');
    for j = 1:3
        p.hsI(j) = quiver(hs.ax(j), 1, 1, 0, 0, 'Color', clr, ...
            'ShowArrowHead', 'off', 'AutoScale', 'off', 'ButtonDownFcn', cb);
    end
    crossFront(hs); % to be safe before next
    if i>1, for j = 1:3, uistack(p.hsI(j), 'down', i-1); end; end
    
    if isfield(p, 'R0') && ~isfield(p, 'ivec')
        I = p.R0 \ (p.R * grid3(d)) + 1;
        p.ivec = reshape(I(1:3,:)', d);

        R0 = normc(p.R0(1:3, 1:3));
        R  = normc(p.R(1:3, 1:3));
        [pd, j] = min(p.pixdim);
        p.Rvec = R0 / R * pd / pixdim(j);
    end
    p.hsI(1).UserData = p;
end

img = p.nii.img;
% This is needed since vec is in image ref, at least for fsl
img(:,:,:,p.flip) = -img(:,:,:,p.flip);
if isfield(p, 'mask') % ignore modulation
    img = bsxfun(@times, img, p.mask);
end
if any(abs(diff(pixdim))>1e-4) % non isovoxel background
    pd = pixdim / min(pixdim);
    for j = 1:3, img(:,:,:,j) = img(:,:,:,j) / pd(j); end
end

if isfield(p, 'Rvec')
    img = reshape(img, [], d(4));
    img = img * p.Rvec;
    img = reshape(img, d);
end

for ix = iaxis
    I = round(get(hs.ijk(ix), 'Value'));
    j = 1:3; j(ix) = [];
    if isfield(p, 'ivec')
        I = abs(p.ivec(:,:,:,ix) - I);
        [~, I] = min(I, [], ix);
        
        ii = {1:d(1) 1:d(2) 1:d(3)};
        ii{ix} = single(1);
        [ii{1}, ii{2}, ii{3}] = ndgrid(ii{:});
        ii{ix} = single(I);
        io = {':' ':' ':' ':'}; io{ix} = 1;
        im = img(io{:});
        for k = 1:2
            im(:,:,:,k) = interp3(img(:,:,:,j(k)), ii{[2 1 3]}, 'nearest');
        end
    
        ind = sub2ind(d(1:3), ii{:});
        X = p.ivec(:,:,:,j(1)); X = permute(X(ind), [j([2 1]) ix]);
        Y = p.ivec(:,:,:,j(2)); Y = permute(Y(ind), [j([2 1]) ix]);    
    else
        ii = {':' ':' ':'};
        ii{ix} = I;
        im = img(ii{:}, j);
        [Y, X] = ndgrid(1:d(j(2)), 1:d(j(1)));
    end
    
    im = permute(im, [j([2 1]) 4 ix]);
    im(im==0) = nan; % avoid dots in emf and eps
    X = X - im(:,:,1)/2;
    Y = Y - im(:,:,2)/2;
    set(p.hsI(ix), 'XData', X, 'YData', Y, 'UData', im(:,:,1), 'VData', im(:,:,2));
end

%% Bring cross and label to front
function crossFront(hs)
for i = 1:3
    txt = allchild(hs.ax(i));
    ind = strcmpi(get(txt, 'Type'), 'text');
    txt = txt(ind); % a number, two letters, plus junk text with matlab 2010b
    uistack([txt' hs.cross(i,:)], 'top');
end

%% Compute color map for LUT
function map = lut2map(p, lutStr)
persistent parula64;
if isfield(p, 'map')
    if isfield(p.nii, 'NamedMap')
        try, map = p.nii.NamedMap{p.volume}.map; end
    else, map = p.map;
    end
    return;
end

lut = p.lut;
map = linspace(0,1,64)'*[1 1 1]; % gray
if     lut == 1, return; % gray
elseif lut == 2, map(:,2:3) = 0; % red
elseif lut == 3, map(:,[1 3]) = 0; % green
elseif lut == 4, map(:,1:2) = 0; % blue
elseif lut == 5, map(:,2) = 0; % violet
elseif lut == 6, map(:,3) = 0; % yellow
elseif lut == 7, map(:,1) = 0; % cyan
elseif any(lut == [8 19 26]), map(:,3) = 0; map(:,1) = 1; % red_yellow
elseif lut == 9, map(:,1) = 0; map(:,3) = flip(map(:,3)); % blue_green
elseif lut == 10 % two-sided
    map = map(1:2:end,:); % half
    map_neg = map;
    map(:,3) = 0; map(:,1) = 1; % red_yellow
    map_neg(:,1) = 0; map_neg(:,3) = flip(map_neg(:,3)); % blue_green
    map = [flip(map_neg,1); map];
elseif lut == 11, map(:,2:3) = 0; % vector lines
elseif lut == 12 % parula not in old matlab, otherwise this can be omitted
    if isempty(parula64)
        fname = fullfile(fileparts(mfilename('fullpath')), 'example_data.mat'); 
        a = load(fname, 'parula'); parula64 = a.parula;
    end
    map = parula64;
elseif lut < 26 % matlab LUT
    map = feval(lutStr, 64);
elseif lut == 27 % phase3: red-yellow-green-yellow-red
    a = map(:,1);
    map(1:32,3) = 0; map(1:16,1) = 1; map(17:32,2) = 1;
    map(1:16,2) = a(1:4:64); map(17:32,1) = a(64:-4:1);
    map(33:64,:) = map(32:-1:1,:);
elseif lut == 28 % phase6: red-yellow-green/violet-blue-cyan
    a = map(:,1);
    map(1:32,3) = 0; map(1:16,1) = 1; map(17:32,2) = 1;
    map(1:16,2) = a(1:4:64); map(17:32,1) = a(64:-4:1);
    map(33:48,2) = 0; map(33:48,3) = 1; map(33:48,1) = a(64:-4:1);
    map(49:64,1) = 0; map(49:64,3) = 1; map(49:64,2) = a(1:4:64);
elseif lut == 29 % RGB
end

%% Preference dialog
function pref_dialog(h, ~)
pf = getpref('nii_viewer_para');
d = dialog('Name', 'Preferences', 'Visible', 'off');
pos = getpixelposition(d);
pos(3:4) = [396 332];
hs.fig = ancestor(h, 'figure');

uicontrol(d, 'Style', 'text', 'Position', [8 306 300 22], ...
    'String', 'Background (template) image folder:', 'HorizontalAlignment', 'left');
hs.openPath = uicontrol(d, 'Style', 'edit', 'String', pf.openPath, ...
    'Position', [8 288 350 22], 'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'TooltipString', 'nii_viewer will point to this folder when you "Open" image');
uicontrol(d, 'Position', [358 289 30 22], 'Tag', 'browse', ...
    'String', '...', 'Callback', @pref_dialog_cb);

hs.rightOnLeft = uicontrol(d, 'Style', 'popup', 'BackgroundColor', 'w', ...
    'Position', [8 252 380 22], 'Value', pf.rightOnLeft+1, ...
    'String', {'Neurological orientation (left on left side)' ...
               'Radiological orientation (right on left side)'}, ...
    'TooltipString', 'Display convention also applies to future use');

uicontrol(d, 'Style', 'text', 'Position', [8 210 40 22], ...
    'String', 'Layout', 'HorizontalAlignment', 'left', ...
    'TooltipString', 'Layout for three views');

% iconsFolder = fullfile(matlabroot,'/toolbox/matlab/icons/');
% iconUrl = strrep(['file:/' iconsFolder 'matlabicon.gif'],'\','/');
% str = ['<html><img src="' iconUrl '"/></html>'];
hs.layout = uicontrol(d, 'Style', 'popup', 'BackgroundColor', 'w', ...
    'Position', [50 214 338 22], 'Value', pf.layout, ...
    'String', {'one-row' 'two-row sag on right' 'two-row sag on left'}, ...
    'TooltipString', 'Layout for three views');

hs.mouseOver = uicontrol(d, 'Style', 'checkbox', ...
    'Position', [8 182 380 22], 'Value', pf.mouseOver, ...
    'String', 'Show coordinates and intensity when mouse moves over image', ...
    'TooltipString', 'Also apply to future use');

uipanel(d, 'Units', 'Pixels', 'Position', [4 110 390 56], 'BorderType', 'etchedin', ...
    'BorderWidth', 2, 'Title', 'For "Save NIfTI as" if interpolation is applicable');
str = {'nearest' 'linear' 'cubic' 'spline'};
val = find(strcmp(str, pf.interp));
uicontrol(d, 'Style', 'text', 'Position', [8 116 140 22], ...
    'String', 'Interpolation method:', 'HorizontalAlignment', 'right');
hs.interp = uicontrol(d, 'Style', 'popup', 'String', str, ...
    'Position', [150 120 68 22], 'Value', val, 'BackgroundColor', 'w');

uicontrol(d, 'Style', 'text', 'Position', [230 116 90 22], ...
    'String', 'Missing value:', 'HorizontalAlignment', 'right');
hs.extraV = uicontrol(d, 'Style', 'edit', 'String', num2str(pf.extraV), ...
    'Position', [324 120 60 22], 'BackgroundColor', 'w', ...
    'TooltipString', 'NaN or 0 is typical, but can be any number');

str = strtrim(cellstr(num2str([0 120 150 200 300 600 1200]')));
val = find(strcmp(str, pf.dpi));
uipanel(d, 'Units', 'Pixels', 'Position', [4 40 390 56], 'BorderType', 'etchedin', ...
    'BorderWidth', 2, 'Title', 'For "Save figure as" and "Copy figure"');
uicontrol(d, 'Style', 'text', 'Position', [8 46 90 22], ...
    'String', 'Resolution:', 'HorizontalAlignment', 'right');
hs.dpi = uicontrol(d, 'Style', 'popup', 'String', str, ...
    'Position', [110 50 50 22], 'Value', val, 'BackgroundColor', 'w', ...
    'TooltipString', 'in DPI (0 means screen resolution)');

uicontrol(d, 'Position', [300 10 70 24], 'Tag', 'OK', ...
    'String', 'OK', 'Callback', @pref_dialog_cb);
uicontrol(d, 'Position',[200 10 70 24], ...
    'String', 'Cancel', 'Callback', 'delete(gcf)');

set(d, 'Position', pos, 'Visible', 'on');
guidata(d, hs);

%% Preference dialog callback
function pref_dialog_cb(h, ~)
hs = guidata(h);
if strcmp(get(h, 'Tag'), 'OK') % done
    fh = hs.fig;
    pf = getpref('nii_viewer_para');
    
    pf.layout = get(hs.layout, 'Value'); % 1:3
    pf.rightOnLeft = get(hs.rightOnLeft, 'Value')==2;    
    pf.mouseOver = get(hs.mouseOver, 'Value');
    if pf.mouseOver % this is the only one we update current fig
        set(fh, 'WindowButtonMotionFcn', {@nii_viewer_cb 'mousemove' fh});
    else
        set(fh, 'WindowButtonMotionFcn', '');        
    end
    
    str = get(hs.interp, 'String');
    pf.interp = str{get(hs.interp, 'Value')};
    
    pf.extraV = str2double(get(hs.extraV, 'String'));
    pf.openPath = get(hs.openPath, 'String');

    str = get(hs.dpi, 'String');
    pf.dpi = str{get(hs.dpi, 'Value')};
    
    hs1 = guidata(fh);
    set(hs1.pref, 'UserData', pf);
        
    setpref('nii_viewer_para', fieldnames(pf), struct2cell(pf));
    delete(get(h, 'Parent'));
elseif strcmp(get(h, 'Tag'), 'browse') % set openPath
    pth = uigetdir(pwd, 'Select folder for background image');
    if ~ischar(pth), return; end
    set(hs.openPath, 'String', pth);
end

%% Simple version of interp3
function V = interp3a(V, I, method)
% V = interp3a(V, I, 'linear');
% This is similar to interp3 from Matlab, but takes care of the Matlab version
% issue, and the input is simplified for coordinate. The coordinate input are in
% this way: I(1,:), I(2,:) and I(3,:) are for x, y and z. 
persistent v;
if isempty(v)
    try 
        griddedInterpolant(ones(3,3,3), 'nearest', 'none');
        v = 2014;
    catch
        try
            griddedInterpolant(ones(3,3,3), 'nearest');
            v = 2013;
        catch
            v = 2011;
        end
    end
end

if strcmp(method, 'nearest') || any(size(V)<2), I = round(I); end
if size(V,1)<2, V(2,:,:) = nan; end
if size(V,2)<2, V(:,2,:) = nan; end
if size(V,3)<2, V(:,:,2) = nan; end
if v > 2011
    if  v > 2013
        F = griddedInterpolant(V, method, 'none');
    else
        F = griddedInterpolant(V, method);
    end
    V = F(I(1,:), I(2,:), I(3,:)); % interpolate
else % earlier matlab
    V = interp3(V, I(2,:), I(1,:), I(3,:), method, nan);
end

%% 2D/3D smooth wrapper: no input check for 2D
function im = smooth23(im, varargin)
% out = smooth23(in, varargin)
% This works the same as smooth3 from Matlab, but takes care of 2D input.
is2D = size(im,3) == 1;
if is2D, im = repmat(im, [1 1 2]); end
im = smooth3(im, varargin{:});
if is2D, im = im(:,:,1); end

%% Show xyz and value
function xyz = set_xyz(hs, I)
if nargin<2
    for i=3:-1:1, I(i) = get(hs.ijk(i), 'Value'); end
end

I = round(I);
xyz = round(hs.bg.R * [I-1 1]');
xyz = xyz(1:3);
str = sprintf('(%i,%i,%i): ', xyz);

for i = 1:hs.files.getModel.size % show top one first
    p = get_para(hs, i);
    if p.show == 0, continue; end
    t = round(p.volume);
    if isfield(p, 'R0') % need interpolation
        if isfield(p, 'warp')
            warp = p.warp(I(1), I(2), I(3), :);
            I0 = p.Ri * (p.R0 * [I-1 1]' + [warp(:); 0]);
        else
            I0 = p.Ri * p.R0 * [I-1 1]'; % overlay ijk
        end
        I0 = round(I0(1:3)+1);
    else, I0 = I;
    end
    try
        val = p.nii.img(I0(1), I0(2), I0(3), t, :);
        if isfield(p, 'scl_slope')
            val = single(val) * p.scl_slope + p.scl_inter;
        end
    catch
        val = nan; % out of range
    end
    
    if isfield(p, 'labels')
        try 
            labl = p.labels{val};
            str = sprintf('%s %s', str, labl);
            continue; % skip numeric val assignment
        end
    end
    if isfield(p.nii, 'NamedMap')
        try
            labl = p.nii.NamedMap{p.volume}.labels{val};
            str = sprintf('%s %s', str, labl);
            continue;
        end
    end
    
    fmtstr = '%.4g ';
    if numel(val)>1
        fmtstr = repmat(fmtstr, 1, numel(val));
        fmtstr = ['[' fmtstr]; fmtstr(end) = ']'; %#ok
    end
    str = sprintf(['%s ' fmtstr], str, val);
end
hs.value.String = str;

%% nii essentials
function s = nii_essential(hdr)
% info = nii_essential(hdr);
% Decode important NIfTI hdr into struct info, which is human readable.
if isfield(hdr, 'nii') % input by nii_viewer
    s.FileName = hdr.nii.hdr.file_name;
    if isfield(hdr, 'mask_info'), s.MaskedBy = hdr.mask_info; end
    if isfield(hdr, 'modulation_info'), s.ModulatdBy = hdr.modulation_info; end
    if isfield(hdr, 'alignMtx'), s.AlignMatrix = hdr.alignMtx; end
    hdr = hdr.nii.hdr;
else
    s.FileName = hdr.file_name;
end
switch hdr.intent_code
    case 2, s.intent = 'Correlation'; s.DoF = hdr.intent_p1;
    case 3, s.intent = 'T-test';      s.DoF = hdr.intent_p1;
    case 4, s.intent = 'F-test';      s.DoF = [hdr.intent_p1 hdr.intent_p2];
    case 5, s.intent = 'Z-score';
    case 6, s.intent = 'Chi squared'; s.DoF = hdr.intent_p1;
        
    % several non-statistical intent_code
    case 1002, s.intent = 'Label'; % e.g. AAL labels
    case 2003, s.intent = 'RGB'; % triplet in the 5th dimension
    case 2004, s.intent = 'RGBA'; % quadruplet in the 5th dimension
end
switch hdr.datatype
    case 0
    case 1,    s.DataType = 'logical';
    case 2,    s.DataType = 'uint8';
    case 4,    s.DataType = 'int16';
    case 8,    s.DataType = 'int32';
    case 16,   s.DataType = 'single';
    case 32,   s.DataType = 'single complex';
    case 64,   s.DataType = 'double';
    case 128,  s.DataType = 'uint8 RGB';
    case 256,  s.DataType = 'int8';
    case 511,  s.DataType = 'single RGB';
    case 512,  s.DataType = 'uint16';
    case 768,  s.DataType = 'uint32';
    case 1024, s.DataType = 'int64';
    case 1280, s.DataType = 'uint64';
    case 1792, s.DataType = 'double complex';
    case 2304, s.DataType = 'uint8 RGBA';
    otherwise, s.DataType = 'unknown';
end
s.Dimension = hdr.dim(2:hdr.dim(1)+1);
switch bitand(hdr.xyzt_units, 7)
    case 1, s.VoxelUnit = 'meters';
    case 2, s.VoxelUnit = 'millimeters';
    case 3, s.VoxelUnit = 'micrometers';
end 
s.VoxelSize = hdr.pixdim(2:4);
switch bitand(hdr.xyzt_units, 56)
    case 8,  s.TemporalUnit = 'seconds';
    case 16, s.TemporalUnit = 'milliseconds';
    case 24, s.TemporalUnit = 'microseconds';
    case 32, s.TemporalUnit = 'Hertz';
    case 40, s.TemporalUnit = 'ppm';
    case 48, s.TemporalUnit = 'radians per second';
end 
if isfield(s, 'TemporalUnit') && strfind(s.TemporalUnit, 'seconds')
    s.TR = hdr.pixdim(5);
end
if hdr.dim_info>0
    s.FreqPhaseSliceDim = bitand(hdr.dim_info, [3 12 48]) ./ [1 4 16];
    a = bitand(hdr.dim_info, 192) / 64;
    if a>0 && s.FreqPhaseSliceDim(2)>0
        ax = 'xyz'; % ijk to be accurate
        pm = ''; if a == 2, pm = '-'; end 
        s.PhaseEncodingDirection = [pm ax(s.FreqPhaseSliceDim(2))]; 
    end
end

switch hdr.slice_code
    case 0
    case 1, s.SliceOrder = 'Sequential Increasing';
    case 2,	s.SliceOrder = 'Sequential Decreasing';
    case 3,	s.SliceOrder = 'Alternating Increasing 1';
    case 4,	s.SliceOrder = 'Alternating Decreasing 1';
    case 5,	s.SliceOrder = 'Alternating Increasing 2';
    case 6,	s.SliceOrder = 'Alternating Decreasing 2';
    otherwise, s.SliceOrder = 'Multiband?';
end
if ~isempty(hdr.descrip), s.Notes = hdr.descrip; end
str = formcode2str(hdr.qform_code);
if ~isempty(str), s.qform = str; end
if hdr.qform_code>0, s.qform_mat = quat2R(hdr); end
str = formcode2str(hdr.sform_code);
if ~isempty(str), s.sform = str; end
if hdr.sform_code>0
    s.sform_mat = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
end

%% decode NIfTI form_code
function str = formcode2str(code)
switch code
    case 0, str = '';
    case 1, str = 'Scanner Anat';
    case 2, str = 'Aligned Anat';
    case 3, str = 'Talairach';
    case 4, str = 'mni_152';
    otherwise, str = 'Unknown';
end

%% Get a mask based on image intensity, but with inside brain filled
function r = img2mask(img, thr)
if nargin<2 || isempty(thr), thr = mean(img(img(:)>0)) / 8; end
r = smooth23(img, 'box', 5) > thr; % smooth, binarize
if sum(r(:))==0, return; end

try
    C = contourc(double(r), [1 1]);
    i = 1; c = {};
    while size(C,2)>2 % split C into contours
        k = C(2,1) + 1;
        c{i} = C(:, 2:k); C(:,1:k) = []; %#ok
        i = i+1;
    end
    
    nc = numel(c);
    rg = nan(nc, 4); % minX minY maxX maxY
    for i = 1:nc
        rg(i,:) = [min(c{i},[],2)' max(c{i},[],2)'];
    end
    ind = false(nc,1);
    foo = min(rg(:,1)); ind = ind | foo==rg(:,1);
    foo = min(rg(:,2)); ind = ind | foo==rg(:,2);
    foo = max(rg(:,3)); ind = ind | foo==rg(:,3);
    foo = max(rg(:,4)); ind = ind | foo==rg(:,4);
    c = c(ind); % outmost contour(s) 
    len = cellfun(@(x) size(x,2), c);
    [~, ind] = sort(len, 'descend');
    c = c(ind);
    C = c{1};
    if isequal(C(:,1), C(:,end)), c(2:end) = []; end % only 1st if closed
    nc = numel(c);
    for i = nc:-1:2 % remove closed contours except one with max len
        if isequal(c{i}(:,1), c{i}(:,end)), c(i) = []; end
    end
    nc = numel(c);
    while nc>1 % +1 contours, put all into 1st
        d2 = nan(nc-1, 2); % distance^2 from C(:,end) to other start/endpoint
        for i = 2:nc
            d2(i-1,:) = sum((C(:,end)*[1 1] - c{i}(:,[1 end])).^2);
        end
        [i, j] = find(d2 == min(d2(:)));
        i = i + 1; % start with 2nd
        if j == 1, C = [C c{i}]; %#ok C(:,1) connect to c{i}(:,1)
        else C = [C c{i}(:,end:-1:1)]; %#ok C(:,end) to c{i}(:,end)
        end
        c(i) = []; nc = nc-1;
    end
    if ~isequal(C(:,1), C(:,end)), C(:,end+1) = C(:,1); end % close the contour
    x = C(1, :);
    y = C(2, :);
    [m, n] = size(r);

    % following is the method in Octave poly2mask
    xe = [x(1:numel(x)-1); x(1, 2:numel(x))]; % edge x
    ye = [y(1:numel(y)-1); y(1, 2:numel(y))]; % edge y
    ind = ye(1,:) == ye(2,:);
    xe(:,ind) = []; ye(:, ind) = []; % reomve horizontal edges
    minye = min(ye);
    maxye = max(ye);
    t = (ye == [minye; minye]);
    exminy = xe(:); exminy = exminy(t);
    exmaxy = xe(:); exmaxy = exmaxy(~t);
    maxye = maxye';
    minye = minye';
    m_inv = (exmaxy - exminy) ./ (maxye - minye);
    ge = [maxye minye exmaxy m_inv];
    ge = sortrows(ge, [1 3]);
    ge = [-Inf -Inf -Inf -Inf; ge];

    gei = size(ge, 1);
    sl = ge(gei, 1);
    ae = []; % active edge
    while (sl == ge(gei, 1))
        ae = [ge(gei, 2:4); ae]; %#ok
        gei = gei - 1;
    end

    miny = min(y);
    if miny < 1, miny = 1; end

    while (sl >= miny)
        if (sl <= m) % check vert clipping
            ie = round(reshape(ae(:, 2), 2, size(ae, 1)/2));
            ie(1, :) = ie(1, :) + (ie(1, :) ~= ie(2, :));
            ie(1, (ie(1, :) < 1)) = 1;
            ie(2, (ie(2, :) > n)) = n;
            ie = ie(:, (ie(1, :) <= n));
            ie = ie(:, (ie(2, :) >= 1));
            for i = 1:size(ie,2)
                r(sl, ie(1, i):ie(2, i)) = true;
            end
        end

        sl = sl - 1;
        ae = ae((ae(:, 1) ~= sl), :);
        ae(:, 2) = ae(:, 2) - ae(:, 3);

        while (sl == ge(gei, 1))
            ae = [ae; ge(gei, 2:4)]; %#ok
            gei = gei - 1;
        end

        if size(ae,1) > 0
            ae = sortrows(ae, 2);
        end
    end
catch %me, fprintf(2, '%s\n', me.message); assignin('base', 'me', me);
end

%% update colorbar label
function set_colorbar(hs)
if strcmpi(get(hs.colorbar, 'Visible'), 'off'), return; end
p = get_para(hs);
map = lut2map(p, hs.lutStr{p.lut});
rg = sort([p.lb p.ub]);
tickLoc = [0 0.5 1];
if any(p.lut == 26:28)
    labls = [0 180 360];
elseif p.lut==10
    rg = sort(abs(rg));
    labls = {num2str(-rg(2),'%.2g') num2str(rg(1),'+/-%.2g') num2str(rg(2),'%.2g')};
elseif p.lut==numel(hs.lutStr) % custom
    im = p.nii.img(:,:,:,p.volume);
    im(isnan(im) | im==0) = [];
    im = unique(im);
    if max(im)<=size(map,1) && isequal(im, round(im)) % integer
        try, map = map(im+1, :); rg = [im(1) im(end)]; end
    end
    labls = [rg(1) rg(2)];
    tickLoc = [0 1];
else
    if rg(2)<0, rg = rg([2 1]); end
    mn = str2double(num2str(mean(rg), '%.4g'));
    labls = [rg(1) mn rg(2)];
end
% colormap in earlier matlab version changes values in colorbar.
% So we have to set those values each time.
colormap(hs.ax(end), map); % map must be double for old matlab
% set(hs.colorbar, 'YTickLabel', labls); % new matlab
set(get(hs.colorbar, 'Children'), 'YData', [0 1]); % Trick for old matlab
set(hs.colorbar, 'YTickLabel', labls, 'YTick', tickLoc, 'Ylim', [0 1]);

fh = hs.fig.UserData;
if isempty(fh) || ~ishandle(fh) || ~isfield(p.nii, 'cii'), return; end
hs = guidata(fh);
colormap(hs.ax(end), map);
set(get(hs.colorbar, 'Children'), 'YData', [0 1]);
set(hs.colorbar, 'YTickLabel', labls, 'YTick', tickLoc, 'Ylim', [0 1]);

%% return screen size in pixels
function res = screen_pixels(id)
res = get(0, 'MonitorPositions');
if size(res,1)<2, res = res(1, 3:4); return; end % single/duplicate monitor
if nargin, res = res(id,3:4); return; end
res = sortrows(res);
res = res(end,1:2) + res(end,3:4) - res(1,1:2);

%% add mask or modulation
function addMask(h, ~)
hs = guidata(h);
jf = hs.files.getSelectedIndex+1;
p = get_para(hs, jf);
pName = fileparts(p.nii.hdr.file_name);
[fname, pName] = uigetfile([pName '/*.nii;*.hdr;*.nii.gz;*.hdr.gz'], ...
    'Select mask NIfTI');
if ~ischar(fname), return; end
fname = fullfile(pName, fname);

nii = nii_tool('load', fname);
hdr = p.nii.hdr;
codes = [hdr.sform_code hdr.qform_code];
[R, frm] = nii_xform_mat(nii.hdr, codes);
if ~any(frm == codes)
    str = ['There is no matching coordinate system between the selected ' ...
        'image and the mask image. Do you want to apply the mask anyway?'];
    btn = questdlg(str, 'Apply mask?', 'Cancel', 'Apply', 'Cancel');
    if isempty(btn) || strcmp(btn, 'Cancel'), return; end
    R0 = nii_xform_mat(hdr, codes(1));
else
    R0 = nii_xform_mat(hdr, frm); % may be the same as p.R
end
% R0 = reorient(R0, hdr.dim(2:4)); % do this since img was done when loaded

% if isfield(p, 'alignMtx'), R = R0 / p.R * R; end % inverse
% this wont work if lines is background & Mprage is overlay
if all(isfield(p, {'R0' 'alignMtx'})) % target as mask
    R1 = reorient(R, nii.hdr.dim(2:4));
    if all(abs(R1(:)-p.R0(:))<1e-4), R0 = p.R; end % not 100% safe
end

d = single(size(p.nii.img)); % dim for reoriented img
d(numel(d)+1:3) = 1; d = d(1:3);

I = inv(R) * R0 * grid3(d) + 1; %#ok ijk+1 for mask
I = round(I * 100) / 100;

im = single(nii.img(:,:,:,1)); % first mask volume
slope = nii.hdr.scl_slope;
if slope==0, slope = 1; end
im = im * slope + nii.hdr.scl_inter;
im = interp3a(im, I, 'nearest');
im1 = im(~isnan(im)); % for threshold computation
im = reshape(im, d);

if strcmp(get(h, 'Label'), 'Apply mask') % binary mask
    if numel(unique(im1))<3
        thre = min(im1);
    else
        a = get_range(nii);
        str = sprintf('Threshold for non-binary mask (%.3g to %.4g)', ...
            min(im1), max(im1));
        a = inputdlg(str, 'Input mask threshold', 1, {num2str(a(1), '%.3g')});
        if isempty(a), return; end
        thre = str2double(a{1});
        fname = [fname ' (threshold = ' a{1} ')']; % info only
    end
    p.mask = ones(size(im), 'single');
    p.mask(abs(im)<=thre) = nan;
    p.mask_info = fname;
    noteStr = '(masked)';
else % modulation
    mi = min(im1); ma = max(im1);
    if mi<0 || ma>1
        str = {sprintf('Lower bound to clip to 0 (image min = %.2g)', mi) ...
               sprintf('Upper bound to clip to 1 (image max = %.2g)', ma)};
        def = strtrim(cellstr(num2str([mi;ma], '%.2g'))');
        a = inputdlg(str, 'Input modulation range', 1, def);
        if isempty(a), return; end
        mi = str2double(a{1}); ma = str2double(a{2});
        fname = [fname ' (range [' a{1} ' ' a{2} '])'];
    end
    im(im<mi) = mi; im(im>ma) = ma;
    p.modulation = (im-mi) / (ma-mi);
    p.modulation_info = fname;
    noteStr = '(modulated)';
end
p.hsI(1).UserData = p;
set_cdata(hs);

str = hs.files.getModel.get(jf-1);
if ~any(regexp(str, [regexptranslate('escape', noteStr) '$']))
    hs.files.getModel.set(jf-1, [str noteStr]);
end

%% Return 0-based 4xN 3D grid: [i; j; k; 1]
function I = grid3(d)
I = ones([4 d(1:3)], 'single');
[I(1,:,:,:), I(2,:,:,:), I(3,:,:,:)] = ndgrid(0:d(1)-1, 0:d(2)-1, 0:d(3)-1);
I = reshape(I, 4, []);

%% update crosshair: ix correspond to one of the three spinners, not views
function set_cross(hs, ix)
h = hs.cross;
for i = ix
    c = get(hs.ijk(i), 'Value');
    g = hs.gap(i);
    if i == 1 % I changed
        set([h(2,3:4) h(3,3:4)], 'XData', [c c]);
        set([h(2,1) h(3,1)], 'XData', [0 c-g]);
        set([h(2,2) h(3,2)], 'XData', [c+g hs.dim(1)+1]);
    elseif i == 2 % J
        set(h(1,3:4), 'XData', [c c]);
        set(h(1,1), 'XData', [0 c-g]);
        set(h(1,2), 'XData', [c+g hs.dim(2)+1]);
        set(h(3,1:2), 'YData', [c c]);
        set(h(3,3), 'YData', [0 c-g]);
        set(h(3,4), 'YData', [c+g hs.dim(2)+1]);
    else % K
        set([h(1,1:2) h(2,1:2)], 'YData', [c c]);
        set([h(1,3) h(2,3)], 'YData', [0 c-g]);
        set([h(1,4) h(2,4)], 'YData', [c+g hs.dim(3)+1]);
    end
end

%% Duplicate image handles, inlcuding ButtonDownFcn for new matlab
function h = copyimg(hs)
h = hs.hsI;
for i = 1:3, h(i) = handle(copyobj(hs.hsI(i), hs.ax(i))); end
cb = get(hs.hsI(1), 'ButtonDownFcn');
set(h, 'Visible', 'on', 'ButtonDownFcn', cb); % cb needed for 2014b+
crossFront(hs);

%% Save selected nii as another file
function save_nii_as(h, ~)
hs = guidata(h);
c = get(h, 'Label');
p = get_para(hs);
nam = p.nii.hdr.file_name;
pName = fileparts(nam);
if isempty(pName), pName = pwd; end
try nii = nii_tool('load', nam); % re-load to be safe
catch % restore reoriented img
    nii = p.nii;
    nii.img = permute(nii.img, [p.perm 4:8]); % all vol in dim(4)
    slope = nii.hdr.scl_slope; if slope==0, slope = 1; end
    nii.img = (single(nii.img) - nii.hdr.scl_inter) / slope; % undo scale
    if nii.hdr.datatype == 4 % leave others as it is or single
        nii.img = int16(nii.img);
    elseif nii.hdr.datatype == 512
        nii.img = uint16(nii.img);
    elseif any(nii.hdr.datatype == [2 128 2304])
        nii.img = uint8(nii.img);
    end
end

if ~isempty(strfind(c, 'a copy')) %#ok<*STREMP> % a copy
    [fname, pName] = uiputfile([pName '/*.nii'], 'Input file name');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    nii_tool('save', nii, fname);
elseif ~isempty(strfind(c, 'dim 4')) % fsl RGB
    if any(size(nii.img,8) == 3:4)
        nii.img = permute(nii.img, [1:3 8 4:7]);
    elseif ~any(nii.hdr.dim(5) == 3:4)
        errordlg('Selected image is not RGB data.'); return;
    end
    [fname, pName] = uiputfile([pName '/*.nii'], 'Input name for FSL RGB file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    nii_tool('save', nii, fname);
elseif ~isempty(strfind(c, 'dim 3')) % old mricron RGB
    if any(nii.hdr.dim(5) == 3:4)
        nii.img = permute(nii.img, [1:3 5:7 4]);
    elseif ~any(size(nii.img,8) == 3:4)
        errordlg('Selected image is not RGB data'); return;
    end
    [fname, pName] = uiputfile([pName '/*.nii'], 'Input name for old mricrom styte file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    old = nii_tool('RGBStyle', 'mricron');
    nii_tool('save', nii, fname);
    nii_tool('RGBStyle', old);
elseif ~isempty(strfind(c, 'AFNI')) % NIfTI RGB
    if any(nii.hdr.dim(5) == 3:4)
        nii.img = permute(nii.img, [1:3 5:8 4]);
    elseif ~any(size(nii.img,8) == 3:4)
        errordlg('Selected image is not RGB data'); return;
    end
    nii.img = abs(nii.img);
    [fname, pName] = uiputfile([pName '/*.nii'], ...
        'Input name for NIfTI standard RGB file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    old = nii_tool('RGBStyle', 'afni');
    nii_tool('save', nii, fname);
    nii_tool('RGBStyle', old);
elseif ~isempty(strfind(c, '3D')) % SPM 3D
    if nii.hdr.dim(5)<2
        errordlg('Selected image is not multi-volume data'); return;
    end
    [fname, pName] = uiputfile([pName '/*.nii'], 'Input base name for SPM 3D file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    nii_tool('save', nii, fname, 1); % force 3D
elseif ~isempty(strfind(c, 'new resolution'))
    str = 'Resolution for three dimension in mm';
    a = inputdlg(str, 'Input spatial resolution', 1, {'3 3 3'});
    if isempty(a), return; end
    res = sscanf(a{1}, '%g %g %g');
    if numel(res) ~= 3
        errordlg('Invalid spatial resolution');
        return;
    end
    if isequal(res, p.nii.hdr.pixdim(2:4))
        warndlg('The input resolution is the same as current one');
        return;
    end
    [fname, pName] = uiputfile([pName '/*.nii;nii.gz'], ...
        'Input result name for the new resolution file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    nii_xform(nii, res, fname, hs.pref.UserData.interp, hs.pref.UserData.extraV)
elseif ~isempty(strfind(c, 'matching background'))
    if p.hsI(1) == hs.hsI(1)
        errordlg('You selected background image');
        return;
    end
    [fname, pName] = uiputfile([pName '/*.nii;*.nii.gz'], ...
        'Input result file name');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    nii_xform(nii, hs.bg.hdr, fname, hs.pref.UserData.interp, hs.pref.UserData.extraV)
elseif ~isempty(strfind(c, 'aligned template'))
    [temp, pName] = uigetfile([pName '/*.nii;*.nii.gz'], ...
        'Select the aligned template file');
    if ~ischar(temp), return; end
    temp = fullfile(pName, temp);
    [mtx, pName] = uigetfile([pName '/*.mat'], ['Select the text ' ...
        'matrix file which aligns the nii to the template']);
    if ~ischar(mtx), return; end
    mtx = fullfile(pName, mtx);
    [fname, pName] = uiputfile([pName '/*.nii;*.nii.gz'], ...
        'Input result file name');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    nii_xform(nii, {temp mtx}, fname, hs.pref.UserData.interp, hs.pref.UserData.extraV)
else
    errordlg(sprintf('%s not implemented yet.', c));
end

%% Return 3-layer RGB, called by set_cdata
function [im, alfa] = lut2img(im, p, lutStr)
rg = sort([p.lb p.ub]);
if isfield(p.nii, 'NamedMap')
    try, p.map = p.nii.NamedMap{p.volume}.map; end
end
if any(p.lut == 26:28)
    im = im(:,:,2) .* single(im(:,:,1)>min(abs(rg))); % mag as mask
end
if rg(2)<0 % asking for negative data
    rg = -rg([2 1]);
    if p.lut~=10, im = -im; end
end

alfa = single(0); % override for lut=10
if p.lut == 10 % two-sided, store negative value
    rg = sort(abs(rg));
    im_neg = -single(im) .* (im<0);
    im_neg = (im_neg-rg(1)) / (rg(2)-rg(1));
    im_neg(im_neg>1) = 1; im_neg(im_neg<0) = 0;
    alfa = im_neg; % add positive part later
    im_neg = repmat(im_neg, [1 1 3]); % gray now
end

if p.lut < 26 % no scaling for 3 phase LUTs, RGB, custom
    im = (im-rg(1)) / (rg(2)-rg(1));
    im(im>1) = 1; im(im<0) = 0;
end
alfa = im + alfa;
if p.lut ~= 29, im = repmat(im, [1 1 3]); end % gray now

switch p.lut
    case 1 % gray do nothing
    case 2, im(:,:,2:3) = 0; % red
    case 3, im(:,:,[1 3]) = 0; % green
    case 4, im(:,:,1:2) = 0; % blue
    case 5, im(:,:,2) = 0; % violet
    case 6, im(:,:,3) = 0; % yellow
    case 7, im(:,:,1) = 0; % cyan
    case {8 19} % red_yellow, autumn
        a = im(:,:,1); a(a>0) = 1; im(:,:,1) = a;
        im(:,:,3) = 0;
    case 9 % blue_green
        im(:,:,1) = 0;
        a = im(:,:,3); a(a==0) = 1; a = 1 - a; im(:,:,3) = a;
    case 10 % two-sided: combine red_yellow & blue_green
        im(:,:,3) = 0;
        a = im(:,:,1); a(a>0) = 1; im(:,:,1) = a;
        im_neg(:,:,1) = 0;
        a = im_neg(:,:,3); a(a==0) = 1; a = 1 - a; im_neg(:,:,3) = a;
        im = im + im_neg;
    case 15 % hot, Matlab colormap can be omitted, but faster than mapping
        a = im(:,:,1); a = a/0.375; a(a>1) = 1; im(:,:,1) = a;
        a = im(:,:,2); a = a/0.375-1;
        a(a<0) = 0; a(a>1) = 1; im(:,:,2) = a;
        a = im(:,:,3); a = a*4-3; a(a<0) = 0; im(:,:,3) = a;
    case 16 % cool
        a = im(:,:,2); a(a==0) = 1; a = 1 - a; im(:,:,2) = a;
        a = im(:,:,3); a(a>0) = 1; im(:,:,3) = a;
    case 17 % spring
        a = im(:,:,1); a(a>0) = 1; im(:,:,1) = a;
        a = im(:,:,3); a(a==0) = 1; a = 1 - a; im(:,:,3) = a;
    case 18 % summer
        a = im(:,:,2); a(a==0) = -1; a = a/2+0.5; im(:,:,2) = a;
        a = im(:,:,3); a(a>0) = 0.4; im(:,:,3) = a;
    case 20 % winter
        im(:,:,1) = 0;
        a = im(:,:,3); a(a==0) = 2; a = 1-a/2; im(:,:,3) = a;
    case 22 % copper
        a = im(:,:,1); a = a*1.25; a(a>1) = 1; im(:,:,1) = a;
        im(:,:,2) = im(:,:,2) * 0.7812;
        im(:,:,3) = im(:,:,3) * 0.5;
    case 26 % phase, like red_yellow
        im(:,:,1) = 1; im(:,:,3) = 0;
    case 27 % phase3, red-yellow-green-yellow-red
        a = im(:,:,1);
        b1 = a<=0.25;
        b2 = a>0.25 & a<=0.5;
        b3 = a>0.5 & a<=0.75;
        b4 = a>0.75;
        a(b1 | b4) = 1;
        a(b2) = (0.5-a(b2))*4;
        a(b3) = (a(b3)-0.5)*4;
        im(:,:,1) = a;
        
        a = im(:,:,2);
        a(b2 | b3) = 1;
        a(b1) = a(b1)*4;
        a(b4) = (1-a(b4))*4;
        im(:,:,2) = a;
        
        im(:,:,3) = 0;
    case 28 % phase6, red-yellow-green/violet-blue-cyan
        a = im(:,:,1);
        b1 = a<=0.25;
        b2 = a>0.25 & a<=0.5;
        b3 = a>0.5 & a<=0.75;
        b4 = a>0.75;
        a(b2) =  (0.5-a(b2))*4; a(b1) = 1;
        a(b3) = (0.75-a(b3))*4; a(b4) = 0;
        im(:,:,1) = a;
        
        a = im(:,:,2);
        a(b1) = a(b1)*4; a(b2) = 1;
        a(b3) = 0; a(b4) = (a(b4)-0.75)*4;
        im(:,:,2) = a;
        
        a = im(:,:,3);
        a(b1 | b2) = 0;
        a(b3 | b4) = 1;
        im(:,:,3) = a;
    case 29 % disp non-NIfTI RGB as RGB
        im = abs(im); % e.g. DTI V1
        if max(im(:)) > 1, im = im / 255; end % it should be unit8
        alfa = sum(im,3)/3;
    otherwise % parula(12), jet(13), hsv(14), bone(21), pink(23), custom
        if isfield(p, 'map') % custom
            map = p.map;            
        else
            try, map = feval(lutStr, 256);
            catch me
                if p.lut == 12, map = lut2map(p); % parula for old matlab
                else, rethrow(me);
                end
            end
        end
        if p.lut ~= 30 % normalized previously
            a = floor(im(:,:,1) * (size(map,1)-1)) + 1; % 1st for bkgrnd
        elseif max(p.nii.img(:)) <= size(map,1)
            alfa = alfa / max(alfa(:));
            a = round(im(:,:,1)) + 1; % custom or uint8, round to be safe
        else
            a = (im(:,:,1) - rg(1)) / (rg(2)-rg(1));
            a(a<0) = 0 ; a(a>1) = 1;
            alfa = a;
            a = round(a * (size(map,1)-1)) + 1;
        end
        a(isnan(a)) = 1;
        aa = a;
        for i = 1:3
            aa(:) = map(a, i);
            im(:,:,i) = aa;
        end
end

%% Return binary sphere ROI from xyz and r (mm)
function b = xyzr2roi(c, r, hdr)
% ROI_img = xyzr2roi(center, radius, hdr)
% Return an ROI img based on the dim info in NIfTI hdr. The center and radius
% are in unit of mm. 
d = single(hdr.dim(2:4));
I = nii_xform_mat(hdr) * grid3(d); % xyz in 4 by nVox

b = bsxfun(@minus, I(1:3,:), c(:)); % dist in x y z direction from center
b = sum(b .* b); % dist to center squared, 1 by nVox

b = b <= r*r; % within sphere
b = reshape(b, d);

%% Return center of gravity of an image
function c = img_cog(img)
% center_ijk = img_cog(img)
% Return the index of center of gravity in img (must be 3D).
img(isnan(img)) = 0;
img = double(abs(img));
img = img / sum(img(:));
c = ones(3,1);
for i = 1:3
    a = permute(img, [i 1:i-1 i+1:3]);
    c(i) = (1:size(img,i)) * sum(sum(a,3),2);
end

%% set up disp parameter for new nifti
function p = dispPara(p, luts)
if nargin<2, luts = []; end
p.show = true; % img on
if isfield(p, 'map')
    p.lut = 30; % numel(hs.lutStr)
elseif any(p.nii.hdr.datatype == [32 1792]) % complex
    p.lut = 26; % phase
    p.lb = str2double(sprintf('%.2g', p.ub/2));
elseif any(p.nii.hdr.intent_code == [1002 3007]) % Label
    p.lut = 24; % prism
elseif p.nii.hdr.intent_code > 0 % some stats
    if p.lb < 0
        p.lut = 10; % two-sided
        p.lb = str2double(sprintf('%.2g', p.ub/2));
    else
        a = setdiff(8:9, luts); % red-yellow & blue-green
        if isempty(a), a = 8; end % red-yellow
        p.lut = a(1);
    end
elseif isempty(luts)
    p.lut = 1; % gray
else
    a = setdiff(2:7, luts); % use smallest unused mono-color lut 
    if isempty(a), a = 2; end % red
    p.lut = a(1);
end
p.lb_step = stepSize(p.lb); 
p.ub_step = stepSize(p.ub);
p.alpha = 1; % opaque
p.smooth = false;
p.interp = 1; % nearest
p.volume = 1; % first volume

%% estimate StepSize for java spinner
function d = stepSize(val)
d = abs(val/10);
% d = round(d, 1, 'significant');
d = str2double(sprintf('%.1g', d));
d = max(d, 0.01);
if d>4, d = round(d/2)*2; end

%% Return nii struct from nii struct, nii fname or other convertible files
function nii = get_nii(fname)
if isstruct(fname), nii = fname; return;
elseif iscellstr(fname), nam = fname{1}; %#ok
else, nam = fname;
end
try 
    nii = nii_tool('load', strtrim(nam));
catch me
    try, nii = dicm2nii(fname, pwd, 'no_save');
    catch, rethrow(me);
    end
end

%% Get figure/plot position from FoV for layout
% siz is in pixels, while pos is normalized.
function [siz, axPos, figPos] = plot_pos(mm, layout)
if layout==1 % 1x3
    siz = [sum(mm([2 1 1]))+mm(1)/4 max(mm(2:3))]; % image area width/height
    y0 = mm(2) / siz(1); % normalized width of sag images
    x0 = mm(1) / siz(1); % normalized width of cor/tra image
    z0 = mm(3) / siz(2); % normalized height of sag/cor images
    y1 = mm(2) / siz(2); % normalized height of tra image
    if y1>z0, y3 = 0; y12 = (y1-z0)/2;
    else, y3 = (z0-y1)/2; y12 = 0;
    end
    axPos = [0 y12 y0 z0;  y0 y12 x0 z0;  y0+x0 y3 x0 y1;  y0+x0*2 0 mm(1)/4/siz(1) min(z0,y1)];
elseif layout==2 || layout==3 % 2x2
    siz = [sum(mm(1:2)) sum(mm(2:3))]; % image area width/height
    x0 = mm(1) / siz(1); % normalized width of cor/tra images
    y0 = mm(2) / siz(2); % normalized height of tra image
    z0 = mm(3) / siz(2); % normalized height of sag/cor images
    if layout == 2 % 2x2 sag at (1,2)
        axPos = [x0 y0 1-x0 z0;  0 y0 x0 z0;  0 0 x0 y0;  x0 0 1-x0 y0];
    else % ==3:      2x2 sag at (1,2)
        axPos = [0 y0 1-x0 z0;  1-x0 y0 x0 z0;  1-x0 0 x0 y0;  0 0 1-x0 y0];
    end
else
    error('Unknown layout parameter');
end
siz = siz / max(siz) * 800;

res = screen_pixels(1); % use 1st screen
maxH = res(2) - 180;
maxW = res(1) - 100;
if siz(1)>maxW, siz = siz / siz(1) * maxW; end
if siz(2)>maxH, siz = siz / siz(2) * maxH; end

figPos = round((res-siz)/2);
if figPos(1)+siz(1) > res(1), figPos(1) = res(1)-siz(1)-10; end
if figPos(2)+siz(2) > res(2)-180, figPos(2) = min(figPos(2), 50); end

%% Return nii struct from cii and gii
function nii = cii2nii(nii)
persistent gii; % Anatomical surface
if nargin<1, nii = gii; return; end

ind = find([nii.ext.ecode]==32, 1);
xml = nii.ext(ind).edata_decoded;
expr = '(?<=((SurfaceNumberOfVertices)|(SurfaceNumberOfNodes))=").*?(?=")';
nVer = str2double(regexp(xml, expr, 'match', 'once'));
if isempty(nVer), error('SurfaceNumberOfVertices not found'); end
if isempty(gii), gii = get_surfaces(nVer, 'Anatomical'); end
if isempty(gii) || numel(gii.Vertices) ~=2, error('Not valid GIfTI'); end
if nVer ~= size(gii.Vertices{1},1), error('GIfTI and CIfTI don''t match'); end

if gii_attr(xml, 'CIFTI Version', 1) == 1
    dim = size(nii.img);
    nii.img = reshape(nii.img, dim([1:4 6 5]));
end

dim = gii_attr(xml, 'VolumeDimensions', 1);
if isempty(dim), dim = [91 109 91]; end % HCP 2x2x2 mm
TR = gii_attr(xml, 'SeriesStep', 1);
if ~isempty(TR), nii.hdr.pixdim(5) = TR; end
mat = gii_element(xml, 'TransformationMatrixVoxelIndicesIJKtoXYZ', 1);

if isempty(mat) % some cii miss 'mat' and 'dim'
    mat = [-2 0 0 90; 0 2 0 -126; 0 0 2 -72; 0 0 0 1]; % best guess from HCP
else
    pow = gii_attr(xml, 'MeterExponent', 1);
    mat(1:3,:) = mat(1:3,:) / 10^(3+pow);
end
nii.hdr.sform_code = gii.DataSpace;
nii.hdr.srow_x = mat(1,:);
nii.hdr.srow_y = mat(2,:);
nii.hdr.srow_z = mat(3,:);
nii.hdr.pixdim(2:4) = sqrt(sum(mat(1:3,1:3).^2));

nVol = size(nii.img, 5);
imgG = permute(nii.img, [6 5 1:4]);
nii.img = zeros([prod(dim) nVol], class(imgG));

iMdl = regexp(xml, '<BrainModel[\s>]'); iMdl(end+1) = numel(xml);
for j = 1:numel(iMdl)-1
    c = xml(iMdl(j):iMdl(j+1));
    offset = gii_attr(c, 'IndexOffset', 1);
    typ = gii_attr(c, 'ModelType');
    if strcmp(typ, 'CIFTI_MODEL_TYPE_SURFACE')
        a = gii_attr(c, 'BrainStructure');
        ig = find(strcmp(a, {'CIFTI_STRUCTURE_CORTEX_LEFT' 'CIFTI_STRUCTURE_CORTEX_RIGHT'}));
        if isempty(ig), warning('Unknown BrainStructure: %s', a); continue; end
        ind = gii_element(c, 'VertexIndices', 1) + 1;
        if isempty(ind), ind = 1:gii_attr(c, 'IndexCount', 1); end
        nii.cii{ig} = zeros(nVer, nVol, 'single');
        nii.cii{ig}(ind,:) = imgG((1:numel(ind))+offset, :);
    elseif strcmp(typ, 'CIFTI_MODEL_TYPE_VOXELS')
        a = gii_element(c, 'VoxelIndicesIJK', 1) + 1;
        a = sub2ind(dim, a(:,1), a(:,2), a(:,3));
        nii.img(a, :) = imgG((1:numel(a))+offset, :);
    end
end

for ig = 1:2 % map surface back to volume
    v = gii.Vertices{ig}'; v(4,:) = 1;
    v = round(mat \ v) + 1; % ijk 1-based
    ind = sub2ind(dim, v(1,:), v(2,:), v(3,:));
    nii.img(ind, :) = nii.cii{ig};
end
nii.img = reshape(nii.img, [dim nVol]);
nii = nii_tool('update', nii);

expr = '<Label\s+Key="(.*?)"\s+Red="(.*?)"\s+Green="(.*?)"\s+Blue="(.*?)".*?>(.*?)</Label>';
ind = regexp(xml, '<NamedMap'); ind(end+1) = numel(xml);
for k = 1:numel(ind)-1
    nii.NamedMap{k}.MapName = gii_element(xml(ind(k):ind(k+1)), 'MapName');
    tok = regexp(xml(ind(k):ind(k+1)), expr, 'tokens');
    if numel(tok)<2, continue; end
    tok = reshape([tok{:}], 5, [])'; % Key R G B nam
    a = str2double(tok(:, 1:4));
    nii.NamedMap{k}.map(a(:,1)+1, :) = a(:,2:4);
    if a(1,1) == 0 % key="0"
        nii.NamedMap{k}.labels(a(2:end, 1)) = tok(2:end, 5); % drop Key="0"
    else
        nii.NamedMap{k}.map = [0 0 0; nii.NamedMap{k}.map];
        nii.NamedMap{k}.labels(a(:, 1)) = tok(:, 5);
    end
end

%% Return gii for both hemesperes
function gii = get_surfaces(nVer, surfType)
persistent pth;
if nargin>1 && strcmpi(surfType, 'Anatomical') && nVer == 32492 % HCP 2mm surface
    fname = fullfile(fileparts(mfilename('fullpath')), 'example_data.mat');
    a = load(fname, 'gii'); gii = a.gii;
    return;
end
if nargin>1, surfType = [surfType ' ']; else, surfType = ''; end
prompt = ['Select ' surfType 'GIfTI surface files for both hemispheres'];
if isempty(pth), pth = pwd; end
[nam, pth] = uigetfile([pth '/*.surf.gii'],  prompt, 'MultiSelect', 'on');
if isnumeric(nam), gii = []; return; end
nam = cellstr(strcat([pth '/'], nam));
for i = 1:numel(nam)
    a = read_gii(nam{i});
    if ~isempty(surfType) && ~strcmpi(surfType, a.GeometryType)
        error('Surface is not of required type: %s', surfType);
    end
    gii.DataSpace = a.DataSpace;
    if all(a.Vertices(:,3)==0), a.Vertices = a.Vertices(:,[3 1 2]); end % flat
    if     strcmp(a.AnatomicalStructurePrimary, 'CortexLeft')
        gii.Vertices{1} = a.Vertices; gii.Faces{1} = a.Faces;
    elseif strcmp(a.AnatomicalStructurePrimary, 'CortexRight')
        gii.Vertices{2} = a.Vertices; gii.Faces{2} = a.Faces;
    end
end

%% Return gii struct with DataSpace, Vertices and Faces.
function gii = read_gii(fname)
xml = fileread(fname); % text file basically
for i = regexp(xml, '<DataArray[\s>]') % often 2 of them
    c = regexp(xml(i:end), '.*?</DataArray>', 'match', 'once');
    [Data, i0] = gii_element(c, 'Data'); % suppose '<Data' is last element
    c = regexprep(c(1:i0-1), '<!\[CDATA\[(.*?)\]\]>', '$1'); % rm CDADA thing
    
    a = gii_attr(c, 'DataType');
    if     strcmp(a, 'NIFTI_TYPE_FLOAT32'), dType = 'single';
    elseif strcmp(a, 'NIFTI_TYPE_INT32'),   dType = 'int32';
    elseif strcmp(a, 'NIFTI_TYPE_UINT8'),   dType = 'uint8';
    else, error('Unknown GIfTI DataType: %s', a);
    end
    
    nDim = gii_attr(c, 'Dimensionality', 1);
    dim = ones(1, nDim);
    for j = 1:nDim, dim(j) = gii_attr(c, sprintf('Dim%g', j-1), 1); end
        
    Endian = gii_attr(c, 'Endian'); % LittleEndian or BigEndian
    Endian = lower(Endian(1));

    Encoding = gii_attr(c, 'Encoding');
    if any(strcmp(Encoding, {'Base64Binary' 'GZipBase64Binary'}))
        % Data = matlab.net.base64decode(Data); % since 2016b
        Data = javax.xml.bind.DatatypeConverter.parseBase64Binary(Data);
        Data = typecast(Data, 'uint8');
        if strcmp(Encoding, 'GZipBase64Binary') % HCP uses this
            Data = nii_tool('LocalFunc', 'gunzip_mem', Data);
        end
        Data = typecast(Data, dType);
        if Endian == 'b', Data = swapbytes(Data); end
    elseif strcmp(Encoding, 'ASCII') % untested
        Data = str2num(Data);
    elseif strcmp(Encoding, 'ExternalFileBinary') % untested
        nam = gii_attr(c, 'ExternalFileName');
        if isempty(fileparts(nam)), nam = fullfile(fileparts(fname), nam); end
        fid = fopen(nam, 'r', Endian);
        if fid==-1, error('ExternalFileName %s not exists'); end
        fseek(fid, gii_attr(c, 'ExternalFileOffset', 1), 'bof');
        Data = fread(fid, prod(dim), ['*' dType]);
        fclose(fid);
    else, error('Unknown Encoding: %s', Encoding);
    end
    
    if nDim>1
        if strcmp(gii_attr(c, 'ArrayIndexingOrder'), 'RowMajorOrder')
            Data = reshape(Data, dim(nDim:-1:1));
            Data = permute(Data, nDim:-1:1);
        else
            Data = reshape(Data, dim);
        end
    end
    
    Intent = gii_attr(c, 'Intent');
    if strcmp(Intent, 'NIFTI_INTENT_TRIANGLE')
        gii.Faces = Data; % 0-based
        continue;
    elseif ~strcmp(Intent, 'NIFTI_INTENT_POINTSET') % store Data only for now
        if ~isfield(gii, 'Data'), gii.Data = []; gii.Intent = []; end
        gii.Intent{end+1} = Intent;
        gii.Data{end+1} = Data;        
        continue;
    end
    
    % now only for NIFTI_INTENT_POINTSET
    meta = @(k)regexp(c, ['(?<=>' k '<.*?<Value>).*?(?=</Value>)'], 'match', 'once');
    gii.AnatomicalStructurePrimary = meta('AnatomicalStructurePrimary');
    gii.AnatomicalStructureSecondary = meta('AnatomicalStructureSecondary');
    gii.GeometricType = meta('GeometricType');
    frms = {'NIFTI_XFORM_UNKNOWN' 'NIFTI_XFORM_SCANNER_ANAT' ...
        'NIFTI_XFORM_ALIGNED_ANAT' 'NIFTI_XFORM_TALAIRACH' 'NIFTI_XFORM_MNI_152'};
    gii.DataSpace = find(strcmp(gii_element(c, 'DataSpace'), frms)) - 1;
    gii.TransformedSpace = find(strcmp(gii_element(c, 'TransformedSpace'), frms)) - 1;
    gii.MatrixData = gii_element(c, 'MatrixData', 1);
    gii.Vertices = Data;
end

%% Return cii/gii attribute
function val = gii_attr(ch, key, isnum)
val = regexp(ch, ['(?<=' key '=").*?(?=")'], 'match', 'once');
if nargin>2 && isnum, val = str2num(val); end %#ok<*ST2NM>

%% Return cii/gii element
function [val, i0] = gii_element(ch, key, isnum)
i0 = regexp(ch, ['<' key '[\s>]'], 'once');
val = regexp(ch(i0:end), ['(?<=<' key '.*?>).*?(?=</' key '>)'], 'match', 'once');
if nargin>2 && isnum, val = str2num(val); end

%% Open surface view or add cii to it
function cii_view(hsN)
fh = hsN.fig.UserData;
if isempty(fh) || ~ishandle(fh) % create surface figure
    fh = figure(hsN.fig.Number+100);
    set(fh, 'NumberTitle', 'off', 'MenuBar', 'none', 'Renderer', 'opengl', ...
        'HandleVisibility', 'Callback', 'InvertHardcopy', 'off');
    if isnumeric(fh), fh = handle(fh); end

    cMenu = uicontextmenu('Parent', fh);
    uimenu(cMenu, 'Label', 'Reset view', 'Callback', {@cii_view_cb 'reset'});
    uimenu(cMenu, 'Label', 'Zoom in' , 'Callback', {@cii_view_cb 'zoomG'});
    uimenu(cMenu, 'Label', 'Zoom out', 'Callback', {@cii_view_cb 'zoomG'});
    uimenu(cMenu, 'Label', 'Change cortex color', ...
        'Callback', {@cii_view_cb 'cortexColor'}, 'Separator', 'on');
    uimenu(cMenu, 'Label', 'Change surface', 'Callback', {@cii_view_cb 'changeSurface'});
    saveAs = findobj(hsN.fig, 'Type', 'uimenu', 'Label', 'Save figure as');
    m = copyobj(saveAs, cMenu);
    set(m, 'Separator', 'on');
    m = get(m, 'Children'); delete(m(1:3)); m = m(4:end); % pdf/eps etc too slow
    set(m, 'Callback', {@nii_viewer_cb 'save' hsN.fig});
    if ispc || ismac
        uimenu(cMenu, 'Label', 'Copy figure', 'Callback', {@nii_viewer_cb 'copy' hsN.fig});
    end
    
    r = 0.96; % width of two columns, remaining for colorbar
    pos = [0 1 r 1; 0 0 r 1; r 1 r 1; r 0 r 1] / 2;
    gii = cii2nii(); % get buffered Anatomical gii
    hs.frame = uipanel(fh, 'Position', [0 0 1 1], 'BackgroundColor', 'k', 'UIContextMenu', cMenu);
    for ig = 1:2
        v = gii.Vertices{ig};
        lim = [min(v)' max(v)'];
        im = ones(size(v,1), 3, 'single') * 0.667;
        for i = ig*2+[-1 0]
            hs.ax(i) = axes('Parent', hs.frame, 'Position', pos(i,:), 'CameraViewAngle', 6.8);
            axis vis3d; axis equal; axis off;
            set(hs.ax(i), 'XLim', lim(1,:), 'YLim', lim(2,:), 'ZLim', lim(3,:));
            hs.patch(i) = patch('Parent', hs.ax(i), 'EdgeColor', 'none', ...
                'Faces', gii.Faces{ig}+1, 'Vertices', v, ...
                'FaceVertexCData', im, 'FaceColor', 'interp', 'FaceLighting', 'gouraud');
            hs.light(i) = camlight('infinite'); material dull;
        end
    end
    set(hs.patch, 'ButtonDownFcn', {@cii_view_cb 'buttonDownPatch'}, 'UIContextMenu', cMenu);
    
    hs.ax(5) = axes('Position', [r 0.1 1-r 0.8], 'Visible', 'off', 'Parent', hs.frame);
    try
        hs.colorbar = colorbar(hs.ax(5), 'PickableParts', 'none');
    catch % for early matlab
        colorbar('peer', hs.ax(5), 'Units', 'Normalized', 'HitTest', 'off');
        hs.colorbar = findobj(fh, 'Tag', 'Colorbar'); 
    end
    set(hs.colorbar, 'Location', 'East', 'Visible', get(hsN.colorbar, 'Visible'));
            
    fh.Position(3:4) = [1/r diff(lim(3,:))/diff(lim(2,:))] * 600 + 4;
    srn = get(0, 'MonitorPositions');
    dz = srn(1,4)- 60 - sum(fh.Position([2 4]));
    if dz<0, fh.Position(2) = fh.Position(2) + dz; end

    fh.WindowButtonUpFcn   = {@cii_view_cb 'buttonUp'};
    fh.WindowButtonDownFcn = {@cii_view_cb 'buttonDown'};
    fh.WindowButtonMotionFcn={@cii_view_cb 'buttonMotion'};
    fh.WindowKeyPressFcn   = {@cii_view_cb 'keyFcn'};
    fh.UserData = struct('xy', [], 'xyz', [], 'hemi', [], 'deg', [-90 0], ...
                         'color', [1 1 1]*0.667);
    hsN.fig.UserData = fh;
    hs.gii = gii.Vertices;
    hs.fig = fh;
    hs.hsN = hsN;
    guidata(fh, hs);
    set_cii_view(hs, [-90 0]);
    try % drawnow then set manual, not exist for earlier Matlab
        set(hs.patch, 'VertexNormalsMode', 'auto');
        drawnow; set(hs.patch, 'VertexNormalsMode', 'manual'); % faster update
    end
end

set_colorbar(hsN);
cii_view_cb(fh, [], 'volume');
cii_view_cb(fh, [], 'background');

%% cii_view callbacks 
function cii_view_cb(h, ev, cmd)
if isempty(h) || ~ishandle(h), return; end
hs = guidata(h);
switch cmd
    case 'buttonMotion' % Rotate gii and set light direction
        if isempty(hs.fig.UserData.xy), return; end % button not down
        d = get(hs.fig, 'CurrentPoint') - hs.fig.UserData.xy; % location change
        d = hs.fig.UserData.deg - d; % new azimuth and elevation
        set_cii_view(hs, d);
        hs.fig.UserData.xyz = []; % so not set cursor in nii_viewer
    case 'buttonDownPatch' % get button xyz
        if ~strcmpi(hs.fig.SelectionType, 'normal') % button 1 only
            hs.fig.UserData.xyz = []; return; 
        end
        hs.fig.UserData.hemi = 1 + any(get(h, 'Parent') == hs.ax(3:4));
        try,   hs.fig.UserData.xyz = ev.IntersectionPoint;
        catch, hs.fig.UserData.xyz = get(gca, 'CurrentPoint'); % old Matlab
        end
    case 'buttonDown' % figure button down: prepare for rotation
        if ~strcmpi(hs.fig.SelectionType, 'normal'), return; end % not button 1
        hs.fig.UserData.xy = get(hs.fig, 'CurrentPoint');
        hs.fig.UserData.deg = get(hs.ax(1), 'View');
    case 'buttonUp' % set cursor in nii_viewer
        hs.fig.UserData.xy = []; % disable buttonMotion
        xyz = hs.fig.UserData.xyz;
        if isempty(xyz), return; end
        ig = hs.fig.UserData.hemi;
        v = get(hs.patch(ig*2), 'Vertices');
        
        % xyz = get(gca, 'CurrentPoint'); % test
        if size(xyz,1) > 1 % for Matlab without IntersectionPoint
            ln = [linspace(xyz(1,1), xyz(2,1), 200);
                  linspace(xyz(1,2), xyz(2,2), 200);
                  linspace(xyz(1,3), xyz(2,3), 200)]; % line between box edges
            ln = permute(ln, [3 1 2]);
            d = sum(bsxfun(@minus, v, ln) .^ 2, 2); % distance squared
            a = permute(min(d), [3 1 2]); % min along the line
            a = sum([a a([2:end end]) a([1 1:end-1])], 2) / 3; % smooth
            i = find((diff(a)>0) & (a(1:end-1)<8), 1); % find 1st valley
            i = max(1, i-1);
            d = d(:,:, i:i+3); % use a couple of samples along the line
            [~, ind] = min(d(:));
            [iv, ~, ~] = ind2sub(size(d), ind);
            xyz = v(iv,:); % may find 2nd intersection for Anatomical surface
            % disp(xyz-hs.fig.UserData.xyz);
            if ~isequal(v, hs.gii{ig}), xyz = hs.gii{ig}(iv,:); end        
        elseif ~isequal(v, hs.gii{ig})
            v = bsxfun(@minus, v, xyz);
            [~, iv] = min(sum(v.^2, 2));
            xyz = hs.gii{ig}(iv,:);
        end
        c = round(hs.hsN.bg.Ri * [xyz(:); 1]) + 1;
        for i = 1:3, hs.hsN.ijk(i).setValue(c(i)); end
    case 'reset'
        set_cii_view(hs, [-90 0]);
    case 'cortexColor'
        c = uisetcolor(hs.fig.UserData.color, 'Set cortical surface color');
        if numel(c) ~= 3, return; end
        hs.fig.UserData.color = c;
        set_cdata_cii(hs);
    case 'changeSurface'
        gii = get_surfaces(size(hs.gii{1}, 1));
        if isempty(gii), return; end
        if size(gii.Vertices{1},1) ~= size(hs.gii{1},1)
            errordlg('GIfTI has different number of vertices from CIfTI');
            return;
        end
        ind = [isequal(gii.Vertices{1}, get(hs.patch(1), 'Vertices')) ...
               isequal(gii.Vertices{2}, get(hs.patch(3), 'Vertices'))];
        if all(ind), return; end % no change

        for i = find(~ind)
            ip = i*2+(-1:0);
            set(hs.patch(ip), 'Vertices', gii.Vertices{i}, 'Faces', gii.Faces{i}+1);
            lim = [min(gii.Vertices{i})' max(gii.Vertices{i})'];
            set(hs.ax(ip), 'ZLim', lim(3,:), 'YLim', lim(2,:));
            try, set(hs.ax(ip), 'XLim', lim(1,:)); end % avoid error for flat
        end
        
        set_cdata_cii(hs);
        try
            set(hs.patch, 'VertexNormalsMode', 'auto');
            drawnow; set(hs.patch, 'VertexNormalsMode', 'manual');
        end
    case 'zoomG'
        va = get(hs.ax(1), 'CameraViewAngle'); 
        if strcmp(get(h, 'Label'), 'Zoom in'), va = va * 0.9;
        else, va = va * 1.1;
        end
        set(hs.ax(1:4), 'CameraViewAngle', va);
    case 'keyFcn'
        if any(strcmp(ev.Key, ev.Modifier)), return; end % only modifier
        figure(hs.fig); % avoid focus to Command Window
        if ~isempty(intersect({'control' 'command'}, ev.Modifier))
            if any(strcmp(ev.Key, {'add' 'equal'}))
                h = findobj(hs.fig, 'Type', 'uimenu', 'Label', 'Zoom in');
                cii_view_cb(h, [], 'zoomG');
            elseif any(strcmp(ev.Key, {'subtract' 'hyphen'}))
                h = findobj(hs.fig, 'Type', 'uimenu', 'Label', 'Zoom out');
                cii_view_cb(h, [], 'zoomG');
            elseif any(strcmp(ev.Key, {'a' 'r'}))
                figure(hs.hsN.fig);
                key = java.awt.event.KeyEvent.(['VK_' upper(ev.Key)]);
                java.awt.Robot().keyPress(key);
                java.awt.Robot().keyRelease(key);
            end
        elseif any(strcmp(ev.Key, {'space' 'comma' 'period'}))
            KeyPressFcn(hs.hsN.fig, ev);
        end
        
    % Rest cases not called by surface callback, but from nii_viewer_cb
    case {'lb' 'ub' 'lut' 'toggle' 'alpha' 'volume' 'stack' 'close' 'closeAll'}
        set_cdata_cii(hs);
        if strcmp(cmd, 'volume'), cii_view_cb(h, [], 'file'); end
    case 'file' % update MapName if available
        p = get_para(hs.hsN);
        try, mName = p.nii.NamedMap{p.volume}.MapName; catch, mName = ''; end
        frm = formcode2str(p.nii.hdr.sform_code);
        hs.fig.Name = ['cii_view - ' mName ' (' frm ')'];
    case 'background'
        clr = hs.hsN.frame.BackgroundColor;
        set(hs.frame, 'BackgroundColor', clr);
        set(hs.colorbar, 'EdgeColor', 1-clr);
    case 'colorbar' % colorbar on/off
        set(hs.colorbar, 'Visible', get(hs.hsN.colorbar, 'Visible'));
    otherwise, return; % ignore other nii_viewer_cb cmd
end

%% set surface FaceVertexCData
function set_cdata_cii(hs)
imP{1} = ones(size(hs.gii{1},1), 1, 'single') * hs.fig.UserData.color;
imP{2} = ones(size(hs.gii{2},1), 1, 'single') * hs.fig.UserData.color;
for j = hs.hsN.files.getModel.size:-1:1
    p = get_para(hs.hsN, j);
    if ~p.show || ~isfield(p.nii, 'cii'), continue; end
    for i = 1:2 % hemispheres
        [im, alfa] = lut2img(p.nii.cii{i}(:, p.volume), p, hs.hsN.lutStr{p.lut});
        alfa = p.alpha * single(alfa>0);
        im = permute(im, [1 3 2]); % nVertices x 3
        im = bsxfun(@times, im, alfa);
        imP{i} = bsxfun(@times, imP{i}, 1-alfa) + im;
    end
end
set(hs.patch(1:2), 'FaceVertexCData', imP{1});
set(hs.patch(3:4), 'FaceVertexCData', imP{2});
% tic; drawnow; toc

%% set surface view
function set_cii_view(hs, ae)
ae = [ae; ae(1)+180 -ae(2); -ae(1) ae(2); -ae(1)-180 -ae(2)];
for i = 1:4
    set(hs.ax(i), 'View', ae(i,:));
    camlight(hs.light(i), 'headlight');
end

%% this can be removed for matlab 2013b+
function y = flip(varargin)
if exist('flip', 'builtin')
    y = builtin('flip', varargin{:});
else
    if nargin<2, varargin{2} = find(size(varargin{1})>1, 1); end
    y = flipdim(varargin{:}); %#ok
end

%% normalize columns
function v = normc(M)
v = bsxfun(@rdivide, M, sqrt(sum(M .* M)));
% v = M ./ sqrt(sum(M .* M)); % since 2016b

%% reorient nii to diagnal major
function [nii, perm, flp] = nii_reorient(nii, leftHand, ask_code)
if nargin<3, ask_code = []; end
[R, frm] = nii_xform_mat(nii.hdr, ask_code);
dim = nii.hdr.dim(2:4);
pixdim = nii.hdr.pixdim(2:4);
[R, perm, flp] = reorient(R, dim, leftHand);
fps = bitand(nii.hdr.dim_info, [3 12 48]) ./ [1 4 16];
if ~isequal(perm, 1:3)
    nii.hdr.dim(2:4) = dim(perm);
    nii.hdr.pixdim(2:4) = pixdim(perm);
    nii.hdr.dim_info = [1 4 16] * fps(perm)' + bitand(nii.hdr.dim_info, 192);
    nii.img = permute(nii.img, [perm 4:8]);
end
sc = nii.hdr.slice_code;
if sc>0 && flp(fps==3)
    nii.hdr.slice_code = sc+mod(sc,2)*2-1; % 1<->2, 3<->4, 5<->6
end
if isequal(perm, 1:3) && ~any(flp), return; end
if frm(1) == nii.hdr.sform_code % only update matching form
    nii.hdr.srow_x = R(1,:);
    nii.hdr.srow_y = R(2,:);
    nii.hdr.srow_z = R(3,:);
end
if frm(1) == nii.hdr.qform_code
    nii.hdr.qoffset_x = R(1,4);
    nii.hdr.qoffset_y = R(2,4);
    nii.hdr.qoffset_z = R(3,4);
    R0 = normc(R(1:3, 1:3));
    dcm2quat = dicm2nii('', 'dcm2quat', 'func_handle');
    [q, nii.hdr.pixdim(1)] = dcm2quat(R0);
    nii.hdr.quatern_b = q(2);
    nii.hdr.quatern_c = q(3);
    nii.hdr.quatern_d = q(4);
end
for i = find(flp), nii.img = flip(nii.img, i); end

%% Return true if input is char or single string (R2016b+)
function tf = ischar(A)
tf = builtin('ischar', A);
if tf, return; end
if exist('strings', 'builtin'), tf = isstring(A) && numel(A)==1; end

%% flip slice dir for nii hdr
% function hdr = flip_slices(hdr)
% if hdr.sform_code<1 && hdr.sform_code<1, error('No valid form_code'); end
% R = nii_xform_mat(hdr);
% [~, iSL] = max(abs(R(1:3,1:3))); iSL = find(iSL==3);
% if hdr.sform_code
%     hdr.srow_x(iSL) = -hdr.srow_x(iSL);
%     hdr.srow_y(iSL) = -hdr.srow_y(iSL);
%     hdr.srow_z(iSL) = -hdr.srow_z(iSL);
% end
% if hdr.qform_code<1, return; end
% R = quat2R(hdr);
% R(:, iSL) = -R(:,iSL);
% R = normc(R(1:3, 1:3));
% dcm2quat = dicm2nii('', 'dcm2quat', 'func_handle');
% [q, hdr.pixdim(1)] = dcm2quat(R);
% hdr.quatern_b = q(2);
% hdr.quatern_c = q(3);
% hdr.quatern_d = q(4);
%%
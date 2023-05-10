function RT_moco()
% Display and save motion information at real time. It also shows images and the
% progress of EPI/DTI while scanning, and allows to check motion information for
% previous series/patients.
%
% To make this work, you will need:
%  1. Set up shared folder at the computer running RT_moco. 
%     The folder default to ../incoming_DICOM, but better set to your own by 
%     setpref('dicm2nii_gui_para', 'incomingDcm', '/mypath/myIncomingDicom');
%     The result log will be saved into incoming_DICOM/RTMM_log/ folder.
%  2. Set up real time image transfer at Siemens console.

% 200207 xiangrui.li at gmail.com first working version inspired by FIRMM

% Create/re-use GUI and start timer
fh = findall(0, 'Type', 'figure', 'Tag', 'RT_moco');
if ~isempty(fh), figure(fh); return; end
res = get(0, 'ScreenSize');
fh = figure('mc'*[256 1]'); clf(fh);
set(fh, 'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off', ... 
	'DockControls', 'off', 'CloseRequestFcn', @closeFig, 'Color', [1 1 1]*0.94, ...
    'Name', 'Real Time Image Monitor ', 'Tag', 'RT_moco', 'Visible', 'off');
try fh.WindowState = 'maximized'; catch, fh.Position = [1 60 res(3) res(4)-80]; end
hs.fig = fh;
hs.rootDir = getpref('dicm2nii_gui_para', 'incomingDcm', '../incoming_DICOM/');
hs.backupDir = getpref('dicm2nii_gui_para', 'backupDir', '');
fullName = dicm2nii('', 'fullName', 'func_handle');
hs.rootDir = fullName(hs.rootDir);
if isfolder(hs.backupDir), hs.backupDir = fullName(hs.backupDir); end
hs.logDir = [hs.rootDir 'RTMM_log/'];
if ~isfolder(hs.logDir), mkdir(hs.logDir); end % folder to save subj.mat

h = uimenu(fh, 'Label', '&Patient');
hs.menu(1) = uimenu(h, 'Label', 'Load Patient', 'Callback', @loadSubj);
hs.menu(2) = uimenu(h, 'Label', 'Redo Patient', 'Callback', @redoSubj);
hs.menu(3) = uimenu(h, 'Label', 'Close Patient', 'Callback', @closeSubj);

h = uimenu(fh, 'Label', '&Series');
uimenu(h, 'Label', 'View Selected Series in 3D', 'Callback', @view_3D);
uimenu(h, 'Label', 'Overlay Selected Series onto Anatomy', 'Callback', @overlay);
hs.derived = uimenu(h, 'Label', 'Skip DERIVED Series', 'Checked', 'on', ...
    'Callback', @toggleChecked, 'Separator', 'on');
hs.SBRef = uimenu(h, 'Label', 'Skip *_SBRef Series', 'Callback', @toggleChecked, 'Checked', 'on');

h = uimenu(fh, 'Label', '&View');
uimenu(h, 'Label', 'Reset Brightness', 'Callback', @setCLim);
uimenu(h, 'Label', 'Increase Brightness', 'Callback', @setCLim);
uimenu(h, 'Label', 'Decrease Brightness', 'Callback', @setCLim);
hDV = uimenu(h, 'Label', '&DVARS Threshold', 'Separator', 'on');
for i = [0.01 0.02 0.05 0.1 0.12 0.15 0.2 0.4]
    uimenu(hDV, 'Label', num2str(i), 'Callback', @DV_yLim);
end
uimenu(h, 'Label', 'Show FD plot', 'Callback', @toggleFD, 'Separator', 'on');
hFD = uimenu(h, 'Label', '&FD Axis Range');
for i = [0.18 0.3:0.3:1.5 2.4 3 6]
    uimenu(hFD, 'Label', num2str(i), 'Callback', @FD_range)
end

panel = @(pos)uipanel(fh, 'Position', pos, 'BorderType', 'none');
if res(3) < res(4) % Portrait
    pa1 = panel([0 0.62 1 0.38]); % img and label
    pa2 = panel([0 0 1 0.62]); % table and plot
    axPos = [0.05 0 0.65 1]; % img axis
    lbPos = [0.65 0 0.34 1]; % label axis
    subjPos = [1 0.95]; seriesPos = [1 0.1]; msPos = [1 0.7]; ha = 'right';
else
    pa1 = panel([0 0 0.38 1]);
    pa2 = panel([0.38 0 0.62 1]);
    axPos = [0.05 0.31 0.9 0.67];
    lbPos = [0.05 0.01 0.9 0.3]; 
    subjPos = [0 0.98]; seriesPos = [1 0.1]; msPos = [0 0.6]; ha = 'left';
end

dy = 0.12 * (0:3);
hs.ax = axes(pa2, 'Position', [0.07 0.5 0.86 0.38], ...
    'NextPlot', 'add', 'XLim', [0.5 300.5], 'UserData', dy, ...
    'TickDir', 'out', 'TickLength', 0.002*[1 1], 'ColorOrder', [0 0 1; 1 0 1]);
xlabel(hs.ax, 'Volume Number');
hs.slider = uicontrol(pa2, 'Units', 'normalized', 'Position', [0.05 0.96 0.9 0.03], ...
    'Style', 'slider', 'Value', 1, 'Min', 1, 'Max', 300, 'Callback', @sliderCB, ...
    'BackgroundColor', 0.5*[1 1 1], 'SliderStep', [1 1]./300);

yyaxis left; ylabel(hs.ax, 'DVARS');
set(hs.ax, 'YTick', dy, 'YLim', dy([1 4]));
c3 = [0 0.8 0;  0.8 0.8 0;  0.5 0 0];
for i = 3:-1:1
    rectangle(hs.ax, 'Position', [0.5 dy(i) 2000 dy(i+1)-dy(i)], ...
        'FaceColor', c3(i,:), 'EdgeColor', c3(i,:), 'LineWidth', 0.01);
end
hs.dv = plot(hs.ax, nan, '.:');

yyaxis right; ylabel(hs.ax, 'Framewise Displacement (mm)');
set(hs.ax, 'YTick', 0:0.4:1.2, 'YLim', [0 1.2]);

txt = @(a)text(hs.ax, 'Units', 'normalized', 'Position', a, 'FontSize', 12, ...
    'BackgroundColor', [1 1 1]*0.94, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
hs.pct(1) = txt([0.995 0.32]); hs.pct(2) = txt([0.995 0.65]);

hs.fd = plot(hs.ax, 0, '.:', 'Visible', 'off');
hs.ax.YAxis(2).Visible = 'off';

ax = axes(pa2, 'Position', [0.07 0.88 0.86 0.04], 'Color', fh.Color);
hs.resp = plot(ax, nan, ones(1,3), 'o', 'Color', 'none', 'MarkerSize', 8);
set(hs.resp(1), 'MarkerFaceColor', [0 0 0]);
set(hs.resp(2), 'MarkerFaceColor', [1 0 0]);
set(hs.resp(3), 'MarkerFaceColor', [0 0.8 0]);
title(ax, ' ', 'FontSize', 14, 'interpreter', 'tex');
set(ax, 'XLim', [0.5 300.5], 'YLim', [0.5 1.5], 'Visible', 'off');

vars = {'Description' 'Series' 'Instances' '<font color="#00cc00">Green</font>' ...
    '<font color="#cccc00">Yellow</font>' 'MeanFD'};
w2 = [90 100 90 90 100]; w2 = num2cell([res(3)*pa2.Position(3)*0.94-sum(w2)-24 w2]);
hs.table = uitable(pa2, 'Units', 'normalized', 'Position', [0.02 0.01 0.96 0.42], ...
    'FontSize', 14, 'RowName', [], 'CellSelectionCallback', @tableCB, ...
    'ColumnName', strcat('<html><h2>', vars, '</h2></html>'), 'ColumnWidth', w2);

ax = axes(pa1, 'Position', axPos, 'YDir', 'reverse', 'Visible', 'off', 'CLim', [0 1]);
hs.img = image(ax, 'CData', ones(2)*0.94, 'CDataMapping', 'scaled');
axis equal; colormap(ax, 'gray');
hs.instnc = text(ax, 'Units', 'normalized', 'Position', [0.99 0.01], 'Color', 'y', ...
    'FontSize', 14, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');

ax = axes(pa1, 'Position', lbPos, 'Visible', 'off');
hs.subj = text(ax, 'Position', subjPos, 'FontSize', 24, 'FontWeight', 'bold', ...
    'HorizontalAlignment', ha, 'VerticalAlignment', 'top', 'Interpreter', 'none');
hs.series = text(ax, 'Position', seriesPos, 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
    'BackgroundColor', fh.Color, 'Interpreter', 'none', 'UserData', [1 0]);
hs.MMSS = text(ax, 'Position', msPos, 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', ha, 'VerticalAlignment', 'top', 'Interpreter', 'none', ...
    'BackgroundColor', fh.Color, 'String', {'' ''}, 'Color', 'b');

set(fh, 'HandleVisibility', 'callback', 'Visible', 'on'); % fh.Resize = 'off';

% set up serial port
delete(instrfind('Tag', 'RTMM'));
if ispc, port = 'COM1'; else, port = '/dev/ttyUSB0'; end % change this to yours
hs.serial = serial(port, 'BaudRate', 115200, 'Terminator', '', 'Tag', 'RTMM', ...
    'Timeout', 0.3, 'UserData', struct('fig', fh, 'send', false), ...
    'BytesAvailableFcnCount', 1, 'BytesAvailableFcnMode', 'byte', ...
    'BytesAvailableFcn', @serialRead); %#ok
try fopen(hs.serial); catch, end

hs.timer = timer('StartDelay', 5, 'ObjectVisibility', 'off', 'UserData', fh, ...
    'StopFcn', @saveResult, 'TimerFcn', @doSeries, 'ErrorFcn', @errorLog);

hs.countDown = timer('ExecutionMode', 'fixedRate', 'ObjectVisibility', 'off', ...
    'TimerFcn', {@countDown hs}, 'UserData', 0);

guidata(fh, hs); closeSubj(fh);
start(hs.timer);

%% Log error for debugging
function errorLog(obj, ~)
hs = guidata(obj.UserData);
vnam = "err_"+hs.subj.String+"_"+hs.series.String{1};
assignin('caller', vnam, MException.last);
% eval(vnam+" = MException.last;");
nam = hs.logDir+"errorLog.mat";
if exist(nam, 'file'), save(nam, vnam, '-append'); else, save(nam, vnam); end

%% TimerFunc: do a series if avail, then call stopFunc to save result
function doSeries(obj, ~)
hs = guidata(obj.UserData);
hs.fig.Name(end) = 78 - hs.fig.Name(end); % dot/space switch: timer indicator
if hs.timer.StartDelay > 1, return; end % no new series
set(hs.menu, 'Enable', 'off'); set([hs.table hs.slider], 'Enable', 'inactive');

dict = dicm_dict('', {'Rows' 'Columns' 'BitsAllocated' 'InstanceNumber'});
try hs.fig.WindowState = 'maximized'; catch, end
L0 = java.awt.MouseInfo.getPointerInfo().getLocation();
java.awt.Robot().mouseMove(L0.getX+9, L0.getY+9); % wake up screen
pause(0.1); java.awt.Robot().mouseMove(L0.getX, L0.getY);

iRun = hs.series.UserData; % updated in new_series()
f = sprintf('%s/%03u_%06u_', hs.subj.UserData, iRun);
s = dicm_hdr_wait([f '000001.dcm']);
if isempty(s), return; end % non-image dicom, skip series
if all(iRun == 1) % first series: reset GUI
    closeSubj(hs.fig);
    hs.subj.String = regexprep(s.PatientName, '[_\s]', '');
    close(findall(0, 'Type', 'figure', 'Tag', 'nii_viewer')); % last subj if any
    if now-getfield(dir(s.Filename), 'datenum')<5/1440
        save([hs.rootDir '/hdr_' hs.subj.String], 's'); % as new subj flag
    end
end

if hs.derived.Checked=="on" && contains(s.ImageType, 'DERIVED'), return; end
if hs.SBRef.Checked=="on" && endsWith(s.SeriesDescription, '_SBRef'), return; end
if startsWith(s.SequenceName, 'ABCD3d1'), return; end

isDTI = contains(s.ImageType, '\DIFFUSION');
isMOS = contains(s.ImageType, '\MOSAIC');
isMoCo = contains(s.ImageType, '\MOCO');
isEnh = isfield(s, 'NumberOfFrames') && s.NumberOfFrames>1;

nTE = asc_header(s, 'lContrasts', 1);
% fieldmap phase diff series: nTE=2, EchoNumber=2
if (contains(s.ImageType, '\P\') && contains(s.SequenceName, 'fm2d')) || ...
   (contains(s.ImageType, '\MEAN') && s.NumberOfAverages>1) % vNAV RMS
    nTE = 1;
end
if isDTI
    nV = [];
    for i = 1:999
        a = asc_header(s, sprintf('sDiffusion.alAverages[%i]', i-1));
        if isempty(a), break; else, nV(i) = a; end %#ok
    end
    nV = nV(1) + sum(nV(2:end))*asc_header(s, 'sDiffusion.lDiffDirections');
else
    nV = nTE * (asc_header(s, 'lRepetitions', 0)+1);
end
if ~isMoCo, hs.series.String = seriesInfo(s); end
if isMOS, nSL = s.CSAImageHeaderInfo.NumberOfImagesInMosaic; end

if isDTI && (isMOS || isEnh)
    nIN = nV;
elseif contains(s.SequenceName, {'epfid2d' 'ASL'}) && (isMOS || isEnh) % EPI/ASL
    nIN = asc_header(s, 'lRepetitions', 0) + 1;
else % T1, T2, fieldmap etc: show info/img only
    if s.MRAcquisitionType == "3D", nIN = asc_header(s, 'sKSpace.lImagesPerSlab');
    else, nIN = asc_header(s, 'sSliceArray.lSize'); % 2D
    end
    if isEnh, nIN = nIN / s.NumberOfFrames; end
    init_series(hs, s, nIN*nV, nV);
    nam = sprintf('%s%06u.dcm', f, nIN*nTE);
    tEnd = now + 9/86400; % wait several seconds for files to arrive
    while now<tEnd && ~isfile(nam), pause(0.2); end
    if ~isfile(nam)
        hs.instnc.String = '1';
        img = dicm_img(s);
    else
        if isEnh
            hs.instnc.String = '1';
            img = permute(dicm_img(s), [1 2 4 3]);
        else
            hs.instnc.String = '';
            nii = dicm2nii([s.Filename(1:end-10) '*'], ' ', 'no_save');
            iSL = bitand(nii.hdr.dim_info, 48)/16;
            img = nii.img(:,:,:,1);
            if     iSL == 1, img = permute(img, [3 2 1]);
            elseif iSL == 2, img = permute(img, [3 1 2]);
            elseif iSL == 3, img = permute(img, [2 1 3]);
            end
            img = flip(img, 1);
        end
        sz = getpixelposition(hs.img.Parent);
        dim = [size(img) 1 1];
        nMos = round(min(sz(3:4)*2./dim(1:2))).^2;
        img(:,1,:) = 0; img(1,:,:) = 0; % visual divider
        img = vol2mos(img(:,:,unique(round(linspace(1, dim(3), nMos)))));
    end
    hs.slider.Value = 1;
    set_img(hs.img, img);
    return;
end

if isempty(nIN) || endsWith(s.SeriesDescription, '_SBRef'), nIN = 1; end
if nIN>5 && hs.countDown.Running == "off" % work for mosaic without tricks
    hs.countDown.UserData = (nIN-1) * s.RepetitionTime/864e5 + fileTime(s.Filename);
    start(hs.countDown);
end
try stopAt = str2double(regexp(s.ImageComments, '(?<=stopAt:)\d*', 'match', 'once')); 
catch, stopAt = inf;
end

mos = dicm_img(s);
if isMOS, img = mos2vol(mos, nSL);
else, img = permute(mos, [1 2 4 3]); mos = vol2mos(img);
end
img = brainMask(img, s);
try thk = s.SpacingBetweenSlices; catch, thk = s.SliceThickness; end
p = refVol(img, [s.PixelSpacing' thk]);
if isDTI
    p.mean = p.mean*5; % make it similar to EPI
end
img0 = double(img);
set_img(hs.img, mos);
init_series(hs, s, nIN, nV);
hs.img.UserData(1) = mean(img(:));
viewer = findall(0, 'Type', 'figure', 'Tag', 'nii_viewer');
if nIN<6 && isempty(viewer), overlay(hs.fig); end

R1 = inv(p.R0);
m6 = zeros(2,6);

nextSeries = sprintf('%s/%03u_%06u_000001.dcm', hs.subj.UserData, iRun+[0 1]);
for i = 2:nIN
    nam = sprintf('%s%06u.dcm', f, (i-1)*nTE+1);
    tEnd = now + 1/1440; % 1 minute no mosaic coming, treat as stopped series
    while ~isfile(nam)
        if isfile(nextSeries) || now>tEnd, return; end
        if hs.countDown.Running=="on", countDown(hs.countDown, 0, hs); end
        if hs.serial.Status=="open", serialRead(hs.serial); end
        pause(0.2);
    end
    s = dicm_hdr_wait(nam, dict); iN = s.InstanceNumber;
    if nTE>1, iN = i; end % fake InstanceNumber for multi-echo EPI
    mos = dicm_img(s);
    if isMOS, img = mos2vol(mos, nSL);
    else, img = permute(mos, [1 2 4 3]); mos = vol2mos(img);
    end
    hs.img.UserData(iN) = mean(img(:)); 
    set_img(hs.img, mos); hs.instnc.String = num2str(iN);
    hs.slider.Value = iN; % show progress
    img = brainMask(img);
    
    if isMoCo % FD from dicom hdr, DV uses MoCo img for now
        s1 = dicm_hdr(nam, dicm_dict('Siemens', 'CSAImageHeaderInfo'));
        m6(2,:) = [s1.CSAImageHeaderInfo.RBMoCoTrans; ...
                   s1.CSAImageHeaderInfo.RBMoCoRot];
    else
        p.F.Values = smooth_mc(img, p.sz);
        [m6(2,:), R1] = moco_estim(p, R1);
    end
    a = abs(m6(2,:) - m6(1,:)); m6(1,:) = m6(2,:);
    hs.fd.YData(iN) = sum([a(1:3) a(4:6)*50]); % 50mm: head radius
    
    img = double(img);
    a = img(:) - img0(:);
    hs.dv.YData(iN) = sqrt(a'*a / numel(a)) / p.mean;
    img0 = img;
    if hs.serial.UserData.send
        fwrite(hs.serial, uint8(hs.dv.YData(iN) / hs.ax.YAxis(1).Limits(2)*255));
    end
    
    a = hs.dv.YData(1:iN); a = [0 a(~isnan(a))];
    dy = hs.ax.UserData; fd = hs.fd.YData(1:iN);
    N = {numel(a) sum(a<dy(2)) sum(a<dy(3))};
    hs.table.Data(1,3:6) = [N mean(fd, 'omitnan')];
    for j = 1:2, hs.pct(j).String = sprintf('%.3g%%', N{j+1}/N{1}*100); end
    if i==2, set(hs.pct, 'Visible', 'on'); end
    if N{2}>=stopAt, [~, ~] = system(['touch "' hs.rootDir 'StopScan"']); end
    if iN>=nIN, return; end % ISSS alike
    % drawnow; % update instance for offline test
end

%% Reshape mosaic into volume, remove padded zeros
function vol = mos2vol(mos, nSL)
nMos = ceil(sqrt(nSL)); % nMos x nMos tiles for Siemens
[nr, nc] = size(mos); % number of row & col in mosaic
nr = nr / nMos; nc = nc / nMos; % number of row and col in slice
vol = zeros([nr nc nSL], class(mos));
for i = 1:nSL
    r = floor((i-1)/nMos) * nr + (1:nr); % 2nd slice is tile(1,2)
    c =    mod(i-1, nMos) * nc + (1:nc);
    vol(:, :, i) = mos(r, c);
end

%% Initialize GUI for a new series
function init_series(hs, s, nIN, nV)
if size(hs.table.Data,1)>0 && hs.table.Data{1,2}==s.SeriesNumber, return; end
tim = [s.AcquisitionDate(3:end) s.AcquisitionTime(1:6)];
fid = fopen([hs.rootDir 'currentSeries.txt'], 'w');
fprintf(fid, '%s_%s_%s', s.PatientName, asc_header(s, 'tProtocolName'), tim);
fclose(fid);

set(hs.slider, 'Max', nIN, 'Value', 1, 'UserData', s.Filename(1:end-10));
if nIN==1, hs.slider.Visible = 'off';
else, set(hs.slider, 'SliderStep', [1 1]./(nIN-1)); hs.slider.Visible = 'on';
end
hs.dv.YData = nan(nV,1); hs.fd.YData = nan(nV,1); hs.img.UserData = nan(nV,1);
hs.fig.UserData.nIN{end+1} = nIN;
if nV>1 && nIN==nV
    set([hs.ax hs.pct], 'Visible', 'on');
    hs.ax.XLim(2) = nV + 0.5;
else
    set([hs.ax hs.pct], 'Visible', 'off');
end
hs.resp(1).Parent.XLim(2) = hs.ax.XLim(2);
set(hs.resp, 'XData', nan, 'YData', 1); update_resp(hs);
set([hs.instnc hs.pct], 'String', '');
figure(hs.fig); drawnow; % bring GUI front if needed
if contains(s.ImageType, '\MOCO'), return; end
hs.table.Data = [{s.SeriesDescription s.SeriesNumber nIN [] [] []}; hs.table.Data];
hs.fig.UserData.hdr{end+1} = s; % 1st instance

pat = asc_header(s,'sPat.lAccelFactPE', 1);
if pat==1, thr = 0.12; else, thr = 0.15; end % arbitrary
h = findobj(hs.fig, 'Type', 'uimenu', 'Label', '&DVARS Threshold');
thrs = str2double(get(h.Children, 'Label'));
[~, i] = min(abs(thrs-thr));
DV_yLim(h.Children(i));

%% Set img and img axis
function set_img(h, img)
d = size(img) + 0.5;
set(h.Parent, 'CLim', [0 imgClim(img)], 'XLim', [0.5 d(2)], 'YLim', [0.5 d(1)]);
h.CData = img;

%% get some series information
function c = seriesInfo(s)
c{1} = s.SeriesDescription;
if numel(c{1})>24, c{1} = [c{1}(1:16) '...' c{1}(end-3:end)]; end
c{2} = sprintf('Series %g', s.SeriesNumber);
if s.StudyID~="1", c{2} = ['Study ' s.StudyID ', ' c{2}]; end
c{3} = datestr(datenum(s.AcquisitionTime, 'HHMMSS.fff'), 'HH:MM:SS AM');
c{4} = datestr(datenum(s.AcquisitionDate, 'yyyymmdd'), 'ddd, mmm dd, yyyy');
try c{5} = sprintf('TR = %g', s.RepetitionTime); catch, end

%% toggle FD display on/off
function toggleFD(h, ~)
hs = guidata(h);
if hs.fd.Visible == "on"
    set([hs.fd hs.ax.YAxis(2)], 'Visible', 'off');
    h.Label = 'Show FD plot';
else
    set([hs.fd hs.ax.YAxis(2)], 'Visible', 'on');
    h.Label = 'Hide FD plot';
end

%% Set FD plot y-axis limit
function FD_range(h, ~)
hs = guidata(h);
dy = str2double(h.Label) * (0:3) / 3;
yyaxis(hs.ax, 'right'); set(hs.ax, 'YTick', dy, 'YLim', dy([1 4]));

%% Set DVARS plot y-axis limit, and update table
function DV_yLim(h, ~)
hs = guidata(h);
dy = str2double(h.Label) * (0:3);
hs.ax.UserData = dy;
for i = 1:numel(hs.fig.UserData.DV)
    a = hs.fig.UserData.DV{i}; a = [0 a(~isnan(a))];
    if numel(a)<2, continue; end
    hs.table.Data(end-i+1, 4:5) = {sum(a<dy(2)) sum(a<dy(3))};
end
yyaxis(hs.ax, 'left'); set(hs.ax, 'YTick', dy, 'YLim', dy([1 4]));
rect = findobj(hs.ax, 'type', 'Rectangle');
for i = 1:3, rect(i).Position([2 4]) = dy([i 2]); end
DV = hs.dv.YData; a = [0 DV(~isnan(DV))];
for i = 1:2, hs.pct(i).String = sprintf('%.3g%%', sum(a<dy(i+1))/numel(a)*100); end

%% Table-click callback: show moco/series info and image if avail
function tableCB(h, evt)
if isempty(evt.Indices) || evt.Indices(1,2)>2, return; end
hs = guidata(h);
C = h.Data;
iT = evt.Indices(1,1);
iR = size(C,1) - iT + 1;
dV = hs.fig.UserData.DV{iR};
hs.fd.YData = hs.fig.UserData.FD{iR};
hs.dv.YData = dV;
if numel(dV)<2 || isnan(dV(2))
    set([hs.ax hs.pct], 'Visible', 'off');
else    
    set([hs.ax hs.pct], 'Visible', 'on');
    for j = 1:2, hs.pct(j).String = sprintf('%.3g%%', C{iT,j+3}/C{iT,3}*100); end
    hs.resp(1).Parent.XLim(2) = hs.ax.XLim(2);
    try
        for i = 1:3
            a = hs.fig.UserData.resp{iR}{i};
            set(hs.resp(i), 'XData', a, 'YData', ones(size(a)));
        end
    catch, set(hs.resp, 'XData', nan, 'YData', 1);
    end
    update_resp(hs);
end
hs.instnc.String = '';
hs.series.String = C{iT,1}; % in case hdr not saved
try s = hs.fig.UserData.hdr{iR}; catch, set_img(hs.img, inf(2)); return; end
if ~isfile(s.Filename), s.Filename = strrep(s.Filename, hs.rootDir, hs.backupDir); end

nIN = C{iT,3};
iIN = ceil(nIN/2); % start with middle Instance if avail
nam = sprintf('%s%06g.dcm', s.Filename(1:end-10), iIN);
if ~isfile(nam), iIN = 1; nam = s; end
hs.instnc.String = num2str(iIN);
set(hs.slider, 'Max', nIN, 'Value', iIN, 'UserData', s.Filename(1:end-10));
if nIN == 1, hs.slider.Visible = 'off';
else, set(hs.slider, 'SliderStep', [1 1]./(nIN-1)); hs.slider.Visible = 'on';
end
hs.ax.XLim(2) = numel(hs.dv.YData) + 0.5;
hs.series.String = seriesInfo(s);
try img = dicm_img(nam); catch, img = ones(2)*0.94; end
set_img(hs.img, img);

%% Load subj data to review
function loadSubj(h, ~)
hs = guidata(h);
[fname, pName] = uigetfile([hs.logDir '*.mat'], 'Select MAT file for a Patient');
if isnumeric(fname), return; end
load([pName '/' fname], 'T3');
hs.fig.UserData = T3.Properties.UserData; 
DV = hs.fig.UserData.DV;
N = size(T3, 1);
C = flip(table2cell(T3), 1); C(:,6) = C(:,3);
dy = hs.ax.UserData;
for i = 1:N
    a = DV{N-i+1}; a = [0 a(~isnan(a))];
    if numel(a)<2, C(i,3:5) = {numel(a) [] []};
    else, C(i,3:5) = {numel(a) sum(a<dy(2)) sum(a<dy(3))};
    end
    try C{i,3} = hs.fig.UserData.nIN{N-i+1}; end
end 
hs.table.Data = C;
s = hs.fig.UserData.hdr{end};
hs.subj.String = regexprep(s.PatientName, '[_\s]', '');
[hs.subj.UserData, nam] = fileparts(s.Filename);
hs.series.UserData = sscanf(nam, '%u_%u', 1:2);
tableCB(hs.table, struct('Indices', [1 1])); % show top series

%% close subj
function closeSubj(h, ~)
hs = guidata(h);
hs.table.Data = {};
hs.img.CData = ones(2)*0.94;
hs.fd.YData = nan; hs.dv.YData = nan;
c = {{}};
hs.fig.UserData = struct('FD', c, 'DV', c, 'hdr', c, 'resp', c, 'GM', c, 'nIN', c);
set([hs.subj hs.series hs.instnc], 'String', '');
set(hs.pct, 'Visible', 'off');

%% Re-do current subj: useful in case of error during a session
function redoSubj(h, ~)
hs = guidata(h);
subj = hs.subj.String;
if isempty(subj), return; end
if ~isfolder(hs.subj.UserData)
    fprintf(2, 'Image for %s deleted?\n', subj);
    return;
end
try delete([hs.logDir subj '*.mat']); catch, end
closeSubj(hs.fig)

%% Get reference vol info. Adapted from nii_moco.m
function p = refVol(img, pixdim)
d = size(img);
p.R0 = diag([pixdim 1]); % no need for real xform_mat here
p.R0(1:3, 4) = -pixdim .* (d/2); % make center voxel [0 0 0]

sz = pixdim;
if all(abs(diff(sz)/sz(1))<0.05) && sz(1)>2 && sz(1)<4 % 6~12mm
    sz = 3; % iso-voxel, 2~4mm res, simple fast smooth
else
    sz = 9 ./ sz'; % 9 mm seems good
end

% resample ref vol to isovoxel (often lower-res)
d0 = d-1;
dd = 4 ./ pixdim; % use 4 mm grid for alignmen
[i, j, k] = ndgrid(0:dd(1):d0(1)-0.5, 0:dd(2):d0(2)-0.5, 0:dd(3):d0(3)-0.5);
I = [i(:) j(:) k(:)]';
a = rng('default'); I = I + rand(size(I))*0.5; rng(a); % used by spm
V = smooth_mc(img, sz);
F = griddedInterpolant({0:d0(1), 0:d0(2), 0:d0(3)}, V, 'linear', 'none');
V0 = F(I(1,:), I(2,:), I(3,:)); % ref: 1 by nVox
I(4,:) = 1; % 0-based ijk: 4 by nVox
I = p.R0 * I; % xyz of ref voxels

% compute derivative to each motion parameter in ref vol
dG = zeros(6, numel(V0));
dd = 1e-6; % delta of motion parameter, value won't affect dG much
R0i = inv(p.R0); % speed up a little
for i = 1:6
    p6 = zeros(6,1); p6(i) = dd; % change only 1 of 6
    J = R0i * rigid_mat(p6) * I; %#ok<*MINV>
    dG(i,:) = F(J(1,:), J(2,:), J(3,:)) - V0; % diff now
end
dG = dG / dd; % derivative

% choose voxels with larger derivative for alignment: much faster
a = sum(dG.^2); % 6 derivatives has similar range
ind = a > std(a(~isnan(a)))/10; % arbituray threshold. Also exclude NaN
p.mean = mean(V0);
p.dG = dG(:, ind);
p.V0 = V0(ind);
p.mm = I(:, ind);
F.GridVectors = {0:d(1)-1, 0:d(2)-1, 0:d(3)-1};
p.F = F;
p.sz = sz;

%% motion correction to ref-vol. From nii_moco.m
function [m6, rst] = moco_estim(p, R)
mss0 = inf;
rst = R;
for iter = 1:64
    J = R * p.mm; % R_rst*J -> R0*ijk
    V = p.F(J(1,:), J(2,:), J(3,:));
    ind = ~isnan(V); % NaN means out of range
    dV = p.V0(ind) - V(ind);
    mss = dV*dV' / numel(dV); % mean(dV.^2)
    if mss > mss0, break; end % give up and use previous R
    rst = R; % accecpt only if improving
    if 1-mss/mss0 < 1e-6, break; end % little effect, stop
    
    a = p.dG(:, ind);
    p6 = (a * a') \ (a * dV'); % dG(:,ind)'\dV' estimate p6 from current R
    R = R * rigid_mat(p6); % inv(inv(rigid_mat(p6)) * inv(R_rst))
    mss0 = mss;
end

R = p.R0 * rst; % inv(R_rst / Rref)
m6 = -[R(1:3, 4)' atan2(R(2,3), R(3,3)) asin(R(1,3)) atan2(R(1,2), R(1,1))];

%% Translation (mm) and rotation (deg) to 4x4 R. Order: ZYXT
function R = rigid_mat(p6)
ca = cosd(p6(4:6)); sa = sind(p6(4:6));
rx = [1 0 0; 0 ca(1) -sa(1); 0 sa(1) ca(1)]; % 3D rotation
ry = [ca(2) 0 sa(2); 0 1 0; -sa(2) 0 ca(2)];
rz = [ca(3) -sa(3) 0; sa(3) ca(3) 0; 0 0 1];
R = rx * ry * rz;
R = [R p6(1:3); 0 0 0 1];

%% Simple gaussian smooth for motion correction, sz in unit of voxels
function out = smooth_mc(in, sz)
out = double(in);
if numel(unique(in))<5, return; end
if all(abs(diff(sz)/sz(1))<0.05) && abs(sz(1)-round(sz(1)))<0.05 ...
        && mod(round(sz(1)),2)==1
    out = smooth3(out, 'gaussian', round(sz)); % sz odd integer
    return; % save time for special case
end

d = size(in);
I = {1:d(1) 1:d(2) 1:d(3)};
n = sz/3;
if numel(n)==1, n = n*[1 1 1]; end
J = {1:n(1):d(1) 1:n(2):d(2) 1:n(3):d(3)};
intp = 'linear';
F = griddedInterpolant(I, out, intp);
out = smooth3(F(J), 'gaussian'); % sz=3
F = griddedInterpolant(J, out, intp);
out = F(I);

%% mask brain for better motion estimate
function img = brainMask(img, s)
persistent msk isDTI;
if nargin>1 % init msk from Volume 1
    isDTI = contains(s.ImageType, '\DIFFUSION');
    nii = nii_tool('init', logical(img)); % xposed, img=dicm_img(s)
    xform_mat = dicm2nii('', 'xform_mat', 'func_handle');
    [~, R, nii.hdr.pixdim(2:4)] = xform_mat(s); R = R(:,[2 1 3 4]); % LPS
    nii.hdr.sform_code = 1;
    nii.hdr.srow_x = -R(1,:); % RAS
    nii.hdr.srow_y = -R(2,:);
    nii.hdr.srow_z = R(3,:);
    if ~isDTI || isempty(msk)
        msk = nii;
        msk.img = EPI_mask(img);
        msk.img = smooth3(double(msk.img), 'guassian', 5) > 1e-6; % dilate
    end
    if isDTI % possibly EPI mask
        msk = nii_xform(msk, nii, [], 'nearest', false); 
    end
end
img(~msk.img) = 0;
if ~isDTI, return; end % for EPI: only mask out
img = EPI_mask(img);

%% Quick brain mask for EPI or alike with low contrast
function M = EPI_mask(img)
B = smooth3(double(img), 'box', 5);
mn = median(B(B>mean(B(:)/8)));
mn = min(max(B(:)), mn*20);
[N, edges] = histcounts(img(:), linspace(0,mn,100));
N = movmean(N, 9);
mx = mean(N);
for i = 1:9
    p = islocalmin(N, 'MinProminence', mx);
    if any(p), break; end
    mx = mx / 2;
end
if ~any(p), M = true(size(B)); return; end % give up
B = B > edges(find(p,1))*0.7;
M = false(size(B));
c = round(nii_viewer('LocalFunc', 'img_cog', img));
M(c(1), c(2), c(3)) = true; n1 = 1;
while 1
    for i = 1:3
        M = (M<circshift(M, 1,i) | M<circshift(M,-1,i)) & B | M;
    end
    n2 = sum(M(:));
    if n2>n1, n1 = n2; else, break; end
end

%% new series or new subj: result saved as incoming_DICOM/RTMM_log/subj.mat
% The subj folders (yyyymmdd.PatientName.PatientID) default to ../incoming_DICOM/
% The dcm file names from Siemens push are always in format of
% 001_000001_000001.dcm. All three numbers always start at 1, and are continuous.
% First is study, second is series and third is instance.
function new = new_series(hs)
try setCountDown(hs); catch, end
try QC_report(hs.rootDir); catch me, assignin('base', 'me', me); disp(me); end
f = hs.subj.UserData;
if ~isempty(f) % check new run for current subj
    iR = hs.series.UserData;
    if isfile(sprintf('%s/%03u_%06u_000001.dcm', f, iR+[0 1]))
        hs.series.UserData(2) = iR(2) + 1; new = true; return;
    elseif isfile(sprintf('%s/%03u_000001_000001.dcm', f, iR(1)+1))
        hs.series.UserData = [iR(1)+1 1];  new = true; return;
    end
end
dirs = dir([hs.rootDir '20*']); % check new subj
dirs(~isfile(strcat(hs.rootDir, {dirs.name}, '/001_000001_000001.dcm'))) = [];
new = false;
for i = numel(dirs):-1:1
    subj = regexp(dirs(i).name, '(?<=\d{8}\.).*?(?=\.)', 'match', 'once');
    subj = regexprep(subj, '[_\s]', '');
    if isfile([hs.logDir subj '.mat']), continue; end
    hs.subj.UserData = [hs.rootDir dirs(i).name]; 
    hs.series.UserData = [1 1];
    new = true; return;
end

% Move/Delete old subj folder right after mid-night
if ~isfile([hs.rootDir 'host.txt']) || mod(now,1) > 10/86400; return; end
dirs(now-[dirs.datenum]<2) = []; % keep for 2 days
for i = 1:numel(dirs)
    try 
        src = [hs.rootDir dirs(i).name];
        if ~isfolder(hs.backupDir), rmdir(src, 's');
        else, system(['cp -p -r ' src ' ' hs.backupDir ';rm -rf ' src]);
        end
    catch me
        disp(me.message); assignin('base', 'me', me);
    end
end

%% Subfunction: get a parameter in CSA series ASC header: MrPhoenixProtocol
function val = asc_header(s, key, dft)
if nargin>2, val = dft; else, val = []; end
csa = 'CSASeriesHeaderInfo';
if ~isfield(s, csa) % in case of multiframe
    try s.(csa) = s.SharedFunctionalGroupsSequence.Item_1.(csa).Item_1; end
end
if isfield(s, 'Private_0029_1020') && isa(s.Private_0029_1020, 'uint8')
    str = char(s.Private_0029_1020(:)');
    str = regexp(str, 'ASCCONV BEGIN(.*)ASCCONV END', 'tokens', 'once');
    if isempty(str), return; end
    str = str{1};
elseif isfield(s, 'MrPhoenixProtocol') % X20A
    str = s.MrPhoenixProtocol;
elseif ~isfield(s, csa), return; % non-siemens
elseif isfield(s.(csa), 'MrPhoenixProtocol') % most Siemens dicom
    str = s.(csa).MrPhoenixProtocol;
elseif isfield(s.(csa), 'MrProtocol') % older version dicom
    str = s.(csa).MrProtocol;
else, return;
end

% tSequenceFileName  = ""%SiemensSeq%\gre_field_mapping""
expr = ['\n' regexptranslate('escape', key) '\s*=\s*(.*?)\n'];
str = regexp(str, expr, 'tokens', 'once');
if isempty(str), return; end
str = strtrim(str{1});

if strncmp(str, '""', 2) % str parameter
    val = str(3:end-2);
elseif strncmp(str, '"', 1) % str parameter for version like 2004A
    val = str(2:end-1);
elseif strncmp(str, '0x', 2) % hex parameter, convert to decimal
    val = sscanf(str(3:end), '%x', 1);
else % decimal
    val = sscanf(str, '%g', 1);
end

%% Wait till a file copy is complete
function s = dicm_hdr_wait(varargin)
tEnd = now + 1/86400; % wait up to 1 second
while 1
    s = dicm_hdr(varargin{:});
    try %#ok<*TRYNC> maybe too strict to be equal? Test indicates always equal 
        if s.PixelData.Start+s.PixelData.Bytes == s.FileSize, return; end
    end
    if now>tEnd, s = []; return; end % give up
    pause(0.1);
end

%% User closing GUI: stop and delete timer
function closeFig(fh, ~)
hs = guidata(fh);
delete(fh);
try delete(hs.serial); catch, end
try hs.timer.StopFcn = ''; catch, end
try tObj = timerfindall; stop(tObj); delete(tObj); catch, end

%% menu callback for both DERIVED and _SBRef
function toggleChecked(h, ~)
if h.Checked == "on", h.Checked = 'off'; else, h.Checked = 'on'; end

%% Increase/Decrease image CLim
function setCLim(h, ~)
hs = guidata(h);
ax = hs.img.Parent;
if startsWith(h.Label, 'Increase'), ax.CLim(2) = ax.CLim(2)*0.8;
elseif startsWith(h.Label, 'Decrease'), ax.CLim(2) = ax.CLim(2)*1.2;
else, ax.CLim(2) = imgClim(hs.img.CData);
end

%% show series in nii_viewer
function view_3D(h, ~)
hs = guidata(h);
nams = dir([hs.slider.UserData '*.dcm']);
if isempty(nams), return; end
nams = strcat(nams(1).folder, '/', {nams.name});
nii = dicm2nii(nams, ' ', 'no_save');
nii_viewer(nii);

%% overlay series onto T1w or Scout if avail
function overlay(h, ~)
hs = guidata(h);
hdrs = hs.fig.UserData.hdr;
if isempty(hdrs), return; end
is3D = @(c)c.MRAcquisitionType=="3D" && ~contains(c.ImageType, 'DERIVED');
is3D = cellfun(is3D, hdrs);
if ~any(is3D), is3D = cellfun(@(c)c.MRAcquisitionType=="3D", hdrs); end
if sum(is3D)>1
    isT1 = cellfun(@(c)contains(c.SequenceName, 'fl3d1'), hdrs);
    isT1 = isT1 & is3D;
    if any(isT1), is3D = isT1; end
end
if ~any(is3D), view_3D(h); return; end % no T1, just show in nii_viewer
is3D = find(is3D, 1, 'last');
a = hdrs{is3D}.Filename(1:end-10);
nams = dir([a '*.dcm']);
if isempty(nams), nams = dir([strrep(a, hs.rootDir, hs.backupDir) '*.dcm']); end
nams = strcat(nams(1).folder, '/', {nams.name});
T1w = dicm2nii(nams, ' ', 'no_save');
nams = dir([hs.slider.UserData '*.dcm']);
nams = strcat(nams(1).folder, '/', {nams.name});
epi = dicm2nii(nams, ' ', 'no_save');
fh = nii_viewer(T1w, epi);
nii_viewer('LocalFunc', 'nii_viewer_cb', [], [], 'center', fh);

%% slider callback: show img if avail
function sliderCB(h, ~)
hs = guidata(h);
if isempty(h.UserData), return; end
h.Value = round(h.Value);
nam = sprintf('%s%06u.dcm', h.UserData, h.Value);
if ~isfile(nam), nam = strrep(nam, hs.rootDir, hs.backupDir); end
if ~isfile(nam), return; end
set_img(hs.img, dicm_img(nam));
hs.instnc.String = num2str(h.Value);

%% Timer StopFunc: Save result, start timer with delay, even after error
function saveResult(obj, ~)
hs = guidata(obj.UserData);
set([hs.menu hs.table hs.slider], 'Enable', 'on');
if size(hs.table.Data,1) > numel(hs.fig.UserData.FD) % new series to save?
    hs.fig.UserData.FD{end+1} = hs.fd.YData;
    hs.fig.UserData.DV{end+1} = hs.dv.YData;
    hs.fig.UserData.GM{end+1} = hs.img.UserData;
    hs.fig.UserData.resp{end+1} = {hs.resp.XData};
    T3 = cell2table(flip(hs.table.Data(:,[1 2 6]), 1), ...
        'VariableNames', {'Description' 'SeriesNumber' 'MeanFD'});
    T3.Properties.UserData = hs.fig.UserData;
    save([hs.logDir hs.subj.String], 'T3');
    hs.serial.UserData.send = false; % stop until asked again
end
if new_series(hs), obj.StartDelay = 0.1; else, obj.StartDelay = 5; end
start(obj);

%% Serial BytesAvail callback: update response: 1=missed, 2=incorrect, 3=correct 
function serialRead(s, ~)
if s.BytesAvailable<1, return; end
b = fread(s, 1);
hs = guidata(s.UserData.fig);
if     b == '?', fwrite(s, uint8('RTMM')); return; % identity
elseif b == 'P', fwrite(s, uint8(hs.subj.String)); return; % PatientName
elseif b == 'T', fwrite(s, uint8(strjoin(hs.MMSS.String))); return; % count down
elseif b == 'M', s.UserData.send = true; return; % start to send motion info
elseif b == 'Q' % stim computer asks to stop scan
    [~, ~] = system(['touch "' hs.rootDir 'StopScan"']); return;
elseif b<1 || b>3, return; % ignore for now
end
if hs.timer.StartDelay>1, return; end % not during a series
x = find(~isnan(hs.dv.YData), 1, 'last');
if isempty(x), x = 0; end
hs.resp(b).XData(end+1) = x + 1; hs.resp(b).YData(end+1) = 1;
update_resp(hs);

%% update response text
function update_resp(hs)
n = cellfun(@numel, {hs.resp.XData}) - 1;
h = hs.resp(1).Parent.Title;
if ~any(n>0), h.Visible = 'off'; return; end
h.Visible = 'on';
h.String = "Missed " + n(1) + ", \color{red}Incorrect " + n(2) + ...
    ", \color[rgb]{0 0.8 0}Correct " + n(3) + ", \color{blue}Total " + sum(n);

%% start countdown
function setCountDown(hs)
nam = [hs.rootDir 'SyngoMeas'];
if ~isfile(nam), return; end
c0 = fileread(nam); pause(0.2); c = fileread(nam);
if ~isequal(c0, c), pause(1); c = fileread(nam); end
tRTMM = fileTime(nam); delete(nam); 
% From scanner: "RunStartTime" "ProtocolName" TotalScanTimeSec "CurrentTime"
c = regexp(c, '"(.*?)" "(.*?)" (\d+) "(.*?)"', 'tokens', 'once');
if isempty(c), return; end % MeasFinished?
tStart = datenum(c{1}, 'yyyy-mm-dd HH:MM:SS,fff');
dClock = datenum(c{4}, 'ddd mm/dd/yyyy HH:MM:SS.fff') - tRTMM;
tFnsh = tStart - dClock + str2double(c{3})/86400;
if tFnsh-now < 2/86400, return; end
hs.fig.UserData.tSyng_RTMM = dClock; % for eyelink
hs.countDown.UserData = tFnsh;
if numel(c{2})>24, c{2} = [c{2}(1:16) '...' c{2}(end-3:end)]; end
hs.MMSS.String = {c{2} ''};
if hs.countDown.Running=="off", start(hs.countDown); end

%% timer func to show scanning time
function countDown(tObj, ~, hs)
t = tObj.UserData - now;
if t<1/86400, stop(tObj); hs.MMSS.String = {'' ''}; return; end
hs.MMSS.String{2} = ['Scanning ' datestr(t, 'MM:SS')];
nam = hs.rootDir + "SyngoMeas";
if ~isfile(nam), return; end
if ~startsWith(fileread(nam), "Finished"), return; end
delete(nam);
stop(tObj);
hs.MMSS.String{2} = ['Finished ' datestr(t, 'MM:SS')];

%% get CLim for dicom img
function mx = imgClim(img)
im = double(img(:));
im = im(im>max(im)/10);
mx = mean(im) + 2*std(im);

%% Create QC report
function QC_report(rootDir)
nam = dir([rootDir 'closed_*']);
if isempty(nam) || isfile([rootDir 'EyelinkRecording.mat']), return; end
nam = [rootDir nam(1).name];
done = onCleanup(@()movefile(nam, strrep(nam, 'closed_', 'done_'))); 
rmQC = onCleanup(@()delete('./tmp_QC_*.pdf'));
subj = regexp(nam, '(?<=closed_)\d{4}\w{2}$', 'match', 'once');
if isempty(subj), return; end
load([rootDir 'RTMM_log/' subj '.mat'], 'T3');
uDat = T3.Properties.UserData;

close all; delete('./tmp_QC_*.pdf');
fig = figure('Position', [10 30 [8.5 11]*96], 'Units', 'normalized');
set(fig, 'Color', 'w', 'PaperUnits', 'normalized', 'PaperPosition', [0 0 1 1]);
ax = axes(fig, 'Position', [0.01 0.955 0.98 0.045], 'Visible', 'off');
try imshow('./logo.png', 'Parent', ax); ax.HandleVisibility = 'off'; catch, end

layout = getpref('nii_viewer_para', 'layout');
if layout ~= 1
    setpref('nii_viewer_para', 'layout', 1);
    cln = onCleanup(@()setpref('nii_viewer_para', 'layout', layout));
end

ax = axes(fig, 'Position', [0.1 0.92 0.8 0.03], 'Visible', 'off');
text(ax, 0.5, 1, subj, 'FontSize', 18, 'HorizontalAlignment', 'center');
s = uDat.hdr{1};
dat = datestr(datenum(s.AcquisitionDate, 'yyyymmdd'), 'dddd mmm dd, yyyy');
text(ax, 0.5, 0, dat, 'FontSize', 12, 'HorizontalAlignment', 'center');
tbl = cell(1, 5);
dict = dicm_dict('', {'AcquisitionTime' 'SeriesNumber' 'SeriesDescription'});
for i = 1:99
    nams = dir([s.Filename(1:end-17) sprintf('%06i_',i) '*.dcm']);
    if isempty(nams), break; end
    s = dicm_hdr([nams(1).folder '/' nams(1).name], dict);
    d = s.AcquisitionTime; d = d(1:2)+":"+d(3:4)+":"+d(5:6);
    try a = T3.MeanFD{T3.SeriesNumber == s.SeriesNumber}; catch, a = []; end
    tbl(i,:) = {s.SeriesNumber d numel(nams) s.SeriesDescription a};
end
tbl = cellfun(@num2str, tbl, 'UniformOutput', false); % for left-align
vName = {'SeriesNumber' 'Time' 'TotalInstances' 'Description' 'meanFD'};
h = uitable(fig, 'Units', 'normalized', 'Position', [0.04 0.1 0.9 0.8], ...
    'FontSize', 12, 'RowName', [], 'ColumnName', vName, 'Data', tbl, ...
    'ColumnWidth', {96 96 108 342 82});
if i>40, h.FontSize = max(8, fix(450/i)); end
newPage(fig); y = 0.95;

el = {}; clear EL;
nam = dir([rootDir 'RTMM_log/' subj '_*.edf']);
if ~isempty(nam)
    tm = []; tg = []; pa = [];
    for i = numel(nam):-1:1 % in case of multiple files
        [~, a] = evalc("edfmex('"+nam(i).folder+"/"+nam(i).name+"')");
        tm = [a.FSAMPLE.time tm]; %#ok
        tg = [a.FSAMPLE.buttons tg]; %#ok
        pa = [a.FSAMPLE.pa(2,:) pa]; %#ok
    end
    i = find(arrayfun(@(c)startsWith(char(c.message), 'RTMM_'), a.FEVENT), 1, 'last');
    a = double(tm)/1000 - double(a.FEVENT(i).sttime)/1000 + ...
        sscanf(a.FEVENT(i).message, 'RTMM_secs=%g') + uDat.tSyng_RTMM*86400;
    EL.Hz = 100; % resample pa to 100 Hz
    EL.t0 = a(1); % recording start time in Syngo secs of the day
    EL.tg = a(diff([0 bitget(tg, 5)])>0); % trigger time
    EL.pa = interp1(a, pa/55^2, a(1):1/EL.Hz:a(end)); % convert roughly to degree
end

for i = 1:numel(uDat.hdr)
    s = uDat.hdr{i};
    series = sprintf('%s (Series %g)', s.ProtocolName, s.SeriesNumber);
    if contains(s.SequenceName, {'epfid2d' 'mbPCASL' 'ep_b0'}) % EPI/ASL/Diff
        fd = uDat.FD{i};
        N = find(~isnan(fd), 1, 'last');
        if isempty(N) || N<11 || all(fd==0), continue; end % skip slice check etc
        if y<0.35, newPage(fig); y = 0.95; end
        if exist('EL', 'var') && contains(s.SequenceName, 'epfid2d')
            t0 = mod(datenum(s.AcquisitionTime, 'HHMMSS.fff'), 1) * 86400;
            [~, j] = min(abs(EL.tg - t0));
            TR = s.RepetitionTime / 1000;
            while j>1 && abs(diff(EL.tg([j-1 j]))-TR)<0.1, j = j-1; end
            % fprintf('%4.2f\n', EL.tg(j)-t0); % normally <1
            j = floor((EL.tg(j)-EL.t0) * EL.Hz);
            nP = round(N * TR * EL.Hz);
            el{end+1} = {EL.pa(j+(1:nP)) series}; %#ok save for users
            y = y - 0.4;
            ax0 = axes(fig, 'Position', [0.1 y+0.27 0.8 0.08]);
            plot(ax0, el{end}{1}, 'b');
            set(ax0, 'XLim', [1 nP], 'XTick', []);
            ylabel(ax0, 'Pupil Size', 'Color', 'b');
        else, y = y - 0.32; clear ax0;
        end
        ax = axes(fig, 'Position', [0.1 y+0.19 0.8 0.08]);
        gm = uDat.GM{i}(1:N);
        gm = (gm/mean(gm) - 1)*100; rg = ceil(std(gm)); % global mean
        % gm = [0; diff(gm)]/mean(gm) * 100; % delta GM
        plot(ax, gm, '.-m');
        set(ax, 'YTick', [], 'YLim', [-rg rg], 'XLim', [0 N+1], 'XTick', []);
        ylabel(ax, 'GM (%)', 'Color', 'm');
        try ax = ax0; catch, end
        title(ax, series, 'Interpreter', 'none', 'FontSize', 12);
        % ylabel(ax, [char(916) 'GM (%)']);
        ax = axes(fig, 'Position', [0.1 y+0.03 0.8 0.16]);
        yyaxis right; plot(ax, fd(1:N), '.-');
        ylabel(ax, 'FD (mm)'); xlabel(ax, 'Volume Number');
        set(ax, 'YTick', 0:0.6:1.8, 'YLim', [0 1.8], 'XLim', [0 N+1]);
        str = sprintf('meanFD=%.2g', mean(fd(2:N)));
        text(ax, 0.8, 0.9, str, 'Units', 'normalized', 'Color', [0.85 0.32 0.1]);
        yyaxis left; plot(ax, uDat.DV{i}(1:N), '.-');
        ylabel(ax, 'DVARS'); set(ax, 'YTick', 0:0.12:0.36, 'YLim', [0 0.3]);
    elseif contains(s.SequenceName, {'tfl3d' 'spc' 'tse2d' 'fm2d' 'epse2d'}) % T1/T2/fmap
        nams = dir([s.Filename(1:end-10) '*.dcm']);
        nams = strcat(nams(1).folder, '/', {nams.name});
        fh = nii_viewer(dicm2nii(nams, ' ', 'no_save'));
        nii_viewer('LocalFunc', 'nii_viewer_cb', [], [], 'center', fh);
        hsV = guidata(fh);
        drawnow; F = getframe(fh, hsV.frame.Position); close(fh); img = F.cdata;
        sz = size(img); sz = sz([2 1]) ./ [8.5 11]/96;
        if sz(1)>0.8, sz = sz / sz(1) * 0.8; end
        y = y - sz(2) - 0.08;
        if y<0.02 && y+sz(2)*0.2>0.02, sz = sz * 0.8; y = y + 0.2*sz(2); end
        if y<0.02, newPage(fig); y = 0.92-sz(2); end
        ax = axes(fig, 'Position', [(1-sz(1))/2 y+0.02 sz], 'Visible', 'off');
        imshow(img, 'Parent', ax);
        title(ax, series, 'Interpreter', 'none', 'FontSize', 12);
    end
end
newPage(fig); close(fig);

if ~isempty(el), save([rootDir 'RTMM_log/' subj '_eye.mat'], 'el'); end
pdfNam = rootDir+"RTMM_log/"+subj+"_"+s.AcquisitionDate(3:8)+"_QC.pdf";
setenv('LD_LIBRARY_PATH', getenv('PATH'));
[~, ~] = system("pdfunite ./tmp_QC_*.pdf "+pdfNam); % for Linux 

%% print fig to a new PDF, called by QC_report()
function newPage(fig)
nam = dir('./tmp_QC_*.pdf');
if isempty(nam), i = 1; else, i = str2double(nam(end).name(8:10)) + 1; end
print(fig, sprintf('./tmp_QC_%03i.pdf', i), '-dpdf');
clf(fig);

%% 3D to mos: for display purpose
function mos = vol2mos(vol)
[nr, nc, nSL] = size(vol);
nMos = ceil(sqrt(nSL));
mos = zeros([nr nc]*nMos, 'like', vol);
for i = 0:nMos-1
    r = i*nr + (1:nr);
    for j = 1:nMos
        iSL = i*nMos + j;
        if iSL>nSL, return; end
        c = (j-1)*nc + (1:nc);
        mos(r,c) = vol(:,:,iSL);
    end
end

%% Return file modify datenum, like dir(fname).datenum, but try ms precision
function dn = fileTime(fname)
if ispc || ismac % work for all OS, but only give ms for Windows. Java issue?
    ms = java.io.File(fname).lastModified; % ms since 00:00 1/1/1970 GMT
    dn = datenum(1970,1,1,0, -java.util.Date().getTimezoneOffset, ms/1000);
else % work for Windows too, but need stat.exe and is slow
    [~, c] = system(['stat "' fname '"']); % ls --full-time
    c = regexp(c, 'Modify:\s*(.{23})', 'tokens', 'once');
    dn = datenum(c{1}, 'yyyy-mm-dd HH:MM:SS.fff');
end
%%
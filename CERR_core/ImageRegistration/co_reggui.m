function L = co_reggui(action,varargin)
% GUI for Manual co-registration of different image modalities to go with
% CERR
% - Detailed Description: this is a manual co-registration routine for two
% set of images (2d/3d) assuming that a possible resmapling and affine
% transformation are sufficient for alignment. The quality of registration is measured by
% using the mutual information criterion (MI)
%
% Written By: Issam El Naqa    Date: 08/28/03
% Revised by:                  Date:
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.


if nargin<1,
    action='Initializeco_reggui';
end;

switch action

    case 'Initializeco_reggui'   %Initialization
        Initializeco_reggui;                             
        
    case 'RegisterMode'
        mode = get(findobj('Tag', 'dispregpopupmenu'),'Value');
        switch mode
            case 1 %manual
            case 2 %ctrl points  
            case 3 %auto control points
        end
               
    case 'LoadRefImage'
        set(findobj(gcbf, 'Tag', 'StatusText'), 'String', 'Loading images...');
        h = get(gcbf,'Userdata');
        pathname 	= h.pathname;
        [filename, pathname] = uigetfile('*.*', 'Load reference image');
        load([pathname,filename]);
        x = cropImage(x);
        h.refimage=min_maxnorm(x, 0:255);
        set(gcbf,'Userdata',h);
        DispImage('axref',x);
        drawnow
        
    case 'LoadPlanCUnregImage'
        
    case 'LoadPlanCRefImage'
        
    case 'LoadUnregImage'
        set(findobj(gcbf, 'Tag', 'StatusText'), 'String', 'Loading images...');
        h = get(gcbf,'Userdata');
        pathname 	= h.pathname;
        [filename, pathname] = uigetfile('*.*', 'Load unregistered image');
        load([pathname,filename]);
        x = cropImage(x);
        h.unregimage=min_maxnorm(x, 0:255);
        h.regimage=h.unregimage; % initailize registered image to unregistered one!
        set(gcbf,'Userdata',h);
        DispImage('axunreg',x);
        drawnow
        set(findobj(gcbf, 'Tag', 'StatusText'), 'String', 'Set registration parameters...');
    case 'EditRegParam'
        h = get(gcbf,'Userdata');
        h.Tx=str2num(get(findobj(gcbf,'Tag','TXed'),'String'));
        h.Ty=str2num(get(findobj(gcbf,'Tag','TYed'),'String'));
        h.Tz=str2num(get(findobj(gcbf,'Tag','TZed'),'String'));
        h.rot=str2num(get(findobj(gcbf,'Tag','Roted'),'String'));
        h.Sx=str2num(get(findobj(gcbf,'Tag','SXed'),'String'));
        h.Sy=str2num(get(findobj(gcbf,'Tag','SYed'),'String'));
        h.Sz=str2num(get(findobj(gcbf,'Tag','SZed'),'String'));
        h.samp=str2num(get(findobj(gcbf,'Tag','Resamped'),'String'));
        set(findobj(gcbf, 'Tag', 'regpushbutton'), 'Enable', 'on');
        set(findobj(gcbf, 'Tag', 'dispmodepopupmenu'), 'Enable', 'on');
        set(findobj(gcbf, 'Tag', 'StatusText'), 'String', 'Press register button for processing...');
        set(gcbf,'UserData',h);
    case 'DisplayMode'
        setDisplayMode;

    case 'enlargeOverlay'
        h = get(gcbf,'Userdata');
        displayOverlays(h.refimage, h.regimage);
        
    case 'ApplyRegistration'
        h = get(gcbf,'Userdata');
             
        mode = get(findobj('Tag', 'dispregpopupmenu'),'Value');
        switch mode
            case 1 %manual
                tempimage=imtranslate2d(h.unregimage,h.Tx,h.Ty);
                tempimage=imrotate2d(tempimage,h.rot);
                tempimage=imscale2d(tempimage,h.Sx,h.Sy);
                tempimage=imresample2d(tempimage,h.samp);
                h.regimage=tempimage;
            case 2 %ctrl points  
                getControlPoints('init');
                getControlPoints('load', h.refimage, h.unregimage);
                waitfor(findobj('Tag', 'RegGui'), 'Tag', 'RegGuiDone');                
                [ref_pts, target_pts] = getControlPoints('getpoints', h.refimage, h.unregimage);
                delete(findobj('Tag', 'RegGuiDone'));
                [tempimage,A]=compute_aff_transform(h.unregimage, ref_pts, target_pts);
                h.regimage=tempimage;                
            case 3
                getControlPoints('init');
                getControlPoints('load', h.refimage, h.unregimage);
                waitfor(findobj('Tag', 'RegGui'), 'Tag', 'RegGuiDone');                
                [ref_pts, target_pts] = getControlPoints('getpoints', h.refimage, h.unregimage);
                delete(findobj('Tag', 'RegGuiDone'));
                [tempimage,A]=compute_perspect_transform(h.unregimage, ref_pts, target_pts);
                h.regimage=tempimage;               
            case 4 %auto control points
                numPoints = 20;
                sigma = 1;
                get_control_points(h.unregimage, h.refimage, numPoints, sigma);
                
        end
        

        % make joint histogram plot
        [h.mi, h.jhist]=get_mutualinfo(h.refimage,h.regimage);
        %set(findobj(gcbf, 'Tag', 'mitext'), 'Visible', 'on');
        %set(findobj(gcbf, 'Tag', 'mivalue'), 'Visible', 'on');
        % make a cross-correlation image
        h.xcorr=fxcorr(h.refimage,h.regimage);
        % save current data
        set(gcbf,'UserData',h);
        % display images
        setDisplayMode;
        DisplayJHist(h.jhist);
        set(findobj(gcbf, 'Tag', 'mivalue'), 'String', num2str(h.mi));
        DispImage('axcorr',h.xcorr);
        drawnow
    case 'info'
        helpwin co_reggui;
    case 'close'
        close(gcbf);
end

return

% supplmentary routines

function setDisplayMode() % set display mode for registration
h = get(gcbf,'Userdata');
h.displaymode = get(findobj(gcbf,'Tag','dispmodepopupmenu'),'Value');
switch h.displaymode
    case 1  % Single registered
        DispImage('axreg',h.regimage);
    case 2  % Overlayed images
        alpha=0.8; % transperancy factor
        alternate_time=0.5; % refresh time
        AlternateOverlayed(h.refimage,h.regimage,'axreg',alpha,alternate_time);
    case 3  % Sliceomatic
end
set(gcbf,'UserData',h);
return

% image display function
function DispImage(imTag,x)
set(gcbf,'CurrentAxes',findobj(gcbf,'Tag',imTag));
cla, h=imagesc(x), axis image, colormap('hot'), axis ij, axis off
set(h, 'ButtonDownFcn', ['co_reggui(''Ctrl_' imTag ''');']);
return

% image translation function
function fh=imtranslate2d(f,xoff,yoff)
[h,w]=size(f);
[x,y]=meshgrid([1:1:h],[1:1:w]);
xd=x(:)+xoff; yd=y(:)+yoff;
fh=reshape(bilinear_interpolation(f,xd,yd),w,h)';
return

% image rotation function around the middle of the image
function fh=imrotate2d(f,ang)
[h,w]=size(f);
phi = ang*pi/180; % Convert to radians
vx=[-floor(h/2):ceil(h/2)-1]; % center around the middle
vy=[-floor(w/2):ceil(w/2)-1];



[x,y]=meshgrid(vx,vy);
x=x(:); y=y(:);
xd=x*cos(phi)+y*sin(phi)+floor(h/2)+1;
yd=-x*sin(phi)+y*cos(phi)+floor(w/2)+1;
fh=reshape(bilinear_interpolation(f,xd,yd),w,h)';
return

% image scaling function (exapnsion/shrinking)
function fh=imscale2d(f,Sx,Sy)
[h,w]=size(f);
[x,y]=meshgrid([1:1:h],[1:1:w]);
xd=x(:)*Sx; yd=y(:)*Sy;
fh=reshape(bilinear_interpolation(f,xd,yd),w,h)';
return

% image resampling function
function fh=imresample2d(f,q)
[h,w]=size(f);
% use a binomial filter of order 5 for smoothing
d=[1 4 6 4 1]/16; B=d'*d;
fh=f;
if q==1
    return
elseif q>1 % upsample
    N=round(q);
    y = zeros(N*h,N*w);
    y(1:N:end,1:N:end)=fh;
    fh=conv2(y,B,'same');
elseif (q<1 & q>0) % downsample
    D=round(1/q);
    fh=conv2(fh,B,'same');
    fh=fh(1:D:end,1:D:end);
else
    errordlg('The resampling factor should a positive number!', 'co_reggui Error', 'replace');
end

% perform fast cross-correlation in frequency domain
function c=fxcorr(x,y)
Fsize=size(x)+size(y)-1;
Fx = fft2(rot90(x,2),Fsize(1),Fsize(2));
Fy = fft2(y,Fsize(1),Fsize(2));
c = real(ifft2(Fx .* Fy));
return

% compute the mutual information using the joint histogram
function [mi, histxy]=get_mutualinfo(x,y)
% x, y : the two images,
siz=min([size(x);size(y)]); % if sizes are different
nbits=8; ngray=2^nbits; % assume 256 levels is sufficient approximation!
x=double(uint8(double(x)+1)); y=double(uint8(double(y)+1)); % convert to 8 bits
histxy=zeros(ngray,ngray);

[iM,jM] = meshgrid(1:siz(1),1:siz(2));

indV = (jM(:) - 1) * siz(1) + iM(:);

xV =double(x(indV));
yV = double(y(indV));

ind2V = (yV - 1) * ngray + xV;

for i=1:length(ind2V)
    histxy(ind2V(i)) = histxy(ind2V(i)) + 1;
end

%for i=1:siz(1)
%    for j=1:siz(2)
%        histxy(x(i,j),y(i,j))= histxy(x(i,j),y(i,j))+1;
%    end
%end


histxy=histxy/sum(histxy(:)); % normalize
% compute marginal distributions
histx=sum(histxy,2); histy=sum(histxy,1); % by integrating out the joint
mi=sum(sum(histxy.*log2(histxy./(histx*histy+eps)+eps)));
return

% joint histogram display
function DisplayJHist(jhist)
set(gcbf,'CurrentAxes',findobj(gcbf,'Tag','axjhist'));
set(findobj(gcbf,'Tag','axjhist'),'Box','off');
cla, view(-37.5,30), colormap('hot'), mesh(jhist);
return


% display transparent in a cyclic fashion
function DisplayOverlayed(x,y,imTag,alpha)
% try alphas, or linear combinations...
%mask = ones(size(y));
%mask(find(y<1)) = alpha;
set(gcbf,'CurrentAxes',findobj(gcbf,'Tag',imTag));
sx=size(x); sy=size(y); % linear combination
siz=max([sx;sy]);
xa=zeros(siz); xa(1:sx(1),1:sx(2))=x;
ya=zeros(siz); ya(1:sy(1),1:sy(2))=y;
cla, imagesc(double(xa)+0.75*double(ya), 'ButtonDownFcn', 'co_reggui(''enlargeOverlay'');'), axis image, colormap('hot'), axis ij, axis off
% hold on
% hi=imagesc();
% axis image, colormap('hot'), axis ij, axis off;
%set(hi,'AlphaData',mask);
return

function AlternateOverlayed(x,y,imTag,alpha, atime)
DisplayOverlayed(x,y,imTag,alpha);
% pause(atime);
% DisplayOverlayed(y,x,imTag,alpha);
return   

function x = cropImage(x)
    minCol = 1, minRow = 1;
    [maxCol, maxRow] = size(x);
    rows = find(~max(x'));
    cols = find(~max(x));
    for i=1:length(rows)
        if rows(i) ~= i
            minRow = rows(i-1)+1;
            maxRow = rows(i)-1;
            break;
        end
    end
    for i=1:length(cols)
        if cols(i) ~= i
            minCol = cols(i-1)+1;
            maxCol = cols(i)-1;
            break;
        end
    end
    x = imcrop(x,[minCol, minRow,  maxCol-minCol, maxRow-minRow]);



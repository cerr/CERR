function [planmovie] = dicomrt_playmcdose(MCdose,axis,slice,export)
% dicomrt_playmcdose(MCdose,axis,slice,export)
%
% Create and shows a movie for Monte Carlo 3D dose distribution
% Cumulative segment's contribution along axis 'axis' and for slice 'slice' is shown. 
%
% Axis is a character and refers to the cartesian axis (X,Y,Z)
% 
% Slice refers to the slice where the dose will be shown.
%
% If export is ~=0 the movie will be exported in avi format with name nameof(MCdose).avi
% If export is omitted the movie will not be exported.
%
% MCdose must be a cell array containing dose from segments.
% MCdose is a cell arrays with the following structure
%
%   beam name     3d matrix/segment
%  --------------------------------------
%  | [beam 1] | [1st segment 3dmatrix ] |
%  |          | [1st segment 3dmatrix ] |
%  |          |                         |
%  |          | [nth segment 3dmatrix ] |
%  --------------------------------------
%  |   ...               ...            |
%  --------------------------------------
%  | [beam 2] | [1st segment 3dmatrix ] |
%  |          | [1st segment 3dmatrix ] |
%  |          |                         |
%  |          | [nth segment 3dmatrix ] |
%  --------------------------------------
%
% Example:
%
% [mymovie]=dicomrt_showmcdose(A,'z',5,1)
%
% store in mymovie a multiframe image which display the sum of the dose
% delivered by each beam segment on slice 5 along z axis and export movie
% to file "mymovie.avi".
%
% See also dicomrt_loadmcdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(3,4,nargin))

if nargin<=3 
    export=1;
end

if iscell(MCdose{2,1})~=1 
    error('dicomrt_playmcdose: Dose matrix must contain segment contribution to produce a movie. Exit now!')
end


% Check axis
if ischar(axis) ~=1
    error('dicomrt_playmcdose: Axis is not a character. Exit now!')
elseif axis=='x' | axis=='X'
    dir=1;
elseif axis=='y' | axis=='Y'
    dir=2;
elseif axis=='z' | axis=='Z'
    dir=3;
else
    error('dicomrt_playmcdose: Axis can only be X Y or Z. Exit now!')
end

% Setup plot variable
xmargin=10; % margin from right end ot the image to allow text to be printed in frame
ymargin=3;

% Show segment's dose
figure;
for i=1:size(MCdose{2,1},1); % loop over beam
    for j=1:size(MCdose{2,1}{i,2},2); % loop over segment
        if i==1 & j==1
            totalMCdose=MCdose{2,1}{i,2}{j};
        else
            totalMCdose=totalMCdose+MCdose{2,1}{i,2}{j};
        end
        if dir==1 % X axis      -> YZ image
            imagesc(squeeze(totalMCdose(:,slice,:)));
            xtext=size(totalMCdose,3)-xmargin;
            ytext=size(totalMCdose,1)-ymargin;
        elseif dir==2 % Y axis  -> XZ image
            imagesc(squeeze(totalMCdose(slice,:,:)));
            xtext=size(totalMCdose,3)-xmargin;
            ytext=size(totalMCdose,1)-ymargin;
        else % Z axis           -> XY image
            imagesc(squeeze(totalMCdose(:,:,slice)));
            xtext=size(totalMCdose,2)-xmargin;
            ytext=size(totalMCdose,1)-ymargin;
        end
        title(['Beam: ' int2str(i) ' - segment: ' int2str(j)],'Interpreter','none');
        step=(['b: ' int2str(i) ' s: ' int2str(j)]);
        text(xtext,ytext,step,'Color','white','FontWeight','bold');
        planmovie(:,i)=getframe;
    end % end loop over segments
end %end loop over beams
title([ ]);

% Save movie in avi format
if export ~=0
    movie2avi(planmovie,inputname(1),'fps',8);
    disp('AVI movie exported to local directory');
else
    disp('AVI movie not exported');
end
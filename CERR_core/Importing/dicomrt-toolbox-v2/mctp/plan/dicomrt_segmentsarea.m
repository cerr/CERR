function [areas] = dicomrt_segmentsarea(study,scale)
% dicomrt_segmentsarea(study,scale)
%
% Calculate the area of beam segments.
%
% study is the rtplan dataset
% scale determines if area is calculated at the isocenter (default)
%       or at the MLC plane (~=1). (OPTIONAL)
%
% areas is a cell array with the following structure:
%
%   beam name    beam area        individual segment area
%                  
%  -----------------------------------------------------------
%  | [beam 1] |  beam area   | (area s1 area s2 ... area sm) | 
%  |          |              |                               |
%  -----------------------------------------------------------
%  |               ...                     ...               |                
%  -----------------------------------------------------------
%  | [beam n] |  beam area   | (area s1 area s2 ... area sp) | 
%  |          |              |                               |
%  -----------------------------------------------------------
%%
% Example:
%
% [B]=dicomrt_segmentarea(A)
%
% returns in B the max beam area and the individual segment's area in cm2 calculated at the isocenter
% for each beam of rtplan A
% 
% See also dicomrt_loaddose, dicomrt_loadct, dicomrt_mcwarm, dicomrt_BEAMexport
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(1,2,nargin))
rtplanformc=dicomrt_mcwarm(study);

% WARNING: TMS 6.0 DEFINE BEAM LIMITING DEVICE APERTURES AT THE ISOCENTRE AND NOT
%          AT THE DEVICE'S PLANE. IF THIS DEFAULT WILL CHANGE IN FUTURE SOME MINOR
%          CHANGES TO THIS SCRIPT WILL BE REQUIRED

% Initialize vectos
areas=cell(size(rtplanformc,1),3);

% Varian MMLC-80 and MC parameters 
leaf=(-19.5:1:19.5);
MLCPLANE=50.9;
ISOPLANE=100.0;
ZMIN_JAWS=[28.0;36.7];
ZMAX_JAWS=[35.8;44.5];
Z_min_CM=27.4;

SCALEfactor=1;
LEAFwidth=1;

if exist('scalepar')~=0 
    if scalepar~=0
        SCALEfactor=MLCPLANE/ISOPLANE;
        LEAFwidth=0.5;
    end
end

% Export plan into BEAM00 input files for MC calculation
for i=1:size(rtplanformc,1) % loop over # beams
    areas{i,1}=rtplanformc{i,1};    
    area_temp=0;
    for j=1:size(rtplanformc{i,4},1) % loop over # segments
        % calculate beam area
        beamarea=((rtplanformc{i,3}{j,1}(1)-rtplanformc{i,3}{j,1}(2))*...
            (rtplanformc{i,3}{j,2}(1)-rtplanformc{i,3}{j,2}(2)))*0.01;
        areas{i,2}(j)=beamarea;
        % retrieve MLC settings
        NEG_VARMLM=rtplanformc{i,4}{j,1}(1:40)*0.1*SCALEfactor;
        POS_VARMLM=rtplanformc{i,4}{j,1}(41:80)*0.1*SCALEfactor;
        % calculate segment area
        area_temp=abs(NEG_VARMLM-POS_VARMLM).*LEAFwidth;
        areas{i,3}(j)=sum(area_temp);
    end
end

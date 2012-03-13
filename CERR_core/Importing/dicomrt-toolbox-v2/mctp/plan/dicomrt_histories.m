function [histories] = dicomrt_histories(study)
% dicomrt_histories(study)
%
% Calculate tyhe number of histories per beam and per segment.
%
% study contains the rtplan dataset
%
% histories is a cell array with the following structure:
%
%  --------------------------------------------------------------
%  | [ Total number ]   | BEAM hist SEG 1  | DOSXYZ hist SEG 1  |
%  |     hist BEAM 1    |       ...        |         ...        |
%  |                    | BEAM hist SEG m  | DOSXYZ hist SEG m  |
%  |-------------------------------------------------------------
%  |       ...          |       ...        |         ...        |
%  |-------------------------------------------------------------
%  | [ Total number ]   | BEAM hist SEG 1  | DOSXYZ hist SEG 1  |
%  |     hist BEAM n    |       ...        |         ...        |
%  |                    | BEAM hist SEG p  | DOSXYZ hist SEG p  |
%  |-------------------------------------------------------------
%
% NCASE=dicomrt_histories(A)
%
% return in NCASE a cell array containing the # of histories per beam and per segment
%
% The number of histories/segment to track in BEAM simulation is constant and equal to 60M particles.
% This allows a stat error on photon fluence < 1.5% over a (0.2x0.2)cm2 area at the phsp plane.
% The number of histories/segment to track in DOSXYZ simulation is calculated using 
% the segment's area defined at the isocenter (as calculated by dicomrt_segmentsarea).
%
% See also dicomrt_BEAMexport, dicomrt_DOSXYZexport, dicomrt_mcwarm
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

rtplanformc=dicomrt_mcwarm(study);

% Initialize vectos
histories=cell(size(rtplanformc,1),2);
VOXEL_VOLUME=rtplanformc{1,2}(9);
mu_eff=0.03;        % effective energy absorption coefficient (water)
obj_error=0.015;     % desired error for dose distribution (default +/- 2%)
BEAMhist=60000000;  % number of histories for BEAM simulation: this will produce a phsp file 
                    % with stat error on photon fluence < 1.5% over a (0.2x0.2)cm2 area
                    % This equivalenet to run ~70M particles from original source and create
                    % a particle density of ~300000 particles/cm2 at the phsp file plane.

segmentarea=dicomrt_segmentsarea(study);

for i=1:size(rtplanformc,1)
    for j=1:size(rtplanformc{i,3},1)
        histories{i,2}(j)=BEAMhist;
        if segmentarea{i,3}(j)==960 % leaves are wide open this plan do not use them
                                    % hence use jaws area to calculate # histories
            histories{i,3}(j)=(segmentarea{i,2}(j)./VOXEL_VOLUME)/(mu_eff*obj_error^2);
        else % use segment area
            histories{i,3}(j)=(segmentarea{i,3}(j)./VOXEL_VOLUME)/(mu_eff*obj_error^2); 
        end
    end
    histories{i,1}=sum(histories{i,3});
end
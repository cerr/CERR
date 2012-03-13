function [bsf] = dicomrt_backscatter(rtplanformc)
% dicomrt_backscatter(rtplanformc)
%
% Calculate the effect in the photon output of the backscatter into the monitor chamber.
%
% The backscatter factor "bsf" is a cell array with the following structure:
%
%  ------------------------------
%  | [ BEAM 1 ]   | bsf  SEG 1  |
%  |              |    ...      |
%  |              | bsf  SEG n  |
%  |-----------------------------
%  |       ...    |    ...      |
%  |-----------------------------
%  | [ BEAM n ]   | bsf  SEG 1  |
%  |              |    ...      |
%  |              | bsf  SEG n  |
%  |-----------------------------
%
% rtplanformc is a cell array with the following structure
%
%   beam name   common beam            primary collimator position         MLC and MU
%                  data
%  ---------------------------------------------------------------------------------------------------
%  | [beam 1] |gantry angle    | [jawsx 1st segment] [jawsy 1st segment]| [mlc 1st segment] [diff MU]|
%  |          |coll angle      |----------------------------------------------------------------------
%  |          |iso position (3)| [jawsx 2nd segment] [jawsy 2nd segment]| [mlc 2nd segment] [diff MU]|
%  |          |StBLD dist   (3)|----------------------------------------------------------------------
%  |          |voxel dim       |                   ...                  |             ...            |
%  |          |patient position|---------------------------------------------------------------------- 
%  |          |                | [jawsx nth segment] [jawsy nth segment]| [mlc nth segment] [diff MU]|
%  ---------------------------------------------------------------------------------------------------
%  |               ...                                    ...                                ...               
%  ---------------------------------------------------------------------------------------------------
%  | [beam n] |gantry angle    | [jawsx 1st segment] [jawsy 1st segment]| [mlc 1st segment] [diff MU]|
%  |          |coll angle      |----------------------------------------------------------------------
%  |          |iso position (3)| [jawsx 2nd segment] [jawsy 2nd segment]| [mlc 2nd segment] [diff MU]|
%  |          |StBLD dist   (3)|----------------------------------------------------------------------
%  |          |voxel dim       |                   ...                  |             ...            |
%  |          |patient position|---------------------------------------------------------------------- 
%  |          |                | [jawsx nth segment] [jawsy nth segment]| [mlc nth segment] [diff MU]|
%  ---------------------------------------------------------------------------------------------------
%
% There are several papers in the litterature about models for backscatter into monitor chambers.
% A short list is reported below:
% 1) Lam et al Med Phys 25 (3) 334-338 1998
% 2) Liu et al Med Phys 27 (4) 737-744 2000
% 3) Verhaegen et al Phys Med Biol 45 3159-3170 2000
%
% See also p. R140 from Ahnesjo and Aspradakis Phys Med Biol 44 R99-R155 for a more complete reference
%
% The effect of the backscatter in the photon output factor for a Varian Clinac 2100 6MV machine 
% is of about 3% max over a range of field sizes going from 4x4cm2 to 40x40cm2.
% For field sizes ranging from 4x4cm2 to 10x10cm2 (which more likely the situation encountered in IMRT)
% the effect of the backscatter in the photon output is reduced to the order of 0.5%.
% Nonetheless it is a factor which is worth to account for.
%
% In this mfile the polynomial model from Liu et al (2000) is implemented.
% The backscatter factor is modelled as a composite effect of the X and Y jaws.
% The model works with symmetric as well as asymmetric fields.
% The backscatter effect of the MLC on the total photon output factor is/(can be) neglected.
% Errors in bsf are not calculated.
%
%----------------------------------------------------------------------------------
% Liu et al 2000 formulas are implemented with following formalism:
%----------------------------------------------------------------------------------
% R(x1,x2,y1,y2) = Rx(x1,x2,y1,y2) + Ry(x1,x2,y1,y2)
%                = Rx(x1,x2,y1,y2) + Ry(y1,y2)
%                = Rx(x1,x2,y1,y2) + Ry1(y1) + Ry2(y2)
%
% Ry(y) = rcy1 + rcy2*y + rcy3*y^3
%
% Rx(x1,x2,y1,y2) = Rx(x1,x2,y1=y2=20)*Py(y1,y2)
%                 = [Rx1(x1,y1=y2=20) + Rx2(x2,y1=y2=20)] * [Py1(y1) + Py2(y2)]
%
% Rx(x) = rxc1 + rxc2*x
%
% Py(y) = pyc1*y + pyc2*y^3
%
% NOTE: x and y are vectors. Therefore every of the factors above will have to be
%       calculated for each of the vector components.
%----------------------------------------------------------------------------------
%
% NOTE: since field dimensions usually don't change within a single IMRT beam one should expect
% the bsf per segment to be the same within each beam. However this algorithm will also detect 
% and account for changes in beam dimensions within each IMRT beam.
%
% See also dicomrt_BEAMexport, dicomrt_DOSXYZexport, dicomrt_mcwarm, dicomrt_histories, dicomrt_loadmcdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Initialize vectos
bsf=cell(size(rtplanformc,1),2);

% Coefficients for polynomial fitting (from Liu et al 2000)
ryc1=1.54;
ryc2=-8.45e-2;
ryc3=4.47e-5;
rxc1=0.4;
rxc2=-1.87e-2;
pyc1=3.95e-2;
pyc2=-3.55e-5;

sbx0y0=1+0.0248; % reference field: x=[5,5] y=[5,5]
                 %
                 % sbx0y0 = 1 + R(x0,y0) = 1 + R(10,10)
                 %

% WARNING: TMS 6.0 DEFINE BEAM LIMITING DEVICE APERTURES AT THE ISOCENTRE AND NOT
%          AT THE DEVICE'S PLANE. IF THIS DEFAULT WILL CHANGE IN FUTURE SOME MINOR
%          CHANGES TO THIS SCRIPT WILL BE REQUIRED

for i=1:size(rtplanformc,1) % loop over # beams
    bsf{i,1}=rtplanformc{i,1};
    %reset local variables (cumulative segment AREA and cumulative MU)
    total_mu=0;
    min_xjaws=0;
    max_xjaws=0;
    min_yjaws=0;
    max_yjaws=0;
    beam_maxarea=0;
    temp=0;
    for j=1:size(rtplanformc{i,3},1) % loop over segments
        
        x=rtplanformc{i,3}{j,1}/10; % dicomrt is in mm!
        y=rtplanformc{i,3}{j,2}/10;
        
        ry1=ryc1+ryc2*y(1)+ryc3*y(1)^3; 
        ry2=ryc1+ryc2*y(2)+ryc3*y(2)^3;
        rx1=rxc1+rxc2*x(1);
        rx2=rxc1+rxc2*x(2);
        py1=pyc1*y(1)+pyc2*y(1)^3;
        py2=pyc1*y(2)+pyc2*y(2)^3;
        
        ry=ry1+ry2;
        rx=(rx1+rx2)*(py1+py2);
        r=(ry+rx)/100; 
        
        sbxy=1+r;
        
        bsf{i,2}{j}=sbx0y0/sbxy; % relative change of photon output 
        
    end
end % calculation of bsf completed
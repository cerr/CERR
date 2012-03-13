function [celldose] = dicomrt_doseconversion(study,filename,int)
% dicomrt_doseconversion(study,filename,int)
%
% Convert dose to medium in dose to water and vice versa (dose2medium <-> dose2water).
% Based on original C code by Frank Verhaegen (ICR, October 2000) and on paper from 
% Siebers et al 2000, Phys. Med. Biol.45 983-995.
%
% Study contains the 3D dose matrix (TPS or MC form).
% Filename is the name of the file which contain the egs4phantom (no ext.).
%
% Int is interactive option. If int ~=1 or if int is not given session is not interactive
% and default parameters (e.g. directories names) will be used. If int = 1 the user will 
% be asked to set some parameters.
% Parameters for this specific m file are:
%
% convtype = 0           dose2medium  -> dose2water
% patient_position = 1   HFS
% nomE = 6               Beam nominal energy (MV)
%
% Convtype determines conversion type:
%    convtype = 0 dose2medium  -> dose2water   (default)
%    convtype = 1 dose2water   -> dose2medium
% 
% Example:
%
% [A]=dicomrt_doseconversion(mcdose,'demo')
%
% will store in A the original dose "mcdose" converted using material information from phantom "demo.egs4phant";
% The egs4phantom is required when converting dose2medium <-> dose2water conversion.
% Since this is not an interactive session convtype = 0, patient_position = 1 and nomE = 6.
%
% See also dicomrt_ctcreate, dicomrt_loadose, dicomrt_loadmcdose, dicomrt_addmcdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(2,4,nargin))

if nargin<=2
    int=0;
end

% Check case and set-up some parameters and variables
[study,type_dose,label]=dicomrt_checkinput(study,1);
rawdose=dicomrt_varfilter(study);


% Check filename: it cannot be a variable
if ischar(filename)~=1, error('dicomrt_doseconversion: Second arguments must be a character string. Exit now!'); end

% Set defaults
if int == 0
    patient_position=1;
    convtype=0;
    NomE=6;
else
    patient_position = input('Input the patient position code [default=1]: '); 
    if isempty(patient_position)==1
        patient_position=1;
    end
    NomE = input('Input beam nominal energy [default=6MV]: '); 
    if isempty(NomE)==1
        NomE=6;
    end
    disp('Input conversion type (0-dose2medium -> dose2water  (default))');
    disp('                      (1-dose2water  -> dose2medium          )');
    convtype = input('Conversion type :'); 
    if isempty(convtype)==1 | convtype~=0 | convtype~=1
        convtype=0;
    end
end

% Set default parameters

% Define defalut media
DefMedia=char('H2O521ICRU',         ...
              'AIR521ICRU',         ...
              'AL521ICRU',          ...
              'CERROBEND521ICRU',   ...
              'CU521ICRU',          ...
              'ICRPBONE521ICRU',    ...
              'ICRUTISSUE521ICRU',  ...
              'LUNG521ICRU',        ...
              'ALDERSONLUNG521ICRU', ...
              'ALDERSONMUSCLE-A521ICRU', ...
              'ALDERSONMUSCLE-B521ICRU', ...
              'H2O700ICRU',         ...
              'AIR700ICRU',         ...
              'AL700ICRU',          ...
              'CERROBEND700ICRU',   ...
              'CU700ICRU',          ...
              'ICRPBONE700ICRU',    ...
              'ICRUTISSUE700ICRU',  ...
              'LUNG700ICRU',         ...
              'ALDERSONLUNG700ICRU', ...
              'ALDERSONMUSCLE-A700ICRU', ...
              'ALDERSONMUSCLE-B700ICRU');

% Assigning mass densities to default media
NomDensity(1)=1.000;	%Water
NomDensity(2)=0.00120;	%Air
NomDensity(3)=2.702;	%Al
NomDensity(4)=9.760;	%Cerrobend
NomDensity(5)=8.933;	%Cu
NomDensity(6)=1.850;	%ICRPbone
NomDensity(7)=1.000;	%ICRUtissue
NomDensity(8)=0.260;	%Lung
NomDensity(9)=0.260;	%ALDERSONLUNG
NomDensity(10)=1.000;	%ALDERSONMUSCLE-A
NomDensity(11)=1.000;	%ALDERSONMUSCLE-B

% Assigning water-to-medium stopping power conversion factors ...
StP_wmed(1)=1.000;	    %Water
StP_wmed(2)=1.079;	    %Air
StP_wmed(3)=1.000;	    %Al
StP_wmed(4)=1.000;	    %Cerrobend
StP_wmed(5)=1.000;	    %Cu
StP_wmed(6)=1.114;	    %ICRPbone
StP_wmed(7)=1.010;	    %ICRUtissue
StP_wmed(8)=0.995;	    %Lung
StP_wmed(9)=0.995;	    %ALDERSONLUNG
StP_wmed(10)=1.010;	    %ALDERSONMUSCLE-A
StP_wmed(11)=1.010;	    %ALDERSONMUSCLE-B


% ... replaced by fitting versus nominal energy
StP_wmed(1)=1.000;	                                            %Water
StP_wmed(2)=3.774207e-5*NomE*NomE-3.634494e-3*NomE+1.136325;	%Air
StP_wmed(3)=1.000;	                                            %Al
StP_wmed(4)=1.000;	                                            %Cerrobend
StP_wmed(5)=1.000;	                                            %Cu
StP_wmed(6)=-4.827607e-4*NomE+1.118848;	                        %ICRPbone
StP_wmed(7)=1.010;	                                            %ICRUtissue
StP_wmed(8)=3.801603e-5*NomE*NomE-2.136921e-3*NomE+1.010577;	%Lung
StP_wmed(9)=3.801603e-5*NomE*NomE-2.136921e-3*NomE+1.010577;	%ALDERSONLUNG
StP_wmed(10)=1.010;	                                            %ALDERSONMUSCLE-A
StP_wmed(11)=1.010;	                                            %ALDERSONMUSCLE-B


% Import egs4phantom data
[media,density,medname] = dicomrt_readegs4phant(patient_position,filename);

% Match egs4phantom materials with default 
for i=1:size(medname,1)
    Med(i)=strmatch(medname(i),DefMedia);
    if isempty(Med(i)) == 1
        error('dicomrt_doseconversion: Material used in egs4phantom is not recognised. Exit now !'); 
    elseif Med(i) >= size(DefMedia,1)./2 % handle case when *700* materials are used in egs4phant
        Med(i)=Med(i)-size(DefMedia,1)./2;
    end
end

% Convert dose
dose=zeros(size(rawdose));
if convtype == 0; % dose2medium  -> dose2water (default)
    dose(:,:,:)=rawdose(:,:,:).*StP_wmed(Med(media(:,:,:)));
else              % dose2water   -> dose2medium
    dose(:,:,:)=rawdose(:,:,:)./StP_wmed(Med(media(:,:,:)));
end

% Log option
log=0;
if log==1
    squeeze(media(63,:,25))'
    Med(media(63,:,25))'
    StP_wmed(Med(media(63,:,25)))'
end

% Returns converted dose in the same format (i.e. cell)
[celldose]=dicomrt_restorevarformat(study,dose);
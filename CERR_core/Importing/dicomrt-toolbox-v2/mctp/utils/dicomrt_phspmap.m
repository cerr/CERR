function [FLvsP,EFLvsP,FL_CAX,E_CAX,ME,xbound,ybound,xgrid,ygrid]=dicomrt_phspmap(phspfile,xmin,xmax,ymin,ymax,xspacing,yspacing,flutype,logopt,ptype,npart)
% dicomrt_phspmap(phspfile,xmin,xmax,ymin,ymax,xspacing,yspacing,flutype,logopt,ptype,npart)
% 
% Analyze and create fluence maps in phase space files.
%
% phspfile  name of the phase space file
% xmin      ROI's xmin
% xmax      ROI's xmax
% ymin      ROI's ymin
% ymax      ROI's ymax
% xspacing  ROI's x resolution
% yspacing  ROI's y resolution
% flutype   switch between estimate of real fluence (~=0) of planar fluence (=0)
% logopt    OPTIONAL parameter to export a text file containing particles' information
% ptype     OPTIONAL particle type to list (0=photons, 1=electrons, 2=all, 3=positions, default=2)
% npart     OPTIONAL number of particles to read for logfile export (default to 100 when logopt in on)
%
% This function return 6D arrays/vectors. Photons' quantities are stored in the first dimension 
% (e.g. FLvsP(:,:,1)) electrons' in the second dimension (e.g. FLvsP(:,:,2)) and
% positrons' in the third dimension (e.g. FLvsP(:,:,3)). Standard deviations are stored 
% are stored in the subsequent vectors in the same order. 
% See C.-M. Ma and D.W.O. Rogers "BEAMDP as a General-Purpose Utility" NRCC Report PIRS-0509(E)
% for analysis of statistical uncertainties.
%
% This is list of some useful variables used and retuned by this function:
% 
% used:
% 
% phspmode      phsp file mode
% npphsp        number of particles in phsp file
% nphotphsp     number of photons in phsp file
% ekmaxphsp     max kinetic energy of particles stored in phsp file
% ekminphsp     minimum electron kinetic energy
% nincphsp      total number of particles incident from original source
% npass         number of times the particle has crossed the scoring plane (not used in this version)
%
% returned:
%
% FLvsP         fluence vs position (Fluence/cm2/incident particle)
% EFLvsP        energy fluence vs position (Energy Fluence/cm2/incident particle/MeV)
% FL_CAX        fluence (Fluence/cm2/incident particle) on a circular area (1cm2) around the central axis (CAX)
% E_CAX         energy on a circular area (1cm2) around the central axis (CAX)
% ME            mean energy of particles within ROI
% xbound        x-boundaries of the grid used for phsp mapping 
% ybound        y-boundaries of the grid used for phsp mapping 
% xgrid         centres of the boundaries in xbound (to use with dicomrt_plotfluence)
% ygrid         centres of the boundaries in ybound (to use with dicomrt_plotfluence)
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(8,11,nargin))

% 0) Set parameters
latchi='00000000000000000000000000000000'; % char form of 32 bit variable
npass=1;
count=0;
nphotons=0;
nelectrons=0;
npositrons=0;
nphotons_cax=0;
nelectrons_cax=0;
npositrons_cax=0;

% 0a) set variables/array dimensions
xdim=round((xmax-xmin)./xspacing);
ydim=round((ymax-ymin)./yspacing);
if xdim<=0 | ydim <=0
    error('dicomrt_phspmap: Error porcessing xmin, xmax, ymin, ymax, xbound or ybound. Exit now!');
end
FLvsP=zeros(ydim,xdim,6);       % slice 1(4) for photons (error)
EFLvsP=zeros(ydim,xdim,6);      % slice 2(5) for e- (error)
                                % slice 3(6) for e+ (error)
FL_CAX=zeros(1,6);
E_CAX=zeros(1,6);
ME=zeros(1,6);

% 0b) set boundaries and grid
xbound=[xmin:xspacing:xmax];
ybound=[ymin:yspacing:ymax];
xgrid=[xmin+xspacing./2:xspacing:xmax-xspacing./2];
ygrid=[ymin+yspacing./2:yspacing:ymax-yspacing./2];

% 1) process data file
% 1a) open file
fid=fopen(phspfile,'r');
% 1b) Read file header
phspmode_bin=fread(fid,5,'char');
phspmode=char(phspmode_bin)';
npphsp=fread(fid,1,'ulong');
nphotphsp=fread(fid,1,'ulong');
ekmaxphsp=fread(fid,1,'float');
ekminphsp=fread(fid,1,'float');
nincphsp=fread(fid,1,'float');

% 1c) Jump to first record 
if phspmode=='MODE2';
    fseek(fid,32,-1);
elseif phspmode=='MODE0';
    fseek(fid,28,-1);
else
    fclose(fid);
    error('dicomrt_phspmap: Mode not recognized/supported. Exit now!');
end

% set number of particles to get
if (exist('logopt')==1 & logopt~=0) 
    if exist('npart')~=1
        npart=100;
    end
    if exist('ptype')~=1
        ptype=2;
    end
end

% Export to file (log/debug)
if exist('logopt')==1 & logopt~=0;
    % 1d) Read phsp records and calculate quantities of interest
    disp('(+) Reading phsp file records and calculating');
    %h = waitbar(0,'Reading/calculation progress');
    %set(h,'Name','dicomrt_phspmap: analyze phase space files');
    time=fix(clock);
    log=fopen([phspfile,'_log.txt'],'a+');
    fprintf(log,['This is a dicomrt_phspmap log file']);
    fprintf(log,'\n');
    fprintf(log,['Session started: ',date,', ']);
    fprintf(log,'%2i',time(4));fprintf(log,'%c',':');fprintf(log,'%2i',time(5));
    fprintf(log,' \n');
    fprintf(log,['Particle type: ',num2str(ptype),' (0=photons, 1=electrons, 2=all, 3=positrons)']);
    fprintf(log,'\n');
    fprintf(log,['Number of particles listed in this session: ',num2str(npart)]);
    fprintf(log,'\n');
    fprintf(log,'%s\t','ENERGY', 'IQ', 'X', 'Y', 'U', 'V', 'W', 'ZLAST', 'WEIGHT', 'LATCH(1:32)');
    fprintf(log,'\n');
    for i=1:npart
        if phspmode=='MODE2';
            latch=fread(fid,1,'int32');
            latch_bin=fliplr(dec2bin(latch));
            latchi(1:length(latch_bin))=latch_bin;
            totalenergy=fread(fid,1,'float');
            xpos=fread(fid,1,'float');
            ypos=fread(fid,1,'float');
            udir=fread(fid,1,'float');
            vdir=fread(fid,1,'float');
            weight=fread(fid,1,'float'); % see section 3)
            zlast=fread(fid,1,'float');       
        elseif phspmode=='MODE0';
            latch=fread(fid,1,'int32');
            latch_bin=fliplr(dec2bin(latch));
            latchi(1:length(latch_bin))=latch_bin;
            totalenergy=fread(fid,1,'float');
            xpos=fread(fid,1,'float');
            ypos=fread(fid,1,'float');
            udir=fread(fid,1,'float');
            vdir=fread(fid,1,'float');
            weight=fread(fid,1,'float'); % see section 3)
            zlast=nan;
        end
        % check particle type
        % 1d1) get npass
        if latchi(32)==1
            npass=npass+1;
        end
        % 1d2) get particle charge
        if round(latch/2^31)==1;
            charge=-1;
            energy=totalenergy-0.5110034;
        elseif round(latch/2^30)==1;
            charge=1;
            energy=totalenergy-0.5110034;
        else round(latch/2^30)==0;
            charge=0;
            energy=totalenergy;
        end
        % 1d3) get particle W (direction cosine along Z) and its sign (carried by weight)
        wdir=min( 1., udir^2 + vdir^2); 
        wdir=sqrt(1. - wdir);
        wdir=sign(weight)*wdir; % transfers sign of WT to W
        weight=abs(weight); % weight is never negative
        % Use estimate of real fluence or planar fluence
        if flutype~=0 % use estimate of real fluence
            weight=weight/max(0.08716,abs(wdir));
        end
        if ptype==2
            fprintf(log,'%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%s',...
                [energy charge xpos ypos udir vdir wdir zlast weight],latchi);
            fprintf(log,'\n');
        elseif ptype==0 & charge==0
            fprintf(log,'%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%s',...
                [energy charge xpos ypos udir vdir wdir zlast weight],latchi);
            fprintf(log,'\n');
        elseif ptype==1 & charge==-1
            fprintf(log,'%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%s',...
                [energy charge xpos ypos udir vdir wdir zlast weight],latchi);
            fprintf(log,'\n');
        elseif ptype==3 & charge==1
            fprintf(log,'%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%6.4f\t%s',...
                [energy charge xpos ypos udir vdir wdir zlast weight],latchi);
            fprintf(log,'\n');
        end
        %waitbar(i/npart,h);
    end
    fclose(log);
    %close(h);
    disp('(=) Completed');
    disp( ' ');
    disp( '    -----------------------dicomrt_phspmap report-----------------------');
    disp( '(*) PHSP file info: ');
    disp(['    Total number of particles in phase space file: ',num2str(npphsp)]);
    disp(['    Total number of photons in phase space file:   ',num2str(nphotphsp)]);
    disp(['    Max kinetic energy (MeV):                      ',num2str(ekmaxphsp)]);
    disp(['    Min energy for electrons (MeV):                ',num2str(ekminphsp)]);
else
    % 1d) Read phsp records and calculate quantities of interest
    disp('(+) Reading phsp file records and calculating');
    %h = waitbar(0,'Reading/calculation progress');
    %set(h,'Name','dicomrt_phspmap: analyze phase space files');
    for i=1:npphsp
        if phspmode=='MODE2';
            latch=fread(fid,1,'int32');
            latch_bin=fliplr(dec2bin(latch));
            latchi(1:length(latch_bin))=latch_bin;
            totalenergy=fread(fid,1,'float');
            xpos=fread(fid,1,'float');
            ypos=fread(fid,1,'float');
            udir=fread(fid,1,'float');
            vdir=fread(fid,1,'float');
            weight=fread(fid,1,'float'); % see section 3)
            zlast=fread(fid,1,'float');       
        elseif phspmode=='MODE0';
            latch=fread(fid,1,'int32');
            latch_bin=fliplr(dec2bin(latch));
            latchi(1:length(latch_bin))=latch_bin;
            totalenergy=fread(fid,1,'float');
            xpos=fread(fid,1,'float');
            ypos=fread(fid,1,'float');
            udir=fread(fid,1,'float');
            vdir=fread(fid,1,'float');
            weight=fread(fid,1,'float'); % see section 3)
            zlast=nan;
        end
        % check particle type
        % 1d1) get npass
        if latchi(32)==1
            npass=npass+1;
        end
        % 1d2) get particle charge
        if round(latch/2^31)==1;
            charge=-1;
            energy=totalenergy-0.5110034;
        elseif round(latch/2^30)==1;
            charge=1;
            energy=totalenergy-0.5110034;
        else round(latch/2^30)==0;
            charge=0;
            energy=totalenergy;
        end
        % 1d3) get particle W (direction cosine along Z) and its sign (carried by weight)
        wdir=min( 1., udir^2 + vdir^2); 
        wdir=sqrt(1. - wdir);
        wdir=sign(weight)*wdir; % transfers sign of WT to W
        weight=abs(weight); % weight is never negative
        % Use estimate of real fluence or planar fluence
        if flutype~=0 % use estimate of real fluence
            weight=weight/max(0.08716,abs(wdir));
        end
        
        % Find spatial location of every particle in phsp plane
        xlocation=find(xbound>xpos);    
        if isempty(xlocation)~=1 & xbound(1)<xpos
            xlocation=xlocation(1);
        else
            xlocation=[];
        end
        ylocation=find(ybound>ypos);
        if isempty(ylocation)~=1 & ybound(1)<ypos
            ylocation=ylocation(1);
        else
            ylocation=[];
        end
        % Update arrays maps
        if isempty(xlocation)~=1 & isempty(ylocation)~=1
            if charge==0
                FLvsP(ylocation-1,xlocation-1,1)=FLvsP(ylocation-1,xlocation-1,1)+weight;
                FLvsP(ylocation-1,xlocation-1,4)=FLvsP(ylocation-1,xlocation-1,4)+weight^2;
                EFLvsP(ylocation-1,xlocation-1,1)=EFLvsP(ylocation-1,xlocation-1,1)+weight*energy;
                EFLvsP(ylocation-1,xlocation-1,4)=EFLvsP(ylocation-1,xlocation-1,4)+(weight*energy)^2;
                if sqrt(xpos.^2+ypos.^2)<=1
                    FL_CAX(1,1)=FL_CAX(1,1)+weight;
                    FL_CAX(1,4)=FL_CAX(1,4)+weight^2;
                    E_CAX(1)=E_CAX(1)+energy;
                    E_CAX(4)=E_CAX(4)+energy^2;
                    nphotons_cax=nphotons_cax+1;
                end
                nphotons=nphotons+1;
                ME(1)=ME(1)+energy;
                ME(4)=ME(4)+energy^2;
            elseif charge==-1
                FLvsP(ylocation-1,xlocation-1,2)=FLvsP(ylocation-1,xlocation-1,2)+weight;
                FLvsP(ylocation-1,xlocation-1,5)=FLvsP(ylocation-1,xlocation-1,5)+weight^2;
                EFLvsP(ylocation-1,xlocation-1,2)=EFLvsP(ylocation-1,xlocation-1,2)+weight*energy;
                EFLvsP(ylocation-1,xlocation-1,5)=EFLvsP(ylocation-1,xlocation-1,5)+(weight*energy)^2;
                if sqrt(xpos.^2+ypos.^2)<=1
                    FL_CAX(1,2)=FL_CAX(1,2)+weight;
                    FL_CAX(1,5)=FL_CAX(1,5)+weight^2;
                    E_CAX(2)=E_CAX(2)+energy;
                    E_CAX(5)=E_CAX(5)+energy^2;
                    nelectrons_cax=nelectrons_cax+1;
                end
                nelectrons=nelectrons+1;
                ME(2)=ME(2)+energy;
                ME(5)=ME(5)+energy^2;
            elseif charge==1
                FLvsP(ylocation-1,xlocation-1,3)=FLvsP(ylocation-1,xlocation-1,3)+weight;
                FLvsP(ylocation-1,xlocation-1,6)=FLvsP(ylocation-1,xlocation-1,6)+weight^2;
                EFLvsP(ylocation-1,xlocation-1,3)=EFLvsP(ylocation-1,xlocation-1,3)+weight*energy;
                EFLvsP(ylocation-1,xlocation-1,6)=EFLvsP(ylocation-1,xlocation-1,6)+(weight*energy)^2;
                if sqrt(xpos.^2+ypos.^2)<=1
                    FL_CAX(1,3)=FL_CAX(1,3)+weight;
                    FL_CAX(1,6)=FL_CAX(1,6)+weight^2;
                    E_CAX(3)=E_CAX(3)+energy;
                    E_CAX(6)=E_CAX(6)+energy^2;
                    npositrons_cax=npositrons_cax+1;
                end
                npositrons=npositrons+1;
                ME(3)=ME(3)+energy;
                ME(6)=ME(6)+energy^2;
            end
        end
        %waitbar(i/npphsp,h);
    end % phsp file read
    %close(h);
    % Post processing data
    disp('(+) Post-processing data');
    % Calculation of errors
    FLvsP(:,:,4)=sqrt(npphsp/(npphsp-1).*(FLvsP(:,:,4)-FLvsP(:,:,1).^2./npphsp));
    FLvsP(:,:,5)=sqrt(npphsp/(npphsp-1).*(FLvsP(:,:,5)-FLvsP(:,:,2).^2./npphsp));
    FLvsP(:,:,6)=sqrt(npphsp/(npphsp-1).*(FLvsP(:,:,6)-FLvsP(:,:,3).^2./npphsp));
    EFLvsP(:,:,4)=sqrt(npphsp/(npphsp-1).*(EFLvsP(:,:,4)-EFLvsP(:,:,1).^2./npphsp));
    EFLvsP(:,:,5)=sqrt(npphsp/(npphsp-1).*(EFLvsP(:,:,5)-EFLvsP(:,:,2).^2./npphsp));
    EFLvsP(:,:,6)=sqrt(npphsp/(npphsp-1).*(EFLvsP(:,:,6)-EFLvsP(:,:,3).^2./npphsp));

    FL_CAX(1,6)=sqrt(npositrons_cax/(npositrons_cax-1).*(FL_CAX(1,6)-FL_CAX(1,3).^2./npositrons_cax));
    
    % Data normalization
    FLvsP=FLvsP/(nincphsp*xspacing*yspacing);
    EFLvsP=EFLvsP/(nincphsp*xspacing*yspacing);
        
    ME(1)=ME(1)./nphotons;
    ME(2)=ME(2)./nelectrons;
    ME(3)=ME(3)./npositrons;
    ME(4)=sqrt(nphotons/(nphotons-1).*(ME(4)-ME(1).^2./nphotons))./nphotons;
    ME(5)=sqrt(nelectrons/(nelectrons-1).*(ME(5)-ME(2).^2./nelectrons))./nelectrons;
    ME(6)=sqrt(npositrons/(npositrons-1).*(ME(6)-ME(3).^2./npositrons))./npositrons;
    
    if nphotons_cax~=0 & nphotons_cax~=1
        FL_CAX(1,4)=sqrt(nphotons_cax/(nphotons_cax-1).*(FL_CAX(1,4)-FL_CAX(1,1).^2./nphotons_cax));
        FL_CAX(1,1)=FL_CAX(1,1)/nphotons_cax;
        E_CAX(4)=sqrt(nphotons_cax/(nphotons_cax-1).*(E_CAX(4)-E_CAX(1).^2./nphotons_cax));
        E_CAX(1)=E_CAX(1)/(nphotons_cax);
        E_CAX(4)=E_CAX(4)/(nphotons_cax);
    elseif nphotons_cax==1
        FL_CAX(1,4)=sqrt((FL_CAX(1,4)-FL_CAX(1,1).^2./nphotons_cax));
        FL_CAX(1,1)=FL_CAX(1,1)/nphotons_cax;
        E_CAX(4)=sqrt((E_CAX(4)-E_CAX(1).^2./nphotons_cax));
        E_CAX(1)=E_CAX(1)/(nphotons_cax);
        E_CAX(4)=E_CAX(4)/(nphotons_cax);
    else
        disp('No photons were found in a circle area of 1cm2 around the central axis');
    end
    if nelectrons_cax~=0 & nelectrons_cax~=1
        FL_CAX(1,5)=sqrt(nelectrons_cax/(nelectrons_cax-1).*(FL_CAX(1,5)-FL_CAX(1,2).^2./nelectrons_cax));
        FL_CAX(1,2)=FL_CAX(1,2)/nphotons_cax;
        E_CAX(5)=sqrt(nelectrons_cax/(nelectrons_cax-1).*(E_CAX(5)-E_CAX(2).^2./nelectrons_cax));
        E_CAX(2)=E_CAX(2)/(nelectrons_cax);
        E_CAX(5)=E_CAX(5)/(nelectrons_cax);
    elseif nelectrons_cax==1
        FL_CAX(1,5)=sqrt((FL_CAX(1,5)-FL_CAX(1,2).^2./nelectrons_cax));
        FL_CAX(1,2)=FL_CAX(1,2)/nphotons_cax;
        E_CAX(5)=sqrt((E_CAX(5)-E_CAX(2).^2./nelectrons_cax));
        E_CAX(2)=E_CAX(2)/(nelectrons_cax);
        E_CAX(5)=E_CAX(5)/(nelectrons_cax);
    else
        disp('No electrons were found in a circle area of 1cm2 around the central axis');
    end
    if npositrons_cax~=0 & npositrons_cax~=1
        FL_CAX(1,6)=sqrt(npositrons_cax/(npositrons_cax-1).*(FL_CAX(1,6)-FL_CAX(1,3).^2./npositrons_cax));
        FL_CAX(1,3)=FL_CAX(1,3)/npositrons_cax;
        E_CAX(6)=sqrt(npositrons_cax/(npositrons_cax-1).*(E_CAX(6)-E_CAX(3).^2./npositrons_cax));
        E_CAX(3)=E_CAX(3)/(npositrons_cax);
        E_CAX(6)=E_CAX(6)/(npositrons_cax);
    elseif npositrons_cax==1
        FL_CAX(1,6)=sqrt((FL_CAX(1,6)-FL_CAX(1,3).^2./npositrons_cax));
        FL_CAX(1,3)=FL_CAX(1,3)/npositrons_cax;
        E_CAX(6)=sqrt((E_CAX(6)-E_CAX(3).^2./npositrons_cax));
        E_CAX(3)=E_CAX(3)/(npositrons_cax);
        E_CAX(6)=E_CAX(6)/(npositrons_cax);
    else
        disp('No positrons were found in a circle area of 1cm2 around the central axis');
    end    
    disp('(=) Completed');
    disp( ' ');
    disp( '    -----------------------dicomrt_phspmap report-----------------------');
    disp( '(*) PHSP file info: ');
    disp(['    Total number of particles in phase space file: ',num2str(npphsp)]);
    disp(['    Total number of photons in phase space file:   ',num2str(nphotphsp)]);
    disp(['    Total number of particles from orig. source:   ',nincphsp]);
    disp(['    Max kinetic energy (MeV):                      ',num2str(ekmaxphsp)]);
    disp(['    Min energy for electrons (MeV):                ',num2str(ekminphsp)]);
    disp( '(*) ROI statistics: ');
    disp(['    Total number of photons:                       ',num2str(nphotons)]);
    disp(['    Total number of electrons:                     ',num2str(nelectrons)]);
    disp(['    Total number of positrons:                     ',num2str(npositrons)]);
    disp(['    Photons average kinetic energy (MeV):          ',num2str(ME(1)),' +/- ',num2str(ME(4)/ME(1)*100),' %']);
    disp(['    Electrons average kinetic energy (MeV):        ',num2str(ME(2)),' +/- ',num2str(ME(5)/ME(2)*100),' %']);
    disp(['    Positrons average kinetic energy (MeV):        ',num2str(ME(3)),' +/- ',num2str(ME(6)/ME(3)*100),' %']);
end

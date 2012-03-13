function plotsegments = dicomrt_plotsegments(study)
% dicomrt_plotsegments(study)
%
% Plot segments for plan which have been warmed by dicomrt_mcwarm and stored in rtplanformc.
%
% Example:
%
% dicomrt_plotsegments(A)
%
% if A is the rtplan study for a plan with 3 beams and 1 segment for 1st beam, 2 segments
% for 2nd beam and 3 segments for 3rd beam the command will produce windows with the plots:
% 
% window 1: A_b1s1, 
% window 2: A_b2s1, A_b2s2, 
% window 3: A_b3s1, A_b3s2, A_b3s3
%
% See also dicomrt_loaddose, dicomrt_loadct, dicomrt_BEAMexport
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check cases
[study_temp]=dicomrt_checkinput(study);
rtplanformc=dicomrt_mcwarm(study_temp);

% WARNING: TMS 6.0 DEFINE BEAM LIMITING DEVICE APERTURES AT THE ISOCENTRE AND NOT
%          AT THE DEVICE'S PLANE. IF THIS DEFAULT WILL CHANGE IN FUTURE SOME MINOR
%          CHANGES TO THIS SCRIPT WILL BE REQUIRED

% Varian MMLC-80 and MC parameters 
leaf=(-19.5:1:19.5);
MLCPLANE=50.9;
ISOPLANE=100.0;
ZMIN_JAWS=[28.0;36.7];
ZMAX_JAWS=[35.8;44.5];
Z_min_CM=27.4;

% Plot parameters
maxcol=2;
maxrow=4;

disp(' ')
disp('A total of :');
disp(maxcol*maxrow);
disp('segments are being plotted per beam');
plotopt = input ('Do you want to change these defaults ? Y/N [N]','s');
if plotopt == 'Y' | plotopt == 'y';
    tempcol = input('Input number of colums you want to use: ');
    if isempty(maxcol) | ischar(maxcol)
        warning('dicomrt_plotsegments: parameters did not change !');
    else
        maxcol=tempcol;
    end
    temprow = input('Input number of rows you want to use: ');
    if isempty(maxcol) | ischar(maxcol)
        warning('dicomrt_plotsegments: parameters did not change !');
    else
        maxrow=temprow;
    end
end

disp('MLC settings are plotted at the isocenter.');
SCALEfactor=1;

% Export plan into BEAM00 input files for MC calculation
for i=1:size(rtplanformc,1)
    handle=figure;
    beamnumber=[inputname(1),' MLC settings: beam ',int2str(i)];
    set(handle,'Name',beamnumber);
    hold
    for j=1:size(rtplanformc{i,3},1)
        % prepare lables and titles
        labelX=('X axis (cm)');
        labelY=('MLC leaves');
        segmentnumber=['segment ',int2str(j)];
        % retrieve settings
        BF_XN=rtplanformc{i,3}{j,1}(1,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5;
        BF_XP=rtplanformc{i,3}{j,1}(2,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5;
        BF_YN=rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5;
        BF_YP=rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5;
        % (Z_min_CM/ZMIN_JAWS(2)*1.5) is a factor which backproject JAWS  
        % settings at phsp plane and increase them of 50%
        YFN_JAWS=rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*ZMIN_JAWS(1)*10*0.1; % dicom-rt is in mm
        YBN_JAWS=rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*ZMAX_JAWS(1)*10*0.1; 
        YFP_JAWS=rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*ZMIN_JAWS(1)*10*0.1;  
        YBP_JAWS=rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*ZMAX_JAWS(1)*10*0.1; 
        XFN_JAWS=rtplanformc{i,3}{j,1}(1,1)/ISOPLANE*0.1*ZMIN_JAWS(2)*10*0.1;
        XBN_JAWS=rtplanformc{i,3}{j,1}(1,1)/ISOPLANE*0.1*ZMAX_JAWS(2)*10*0.1;
        XFP_JAWS=rtplanformc{i,3}{j,1}(2,1)/ISOPLANE*0.1*ZMIN_JAWS(2)*10*0.1;
        XBP_JAWS=rtplanformc{i,3}{j,1}(2,1)/ISOPLANE*0.1*ZMAX_JAWS(2)*10*0.1;
        NEG_VARMLM=rtplanformc{i,4}{j,1}(1:40)*0.1*SCALEfactor;
        POS_VARMLM=rtplanformc{i,4}{j,1}(41:80)*0.1*SCALEfactor;
        
        leaf=leaf*SCALEfactor;
        
        subplot(maxrow,maxcol,j);
        if ishold~=1
            hold on;
        end
        firstplot=plot(NEG_VARMLM,leaf);
        set(firstplot,'MarkerSize',6);
        set(firstplot,'Marker','>');
        set(firstplot,'MarkerFaceColor','k');
        set(firstplot,'MarkerEdgeColor','k');
        set(firstplot,'LineStyle','none');
        secondplot=plot(POS_VARMLM,leaf);
        if ishold~=1
            hold on;
        end
        set(secondplot,'MarkerSize',6);
        set(secondplot,'Marker','<');
        set(secondplot,'MarkerFaceColor','r');
        set(secondplot,'MarkerEdgeColor','r');
        set(secondplot,'LineStyle','none');
        title(segmentnumber,'FontWeight','bold','FontSize',12,'Interpreter','none');
        if SCALEfactor==1;
            BF_XN=BF_XN*ISOPLANE/Z_min_CM;
            BF_XP=BF_XP*ISOPLANE/Z_min_CM;
            BF_YN=BF_YN*ISOPLANE/Z_min_CM;
            BF_YP=BF_YP*ISOPLANE/Z_min_CM;
            YFN_JAWS=YFN_JAWS*ISOPLANE/ZMIN_JAWS(1);
            YBN_JAWS=YBN_JAWS*ISOPLANE/ZMAX_JAWS(1); 
            YFP_JAWS=YFP_JAWS*ISOPLANE/ZMIN_JAWS(1);  
            YBP_JAWS=YBP_JAWS*ISOPLANE/ZMAX_JAWS(1); 
            XFN_JAWS=XFN_JAWS*ISOPLANE/ZMIN_JAWS(2);
            XBN_JAWS=XBN_JAWS*ISOPLANE/ZMAX_JAWS(2);
            XFP_JAWS=XFP_JAWS*ISOPLANE/ZMIN_JAWS(2);
            XBP_JAWS=XBP_JAWS*ISOPLANE/ZMAX_JAWS(2);
        else
            BF_XN=BF_XN*MLCPLANE/Z_min_CM;
            BF_XP=BF_XP*MLCPLANE/Z_min_CM;
            BF_YN=BF_YN*MLCPLANE/Z_min_CM;
            BF_YP=BF_YP*MLCPLANE/Z_min_CM;
            YFN_JAWS=YFN_JAWS*MLCPLANE/ZMIN_JAWS(1);
            YBN_JAWS=YBN_JAWS*MLCPLANE/ZMAX_JAWS(1); 
            YFP_JAWS=YFP_JAWS*MLCPLANE/ZMIN_JAWS(1);  
            YBP_JAWS=YBP_JAWS*MLCPLANE/ZMAX_JAWS(1); 
            XFN_JAWS=XFN_JAWS*MLCPLANE/ZMIN_JAWS(2);
            XBN_JAWS=XBN_JAWS*MLCPLANE/ZMAX_JAWS(2);
            XFP_JAWS=XFP_JAWS*MLCPLANE/ZMIN_JAWS(2);
            XBP_JAWS=XBP_JAWS*MLCPLANE/ZMAX_JAWS(2);       
        end
        %line(BF_XN,BF_YP,'Marker','x'); % disabled until BF is not implemented 
        %line(BF_XP,BF_YP,'Marker','x');
        %line(BF_XP,BF_YN,'Marker','x');
        %line(BF_XN,BF_YN,'Marker','x');
        %line(BF_XN,BF_YP,'Marker','x');
        %line(BF_XP,BF_YP,'Marker','x');
        %line(BF_XP,BF_YN,'Marker','x');
        %line(BF_XN,BF_YN,'Marker','x');
        plot(0,YFN_JAWS,'o'); % projection of ?F? and ?B? at any plane is the same.
        plot(0,YFP_JAWS,'o'); % Therefore only F is plotted.
        plot(XFN_JAWS,0,'s');
        plot(XFP_JAWS,0,'s');  
        xlabel(labelX);
        ylabel(labelY);
        axis tight;
    end
end

% Generate TopModule readable fluence file from CERR beamlet weights
%
% APA, 01/16/2015
loadDirectory = '/Users/parastiwari/research/result/April3/';

patientName={'7200cGy_10'};
wfname = 'wV';

fldir = sprintf('%s/fluence',loadDirectory);
imgdir = sprintf('%s/images',loadDirectory);
if(exist(fldir,'dir'))
    rmdir(fldir,'s');
end
mkdir(fldir);
if(exist(imgdir,'dir'))
    rmdir(imgdir,'s');
end
mkdir(imgdir);

for i=1:length(patientName)
   
    planName = sprintf('%s%s_VMC++.mat',loadDirectory,patientName{i});
    planC = loadPlanC(planName, '~/tmp');
    indexS = planC{end};
    beamNum = 2;
    IM = planC{indexS.IM}.IMDosimetry;
    wtfName = sprintf('%s%s%s',loadDirectory,wfname,patientName{i});
    
    %s=1;
    beamletStart = 1;
    
    bw = load(wtfName);
    %bw = ones(1,length(bw));
    for j=1:length(IM.beams)
        numBeamlets = length(IM.beams(j).xPBPosV);
        
        %bw = ones(1,numBeamlets);
        if(size(bw,1)>1)
            bw = bw';
        end
        
        fluenceFileName = sprintf('%s/fluence/fluence_plan%s_beam%d',loadDirectory,patientName{i},j);
        imageName = sprintf('%s/images/fluence_plan%s_beam%d',loadDirectory,patientName{i},j);
        
        fid = fopen(fluenceFileName,'w');
        
        %e = s+l-1;
        beamletEnd = beamletStart + numBeamlets - 1;
        xPBv = IM.beams(j).xPBPosV;
        yPBv = IM.beams(j).yPBPosV;
        PBWtsV = bw(beamletStart:beamletEnd);
        beamletStart = beamletEnd + 1;
        
        apertureTotalX = 256*0.2;
        if min(yPBv) >= -20 && max(yPBv) <= 20
            Nprs = length(min(yPBv):0.5:max(yPBv));
        else
            Nprs = NaN;
            disp('Needs implementation')
        end
        
        xRes = 0.25;
        fluencexPosV = (xRes/2):xRes:20;
        %fluencexPosV = 0.1:0.2:19.9;
        %Nx = min(find(fluencexPosV > max(abs(xPBv))));
        Nx = find(abs(fluencexPosV - max(abs(xPBv))) < 1e-3);
        fprintf(fid, 'VERSION 2.0\n');
        fprintf(fid, 'Beam weighs\n');
        fprintf(fid, '\t%d\t%d\t10.0\t2.0\n', Nprs, 2 * Nx);
        fprintf (fid, '\t5.0\t5.0\t5.0\t5.0\n');
        %xFluenceV = -fluencexPosV(Nx):0.2:fluencexPosV(Nx);
        xFluenceV = -fluencexPosV(Nx):xRes:fluencexPosV(Nx);
        unixXpbV = unique(xPBv);
        dx = unixXpbV(2) - unixXpbV(1);
        xFlV = [];
        yFlV = [];
        flV = [];
        for y = min(yPBv):0.5:max(yPBv)
            %for y = max(yPBv):-0.5:min(yPBv)
            leafNum = 30 + (y-0.25)/0.5+1;
            %leafNum = 60 - leafNum + 1;
            fprintf(fid, 'slice\t%d\n', leafNum);
            xLeaf = xPBv(yPBv==y);
            PBv = PBWtsV(yPBv==y);
            xPB = [-max(abs(xPBv)):dx:min(xLeaf)-dx xLeaf max(xLeaf)+dx:dx:max(abs(xPBv))];
            %pbWtsV = [0*(-max(abs(xPBv)):dx:min(xLeaf)-dx) xLeaf.^0 0*(max(xLeaf)+dx:dx:max(abs(xPBv)))];
            pbWtsV = [0*(-max(abs(xPBv)):dx:min(xLeaf)-dx) PBv 0*(max(xLeaf)+dx:dx:max(abs(xPBv)))];
            %fV = interp1(xPB,pbWtsV,xFluenceV,'linear','extrap');
            for ifl = 1:length(xFluenceV)
                indFl = find(abs(xFluenceV(ifl) - xPB) < 1e-3);                
                if ~isempty(indFl)
                    fV(ifl) = pbWtsV(indFl);
                else
                    fV(ifl) = 0;
                end
            end
            %fV(fV < 0) = 0;
            %fV = pbWtsV;
            fprintf (fid, '%3.3f\n', fV);
           
            flV = [flV ;fV];
            %             xFlV = [xFlV xFluenceV];
            %             yFlV = [yFlV y*xV.^0];
        end
        
        figure, imagesc(min(yPBv):1:max(yPBv),xFluenceV,flV');
        saveas(gcf, imageName, 'jpg');
        delete(gcf);
        
        fclose(fid);
    end
end
clear planC;

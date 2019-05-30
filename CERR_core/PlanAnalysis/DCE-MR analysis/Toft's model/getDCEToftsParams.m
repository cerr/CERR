function [countV,ktrAll,veAll,kepAll,vpAll,dceRsqAll,ROIPointShift,basePts,outFolder] =  getDCEToftsParams(paramS,shiftS,headerS,...
    maskSlices,sliceTimeCourse,pCalcConc,mask3M,T13M,tmin,AIFP,outPath)
%
% Kristen Zakian
% AI 5/26/16
% AI 8/16/16  - Added count : enhanced voxels
%               Added count : voxels that enhance but have low r-sq (poor fit)
% AI 8/9/17   - Removed basePts from parameter files. 
%               (Is set to roishift-1 if roiShift>1, 1 otherwise.)

% Get user-input parameters
model = paramS.model;
xSize = headerS.xSize;
ySize = headerS.ySize;
filt = paramS.filt;
fSize = paramS.fSize;
fSigma = paramS.fSigma;
CACut = paramS.CACut;
cutOff = paramS.cutOff;
saveMatPlot = paramS.saveMatPlot;
displayImgNum = paramS.displayImgNum;
checkShift = shiftS.checkShift;
skip = shiftS.skip;
skipArr = shiftS.skipArr;
workSlices = length(maskSlices);
yMax = paramS.yMax;
if nargout==9
    % Select folder for output ktrans and ve files
    outFolder = uigetdir(outPath, 'Choose output folder. SINGLE CLICK!  ');
else
    outFolder = outPath;
end

%% Data tabulation
% Count #voxels that enhance/don't
% Those that enhance can have any r-squared as long as the end of the time course has contrast > CAcut
nonEnhCount = 0;                  % count non-enhancing voxels.
enhCount = 0;
enhCountPoorFit = 0;              % number of voxels which enhance but r-sq too low (poor fit)
junkCount = 0;                    % number of noisy unfittable voxels.
nonPhysio = 0;                    % number of slowly enhancing voxels not fittable by model.
fitCount = 0;                     % fittable voxels (enhancing, rsq > cutOff, not slow).
uCount = 0;                       % number of usable.
rsqEnhance = zeros(1,30000);      % initalize array to contain r-squared values of enhanced voxels.



%% DCE calculations

% Preparing for  making an average time course at one slice (ROIslice) that
% will be used to decide how much to time-shift the tissue time course curves.
% We will do this for just the first slice and use the shift value for all.
ktrAll = zeros(xSize, ySize, workSlices);  % initialize array for all
veAll = zeros(xSize, ySize, workSlices);  % initialize array for all
vpAll = zeros(xSize, ySize, workSlices);  % initialize array for all
kepAll = zeros(xSize, ySize, workSlices);
dceRsqAll = zeros(xSize, ySize, workSlices);
voxCount =  0;                    % initialize count of all voxels in all slices
figCount = 0;
ktrans1DAll = zeros(1,500000);    % 1D vectors to hold all values for histo
ve1DAll = zeros(1,500000);
vp1DAll = zeros(1,500000);
ktrans1DCut = zeros(1,500000);    % 1D vectors to hold all values for histo
ve1DCut = zeros(1,500000);
vp1DCut = zeros(1,500000);
kep1DCut = zeros(1,500000);

%Write mode
modeSel = questdlg('Use r-squared cut-off?','Mode','Yes','No','No') ;
if isempty(modeSel)||strcmp(modeSel,'Cancel')
    return
end

for k = 1:workSlices
    
    fprintf('\nComputing parameters for slice %d of %d',k,workSlices);
    
    %Get slice timecourse
    sliceTCourse = sliceTimeCourse(:,:,:,k);
    
    % Apply Gaussian filter to slice if reqd
    if strcmp(filt,'y')
        [fDCEData] = filterImg(sliceTCourse,fSize,fSigma); %apply lowpass filter
        sliceTCourse = fDCEData;
    end
    

    % Mask the slice time course data.
    maskM = mask3M(:,:,maskSlices(k));
%    test: display the mask
%     figure, imshow(maskM)                                 
%     pause(1);
%     close(gcf);
    [mSliceTcourse, ROIRows, ROICols, ROIVoxels] = ROIMaskedSlices(sliceTCourse,maskM);
    
    % Get user-input shift
    %   Generate an average time course for the ROI from the first slice & display.
    %   Have the user choose the amount to shift the time course to get last
    %   baseline point before upslope.
    %   Only need to do this for first 20 time points.
    if (k == 1)
        if strcmp(checkShift,'y')
            ROIPointShift = getShiftFn(mSliceTcourse,maskM);
        else
            ROIPointShift = shiftS.ROIPointShift;
        end
        
        %Added 8/9/17
        if ROIPointShift>1
            basePts = ROIPointShift - 1;
        else
            basePts = 1;
        end
        
    end
    
    % Fit Tofts model
    
    % initialize arrays to hold these values
    ktrans = zeros(xSize,ySize);
    ve = zeros(xSize,ySize);
    vp = zeros(xSize,ySize);
    kep = zeros(xSize,ySize);
    dceRsq = zeros(xSize, ySize);
    ktransCut = zeros(xSize,ySize);
    veCut = zeros(xSize,ySize);
    kepCut = zeros(xSize,ySize);
    vpCut = zeros(xSize,ySize);
    dispCount = 0;
    countFlag = 0;

    for j = 1:ROIVoxels
        
        % Get mean signal value before time-shift
        ix = ROIRows(j);
        iy = ROICols(j);
        voxCount = voxCount + 1;                            %total voxel count for all ROIS, all slices
        frames = headerS.frames;
        signalT = double(mSliceTcourse(ix,iy,1:frames));
        signalT = squeeze(signalT); %ADD transpose for resamp
        base = signalT(1:basePts);                          % baseline signal value obtained from time course BEFORE SHIFT
        s0 = mean(base);
        
        % If using a precalculated T1 map get T1 for this voxel
        if ~isempty(T13M)
            T1slice =  T13M(:,:,k);
            pCalcConc(4) = double(T1slice(ix,iy))./1000.;   %  loaded T1 file is in ms, convert to seconds
        end
        concV = calcConc(signalT,pCalcConc,s0);
      
        [p,tissueNew,fitCurve,tminNew,rsq,newFrames] = fitToftsMod(tmin,AIFP,concV,frames,...
                                                         model,ROIPointShift,skip,skipArr);
        
        %Compute ktrans,ve,kep,rsq
        tissue = tissueNew;
        ktrans(ix,iy) = p(1);
        ktrans1DAll(voxCount) = p(1);
        ve(ix,iy) = p(2);
        ve1DAll(voxCount) = p(2);
        if strcmp(model,'ET')
            vp(ix,iy) = p(3);
            vp1DAll(voxCount) = p(3);
        end
        dceRsq(ix,iy) = rsq;
        kep(ix,iy) = ktrans(ix,iy)/ve(ix,iy);
        
        %Display a curve and fit
        dispCount = dispCount+1;
        if (dispCount == displayImgNum)
            countFlag = 1;                                 % if at displayImgNum
            dispCount = 0;                                 % set counter for display curve decision back to zero
        end
        if (countFlag == 1)
            figCount = figCount + 1;
            figtitle = ['Voxel: ',num2str(voxCount),', R-squ = ', num2str(rsq),',  ktrans = ',...
                num2str(ktrans(ix,iy)), ' ve= ',num2str(ve(ix,iy)), ' Vp = ',num2str(vp(ix,iy))];
            figure ('Name', figtitle);
            plot (tminNew,fitCurve,'-d',tminNew,tissue);
            ylim([0 yMax])                                 % Set y axis maximum so all plots scaled same.
            legend({'Fit curve','Shifted curve'});
            % plot with x axis units as points so can figure out  what to skip
            pause(1);
            hold on;
            countFlag = 0;
            
            if strcmp(saveMatPlot, 'y')
                figName = [outFolder, filesep, 'fitcurve_', num2str(figCount), '.fig'];
                savefig(gcf,figName);
            end
            close(gcf);
        end       %  end if countflag = 1:  show plot of voxel
        
        %Test for non-enhancement
        %Subdivide into truly non-enhancing or unusable
        %For enhancing voxels, subdivide into
        %rsq > cutOff and ve < 0.5  (valid)
        %rsq > cutOff and ve > 0.5  slow enhancement
        %rsq < cutOff (unusable).
        %Define variables
        limit = 0.04;
        noSig = 0.03;
        noSigLim = 8;
        testLen = 17* (frames <= 35) + 20*(frames > 35);
        testSig = tissue(newFrames-testLen:newFrames);
        noSigCount = length(find(testSig <noSig));
        std_20 = std(tissue(newFrames-testLen:newFrames)); % # frames w sig < nosig
        %Get enhancement state
        [enhance, ~] = checkEnhance(fitCurve,newFrames,CACut);
        if enhance==1 && rsq > cutOff
            enhCount = enhCount + 1;   % if enchance==1
            uCount = uCount +1;
            fitCount = fitCount + 1;
            rsqEnhance(uCount) = rsq;
        else
            % note that non-enhancing voxels will have parameters set to 100 for now
            % Must take care of this later.
            ktrans(ix,iy) = 100;
            ve(ix,iy) = 100;
            kep(ix,iy) = 100;
            if strcmp(model,'ET')
                vp(ix,iy) = 100;
            end
            if(enhance == 0)
                % Test for true non-enhancement
                %  Non-enhancing junk voxels have very low-end value but are so noisy that you can't be sure
                %  they are really non-enhancing.
                %  Test: if the standard deviation of the last points in the time course is too high
                %        (exceeds limit) OR if the number of time course points with zero signal is too
                %        high (exceeds noSigLim) then the voxel is classified as junk.
                
                if ((std_20 > limit) || (noSigCount > noSigLim))
                    junkCount = junkCount + 1;            % Unusable voxel count
                    %look at these fits to decide the limit
                    %figtitle = ['non-enhancing unusable voxel: std last 20 pts  = ' num2str(std_20)];
                    %figure ('Name', figtitle);
                    %plot (tminnew,fitcurve,'--',tminnew,tissue);
                    %ylim([0 ymax])                       % Set y axis maximum so all plots scaled same.
                    %pause(4);
                    %hold on;
                else
                    %true non-enhancing have low end value but data quality is ok so truly
                    %non-enhancing
                    nonEnhCount = nonEnhCount + 1;
                    %look at these fits to decide the limit
                    %figtitle = ['true non-enhancing  voxel: std last 20 pts  = ' num2str(std_20)];
                    %figure ('Name', figtitle);
                    %plot (tminnew,fitcurve,'--',tminnew,tissue);
                    %ylim([0 ymax])                      % Set y axis maximum so all plots scaled same.
                    %pause(4);
                    %hold on;
                end
            else   % if enhancement == 1
                enhCount = enhCount + 1;
                if (rsq <= cutOff)
                    enhCountPoorFit = enhCountPoorFit + 1;         %CHANGED
                    
                end                                     % end if rsq > cutOff
            end                                         % end if enhancing
        end                                             % end if ve <=1
        
        %Compute ktrans with r-squared cutOff
        ktransCut(ix,iy) = ktrans(ix,iy)*(dceRsq(ix,iy)> cutOff);
        %ktrans1DCut(voxCount)= ktrans(ix,iy)*(dceRsq(ix,iy)> cutOff);
        veCut(ix,iy) = ve(ix,iy)*(dceRsq(ix,iy)> cutOff);
        %ve1DCut(voxCount) = ve(ix,iy)*(dceRsq(ix,iy)> cutOff);
        if strcmp(model,'ET')
            vpCut(ix,iy) = vp(ix,iy)*(dceRsq(ix,iy)> cutOff);
            %vp1DCut(voxCount) = vp(ix,iy)*(dceRsq(ix,iy)> cutOff);
            vpAll(ix,iy,k) = vpCut(ix,iy);
        end
        kepCut(ix,iy) = kep(ix,iy)*(dceRsq(ix,iy)> cutOff);
        %kep1DCut(voxCount) = kep(ix,iy)*(dceRsq(ix,iy)> cutOff);
        ktrAll(ix,iy,k) = ktransCut(ix,iy);
        veAll(ix,iy,k) = veCut(ix,iy);
        kepAll(ix,iy,k) = kepCut(ix,iy);
        dceRsqAll(ix,iy,k) = dceRsq(ix,iy);
    end                                             % end loop over ROI voxels
    
    fprintf('\n Processed slice %d\n--------------------------------------\n',k);
    
end                                                     % end loop over slices

%Return voxel counts
countV = [voxCount,nonEnhCount,enhCount,enhCountPoorFit,junkCount,nonPhysio,fitCount];

end
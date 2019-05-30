function AIFPlasma = genAIF(tsec,coefFile,frames,tmin,paramS,shiftS)
% Function to generate the AIF.
% -----------------------------------------------------------------------------------
% Parker function coefficients have been generated using the mean of 
% AIFs from the Gollub rectal data.
% The population_aif function will take those coefficients and generate a Parker AIF at the
% time points for the current data set. Pass it the time vector and the
% name of the Parker coefficient file.
% Field strength and relaxivity were accounted for when the Parker coefs for
% the AIF were generated.
% -------------------------------------------------------------------------------------
%
% Kristen Zakian

% Read input parameters
hct = double(paramS.hct);
checkAIFShift = double(shiftS.checkAIFShift);
userAIFShift = double(shiftS.userAIFShift);

% Generate the Parker-like AIF at the time points of this DCE data set.
% note that time points are converted to minutes for the Parker calculation
% And Parker coefficients that are in terms of time have minutes units

aifConc = fGenerateParkerAIF(tsec, coefFile);
AIFPlasma = aifConc./(1-hct);       % convert blood conc AIF to plasma conc AIF
aifPOrig = AIFPlasma;               % make a copy



%Remove the delay in the AIF so that it starts at 0.
%Initial values are already zeroes.
 if strcmp(checkAIFShift,'y')
     % plot the AIF
     figtitle3 = 'Start of AIF time course';
     figure ('Name', figtitle3);
     plot (tmin,AIFPlasma);
     aShift = input('Input the AIF shift (e.g. 2, to shift left 2 points):   ');
     close(gcf);
     AIFShift = circshift(AIFPlasma', -aShift);
     AIFPlasma = AIFShift';
     newpointsAIF = frames-aShift;  % remove the wrapped values
                                    % extrapolate replacement values
                                    % by linear regression to maintain number of pts in
                                    % tcourse
     linfitT = tmin(frames-(aShift+4):frames-aShift);
     linfitAIF = AIFPlasma(frames-aShift-4:frames-aShift);
     pLin = polyfit(linfitT,linfitAIF,1);
     slope = pLin(1);
     int = pLin(2);
     tV = tmin(frames-aShift+1:frames);
     newVals = slope*tV+int;
     AIFPlasma(frames-aShift+1:frames)= newVals;      
         
 % display unshifted and shifted aif curve
         
        figtitle = ['AIF unshifted and shifted. Shift = ' num2str(aShift)];
        figure ('Name', figtitle);
        plot (tmin,aifPOrig,tmin,AIFPlasma,'--');
        pause(4);
        close(gcf);
 else
     
     aShift = userAIFShift;
     
     AIFShift = circshift(AIFPlasma', -aShift);
     AIFPlasma = AIFShift';
     newpointsAIF = frames-aShift;  % remove the wrapped values
                                    % extrapolate replacement values
                                    % by linear regression to maintain number of pts in
                                    % tcourse
     linfitT = tmin(frames-(aShift+4):frames-aShift);
     linfitAIF = AIFPlasma(frames-aShift-4:frames-aShift);
     pLin = polyfit(linfitT,linfitAIF,1);
     slope = pLin(1);
     int = pLin(2);
     tV = tmin(frames-aShift+1:frames);
     newVals = slope*tV+int;
     AIFPlasma(frames-aShift+1:frames)= newVals;    
     
      % display unshifted and shifted aif curve
         
       figtitle = ['AIF unshifted and shifted. Shift = ' num2str(aShift)];
       figure ('Name', figtitle);
       plot (tmin,aifPOrig,tmin,AIFPlasma,'--');
       pause(4);
       close(gcf);

 end


end
function [p,tissue,fitCurve,tmin,rsq,framesOut,chisquared] = fitToftsMod(tmin,aifPlasma,tissue,frames,...
    model,ROIPointShift,skip,skipArr)
% This function fits a single voxel time course to a toft's model
% and returns the best fit ktrans and ve in the output vector 'p'.
% Also returns the best fit curve and the truncated form of the original tissue
% curve if it was shifted. It also returns the truncated time in minutes, tmin.
%-------------------------------------------------------------------------------------------
% INPUTS
% tmin          : Time in minutes.
% aifPlasma     : Plasma concentration.
% tissue        : Tissue concentration.
% frames        : No. time points.
% model         : Fit model ( 'T' for Tofts, 'ET' for extended Tofts. ).
% ROIPointShift : User-input shift applied to average ROI time course.
% skip          : Set to 1 to discard selected time points, 0 to use all
%                 time points.
% skipArr       : Time points to be discarded.
%--------------------------------------------------------------------------------------------
% Kristen Zakian
% AI 5/26/16
% AI 8/16/16 - Modified upper bounds(ub) for 'ET' model.
% AI 9/28/16 - Modified p0,lb,ub for 'ET' model.
%            - Added constraint: ce + vp <= 1 to fn: fit1cET
% AI 2/3/17  - Changed fit bounds (ub): vp<=0.1
% AI 5/18/17 - Added chi sq. measure of fit
%              Extended Tofts: Fit using fmincon instead oflsqcurvefit
%              Modified ET fit to use cumtrapz
% -------------------------------------------------------------------------------------------


%Shift the tissue curve so that the upslope starts at t = 0.
tissueShift = circshift(tissue, -ROIPointShift);
tissue = tissueShift.';

%Truncate the ends of the time point array, the tissue array, and the AIF
%by the number of points shifted
shiftFrames = frames-ROIPointShift;
tissue = tissue(1:shiftFrames);
aifPlasma = aifPlasma(1:shiftFrames);
tmin = tmin(1:shiftFrames);

if (skip == 1)                                                % handle case where bad frames will be skipped
    
    %If the data array was shifted,subtract shift from the values of the skip array elements
    skipArr = skipArr - ROIPointShift;
    
    % if skipping points near the beginning (almost never happens), you may end up with
    % negative elements in skip array.
    %  if skip index is <= 0 after the tshift,  that index should be removed from the skip array

     skipArrposindices = skipArr(skipArr > 0);  %  this gives the indices of the points to be skipped in the shifted array, excluding
                                                                                 % zero or negative indices corresponding to points at index <= tshift

     skipArr = skipArrposindices;    
     
    %Create a mask vector with zeros for the skipped frames
    skipMask = ones(1,shiftFrames);
    skipMask(skipArr) = 0;
    
    %Multiply the time vector by the mask and then remove the zeros.
    %Before masking, must take care of array values which really are zero
    
    % 1.  Assign all time, tissue and AIF zeros a value of 100
    % 2.  Apply the mask
    % 3.  Remove zero points
    % 4.  Replace 100s with zeros.
    lowLim = 0.0001;
    dummyVal = 500;
    
    %Replace values <= lowLim with dummyVal
    tissue(tissue<=lowLim) = dummyVal;
    aifPlasma(aifPlasma<=lowLim) = dummyVal;
    tmin(tmin<=lowLim) = dummyVal;
    
    %Now apply the skip frames mask
    tissueSkip = tissue(logical(skipMask));
    aifPlasmaSkip = aifPlasma(logical(skipMask));
    tminSkip = tmin(logical(skipMask));
    framesSkip = length(tminSkip);
    
    %Replace original arrays with skip arrays
    frames = framesSkip;                                          % number of frames with the skipped frames eliminated
    
    %Replace the dummy values with original zeros
    tissueSkip(tissueSkip==dummyVal) = 0;
    aifPlasmaSkip(aifPlasmaSkip==dummyVal) = 0;
    tminSkip(tminSkip==dummyVal) = 0;
    
    
    %Initialize the arrays for fitting
    tissue = tissueSkip;
    aifPlasma = aifPlasmaSkip;
    tmin = tminSkip;
else
    frames = shiftFrames;                                         % if no frames skipped, frames just equals
    % the number of frames after the shift
end  %end if frames are being skipped

framesOut = frames;



% lsqcurvefit takes a ktrans, ve pair, and plugs it into the Tofts functional
% formula for Ctissue. Compares to measured Ctissue, calculates error
% squared, repeats for all ktrans, ve pairs and finds best pair.
% returns vector with best ktrans, ve.

switch(model)
    case 'T'                                                      % If simple Tofts model
        
        %Optimization options
        options = optimoptions('lsqcurvefit',...
            'MaxFunEvals', 2000, ...
            'MaxIter', 1000, ...
            'TolFun',10^(-6), 'TolX', 10^(-6),...
            'Display', 'off');
        
        %Parameter bounds
        p0 = [0.3, 0.3];
        lb = [0.001, 0.001];
        ub = [6.,1.0,1.];                                          % upper bound on ktrans = 6., UB on ve = 1.1
        %(give a little noise allowance)
        
        %Fit curve
        p = lsqcurvefit(@fit1c,p0,tmin',tissue',lb,ub,options,aifPlasma');
        whichStats = 'rsquare';                                   % choose only r squared to be calculated
        fitCurve = fit1c(p,tmin,aifPlasma);                       % Best fit curve
        
        % regstats does a linear regression of the fitted curve compared to the raw data curve.
        % So input fitcurve and tissue curve
        %  **************************
        stats = regstats(fitCurve,tissue,'linear', whichStats);
        rsq = stats.rsquare;
        %  *****************************
        
        % calculate chi-squared for the best fit
        elemt1 = (tissue-fitcurve).*(tissue-fitcurve)./tissue;
        chisquared = sum(elemt1, 1);    % chi-squared value for observed time course
        
        
    case 'ET'                                                    %If extended Tofts model
        
        %Optimization options
        options = optimoptions('fmincon',...
            'MaxFunEvals', 2000, ...
            'MaxIter', 1000, ...
            'TolFun',10^(-6), 'TolX', 10^(-6),...
            'Display', 'off');
        
        %Parameter bounds
        p0 = [0.4, 0.3, 0.05];                                   %Changed 09/28/16
        lb = [0.001, 0.001, 0.0001];                             %Changed 09/28/16
        ub = [6., 1.0, 0.5];                                     %Changed 02/03/17
        %(references all have vp well under 0.1)
        %Fit curve
        % We will find the set of parameters (p) which minimizes chi-squared
        % calculated from the model fit time course and the real data and
        % the constraint ve + vp <= 1
        % In linear format:
        %   Ap <= b, where p = [ktrans, ve, vp], A = [0, 1, 1], b = 1.
        A = [0, 1., 1.];
        b = 1.;
        Aeq = [];
        beq = [];
        nonlcon = [];
        p = fmincon(@chisq_fit1cET, p0,A, b, Aeq, beq, lb, ub, nonlcon, options,  tmin',tissue',aifPlasma');
        whichStats = 'rsquare';
        fitCurve = fit1cET(p,tmin',aifPlasma');                  % Best fit curve
        chisquared = chisq_fit1cET(p, tmin,tissue, aifPlasma);
        
        %regstats does a linear regression of the fitted curve compared to the raw data curve.
        %So input fitcurve and tissue curve
        stats = regstats(fitCurve,tissue,'linear', whichStats);
        rsq = stats.rsquare;
end                                                              % end model-specific operations


% get statistics by generating the best fit curve

% plot original tissue data and best fit curve
%figure ('Name', 'Best fit curve')
%set(0, 'DefaultAxesLineStyleOrder','-|-.|--|:')
%plot (tmin,fitcurve,tmin,tissue);
%best_p = p;
%if ~isreal(p)
%   keyboard
%end


% *********************   Chi-square calc. *********************
    function chisq = chisq_fit1cET(p,t, tissue, ca_in)
        
        conc_calc = fit1cET(p, t, ca_in) ;
        tissue_temp2 = zeros(size(tissue));
        minval = 0.01;
        tissue_temp2(:) = tissue(:).*(abs(tissue(:) > 0.001)) + minval.*(abs(tissue(:) <= 0.001));
        tissue = tissue_temp2;
        elemt = (tissue-conc_calc).*(tissue-conc_calc)./tissue;
        chisq = sum(elemt, 1);      % chi-squared value for observed time course
        % compared to modeled time course for this p
    end
% ****************** Basic Tofts Model  *************************

    function c = fit1c(p,t,c_in)                                    % basic Tofts model
        
        % Return params [Ktrans (1/min) ve]
        % pmin = [p(1)*60, p(2)];
        
        %  the function fit1c has input parameters:
        %  p = [ktrans, ve]
        %  t = array of sampling times
        
        
        fin = p(1);
        if ~isequal(p(2),0)
            fout = p(1)/p(2);
        else
            error('fit1c: ve = 0');
        end
        
        
        I = cumtrapz(t,c_in.*exp(fout*t));
        
        
        c = fin*exp(-fout*t).*I;                                  % returns a concentration time course for the
        % current ktrans, ve pair
        
    end


% ************* Extended Tofts Model ****************

    function c = fit1cET(p,t,c_in)
        
        % Return params [Ktrans (1/min) ve, vp]
        % p = current values of ktrans, ve, vp
        % t = array tmin = array of sampling times
        % c_in = aif_plasma
        
        fin = p(1);
        if ~isequal(p(2),0)
            fout = p(1)/p(2);
        else
            error('fit1cET: ve = 0');
        end
        
        vp = p(3);  % Added AI 9/28/16
        ve = p(2);
        %Added AI 5/18/17
        %  Z = cumtrapz(X,Y) computes the cumulative integral of Y with respect to X using trapezoidal integration.
        %  X and Y must be vectors of the same length, or X must be a column vector and Y an array whose first nonsingleton
        %  dimension is length(X).
        
        I2 = cumtrapz(t,c_in.*exp(fout*t));
        expktransve = fin*exp(-fout*t);
        c = vp*c_in + fin*exp(-fout*t).*I2;
        
    end

end
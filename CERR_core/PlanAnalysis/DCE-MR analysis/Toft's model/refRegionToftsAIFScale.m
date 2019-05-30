function [AIFScaled,rsq] = refRegionToftsAIFScale(tminV,AIFP,tissueV,paramFile,varargin)
% This function scales an arterial input function according to a muscle
% reference region concentration time course.
% Edited July 13, 2015 to handle skipping of bad frames
% AI 2/7/17 Changed upper bound on ve to 1.0 
% --------------------------------------------------------------------------------------
% INPUTS
% tminV      : Time array in minutes (tmin)
% AIFP       : Plasma AIF (aif_plasma)
% tissueV    : Tissue time course (tissue)
% paramFile  : Parameter file
% frames     : Time frames
%
% OPTIONAL
% varagin{1} : AIFAmp from parameter file
%
% NOTE: Both AIF and muscle time courses are assumed to already have been
%       shifted to zero.
%---------------------------------------------------------------------------------------
%  COMMENTS
%
%  During Tofts model fitting of the muscle time course,  this function
%  varies the amplitude of the AIF in addition to Ktrans and ve.
%  This function finds the AIF and Ktrans which give ve = 0.1 for muscle.
%  The scaled AIF which corresponds to ve = 0.1 is then returned to the
%  calling program.
%  The basic Tofts model is used.
%
%  Fitting using lsqcurvefit:
%  [p, resnorm] = lsqcurvefit(function, p0, xdata, ydata, p_lb, p_ub, fitting options...
%  any input needed for the function] (for example the aif).
%  In our case, the xdata is the array of time sampling points
%  The y data is the tissue concentration curve
%  The unknown parameters are p1 = ktrans, p2 = ve
%  Fit options without step size.
%
% ---------------------------------------------------------------------------------------

options = optimoptions('lsqcurvefit',...
    'MaxFunEvals', 2000, ...
    'MaxIter', 1000, ...
    'TolFun',10^(-6), 'TolX', 10^(-6),...
    'Display', 'off');

if nargin == 5             %AIFAmp is available
    AIFAmpIn = varargin{1};
    AIFIn = 1;
    %Ask the user if he wants to use this value or recalculate it.
    useValue = questdlg(sprintf('Use value from parameter file:\n AIFAmp = %g ?',AIFAmpIn),'AIF scaling','Yes','No','Yes');
else                       %AIFAmp is not available
    useValue = 'No';
    AIFIn = 0;
end


fid = fopen(paramFile);
inputC = textscan(fid, '%s %s %n','endofline','\r\n');
if strcmp(useValue,'No')
    % Define inputs to lsqcurvefit
    %Find the maximum value in the original AIF and use it for a starting value.
    %Set upper and lower limits = starting value/50 and starting value * 2.
    seedAIFScale = max(AIFP(:));
    nElements = 2000;
    minAIFScale = seedAIFScale./100;
    maxAIFScale = seedAIFScale.*8;
    AIFRangeV = linspace(minAIFScale, maxAIFScale, nElements);
    count = 0;
    p0 = [0.3, 0.3];
    lb = [0.001, 0.001];
    ub = [6.0, 1.0];         % Upper bound on ktrans = 6.,
                             % AI 2/7/17 Changed upper bound on Ve to 1.0 
    % UB on ve = 1.1 (give a little noise allowance)
    
    % Do the Tofts fit of muscle for varying AIF amplitudes until ve <= 0.1
    fprintf('\nBeginning Tofts fit of muscle with varying AIF amplitudes until ve <= 0.1... ');
    p = p0;
    while (p(2) > 0.105 || p(2) < 0.095)
        count = count + 1;
        if count > numel(AIFRangeV)
            msgbox('Tofts fit did not yield ve<=0.1 in 2000 iterations.','refRegionToftsAIFScale.m');
            return
        end
        AIFAmp = AIFRangeV(count);
        p = lsqcurvefit(@fit1c,p0,tminV',tissueV',lb,ub,options,AIFP',AIFAmp);
        %ve_and_aif_amp = [p(2), AIFAmp]
    end
    fprintf('\nFit complete.');
    %Store AIFAmp to parameter file
    fprintf('\nStoring AIFamp to parameter file...\n');
    fmt = '\r\n%s\t%s\t%d';
    fclose(fid);
    if AIFIn
        AIFIdx = strcmp (inputC{1},'AIFAmp');
        inputC{3}(AIFIdx) = AIFAmp;
        veIdx = strcmp (inputC{1},'Ve');
        inputC{3}(veIdx) = p(2);
        fid = fopen(paramFile,'w+');
        for lineNum = 1:size(inputC{1},1)
            col1 = inputC{1}(lineNum);
            col2 = inputC{2}(lineNum);
            col3 = inputC{3}(lineNum);
            fprintf(fid,fmt,col1{1},col2{1},col3);
        end
    else
        fid = fopen(paramFile,'a');
        newAIFEntryC = {'AIFAmp','na',AIFAmp};
        fprintf(fid,fmt,newAIFEntryC{:});
        newVeEntryC = {'Ve','na',p(2)};
        fprintf(fid,fmt,newVeEntryC{:});
    end
    %On exiting the loop, AIFAmp is the value that gives ve < 0.1
else
    AIFAmp = AIFAmpIn;        %Use the input value from the paramter file.
    veIdx = strcmp (inputC{1},'Ve');
    ve = inputC{3}(veIdx);
    p = [ve,AIFAmp];
end
fclose(fid);

% Scale AIFP
maxAIFPIn = max(AIFP(:));
AIFPNorm = AIFP./maxAIFPIn;
AIFScaled = AIFPNorm.* AIFAmp;

% Plot orig muscle and fit muscle which had ve = 0.1
fitcurve = fit1c(p,tminV,AIFP,AIFAmp);  %Best fit curve
figtitle = 'Original muscle and fit muscle';
figure ('Name', figtitle);
plot (tminV,tissueV,tminV,fitcurve,'--');
pause(2);
close(gcf);

% Get r-sq
whichstats = 'rsquare';                       %choose only r squared to be calculated
%regstats does a linear regression of the fitted curve compared to
%the raw data curve.  So input fitcurve and tissue curve
stats = regstats(fitcurve,tissueV,'linear', whichstats);
rsq = stats.rsquare;


% ******************Basic Tofts Model  *************************

    function c = fit1c(p,t,cIn,AIFAmp)        % basic Tofts model
        % INPUTS:
        % p = [ktrans, ve]
        % t = array of sampling times
        % Return params [Ktrans (1/min) ve]
        % pmin = [p(1)*60, p(2)];
        % ---------------------------------
        
        maxCIn = max(max(cIn));
        cInNorm = cIn./maxCIn;
        cInScaled = cInNorm.* AIFAmp;
        
        fin = p(1);
        if ~isequal(p(2),0)
            fout = p(1)/p(2);
        else
            error('fit1c: ve = 0');
        end
        
        I = cumtrapz(t,cInScaled.*exp(fout*t));
        
        c = fin*exp(-fout*t).*I;        % returns a concentration time course for the
        % current ktrans, ve pair
        
        
    end


end



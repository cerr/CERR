function writeStats(outFolder,outfileBase,model,cutOff,countV,ktrans1DCut,ve1DCut,kep1DCut,vp1DCut)
% Generates histograms of all parameters in voxels where r-squared exceeded
% cutOff, data were usable and enhancing.
% ------------------------------------------------------------------------
% INPUTS:
% outFolder     : Output folder name.
% outfileBase   : Base patient folder name.
% model         : Model used for curve-fitting. May be 'T' (Tofts) or 'ET' (Extended Tofts).
% cutOff        : R-squared cutoff.
% countV        : Vector of voxel counts-
%                 countV(1) - total number of voxels in ROI.
%                 countV(2) - no. non-enhancing voxels.
%                 countV(3) - no. enhancing voxels.
%                 countV(4) - no. enhancing voxels with low r-sq (poor fit).
%                 countV(5) - no. noisy/unfittable ("junk") voxels.
%                 countV(6) - no. slowly enhancing voxels not fittable by model (nonphysio).
%                 countV(7) - no. fit voxels (enhancing, rsq > cutOff, not slow).
% Vectors representing DCE parmameters across ALL SLICES -
% ktrans1DCut, ve1DCut, kep1DCut, vp1DCut (if extended Tofts). 
%--------------------------------------------------------------------------
% Kristen Zakian
% AI  5/26/16
% AI  8/16/16 - Added counts : enchCount,enhCountPoorFit

%Apply corrections
% Remove all 100-valued voxels
ktrans1DCut = ktrans1DCut(ktrans1DCut ~= 100);
ve1DCut= ve1DCut(ve1DCut ~= 100);
kep1DCut = kep1DCut(kep1DCut ~= 100);
% Display max values
sprintf('\n maxKtrans1DCut = %g',max(ktrans1DCut));
sprintf('\n maxKtrans1DCut = %g',max(ve1DCut));
sprintf('\n maxKtrans1DCut = %g',max(kep1DCut));
% Remove zero-valued voxels
ktrans1DCut = ktrans1DCut(ktrans1DCut~=0);
ve1DCut= ve1DCut(ve1DCut~=0);
kep1DCut = kep1DCut(kep1DCut~=0);

%Get parameter statistics
ktransStatV = getstats(ktrans1DCut);
ktransStatV(end+1)= skewness(ktrans1DCut);
ktransStatV(end+1)= kurtosis(ktrans1DCut);

veStatV = getstats(ve1DCut);
kepStatV = getstats(kep1DCut);
if strcmp(model,'ET')
    vp1DCut= vp1DCut(vp1DCut ~= 100.);
    vp1DCut = vp1DCut(vp1DCut~=0);
    vpStatV = getstats(vp1DCut);
end


%Write parameter histograms to file

% Plot ktrans cut histogram and write histogram bin data to xls file
lowerEdge = 0;               %histogram lower edge
upperEdge = 2;               %histogram upper edge
binWidth = 0.02;             %histogram bin width
figTitle = [' Ktrans where rsq > ', num2str(cutOff)];
textX = 0.5;
fName = 'Ktr_cut';
writeHist(lowerEdge,upperEdge,binWidth,ktrans1DCut,ktransStatV,outFolder,outfileBase,figTitle,textX,fName)% Write to file

% Plot ve cut histogram and write histogram bin data to xls file
lowerEdge = 0;               %histogram lower edge
upperEdge = 1;               %histogram upper edge
binWidth = 0.02;             %histogram bin width
figTitle = [' Ve where rsq > ', num2str(cutOff)];
textX = 0.5;
fName = 'Ve_cut';
writeHist(lowerEdge,upperEdge,binWidth,ve1DCut,veStatV,outFolder,outfileBase,figTitle,textX,fName)%Write to file

% Plot kep histo and write kep histo bin data to xls file
lowerEdge = 0;               %histogram lower edge
upperEdge = 8;               %histogram upper edge
binWidth = 0.1;             %histogram bin width
figTitle = [' Kep where rsq > ', num2str(cutOff)];
textX = 3;
fName = 'Kep_cut';
writeHist(lowerEdge,upperEdge,binWidth,kep1DCut,kepStatV,outFolder,outfileBase,figTitle,textX,fName)%Write to file

if strcmp(model,'ET')
% Plot vp histo and write vp histo bin data to xls file
lowerEdge = 0;               %histogram lower edge
upperEdge = 1;               %histogram upper edge
binWidth = 0.02;             %histogram bin width
figTitle = [' Vp where rsq > ', num2str(cutOff)];
textX = 0.5;
fName = 'Vp_cut';
writeHist(lowerEdge,upperEdge,binWidth,vp1DCut,vpStatV,outFolder,outfileBase,figTitle,textX,fName)%Write to file
end



%PREPARE AND WRITE DATA FOR STATISTICAL ANALYSIS (whole tumor stats)
% Display fit voxel percentages
% voxcount    : total number of voxels in ROI
% nonEnhCount : count non-enhancing voxels
% junkCount   : number of noisy unfittable voxels
% slowCount   : number of slowly enhancing voxels not fittable by model
% fitCount    : fittable voxels (enhancing, rsq > cutOff, not slow).
voxCount = countV(1);
nonEnhCount = countV(2);
enhCount = countV(3);
enhCountPoorFit = countV(4);
junkCount = countV(5);
nonPhysio = countV(6);
fitCount = countV(7);
perNonEnh = 100*nonEnhCount/voxCount;
perEnh = 100*enhCount/voxCount;
perEnhPoorFit = 100*enhCountPoorFit/voxCount;
perJunk = 100*junkCount/voxCount;
perNonphysio = 100*nonPhysio/voxCount;
perFit = 100*fitCount/voxCount;
sprintf(['\nPercent enhancing: %g\nPercent enhancing with poor fit(low rsq.): %g,...',...
    'Percent non-enhancing: %g\nPercent junk: %g\nPercent non-physiological: %g\n',...
    'Percent fit: %g\n'],perEnh,perEnhPoorFit,perNonEnh,perJunk,perNonphysio,perFit);
%Stat file column headers
stats_head={'Total voxels', '# Model fit', '% Model fit','% Enhancing','% Non-enhancing'...
            '% Enh ve nonphysio (slow)','% Enhancing r2<cutoff', '# No enhance noisy' '% No enhance noisy',...
            'rsq cutOff','mean ktrans', 'ktrans std','median ktrans','mean ve','std ve','median ve','mean kep',...
            'std kep','median kep','mean vp','std vp', 'median vp','ktr_10-Pct', 'ktr_75-Pct', 'ktr_90-Pct',...
            've_10-Pct', 've_75-Pct','ve_90-Pct','kep_10-Pct', 'kep_75-Pct',...
            'kep_90-Pct','vp_10-Pct', 'vp_75-Pct','vp_90-Pct','ktrans_skewness','ktrans_kurtosis'};
switch(model)
    case 'ET'
        
        statsOutV = zeros(1,36);
        statsOutV(1) = voxCount;
        statsOutV(2) = fitCount;
        statsOutV(3) = perFit;
        statsOutV(4) = perEnh;
        statsOutV(5) = perNonEnh;
        statsOutV(6) = perNonphysio;
        statsOutV(7) = perEnhPoorFit;
        statsOutV(8) = junkCount;
        statsOutV(9) = perJunk;
        statsOutV(10) = cutOff;
        statsOutV(11:13) = ktransStatV(1:3);
        statsOutV(14:16) = veStatV(1:3);
        statsOutV(17:19) = kepStatV(1:3);
        statsOutV(20:22) = vpStatV(1:3);
        statsOutV(23:25) = ktransStatV(4:6);
        statsOutV(26:28) = veStatV(4:6);
        statsOutV(29:31) = kepStatV(4:6);
        statsOutV(32:34) = vpStatV(4:6);
        statsOutV(35) = ktransStatV(7);
        statsOutV(36) = ktransStatV(8);

    case 'T'
        
        statsOutV = zeros(1,36);
        
        statsOutV(1) = voxCount;
        statsOutV(2) = fitCount;
        statsOutV(3) = perFit;
        statsOutV(4) = perEnh;
        statsOutV(5) = perNonEnh;
        statsOutV(6) = perNonphysio;
        statsOutV(7) = perEnhPoorFit;
        statsOutV(8) = junkCount;
        statsOutV(9) = perJunk;
        statsOutV(10) = cutOff;
        statsOutV(11:13) = ktransStatV(1:3);
        statsOutV(14:16) = veStatV(1:3);
        statsOutV(17:19) = kepStatV(1:3);
        statsOutV(20:22) = 0;
        statsOutV(23:25) = ktransStatV(4:6);
        statsOutV(26:28) = veStatV(4:6);
        statsOutV(29:31) = kepStatV(4:6);
        statsOutV(32:34) = 0;
        statsOutV(35) = ktransStatV(7);
        statsOutV(36) = ktransStatV(8);

end

modelName = ['_' model];
% write excel file with statistics

xlsStatsName = [outfileBase 'whole_tumor_stats' modelName];
xlsStatsOutfile = [outFolder '\' xlsStatsName '.xlsx'];
hh = [stats_head;num2cell(statsOutV)];
xlswrite(xlsStatsOutfile,hh);

end
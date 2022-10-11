function treatmentDays = getTreatmentSchedule(nFrx,scheduleType)
% Return RT treatment days for a given no. of fractions and schedule type
% Supported schedule types: 'weekday' ,'boost'.

switch(scheduleType)

    case 'weekday'
        %1 fraction every weekday with weekend breaks
        nWeeks = floor(nFrx/5);
        treatmentDays = [];
        for week = 1:nWeeks
            treatmentDays = [treatmentDays, [1:5] + 7*(week-1)];
        end
        remDays = mod(nFrx,5);
        treatmentDays = [treatmentDays, 1:remDays + nWeeks*7];

    case 'primershot'
        %One initial fraction (termed a "primer shot") followed by a 
        %2-week gap for full reoxygenation, with remaining fractions
        %delivered daily

        boost = 1;
        remDays = 14 + getTreatmentSchedule(nFrx-1,'weekday');
        treatmentDays = [boost,remDays];

        
    otherwise
        error('Invalid scheduleType %s',scheduleType)
end


end
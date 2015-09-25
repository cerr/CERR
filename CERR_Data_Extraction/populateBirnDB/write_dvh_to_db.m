function write_dvh_to_db(conn,patient_id)
%function write_dvh_to_db(conn,patient_id)
%
%Input: Writes DVHs for selected structures and doses from global planC to database
%
%APA, 02/27/2011

global planC
indexS = planC{end};


colNamesDVH = {'patient_id', 'structure_edition', 'structure_type', 'dose_calc_mode', 'total_volume', 'min_dose',...
    'mean_dose', 'max_dose', 'number_of_bins', 'dose_id', 'structure_id', 'dvh_id', 'bin_width'};

colNamesDVHBins = {'dvh_id', 'bin_dose_gy', 'cum_percent_vol', 'cum_cm3_vol'};


%Loop over all doses and structures
numStructs = length(planC{indexS.structures});
numDoses = length(planC{indexS.dose});

for doseNum = 1:numDoses
    
    %get dose-units and convert to gy
    if any(strcmpi(planC{indexS.dose}(doseNum).doseUnits,{'cgy','cgys','cgray','cgrays'}))
        planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray * 0.01;
        planC{indexS.dose}(doseNum).doseUnits = 'grays';
    end
    
    %find the dose with dose_uid matching this dose's doseUID from planC
    doseUID = planC{indexS.dose}(doseNum).doseUID;
    sqlq_find_dose = ['select dose_id from dose where dose_uid = ''', doseUID,''''];
    dose_raw = exec(conn, sqlq_find_dose);
    dose = fetch(dose_raw);
    dose = dose.data;
    if ~isstruct(dose)
        continue
    else
        dose_id = dose.dose_id{1};
    end
    
    %find the structure with structure_uid matching this structures's structUID from planC
    for structNum = 1:numStructs
        
        structS = planC{indexS.structures}(structNum);
        
        %Find matching structure in DB
        sqlq_find_str = ['Select structure_id from structure where structure_uid = ''', structS.strUID,''''];
        str_raw = exec(conn, sqlq_find_str);
        str = fetch(str_raw);
        str = str.Data;
        if ~isstruct(str)
            continue;
        else
            structure_id = str.structure_id{1};
        end
        
        
        %find the DVH with this dose_id and structure_id
        sqlq_find_dvh = ['Select dvh_id from dvh where (structure_id = ''', structure_id,'''', ' and dose_id = ''', dose_id, ''')'];
        % whereclause = ['where structure_id = ''', structS.strUID,'''', ' and dose_id = ''', doseUID, ''''];
        whereclause = ['where structure_id = ''', structure_id,'''', ' and dose_id = ''', dose_id, ''''];
        dvh_raw = exec(conn, sqlq_find_dvh);
        dvh = fetch(dvh_raw);
        dvh = dvh.Data;
        if ~isstruct(dvh)
            dvh_id = char(java.util.UUID.randomUUID);
            isNewRecord = 1;
        else
            dvh_id = dvh.dvh_id{1};
            isNewRecord = 0;
        end
        
        %patient_id
        dvhRecC{1} = patient_id;
        
        %structure_edition
        dvhRecC{2} = NaN;
        
        %structure_type
        dvhRecC{3} = NaN;
        
        %dose_calc_mode
        dvhRecC{4} = '';
        
        %total_volume
        dvhRecC{5} = getStructureVol(structNum,planC);
        
        %Compute cumulative DVH: doseBinsV, cumVols2V, cum_percent_vol
        try
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum);
            cumVolsV = cumsum(volsHistV);
            cumVols2V  = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding dose including that dose bin.
            cum_percent_vol = cumVols2V/cumVolsV(end)*100;
        catch
            doseBinsV = [];
        end
        
        %min_dose
        if ~isempty(doseBinsV) % for empty structures
            dvhRecC{6} = minDose(planC, structNum, doseNum, 'Absolute');
        else
            dvhRecC{6} = NaN;
        end
        
        %mean_dose
        if ~isempty(doseBinsV)
            dvhRecC{7} = meanDose(planC, structNum, doseNum, 'Absolute');
        else
            dvhRecC{7} = NaN;
        end
        
        %max_dose
        if ~isempty(doseBinsV)
            dvhRecC{8} = maxDose(planC, structNum, doseNum, 'Absolute');
        else
            dvhRecC{8} = NaN;
        end
        
        %number_of_bins
        dvhRecC{9} = length(doseBinsV);
        
        %dose_id
        dvhRecC{10} = dose_id;
        
        %structure_id
        dvhRecC{11} = structure_id;
        
        %dvh_id
        dvhRecC{12} = dvh_id;
        
        %bin_width
        if isempty(doseBinsV)
            dvhRecC{13} = mean(diff(doseBinsV));
        else
            dvhRecC{13} = NaN;
        end
        
        if isNewRecord
            insert(conn,'dvh',colNamesDVH,dvhRecC);
        else
            update(conn,'dvh',colNamesDVH,dvhRecC,whereclause);
            %Find dvh_bins which match this dvh and delete them
            sqlq_delete_dvh_bins = ['delete from dvh_bins where dvh_id = ''', dvh_id,''''];
            dvh_bins_delete = exec(conn, sqlq_delete_dvh_bins);
        end
        
        %write dvh_bins
        numBins = length(doseBinsV);
        for binNum = 1:numBins
            dvhBinsRecC{1} = dvh_id;
            dvhBinsRecC{2} = doseBinsV(binNum);
            dvhBinsRecC{3} = cum_percent_vol(binNum);
            dvhBinsRecC{4} = cumVols2V(binNum);
            insert(conn,'dvh_bins',colNamesDVHBins,dvhBinsRecC);
            pause(0.01)
        end
        
    end %structures
    
end %doses


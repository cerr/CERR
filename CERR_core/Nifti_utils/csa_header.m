function val = csa_header(s, key)
fld = 'CSAImageHeaderInfo';
if isfield(s, fld) && isfield(s.(fld), key), val = s.(fld).(key); return; end
if isfield(s, key), val = s.(key); return; end % general tag: 2nd choice
try val = s.PerFrameFunctionalGroupsSequence.Item_1.(fld).Item_1.(key); return; end
fld = 'CSASeriesHeaderInfo';
if isfield(s, fld) && isfield(s.(fld), key), val = s.(fld).(key); return; end
val = [];
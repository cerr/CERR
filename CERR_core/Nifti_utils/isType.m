%% Subfunction: return true if keyword is in s.ImageType
function tf = isType(s, keyword)
typ = tryGetField(s, 'ImageType', '');
tf = ~isempty(strfind(typ, keyword)); %#ok<*STREMP>

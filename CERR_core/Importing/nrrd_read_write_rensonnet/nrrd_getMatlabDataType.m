% Get matlab type corresponding to each nrrd type
% Date: November 2017
% Author: Gaetan Rensonnet
function matlabdatatype = nrrd_getMatlabDataType(metaType)

% Determine the datatype
switch (metaType)
    case {'signed char', 'int8', 'int8_t'}
        matlabdatatype = 'int8';
        
    case {'uchar', 'unsigned char', 'uint8', 'uint8_t'}
        matlabdatatype = 'uint8';
        
    case {'short', 'short int', 'signed short', 'signed short int', ...
            'int16', 'int16_t'}
        matlabdatatype = 'int16';
        
    case {'ushort', 'unsigned short', 'unsigned short int', 'uint16', ...
            'uint16_t'}
        matlabdatatype = 'uint16';
        
    case {'int', 'signed int', 'int32', 'int32_t'}
        matlabdatatype = 'int32';
        
    case {'uint', 'unsigned int', 'uint32', 'uint32_t'}
        matlabdatatype = 'uint32';
        
    case {'longlong', 'long long', 'long long int', 'signed long long', ...
            'signed long long int', 'int64', 'int64_t'}
        matlabdatatype = 'int64';
        
    case {'ulonglong', 'unsigned long long', 'unsigned long long int', ...
            'uint64', 'uint64_t'}
        matlabdatatype = 'uint64';
        
    case {'float'}
        matlabdatatype = 'single';
        
    case {'double'}
        matlabdatatype = 'double';
        
    case {'block'}
        error('Data type ''block'' is currently not supported.\n');
        
    otherwise
        assert(false, 'Unknown datatype')
end
end

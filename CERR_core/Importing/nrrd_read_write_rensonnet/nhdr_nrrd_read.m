% Read NHDR/NRRD files 
% 
% headerInfo = nhdr_nrrd_read(nrrdFileName, bReadData)
%
% Inputs:
% * nrrdFileName (char): path to NHDR/NRRD file, either a detached header,
% a detached header pointing to detached data files or a NRRD standalone
% file with header and data included
% * bReadData (bool): set to true to read the data and store it in
% headerInfo.data, set to false to just import the header without the data
%
% Outputs:
% * headerInfo (struct): contains all the fields specified in the file
% header. If data was read it is contained in the 'data' field. That
% structure can be fed to the nhdr_nrrd_write module as is and produce
% valid NHDR/NRRD files.
% 
% Format definition:
% http://teem.sourceforge.net/nrrd/format.html
%
% A few supported NRRD features:
% - detached headers with all variants of 'data file:'
% - raw, txt/text/ascii, gz/gzip encodings
% - definition of space and orientation
% - handling of diffusion-weighted MRI data with '<key>:=<value>' lines 
%   'modality:=DWMRI', 'DWMRI_b-value:=' and 'DWMRI_gradient_0000:=', 
%   'DWMRI_gradient_0001:=', 'DWMRI_gradient_0002:=', etc.
%   (see https://www.na-mic.org/wiki/NAMIC_Wiki:DTI:Nrrd_format)
% 
%
% Other features:
% - exits cleanly upon error (no file should be left open)
% - informative error messages whenever possible
% - warnings printed to console 
% - NHDR/NRRD writer fills out missing fields by inspecting the data
%   whenever possible
% 
%
% Unsupported features:
% 
% In general, any header field that we were unable to parse is reported
% in a message printed to the console. Specific examples of
% unsupported features include:
% 
% - reading data along more than 1 dimension or along a dimension other
%   than the slowest (last) axis specified by the optional <subdim>, as in
%   'data file: <format> <min> <max> <step> [<subdim>]' or 'data file: LIST
%   [<subdim>]'
% - storing all the comments found in headers
% - hex encoding
% - bz2/bzip2 encoding
% - byte skip; can only accept -1 with raw encoding, 0 for all other
%   encodings
% - line skip: can only accept 0
% - checking that field specifications of the form '<field>: <desc>' 
%   appear no more than once in the NRRD header (unlike '<key>:=<value>'
%   lines)
%
% Date: July 2018
% Author: Gaetan Rensonnet
%
%
%
% Notes :
%
% This is intended as a more comprehensive and accurate implementation of
% the NRRD format specification than most of the Matlab scripts that have
% been proposed so far. We try to fail graciously when an unsupported
% feature of the NRRD format is encountered. One of our main contributions
% is to propose a writer module which is compatible with the read module,
% in that the output of one can be given as an argument to the other to
% read or produce equivalent NHDR/NRRD files. This is still a version with
% much room for improvement.
%
% The following contributions inspired parts of our Matlab read/write
% modules:
% 
% 1. The body of the writer module was pretty much written from scratch but
% the general structure of the reader's main body is based on the Matlab
% functions maReadNrrdHeader.m and maReadNrrdData.m by marc@bwh.harvard.edu
% and kquintus@bwh.harvard.edu (unpublished). Many additions were made and
% a few bugs fixed.
%
% 2. Jeff Mather's NRRD reader
% (http://nl.mathworks.com/matlabcentral/fileexchange/34653-nrrd-format-file-reader)
% and
% http://jeffmatherphotography.com/dispatches/2012/02/writing-a-file-reader-in-matlab/)
% provided the auxiliary functions:
% - adjustEndian
% - getDatatype, which we renamed nrrd_getMatlabDataType and now throws
% a gracious error if it encounters 'block'-type data,
% - readData was adapted to include a cross-platform fix to delete
% temporary files when using gzip encoding. David Feng's fix used a
% Windows-specific command to delete temporary files
% (https://nl.mathworks.com/matlabcentral/fileexchange/50830-nrrd-format-file-reader).
%
% 3. mdcacio's nrrdWriter
% (https://nl.mathworks.com/matlabcentral/fileexchange/48621-nrrdwriter-filename--matrix--pixelspacing--origin--encoding-)
% provided the auxiliary functions:
% - writeData(): we got rid of the 'unexpected end of input stream when
% attempting to gunzip the file' error when using gzip encoding, which we
% later found had been fixed by Quan Chen independenlty and in a similar
% manner.
% - setDatatype(), which we renamed get_nrrd_datatype() and is the
% reciprocal of getDatatype 
%

function headerInfo = nhdr_nrrd_read(nrrdFileName, bReadData)

[mainFpath,mainFileName,mainFext] = fileparts(nrrdFileName);

headerInfo = struct();

% default header:
headerInfo.content = mainFileName;        % default value, overwritten if content field is set
headerInfo.data = [];


fidr = fopen(nrrdFileName, 'r');

if (fidr == -1)
    error('ABORT: %s does not exist.\n', nrrdFileName);
end

try 
    if ~(strcmpi(mainFext, '.nhdr') || strcmpi(mainFext, '.nrrd'))
        warning('%s looks like a %s file, not a nhdr or nrrd file.\n', nrrdFileName, mainFext );
    end
    
    % Magic line
    cs  = fgetl(fidr);
    assert(numel(cs) >= 8 && isequal(cs(1:4), 'NRRD'),...
        'Bad signature. First line should be magic line of type "NRRD000X" with X an integer between 1 and 5.'); % FIXME should throw an error if a bad integer is provided
    nrrd_version = sscanf(cs(5:end), '%d');
    if nrrd_version > 5
        error('This reader only supports versions of the NRRD file format up to 5. Detected %d.', nrrd_version)
    end

    % Always optional: defining orientation
    define_orientation = 0;         % internal-use variable
    
    % Parse header
    while ~feof(fidr)
        
        cs = fgetl(fidr);         % content string
        
        if isempty(cs)
            % End of header
            break;
        end
                
        if foundKeyword( 'CONTENT:', cs )
            
            headerInfo.content = strtrim( cs( length('CONTENT:')+1:end ) );
            
        elseif foundKeyword('TYPE:', cs )
            
            headerInfo.type = strtrim( cs( length('TYPE:')+1:end ) );
            
        elseif foundKeyword('ENDIAN:', cs )
            
            headerInfo.endian = strtrim( cs( length('ENDIAN:')+1:end ) );
            
        elseif foundKeyword('ENCODING:', cs )
            
            headerInfo.encoding = strtrim( cs( length('ENCODING:')+1:end ) );
            
        elseif foundKeyword('DIMENSION:', cs )
            
            headerInfo.dimension = sscanf( cs( length('DIMENSION:')+1:end ), '%i' );
            
        elseif foundKeyword('SIZES:', cs )
            
            iSizes = sscanf( cs(length('SIZES:')+1:end), '%i' );
            headerInfo.sizes = iSizes(:)';      % store as row vector
            
        elseif foundKeyword('KINDS:', cs )
            
            headerInfo.kinds = extractStringList( cs(length('KINDS:')+1:end) ); % bug fixed with extractStringList where 2 entries are present
            % FIXME: check that axis sizes match each kind according to nrrd standard
            
        elseif foundKeyword('SPACE:', cs )
            % Starts defining orientation (either space or space dimension,
            % not both)
            define_orientation = 1;
            
            if isfield(headerInfo, 'spacedimension')
                fprintf(['WARNING nhdr_nrrd_read %s:\n ''space'' field specifier will ' ...
                    'be checked for consistency but will be ignored afterwards ' ...
                    'because ''space dimension'' was specified before.\n'], fopen(fidr)); 
            end
            
            tmp_space = strtrim( cs( length('SPACE:')+1:end ) );
            tmp_spacedimension = nrrd_getSpaceDimensions(tmp_space);
            if tmp_spacedimension <= 0
                error('%s: unrecognized ''space'' descriptor ''%s''.', fopen(fidr), tmp_space)
            end
            
            if isfield(headerInfo, 'spacedimension')
                % internal_spacedimension already set
                if internal_spacedimension ~= tmp_spacedimension
                    error(['%s: ''space'' field specifier implies a spatial ' ...
                            '(world) dimension equal to %d, which differs from ' ...
                            'the ''space dimension'' field specifier set to %d.'],...
                            fopen(fidr), tmp_spacedimension, internal_spacedimension)
                end
                % if no inconsistencies found, just ignore space field
            else
                % Set space info for the first time:
                headerInfo.space = tmp_space;
                internal_spacedimension = tmp_spacedimension;  % for internal use only
            end
            
        elseif foundKeyword('SPACE DIMENSION:', cs)
            % Starts defining orientation (either space or space dimension,
            % not both)
            define_orientation = 1;
            if isfield(headerInfo, 'space')
                fprintf(['WARNING nhdr_nrrd_read %s:\n ''space dimension'' field specifier ' ...
                    ' will be checked for consistency but will be ignored afterwards ' ...
                    'because ''space'' was specified before.\n'],...
                    fopen(fidr));
            end
            
            tmp_spacedimension = sscanf( cs( length('SPACE DIMENSION:')+1:end), '%i' );
            if numel(tmp_spacedimension) ~= 1
                error(['%s: ''space dimension'' should be specified as one' ...
                    ' integer number. Found %d element(s) instead.'],...
                      fopen(fidr), numel(tmp_spacedimension))
            end
            if tmp_spacedimension <= 0
                error('%s: ''space dimension'' should be specified as a strictly positive integer (found %d).',...
                                fopen(fidr), tmp_spacedimension)
            end
            
            if isfield(headerInfo, 'space')
                if tmp_spacedimension ~= internal_spacedimension
                    error(['%s: ''space dimension'' field specifier set to %d, ' ...
                        'which differs from the space (world) dimension implied by the ' ...
                        '''space'' field specifier which is equal to %d.'],...
                            fopen(fidr), tmp_spacedimension, internal_spacedimension)
                end
                % if no inconsistencies found, just ignore space dimension
                % field
            else
                % Set space info for the first time:
                headerInfo.spacedimension = tmp_spacedimension;
                internal_spacedimension = tmp_spacedimension;  % for internal use only
            end
            
        elseif foundKeyword('SPACE DIRECTIONS:', cs )
            % Required if orientation defined but must come after space or
            % space dimension
            % space directions: <vector[0]> <vector[1]> ... <vector[dim-1]>
            % The format of the <vector> is as follows. The vector is
            % delimited by "(" and ")", and the individual components are
            % comma-separated. 
            if ~define_orientation
               error('%s: field specifier ''space directions'' cannot be set before ''space'' or ''space dimension''.',fopen(fidr))
            end

            space_dir_tmp = strtrim(cs(length('SPACE DIRECTIONS:')+1:end));     % remove leading and trailing spaces

            spacedir_vecs = strsplit(space_dir_tmp); %  cell array of strings after split at {' ','\f','\n','\r','\t','\v'}
            SD_data = zeros(internal_spacedimension, internal_spacedimension);
            
            % Check each vector: either none or (f1,...,f_spaceDim) with fi
            % a floating-point number
            cnt_space_vectors = 0;
            for i = 1:length(spacedir_vecs)
                none_start_index = strfind(lower(spacedir_vecs{i}), 'none');
                if ~isempty(none_start_index)
                    % Axis-specific entry contains substring none
                    if ~strcmpi(spacedir_vecs{i}, 'none')
                        fprintf(['WARNING nhdr_nrrd_read: detected %s instead of ' ...
                            'expected none for axis %d of the per-axis field specifications "space directions:".\n' ...
                            ' There should be no quotation marks, parentheses or any other characters, just plain none.\n'],...
                            spacedir_vecs{i}, i);
                        % Clean none vector specification
                        spacedir_vecs{i} = 'none';
                    end
                else
                    % Axis-specific entry is a numerical vector 
                    cnt_space_vectors = cnt_space_vectors + 1;
                    if cnt_space_vectors > internal_spacedimension
                        error(['%s:\n ''space directions'' field specifier: ' ...
                            'number of space vectors detected exceeds space (world)' ...
                            ' dimension, which is equal to %d.'],...
                            fopen(fidr), internal_spacedimension)
                    end
                    btw_parentheses = spacedir_vecs{i}(1) == '(' ...
                                        && spacedir_vecs{i}(end) == ')';
                    axis_vector = regexprep(spacedir_vecs{i}, '[()]', ''); % stripped off all parens
                    if ~btw_parentheses
                        fprintf(['WARNING nhdr_nrrd_read: vector should be delimited ' ...
                                'by parentheses for axis %d of the per-axis field ' ...
                                'specifications "space directions:".\n' ...
                                ' At least one missing parenthesis in ''%s''.\n'],...
                                i, spacedir_vecs{i})
                    end
                    % Clean up by forcing single enclosing parentheses:
                    spacedir_vecs{i} = ['(',  axis_vector,  ')'];
                    % Check vector and extract numerical data
                    vector_entries = strsplit(axis_vector, ',');
                    if length(vector_entries) ~= internal_spacedimension
                        error(['%s:\n vector for data axis %d (space axis %d) of the ' ...
                                'per-axis field specifications "space directions:" should ' ...
                                'contain %d entries corresponding to the space (or world) dimension ' ...
                                'specified in the "space" or "space dimension" field specification.' ...
                                ' Found %d here.'],...
                                fopen(fidr), i, cnt_space_vectors, internal_spacedimension, ...
                                length(vector_entries))                            
                    end
                    for j = 1:length(vector_entries)
                        vector_entry = sscanf(vector_entries{j}, '%f');
                        if isempty(vector_entry)
                            error(['%s\n in field specification "space directions:",  ' ...
                                'vector for data axis %d (space axis %d) too short. ' ...
                                'Detected %d entries instead of expected %d corresponding to ' ...
                                'space (world) dimension.'],...
                                fopen(fidr), i, cnt_space_vectors, j-1, internal_spacedimension)
                        end
                        SD_data(j, cnt_space_vectors) = vector_entry;
                    end
                end
            end
            % Store array of cleaned up strings
            headerInfo.spacedirections = spacedir_vecs;               % cell array of strings, ideally of the form {'(1,0,0)' '(0,2,0.1)' 'none'  '(0.1,0.1,1.1)'} if internal_spacedimension==3

            % Extract numerical data more leniently:
            SD_data_chk = strrep(space_dir_tmp, 'none', '' );                       % ignore "none" entries
            SD_data_chk = extractNumbersWithout(SD_data_chk, {'(',')',',', '"', ''''} );           % detects numbers up to first non numerical entry
            if numel(SD_data_chk) ~= (internal_spacedimension)^2
                   error(['Expected ''space directions'' to specify a %d-by-%d matrix ' ...
                       '(%d elements in total) in agreement with world space dimension.' ...
                       ' Found %d element(s) instead.\n'],...
                            internal_spacedimension, internal_spacedimension,...
                            (internal_spacedimension)^2, numel(SD_data_chk));
            end

            % Sanity check
            if ~isequal(SD_data_chk(:), SD_data(:))
               error(['%s:\n ''space directions'' field specifier: couldn''t' ...
                   ' read space vectors. Please refer to the NRRD format definition.'],...
                   fopen(fidr)) 
            end
            headerInfo.spacedirections_matrix = SD_data;
            % Correctness of field specification is checked below after 
            % whole header is parsed because we need to be sure that the 
            % "dimension" basic field specification was set

        elseif foundKeyword('SPACE UNITS:', cs )
            % Always optional, must come after space or space dimension
            if define_orientation ~= 1
                error('Field specification ''space units'' cannot be specified before ''space'' or ''space dimension''.')
            end
            
            space_units_tmp = strrep( cs(length('SPACE UNITS:')+1:end), 'none', '');        % ignore none entries
            % FIXME:  ideally, check that the sum of elements including none and
            % " " matches headerInfo.dimension, i.e. the total dimension, as
            % specified in the standard. Standard a bit unclear: should
            % unknown units be specified with "???", "none" or "" ? (quotes
            % seem to be required). 
            
            headerInfo.spaceunits = extract_spaceunits_list( space_units_tmp );
            
            if length(headerInfo.spaceunits) ~= internal_spacedimension
               error(['Expected ''space units'' to contain %d elements enclosed in double quotes' ...
                   ' to match the ''space'' or ''space dimension'' field but found the following ' ...
                   '%d element(s):\n%s'],...
                   internal_spacedimension, length(headerInfo.spaceunits), sprintf('%s\t',headerInfo.spaceunits{:})) 
            end
            
        elseif foundKeyword('SPACE ORIGIN:', cs )
            % Always optional, must come after space or space dimension
            
            assert(define_orientation==1, ...
                    sprintf(['%s: field ''space origin'' cannot be specified' ...
                            ' before ''space'' or ''space dimension''.'], ...
                            fopen(fidr)));
            
            iSO = extractNumbersWithout( cs(length('SPACE ORIGIN:')+1:end), {'(',')',','} );
            
            assert(numel(iSO) == internal_spacedimension,...
                    sprintf(['%s: expected ''space origin'' to specify a ' ...
                            '%d-element vector to match the ''space'' or ' ...
                            '''space dimension'' field but found %d ' ...
                            'element(s).'],...
                            fopen(fidr),internal_spacedimension, numel(iSO)) );
            
            headerInfo.spaceorigin = iSO(:);
            
        elseif foundKeyword('MEASUREMENT FRAME:', cs )
            % Always optional, must come after space or space dimension
            
            assert(define_orientation==1,...
                    sprintf(['%s: field ''measurement frame'' cannot be ' ...
                            'specified before ''space'' or ''space dimension''.'],...
                            fopen(fidr)));
            
            measframe_str = strrep( cs(length('MEASUREMENT FRAME:')+1:end), 'none', '');
            
            iMF = extractNumbersWithout( measframe_str, {'(',')',','} ); % fails if non number entries are not previously removed
            
            assert(numel(iMF) == (internal_spacedimension)^2,...
                sprintf(['%s: expected ''measurement frame'' to specify a ' ...
                        '%d-by-%d matrix (%d total elements) but found %d ' ...
                        'element(s).'],...
                        fopen(fidr), internal_spacedimension, ...
                        internal_spacedimension, (internal_spacedimension)^2,...
                        numel(iMF)));
            
            headerInfo.measurementframe = reshape(iMF(:), [internal_spacedimension, internal_spacedimension]);
            
            % FIXME: this will gladly accept '1 0 0 0 1 0 0 0 1' instead of
            % '(1,0,0) (0,1,0)  (0,0,1)' for instance. But it should have
            % length spacedimension according to standard so this is not too bad.
            
        elseif foundKeyword('THICKNESSES:', cs )
            
            sThicknesses = extractStringList( cs(length('THICKNESSES:')+1:end) ); % fixed bug with extractStringList where 2 entries are present
            iThicknesses = [];
            lenThicknesses = length( sThicknesses );
            for iI=1:lenThicknesses
                iThicknesses = [iThicknesses, str2double(sThicknesses{iI}) ];
            end
            headerInfo.thicknesses = iThicknesses;
            
        elseif foundKeyword('CENTERINGS:', cs )
            
            headerInfo.centerings = extractStringList( cs(length('CENTERINGS:')+1:end ) ); % fixed bug with extractStringList where 2 entries are present
            
        elseif foundKeyword('LINE SKIP:', cs) || foundKeyword('LINESKIP', cs)
            
            if foundKeyword('LINE SKIP:', cs)
                headerInfo.lineskip = sscanf( cs( length('LINE SKIP:')+1:end ), '%d' );
            else
                headerInfo.lineskip = sscanf( cs( length('LINESKIP:')+1:end ), '%d' );
            end
            assert(headerInfo.lineskip >= 0,...
                    sprintf(['Field lineskip or line skip should be greater' ...
                            ' than or equal to zero, detected %d.'], ...
                            headerInfo.lineskip));

        elseif foundKeyword('BYTE SKIP:', cs) || foundKeyword('BYTESKIP:', cs)
            
            if foundKeyword('BYTE SKIP:', cs)
                headerInfo.byteskip = sscanf( cs( length('BYTE SKIP:')+1:end ), '%d' );
            else
                headerInfo.byteskip = sscanf( cs( length('BYTESKIP:')+1:end ), '%d' );
            end
            assert(headerInfo.byteskip >= -1, ...
                    sprintf(['Field byteskip or byte skip can only take ' ...
                            'non-negative integer values or -1, detected %d.'], ...
                            headerInfo.byteskip));
            
        elseif foundKeyword('MODALITY', cs )
            
            headerInfo.modality = strtrim( extractKeyValueString( cs(length('MODALITY')+1:end ) ) );
            
        elseif foundKeyword('DWMRI_B-VALUE', cs )
            
            headerInfo.bvalue = str2double( extractKeyValueString( cs(length('DWMRI_B-VALUE')+1:end ) ) );
            
        elseif foundKeyword('DWMRI_GRADIENT_', cs )
            
            [iGNr, dwiGradient] = extractGradient(cs(length('DWMRI_GRADIENT_')+1:end ));
            headerInfo.gradients(iGNr+1,:) = dwiGradient;
            % FIXME: make it more general than numbering limited to 4 digits?
            
        elseif foundKeyword('DATA FILE:', cs ) || foundKeyword('DATAFILE:', cs)
            % This tells us it is a detached header and ends it. 3 possibilities here
            
            field_value = strtrim( cs(length('DATA FILE:')+1:end) );
            if foundKeyword('DATAFILE:', cs)
                field_value = strtrim( cs(length('DATAFILE:')+1:end) );
            end
            
            [filelist, LIST_mode, subdim] = extract_datafiles(field_value);
            
            
            headerInfo.datafiles = filelist;
            
            % In LIST mode, filelist is empty and is filled by reading the
            % rest of the header
            if LIST_mode
                datafile_cnt = 0;
                while ~feof(fidr)
                    cs = fgetl(fidr);
                    if isempty(cs)
                        break;
                    end
                    datafile_cnt = datafile_cnt + 1;
                    headerInfo.datafiles{datafile_cnt} = cs;
                end
            end
            
            % We could technically break the loop here bc data file/datafile is
            % supposed to close a header; however I think it does no harm to
            % keep parsing (in LIST_mode, end of file reached anyways)
            
        else
            
            % see if we are dealing with a comment
            
            csTmp = strtrim( cs );
            if csTmp(1)~='#' && ~strcmp(cs(1:4),'NRRD')
                fprintf('WARNING nhdr_nrrd_read: Could not parse input line: ''%s'' \n', cs );
                % REVIEW: is it better to blindly write it to the output
                % structure in order to be able to write the exact same file
                % later on ?
            end
        end
        
    end
    
    
    % Check for required fields 
    % REVIEW: should this be checked only when the data is read? People 
    % might be interested in just parsing the header no matter what is 
    % in it...)
    assert(isfield(headerInfo, 'sizes'), 'Missing required ''sizes'' field in header');
    assert(isfield(headerInfo, 'dimension'), 'Missing required ''dimension'' field in header');
    assert(isfield(headerInfo, 'encoding'), 'Missing required ''encoding'' field in header');
    assert(isfield(headerInfo, 'type'), 'Missing required ''type'' field in header');

    % Check other cross-field dependencies, etc. 
    % TODO: assert lengths of all
    % fields specified, check that kinds and axis sizes match, etc.
    if isfield(headerInfo, 'byteskip') && headerInfo.byteskip == -1
        assert( strcmpi(headerInfo.encoding, 'raw'), ...
            sprintf('byte skip value of -1 is only valid with raw encoding. See definition of NRRD File Format for more information.\n'));
    end
           
    matlabdatatype = nrrd_getMatlabDataType(headerInfo.type);
    
    %  endian field required if data defined on 2 bytes or more
    if ~(any(strcmpi(headerInfo.encoding,{'txt', 'text', 'ascii'})) || any(strcmpi(matlabdatatype, {'int8', 'uint8'})))
        assert(isfield(headerInfo, 'endian'), 'Missing required ''endian'' field in header');
    else
        if ~isfield(headerInfo,'endian')
            headerInfo.endian = 'little';    % useless but harmless, just for code compatibility because endian field may be accessed later on while reading data
        end
    end
    
    % Space and orientation information
    if define_orientation
        assert(isfield(headerInfo, 'spacedirections'), ...
                ['Missing field ''space directions'', required if either' ...
                ' ''space'' or ''space dimension'' is set.']);
        if length(headerInfo.spacedirections) ~= headerInfo.dimension
            fprintf(['WARNING nhdr_nrrd_read %s:\n Unexpected format found for ''space directions'' specifier.\n',...
                    ' Expected none entries and vectors delimited by parentheses such as (1.2,0.2,0.25), ', ...
                    'the number of entries being equal to the dimension field specification.\n',...
                    ' See definition of NRRD File Format for more information.\n'], fopen(fidr));
        end
    end
    
    % TODO: add support for positive line skips 
    if isfield(headerInfo, 'lineskip') && headerInfo.lineskip > 0
        assert(isfield(headerInfo, 'byteskip') && headerInfo.byteskip == -1, ...
            sprintf(['lineskip option is currently not supported and can ' ...
                    'only be set to zero unless raw encoding is used and ' ...
                    'byte skip is set to -1 (which cancels the effect of ' ...
                    'lineskip altogether).']));
    end  
    
    % TODO: add support for positive byte skips (see line skip)
    if isfield(headerInfo, 'byteskip') && ~strcmpi(headerInfo.encoding,'raw')
        assert( headerInfo.byteskip == 0, ...
            sprintf('byte skip option with non raw encoding is currently not supported and can only be set to zero.\n'));
    end
    if isfield(headerInfo, 'byteskip') && strcmpi(headerInfo.encoding, 'raw')
        assert( headerInfo.byteskip == -1, ...
            sprintf('non-negative byte skip values with raw encoding are currently not supported; byte skip can only be set to -1.\n'));
    end
    
catch me
    % Clean up before raising error
    fclose(fidr);
    rethrow(me);
end

% Read the data. Detect if data is in the file or in a detached data file
% and check what type of detached file it is if need be.
if bReadData
    N_data_tot = prod(headerInfo.sizes);
    if isfield(headerInfo, 'datafiles')
        % This is a detached header file
        
        % We no longer need to read the header (closing it before reading
        % all the detached data files is safer)
        fclose(fidr);           
        
        % TODO: we currently only read slices along the slowest axis (i.e.,
        % last coordinate)
        if ~isempty(subdim) && subdim~=headerInfo.dimension
            error(['(detached header): reading data from slices along axis other than the last' ...
                ' (i.e. slowest) one, is currently not supported.\n' ...
                'Last argument [<subdim>] in ''data file'' or ''datafile'' field ' ...
                'should be removed or set equal to %d, which is the detected' ...
                ' ''dimension'' field value, for now.'],...
                        headerInfo.dimension);
        end
        
        % Read data chunk by chunk from detached data files
        N_data_files = length(headerInfo.datafiles);
        assert(mod(N_data_tot, N_data_files)==0, ...
            sprintf(['Number of detected data files (%d) does not divide total' ...
                    ' number of values contained in data %d obtained from prod(sizes=[%s]).\n'],...
                    N_data_files, N_data_tot, sprintf('%d ',headerInfo.sizes)));
        
        N_data_per_file = N_data_tot/N_data_files;
        
        headerInfo.data = zeros(headerInfo.sizes, matlabdatatype);      % specify right type of zeros, otherwise double by default
        
        for i = 1:N_data_files
            
            % Check type of detached data file
            [~,fname_data,ext_data] = fileparts(headerInfo.datafiles{i});        % redundant because done above
            
            data_ind = (i-1)*N_data_per_file+1:i*N_data_per_file;
            
            if strcmpi(ext_data,'.nhdr')
                
                error(['datafile %di/%d: nhdr file should not be used as ' ...
                        'detached data file.'], ...
                        i, length(headerInfo.datafiles));
                
            elseif strcmpi(ext_data, '.nrrd')
                % Detached NRRD file
                
                bRead_Detached_Data = true;
                tmp_struct = nhdr_nrrd_read(fullfile(mainFpath, ...
                                            [fname_data, ext_data]), ...
                                            bRead_Detached_Data);   % recursive call
                % TODO: check the rest of the structure for
                % inconsistencies with metadata from header
                assert(N_data_files==1 || headerInfo.dimension == tmp_struct.dimension +1, ...
                    sprintf(['Detached header %s: the number of dimensions in detached ' ...
                            'nrrd data file %d/%d (%s) should be one fewer than that of' ...
                            ' the header file.\nDetected %d instead of %d.\nDifferent ' ...
                            'datafile dimensions as specified by the nrrd standard are' ...
                            ' not supported as of now.\n'],...
                            fopen(fidr), i, N_data_files, headerInfo.datafiles{i},...
                            tmp_struct.dimension, headerInfo.dimension-1 ));
                
                headerInfo.data(data_ind) = tmp_struct.data(:);
                
                % Store detached data header for last detached file seen,
                % assuming that all are the same. Do not store data though
                % as it would be redundant.
                tmp_struct = rmfield(tmp_struct, 'data');
                headerInfo.detached_header = tmp_struct;

            else
                % e.g., detached .raw file
                
                fid_data = fopen( fullfile(mainFpath, [fname_data, ext_data]), 'r');
                if( fid_data < 1 )
                    error(['While reading detached header file %s:\ndetached ' ...
                           'data file number %d/%d (%s) could not be opened.'], ...
                           nrrdFileName, i, N_data_files, headerInfo.datafiles{i});
                end
                try
                    tmp_data = readData(fid_data, N_data_per_file, headerInfo.encoding, matlabdatatype);
                    fclose(fid_data);
                catch me_detached
                    fclose(fid_data);
                    rethrow(me_detached);
                end
                
                tmp_data = adjustEndian(tmp_data, headerInfo.endian);
                
                headerInfo.data(data_ind) = tmp_data(:);
            end
            
        end
        
    else
        % This is a NRRD standalone file: read data directly from it
        try
            headerInfo.data = readData(fidr, N_data_tot, headerInfo.encoding, matlabdatatype);
            fclose(fidr);
        catch me_detached
            fclose(fidr);
            rethrow(me_detached);
        end        
        headerInfo.data = adjustEndian(headerInfo.data, headerInfo.endian);
        headerInfo.data = reshape(headerInfo.data, headerInfo.sizes(:)');   % data into expected form. Transpose required by reshape function bc size vectors need to be row vectors
    end
else
    fclose(fidr);
end




end

% -------------------------------------------------------------------%

% ====================================================================
% --- Auxiliary functions -------------------------------------------%
% ====================================================================

function [iGNr, dwiGradient] = extractGradient( st )

% first get the gradient number

iGNr = str2num( st(1:4) ); % FIX numbering limited to 4 digits (synchronize with writer module)

% find where the assignment is

assgnLoc = strfind( st, ':=' );

if ( isempty(assgnLoc) )
    dwiGradient = [];
    return;
else
    
    dwiGradient = sscanf( st(assgnLoc+2:end), '%f' );
    
end

end

% Return part of string after :=
function kvs = extractKeyValueString( st )

assgnLoc = strfind( st, ':=' );

if ( isempty(assgnLoc) )
    kvs = [];
    return;
else
    
    kvs = st(assgnLoc(1)+2:end);
    
end

end

% Turn space-separated list into cell array of strings. 
function sl = extractStringList( strList )
sl = strsplit(strtrim(strList)); % old Matlab file exchange version had a strange bug with lists of length 2
end


% Store in an array the list of numbers separated by the tokens listed in
% the withoutTokens cell array 
function iNrs = extractNumbersWithout( inputString, withoutTokens )

auxStr = inputString;

for iI=1:length( withoutTokens )
    
    auxStr = strrep( auxStr, withoutTokens{iI}, ' ' );
    
end

iNrs = sscanf( auxStr, '%f' );

end

% Return true if the string keyWord is the beginning of the content string
% cs (ignoring case)
function fk = foundKeyword( keyWord, cs )
lenKeyword = length( keyWord );
fk = (lenKeyword <= length(cs)) && strcmpi( cs(1:lenKeyword), keyWord);
end

% Return cell array of strings with space units in the form {mm, km, m}
% from input of the form "mm " "mm" " m" where undesired blank spaces may
% have crept in. The double quotes are removed in the process but will be
% added by the nhdr/nrrd writer function.
function su_ca = extract_spaceunits_list( fieldValue )
fv_trimmed = strtrim( fieldValue );
su_ca = strsplit(fv_trimmed, '"');                              % units are delimited by double quotes
su_ca = su_ca(~ ( strcmp(su_ca, '') | strcmp(su_ca, ' ') ) );   % remove empty or blank space strings
for i = 1:length(su_ca)
    su_ca{i} = strtrim( su_ca{i} );
end
end


% Extract data file list into a cell array from the datafile or data file
% field in a NHDR file, stripped off its leading and trailing spaces;
% LIST_mode is set to one if a list of files closes the header;
% subdim is empty by default and may be set through either of these field
% specifications:
% data file: <format> <min> <max> <step> [<subdim>]
% data file: LIST [<subdim>]

function [filelist, LIST_mode, subdim] = extract_datafiles( field_string)

field_string = strtrim(field_string);
filelist = {};
LIST_mode = 0;
subdim = [];
if length(field_string)>= 4 && strcmpi(field_string(1:4), 'LIST')
    % LIST mode
    subdim = sscanf(field_string(5:end), '%d'); % assert 1<=dimensions 
    LIST_mode = 1;
    return;
else
    % single detached data file or multiple files written in concise form, non LIST mode
    str_lst = strsplit(field_string); % without delimiters specified, splits at any sequence in the set  {' ','\f','\n','\r','\t','\v'}
    if length(str_lst) == 1
        % Single detached data file:
        filelist{1} = str_lst{1};
        % subdim does not make sense here since all of the data is
        % contained in the deatached data file
    elseif any(length(str_lst)==[0, 2, 3]) || length(str_lst)>5 
        % Invalid cases (2, 3 or striclty more than 5 entries)
        error(['error in ''data list'' (or ''data list'') field, in non' ...
                ' ''LIST'' mode:\nexpected  ''<filename>'' or ''<format> ' ...
                '<min> <max> <step> [<subdim>]'' but found instead ''%s'' ' ...
                '(%d elements instead of 1, 4 or 5).'],...
                sprintf('%s ',str_lst{:}), length(str_lst));
    else 
        % Multiple detached data files with filenames including integral
        % values generated by min:step:max
                
        str_format = str_lst{1};
        id_min = sscanf(str_lst{2}, '%d');
        id_max = sscanf(str_lst{3}, '%d');
        step = sscanf(str_lst{4}, '%d');
        
        % check format and indexing values
        assert(step~=0,...
                sprintf(['detached data files with names specified by ' ...
                        'sprintf()-like format:  step should be strictly positive' ...
                        ' or negative, not zero.']));
        if step < 0
            assert(id_min >= id_max, ...
                    sprintf(['detached data files with names specified by ' ...
                            'sprintf()-like format:  when step is <0, min ' ...
                            'should be larger than or equal to max, here we ' ...
                            'found min=%d < max=%d.'],id_min, id_max));
        else
            assert(id_min <= id_max,...
                    sprintf(['detached data files with names specified by ' ...
                            'sprintf()-like format: : when step is >0, min ' ...
                            'should be smaller than or equal to max, here we ' ...
                            'found min=%d > max=%d.'],id_min, id_max));
        end
         
        % populate data file list
        fileIDs = id_min:step:id_max;
        filelist = cell(length(fileIDs), 1);
        for i = 1:length(fileIDs)  % does not necessarily incude <max>, it cannot be larger than <max> 
            expanded_fname = sprintf(str_format, fileIDs(i));
            filelist{i} = expanded_fname;
        end
        
        if length(str_lst) == 5
            subdim = sscanf(str_lst{5}, '%d');
        end   
    end
end
        

end


% Read data in a column vector from open file with pointer fidIn at the
% beginning of the data to read. The other arguments specify the number of
% elements to read (determined in main body of reader function above), data
% file encoding (specified in NHDR/NRRD header) and the Matlab type the
% data should be converted to (determined in main body of reader function
% above).
function data = readData(fidIn, Nelems, meta_encoding, matlabdatatype)

switch (meta_encoding)
    case {'raw'}
        % This implicitely assumes that byteskip was set to -1 in raw
        % encoding
        data_bytes = (Nelems)*sizeOf(matlabdatatype);   % bytes of useful info to return in data array
        fseek(fidIn,0,'eof');                           % set position pointer to end of file
        tot_bytes_file = ftell(fidIn);                  % current location of the position pointer (I believe as a byte offset from beginning of file)
        fseek(fidIn,tot_bytes_file-data_bytes,'bof');   % make sure position pointer is right before useful data starts
        
        % Just read binary file (original version of the code)
        data = fread(fidIn, inf, [matlabdatatype '=>' matlabdatatype]);
        
    case {'gzip', 'gz'}
        
        tmp = fread(fidIn, Inf, 'uint8=>uint8'); % byte per byte
        
        tmpBase = tempname(pwd);
        tmpFile = [tmpBase '.gz'];
        fidTmp = fopen(tmpFile, 'wb');  % this creates tmpFile
        assert(fidTmp > 3, 'Could not open temporary file for GZIP decompression')
        
        try
            fwrite(fidTmp, tmp, 'uint8');
        catch me
            fclose(fidTmp);
            delete(tmpFile);
            rethrow(me);
        end
        fclose(fidTmp);        
        
        try
            gunzip(tmpFile); % this creates tmpBase (tmpFile without the .gz)
        catch me
            delete(tmpFile);
            rethrow(me);
        end
        delete(tmpFile);
        
        fidTmp = fopen(tmpBase, 'rb');
        % cleaner = onCleanup(@() fclose(fidTmp));
        try
            data = readData(fidTmp, Nelems, 'raw', matlabdatatype); % recursive call            
        catch me
            fclose(fidTmp);
            delete(tmpBase);
            rethrow(me);
        end
        fclose(fidTmp);
        delete(tmpBase);

    case {'txt', 'text', 'ascii'}
        
        data = fscanf(fidIn, '%f');
        data = cast(data, matlabdatatype);
        
    otherwise
        assert(false, 'Unsupported encoding')
end
% Check number of read elements (sometimes there is an offest of about 1)
assert(Nelems == numel(data),...
        sprintf(['Error reading binary content of %s: detected %d elements' ...
                ' instead of %d announced in header.'],...
                fopen(fidIn), numel(data), Nelems));
end


% Switch byte ordering according to endianness specified in nhdr/nrrd file.
% The metadata should just contain a field 'endian' set to 'little' or
% 'big'.
function data = adjustEndian(data, meta_endian)

[~,~,endian] = computer();

needToSwap = (isequal(endian, 'B') && isequal(lower(meta_endian), 'little')) || ...
    (isequal(endian, 'L') && isequal(lower(meta_endian), 'big'));

if (needToSwap)
    data = swapbytes(data);
end
end

% Size of Matlab's numeric classes in bytes
% See: https://stackoverflow.com/questions/16104423/size-of-a-numeric-class

function numBytes = sizeOf(dataClass)

    % create temporary variable of data type specified
    eval(['var = ' dataClass '(0);']); 

    % Use the functional form of whos, and get the number of bytes   
    W = whos('var');
    numBytes = W.bytes;

end

% Write NHDR/NRRD files
% 
% headerInfo = nhdr_nrrd_write(nrrdFileName, headerInfo, bWriteData)
%
% Inputs:
% * nrrdFilename (char): path to NHDR/NRRD file(s), either a detached header,
% a detached header pointing to detached data files or a nrrd standalone
% depending on what is specified in headerInfo
% * headerInfo (struct): structure containing all the required and optional
% NRRD fields, such as produced by nhdr_nrrd_read.m, as well as the data. 
% List of accepted structure field names with corresponding NRRD fields in
% parentheses:
%   - byteskip (byte skip: <desc>): scalar integer. For now, can only
%       accept -1 with raw encoding and 0 with all other encodings;
%	- content (content: <desc>): string;
%	- data (~): numerical array containing the raw data;
%	- datafiles (data file: <desc>): cell array of strings containing the
%       paths to detached data files relative to the header file. This can 
%       be a simple string if there is only one detached data file;
% 	- detached_header (~): Matlab structure containing all the fields 
%       required to write valid detached NRRD files containing the data. 
%       All detached NRRD data files are assumed to have the same header;
% 	- dimension (dimension: <desc>): scalar integer;
%   - encoding (encoding: <desc>): string;
%   - kinds (kinds: <desc>): cell array of strings;
%   - lineskip (line skip: <desc>): scalar integer. For now, can only be 
%       set to zero unless raw encoding is used and byte skip is set to -1
%       (which cancels the effect of line skip altogether);
%   - measurementframe (measurement frame: <desc>): matrix of size 
%       [Ns, Ns], where Ns in the number of space dimensions;
%   - sizes (sizes: <desc>): matrix of size [1, d] or [d, 1] where d is the
%       dimension;
%   - space (space: <desc>): string;
%   - spacedimension (space dimension: <desc>): scalar integer;
%   - spacedirections (space directions: <desc>): cell array of strings 
%       for code compatibility, e.g. 
%       {'(1,0,0)' '(0,2,0.1)' 'none'  '(0.1,0.1,1.1)'} for 3 
%       world space dimensions;
%   - spacedirections_matrix (~): matrix of size [Ns, Ns] where Ns is the 
%       number of space dimensions. Should match the string description 
%       contained in spacedirections, if specified;
%   - spaceorigin (space origin: <desc>): matrix of size [1, Ns] or [Ns, 1]
%       where Ns is the number os space dimensions;
%   - spaceunits (space units: <desc>): cell array of strings;
%   - type (type: <desc>): string.
%  
%   - bvalue (bvalue:=<value>): floating-point scalar (nominal b-value);
%   - modality (modality:=<value>): string
%   - gradients (DWMRI_gradient_%04d:=<value>): matrix of size [Ng, 3] 
%       where Ng is the number of gradients in a PGSE-type 
%       diffusion-weighted MRI protocol. Note that the b-value associated 
%       with each gradient [g_x, g_y, g_z] is computed as 
%       b = b_nom*(g_x^2 + g_y^2 + g_z^2), where b_nom is the
%       nominal b-value, so the gradients must be scaled accordingly;
% * bWriteData (bool): set to true to write the data specified in
% headerInfo.data, set to false to just write the header file without the
% data
%
% Outputs:
% * headerInfo (struct): same structure as that passed as argument with
% additional (potentially mandatory) fields if inferrable from the data,
% such as 'dimension', 'sizes', etc.
%
% The function creates all the required NHDR/NRRD file(s).
%
% See nhdr_nrrd_read.m for more information.
%
%
% % Format definition:
% http://teem.sourceforge.net/nrrd/format.html
%
% Date: August 2018
% Author: Gaetan Rensonnet
function headerInfo = nhdr_nrrd_write(nrrdFileName, headerInfo, bWriteData)

[path_main_header,  ~, fext] = fileparts(nrrdFileName);
if isfield(headerInfo, 'datafiles')
    assert(strcmpi(fext, '.nhdr'), sprintf('Invalid filename extension ''%s''. A detached nrrd header (headerInfo structure contains ''datafiles'' field) should have extension ''.nhdr''.\n',fext));
else
    assert(strcmpi(fext, '.nrrd'), sprintf('Invalid filename extension ''%s''. A standalone nrrd file (no ''datafiles'' field in headerInfo structure) should have extension ''.nrrd''.\n',fext));
end

header_fnames = fieldnames(headerInfo);             % cell array of strings
fnames_parsed = false(1,length(header_fnames));     % flags field names from header successfully parsed

% --- Checking availability of required information before opening files ---
% Guess as much from the data as possible

% Check required 'sizes' information
if isfield(headerInfo, 'sizes')
    if isfield(headerInfo, 'data') 
        assert(nrrd_size_check(size(headerInfo.data), headerInfo.sizes),...
        sprintf('Sizes mismatch: [%s] in headerInfo structure is not compatible with the size of the data array [%s].\n',...
                                    sprintf('%d ',headerInfo.sizes), sprintf('%d ',size(headerInfo.data)) ));
    end
else
    assert( isfield(headerInfo, 'data'), sprintf('Missing required field ''sizes'' in headerInfo structure, cannot be deduced from data because no data was provided.\n'));
    headerInfo.sizes = size(headerInfo.data);
end

% Check required 'dimension' information
if isfield(headerInfo, 'dimension')
    assert( isequal(headerInfo.dimension, length(headerInfo.sizes)), sprintf('Dimension mismatch: %d in headerInfo structure is not compatible with detected data size [%s].\n',...
                                            headerInfo.dimension, sprintf('%d ', headerInfo.sizes)));
else
    headerInfo.dimension = length(headerInfo.sizes);
end

% Check required 'type' information
if isfield(headerInfo, 'type')
    matlabdatatype = nrrd_getMatlabDataType(headerInfo.type);
    if isfield(headerInfo, 'data')
        assert( isequal(class(headerInfo.data), matlabdatatype), ...
            sprintf('Type mismatch: %s in headerInfo structure is not compatible with the Matlab type of the data array (%s).\nYou may want to look at nrrd_getMatlabDataType and at Matlab''s cast functions.',headerInfo.type, class(headerInfo.data)));
    end
else
   assert( isfield(headerInfo, 'data'), sprintf('Missing required field ''type'' in headerInfo structure, cannot be deduced from data because no data was provided.\n'));
   headerInfo.type = get_nrrd_datatype(class(headerInfo.data));
end

% Check required 'encoding' information
if ~isfield(headerInfo, 'encoding')
    headerInfo.encoding = 'raw';
end

% Set endianness to current platform's endianness
[~,~,endian] = computer();
if (isequal(endian, 'B'))
    headerInfo.endian = 'big';
else
    headerInfo.endian = 'little';
end

    
fidw = fopen( nrrdFileName, 'w');
if fidw == -1
    error('nhdr_nrrd_writer: could not open file %s.\n',nrrdFileName);
end

% if an error is thrown while parsing, close open file before exiting
try     
    % --- Traditional header and required fields ---

    fprintf( fidw, 'NRRD0005\n' );  
    fprintf( fidw, '# Complete NRRD file format specification at:\n' );
    fprintf( fidw, '# http://teem.sourceforge.net/nrrd/format.html\n' );

    if isfield(headerInfo,'content')
        fprintf( fidw, 'content: %s\n', headerInfo.content);  % always optional
        fnames_parsed(strcmpi('content', header_fnames)) = true;
    end

    fprintf( fidw, 'type: %s\n', headerInfo.type );
    fnames_parsed(strcmpi('type', header_fnames)) = true;

    fprintf( fidw, 'encoding: %s\n', headerInfo.encoding);
    fnames_parsed(strcmpi('encoding', header_fnames)) = true;

    fprintf( fidw, 'dimension: %d\n', headerInfo.dimension );
    fnames_parsed(strcmpi('dimension', header_fnames)) = true;

    fprintf( fidw, 'sizes: ' );
    for iI=1:length( headerInfo.sizes )
      fprintf( fidw, '%d', headerInfo.sizes(iI) );
      if ( iI~=length( headerInfo.sizes ) )
        fprintf( fidw, ' ' );
      end
    end
    fprintf( fidw, '\n' );
    fnames_parsed(strcmpi('sizes', header_fnames)) = true;

    fprintf( fidw, 'endian: %s\n', headerInfo.endian );
    fnames_parsed(strcmpi('endian', header_fnames)) = true;
    
    % ---- Defining orientation (always optional) -----
    
    define_orientation = 0;
    if isfield(headerInfo,'space')
        fprintf(fidw, 'space: %s\n', headerInfo.space );
        fnames_parsed(strcmpi('space', header_fnames)) = true;
        define_orientation = 1;
        num_sp_dim = nrrd_getSpaceDimensions(headerInfo.space);
    elseif isfield (headerInfo,'spacedimension')
        fprintf(fidw, 'space dimension: %d\n', headerInfo.spacedimension);
        fnames_parsed(strcmpi('spacedimension', header_fnames)) = true;
        define_orientation = 1;
        num_sp_dim = headerInfo.spacedimension;
    end
    % Space and space dimension fields cannot be specified simultaneously
    if isfield(headerInfo,'space') && isfield(headerInfo, 'spacedimension')
        error('The always optional fields ''space'' and ''spacedimension'' defining orientation cannot be specified simultaneously in headerInfo structure');
    end
    
    if define_orientation
        % So far the number of spatial dimensions should be 3 or 4
        % (this is important for writing space directions, space origin,
        % measurement frame)
        assert(num_sp_dim>=3, sprintf('Number of space dimensions should be at least 3 in current nrrd format, detected %d instead in headerInfo structure.\n',num_sp_dim));
        
        % check for necessary field 'space direction' when orientation defined
        if ~isfield(headerInfo, 'spacedirections')
            error('Missing field in headerInfo structure: spacedirections should always be specified if orientation is defined via ''space'' or ''space directions'' ');
        end
        
        assert(iscell(headerInfo.spacedirections), ...
            ['spacedirections field in headerInfo should be a cell array of ' ...
            'strings for code compatibility, e.g. {''(1,0,0)'' ''(0,2,0.1)'' ''none''  ''(0.1,0.1,1.1)''}' ...
            ' for 3 world space dimensions.'])

        % Check format and clean up when possible
        for i = 1:length(headerInfo.spacedirections)
            none_match = regexp(headerInfo.spacedirections{i}, 'none', 'match');
            if ~isempty(none_match)
                % none for non space axis
                if ~strcmpi(headerInfo.spacedirections{i}, 'none')
                   fprintf(['nhdr_nrrd_write WARNING: detected %s instead of ' ...
                       'expected none in header.spacedirections{%d}.\n Wrote clean version to output file(s).\n'],...
                       headerInfo.spacedirections{i}, i)
                end
                headerInfo.spacedirections{i} = 'none';
            else
                % numerical vector for space (world) axis
                btw_parentheses = headerInfo.spacedirections{i}(1) == '(' ...
                    && headerInfo.spacedirections{i}(end) == ')';
                if ~btw_parentheses
                   fprintf(['nhdr_nrrd_write WARNING: space vector in header.spacedirections{%d} ' ...
                       'should contain comma-separated values enclosed in single parentheses.\n ' ...
                       'At least one parenthesis missing here. Wrote clean version to output file(s).\n'],...
                         i)
                end
                headerInfo.spacedirections{i} = ['(' regexprep(headerInfo.spacedirections{i}, '[()]', ''), ')'];
            end
        end
        spacedir_str = strjoin(headerInfo.spacedirections, ' ');

        % Write to file
        fprintf(fidw, 'space directions: %s\n', spacedir_str);
        % Flag as parsed
        fnames_parsed(strcmpi('spacedirections', header_fnames)) = true;
        
        % Data defining space direction matrix
        SD_data = strrep(spacedir_str, 'none', '');
        SD_data = extractNumbersWithout(SD_data, {'(',')',',', '"', ''''});       % this fails if non numerical entries were not previously removed
        assert(length(SD_data) == num_sp_dim^2, sprintf('expected spacedirections field to contain %d numbers (square of %d, the world space dimension). Found %d instead.\nspacedirections should be a cell array of strings containing vectors of the form (dx,dy,dz) or none entries.\n',...
                                                        num_sp_dim^2, num_sp_dim, length(SD_data)))
        % Check spacedirections_matrix field (internal, not a NRRD field)
        if isfield(headerInfo, 'spacedirections_matrix')
            assert(isequal(headerInfo.spacedirections_matrix(:), SD_data(:)), ...
                sprintf('Numeric data in spacedirections and spacedirections_matrix fields of headerInfo do not match. They should contain %d identical numbers in the same order.\n', num_sp_dim^2))
        else
            % add it to output headerInfo structure 
            headerInfo.spacedirections_matrix = reshape(SD_data(:), [num_sp_dim, num_sp_dim]);  
        end
        fnames_parsed(strcmpi('spacedirections_matrix', header_fnames)) = true;
    end
    
    
    % --- optional options for the optional definition of orientation ---
    
    % space origin
    if isfield(headerInfo,'spaceorigin')
        if define_orientation
            so = headerInfo.spaceorigin;
            assert(length(so)==num_sp_dim, ...
                sprintf('Field ''spaceorigin'' in headerInfo structure expected vector with %d entries to match the defined orientation, detected %d entries instead.\n',num_sp_dim, length(so)));
            fprintf( fidw, 'space origin: (%f%s)\n', so(1), sprintf(',%f',so(2:end)) );
            fnames_parsed(strcmpi('spaceorigin', header_fnames)) = true;
        else
            error('Field ''spaceorigin'' in headerInfo structure cannot be specified if neither ''space'' nor ''spacedimension'' was specified.');
        end
    end
    
    % measurement frame
    if isfield(headerInfo,'measurementframe')
        if define_orientation
            mf = headerInfo.measurementframe;
            assert(size(mf,1)==num_sp_dim && size(mf,2)==num_sp_dim,...
                sprintf('Field ''measurementframe'' in headerInfo structure expected a %d-by-%d matrix to match the defined orientation, detected size [%s] instead.\n',...
                                                 num_sp_dim, num_sp_dim, sprintf('%d ',size(mf))));
                                             
            fprintf( fidw, 'measurement frame:');
            for imf = 1:size(mf,2)
               fprintf(fidw,' (%f%s)', mf(1,imf), sprintf(',%f',mf(2:end,imf)));                
            end
            fprintf(fidw, '\n');
            fnames_parsed(strcmpi('measurementframe', header_fnames)) = true;
        else
            error('Field ''measurementframe'' in headerInfo structure cannot be specified if neither ''space'' nor ''spacedimension'' were specified.');
        end
    end
    
    % spaceunits
    if isfield(headerInfo,'spaceunits')
        if define_orientation
            fprintf( fidw, 'space units: ' );
            for iI=1:length( headerInfo.spaceunits )
                fprintf( fidw, '\"%s\"', char(headerInfo.spaceunits(iI)) );
                if ( iI~=length( headerInfo.spaceunits ) )
                    fprintf( fidw, ' ' );
                end
            end
            fprintf( fidw, '\n' );
            fnames_parsed(strcmpi('spaceunits', header_fnames)) = true;
        else
            error('Field ''spaceunits'' in headerInfo structure cannot be specified if neither ''space'' nor ''spacedimension'' were specified.');
        end
    end
    % --- end of orientation definition -----
    
    % --- Optional fields "<field>: <desc>" ---- 
    
    % kinds
    if isfield(headerInfo, 'kinds')
        assert(length(headerInfo.kinds)==headerInfo.dimension, sprintf('Detected %d kinds instead of expected nrrd dimension %d.\n',length(headerInfo.kinds), headerInfo.dimension));
        fprintf( fidw, 'kinds: ' );
        for iI=1:length( headerInfo.kinds )
          fprintf( fidw, '%s', headerInfo.kinds{iI} );
          if ( iI~=length( headerInfo.kinds ) )
            fprintf( fidw, ' ' );
          end
        end
        fprintf( fidw, '\n' );
        fnames_parsed(strcmpi('kinds', header_fnames)) = true;
    end
    
    % line skip
    if isfield(headerInfo, 'lineskip')
       assert(headerInfo.lineskip >= 0, sprintf('Field ''lineskip'' in headerInfo structure should be non-negative, detected %d.\n', headerInfo.lineskip));
       fprintf(fidw, 'lineskip: %d\n', headerInfo.lineskip);
       fnames_parsed(strcmpi('lineskip', header_fnames)) = true;
    end
    
    % byte skip
    if isfield(headerInfo, 'byteskip')
       assert(headerInfo.byteskip >= -1, sprintf('Field ''byteskip'' should be -1 or a non-negative integer, detected %d.\n', headerInfo.byteskip));
       if headerInfo.byteskip == -1
           assert(strcmpi(headerInfo.encoding, 'raw'), sprintf('byte skip value of -1 is only valid with raw encoding.\n'));
       end
       fprintf(fidw, 'byteskip: %d\n', headerInfo.byteskip);
       fnames_parsed(strcmpi('byteskip', header_fnames)) = true;
    end
    
    % --- "<key>:=<value>"  pairs (always optional)
    
    % Modality 
    if isfield(headerInfo, 'modality')
       fprintf( fidw, 'modality:=%s\n',headerInfo.modality);
       fnames_parsed( strcmpi('modality', header_fnames)) = true;
    end
    
    % b-value 
    if isfield(headerInfo, 'bvalue')
        fprintf( fidw, 'DWMRI_b-value:=%9.8f\n', headerInfo.bvalue);
        fnames_parsed( strcmpi('bvalue', header_fnames)) = true;
    end
    
    % DW-MRI gradient
    if isfield(headerInfo, 'gradients')
       Ngrads = size(headerInfo.gradients, 1);
       for igrad = 1:Ngrads
           strprint = strcat('DWMRI_gradient_',sprintf('%04d',igrad-1)) ; % The 0 flag in the %04d format specifier requests leading zeros in the output and sets minimum width of the printed value to 4
           strprint = [strprint,':='] ;
           strprint = [strprint, sprintf('%9.8f ', headerInfo.gradients(igrad,:))] ;
           fprintf(fidw,[strprint '\n']) ;       
       end
       fnames_parsed(strcmpi('gradients', header_fnames)) = true;
       % FIXME: make it more general than numbering limited to 4 digits?        
    end
       
    
    % --- External datafiles (should be performed in LIST mode) ---
    
    if isfield(headerInfo, 'datafiles')
        % This is a detached header, not a standalone nrrd file
        
        % 'Convert' to cell array for code compatibility. This only works
        % with one filename and fails with a comma-separated list of
        % filenames for instance.
        if ischar(headerInfo.datafiles)
            headerInfo.datafiles = { headerInfo.datafiles};            
        end
            
        if length(headerInfo.datafiles)==1
            % data file: <filename> 
            fprintf(fidw, 'data file: %s\n',headerInfo.datafiles{1}); % path relative to detached header
        else
            % data file: LIST [<subdim>]
            % FIXME: add support for subdim argument instead of ignoring it
            fprintf(fidw, 'data file: LIST\n');
            for i = 1:length(headerInfo.datafiles)
               fprintf(fidw,'%s\n', headerInfo.datafiles{i}); 
            end
        end
        fnames_parsed(strcmpi('datafiles', header_fnames)) = true;
    end
    
catch me
    fclose(fidw);
    rethrow(me);
end

%% Write data
if bWriteData
    
    if isfield(headerInfo, 'datafiles')
        % This is a detached header, detached data files need to be
        % written to
        
        fclose(fidw);       % close main file
        
        N_data_tot = prod(headerInfo.sizes);
        
        % Read data chunk by chunk from detached data files
        N_data_files = length(headerInfo.datafiles);
        
        assert(mod(N_data_tot, N_data_files)==0, sprintf('Number of detected data files (%d) does not divide total number of values contained in data %d obtained from prod(sizes=[%s]).\n',...
            N_data_files, N_data_tot, sprintf('%d ',headerInfo.sizes)));
        
        N_data_per_file = N_data_tot/N_data_files;
        
        for i = 1:N_data_files
            
            % Check type of detached data file
            [~,fname_data,ext_data] = fileparts(headerInfo.datafiles{i}); 
            
            data_ind = (i-1)*N_data_per_file+1:i*N_data_per_file;   % indices of data to be written
            
            if strcmpi(ext_data,'.nhdr')
                
                error('datafile %di/%d: nhdr file should not be used as detached data file.\n',i,length(headerInfo.datafiles));
                
            elseif strcmpi(ext_data, '.nrrd')                
                % Detached nrrd file
                
                assert(isfield(headerInfo, 'detached_header'), sprintf('Missing field ''detached_header'' in headerInfo structure.\nThis is only required for detached headers with data stored in detached data files of type nrrd.\nShould contain a Matlab structure describing the chunk of data stored in the detached nrrd file (the data field, if present, will be overwritten).\nIt is assumed that the header is identical for all detached nrrd data files.\n'));
                % we have to check for all i's because detached nrrd files may be
                % interspersed with detached .raw or .hex files                   
                info_detached_data = headerInfo.detached_header;        % change headerInfo! put only part of the data, change dimensions, remove datalists
                fnames_parsed(strcmpi('detached_header', header_fnames)) = true;
                
                % Add data chunk to be written to new file
                info_detached_data.data = headerInfo.data(data_ind);
                info_detached_data.data = reshape(info_detached_data.data, info_detached_data.sizes);   % for code compatibility
                
                % Write detached nrrd file using a recursive call
                bWrite_Detached_Data = true;
                tmp_struct = nhdr_nrrd_write(fullfile(path_main_header, [fname_data, ext_data]), info_detached_data, bWrite_Detached_Data);   % recursive call
                
            else
                % e.g., detached .raw or .hex file
                
                fid_data = fopen( fullfile(path_main_header, [fname_data, ext_data]), 'w');
                if( fid_data < 1 )
                    error('Detached data file number %d/%d (%s) could not be opened.\n', i, N_data_files, headerInfo.datafiles{i});
                end
                
                try
                    outtype = nrrd_getMatlabDataType(headerInfo.type);
                    writeData(fid_data, headerInfo.data(data_ind), outtype, headerInfo.encoding);
                    fclose(fid_data);
                catch me_detached
                    fclose(fid_data);
                    rethrow(me_detached);
                end
                
                
            end
            
        end
        
        
    else
        % Standalone nrrd file with data included after header        
        
        try
            % After the header, there is a single blank line containing zero
            % characters to separate it from data
            fprintf(fidw, '\n');
            outtype = nrrd_getMatlabDataType(headerInfo.type);
            writeData(fidw, headerInfo.data, outtype, headerInfo.encoding);
            fclose(fidw);
        catch me_data
            fclose(fidw);
            rethrow(me_data);
        end
        
    end
    
else
    fclose(fidw);
end

% Issue warnings for unknown/unsupported fields (after reading data)
for i = 1:length(header_fnames)
    if ~fnames_parsed(i) && ~strcmpi(header_fnames{i},'data')
        fprintf('nhdr_nrrd_write WARNING: could not parse and write field %s from headerInfo structure.\n', header_fnames{i});
    end
end


end



% --- Auxiliary functions ------------

% ========================================================================
% Store in an array the list of numbers separated by the tokens listed in
% the withoutTokens cell array 
% ========================================================================
function iNrs = extractNumbersWithout( inputString, withoutTokens )

auxStr = inputString;

for iI=1:length( withoutTokens )
    
    auxStr = strrep( auxStr, withoutTokens{iI}, ' ' );
    
end

iNrs = sscanf( auxStr, '%f' );

end


% ========================================================================
% Determine the nrrd datatype : from matlab datatype to outtype (NRRD)
% ========================================================================
function nrrddatatype = get_nrrd_datatype(matlab_metaType)

% Determine the datatype
switch (matlab_metaType)
 case {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64',...
       'uint64', 'double'}
   nrrddatatype = matlab_metaType;
  
 case {'single'}
  nrrddatatype = 'float';
  
 case {'block'}
  error('Data type ''block'' is currently not supported.\n');
  
 otherwise
  error('Unknown matlab datatype %s', matlab_metaType)
end
end

% ========================================================================
% writeData -->
% fidIn is the open file we're overwriting
% matrix - data that have to be written
% datatype - type of data: int8, string, double...
% encoding - raw, gzip, txt/ascii
% ========================================================================
function ok = writeData(fidIn, matrix, datatype, encoding)

switch (encoding)
 case {'raw'}
  
  ok = fwrite(fidIn, matrix(:), datatype);
  
 case {'gzip', 'gz'}
     
     % Store in a raw file before compressing
     tmpBase = tempname(pwd);
     fidTmpRaw = fopen(tmpBase, 'w');
     assert(fidTmpRaw > 3, 'Could not open temporary file for GZIP compression');
     try
         fwrite(fidTmpRaw, matrix(:), datatype);
         fclose(fidTmpRaw);
     catch me
         fclose(fidTmpRaw);
         delete(tmpBase);
         rethrow(me);
     end
     
     
     % Now we gzip our raw file
     tmpFile = [tmpBase '.gz'];
     try
         gzip(tmpBase);     % this actually creates tmpFile
     catch me 
         delete(tmpBase);
         rethrow(me);
     end
     delete(tmpBase);
     
     % Finally, we put this info into our nrrd file (fidIn)
     
     fidTmpRaw = fopen(tmpFile, 'r'); % should this be in a try catch as well?
     assert(fidTmpRaw > 3, 'Could not open temporary file for writing to nrrd file during gzip compression.');
     try
         % tmp = fread(fidTmpRaw, Inf, [datatype '=>' datatype]); % precision argument : from datatype (source) to datatype, how about just byte by byte ?
         tmp = fread(fidTmpRaw, Inf, 'uint8=>uint8');   % this seems to be more robust
         fclose(fidTmpRaw) ;
     catch me
         fclose(fidTmpRaw);
         delete(tmpFile);
         rethrow(me);
     end
     
     % ok = fwrite (fidIn, tmp, datatype); % why not byte by byte here?
     ok = fwrite(fidIn, tmp, 'uint8');      % this seems to be more robust
     delete (tmpFile);

 case {'text', 'txt', 'ascii'}
  
  ok = fprintf(fidIn,'%u ', matrix(:)); % FIX: better with %g ?
  %ok = fprintf(fidIn,matrix(:), class(matrix));
  
 otherwise
  error('Unsupported encoding %s', encoding)
end

end

% ========================================================================
% Compare a Matlab-type size vector (no trailing ones, minimum length 2) to
% the size vector specified in a nrrd file/header which may contain
% trailing ones and may have only one dimension.
% ========================================================================

function sizesok = nrrd_size_check(matlab_size, nrrd_size)
% Make row vectors
matlab_size = matlab_size(:)';
nrrd_size = nrrd_size(:)';

% nrrd sizes may contain only one dimension
if length(nrrd_size)==1
    sizesok = prod(matlab_size)==nrrd_size;
elseif length(nrrd_size)>=2
    ind_max = find(nrrd_size~=1,1,'last');  % find last non-1 entry
    % ones are ok in the first two dimensions:
    if isempty(ind_max)
        ind_max = 2;                
    else
        ind_max = max(2, ind_max);  % does not work if ind_max is empty
    end
    % Compare matlab size to nrrd size without trailing ones after from
    % third entry on.
    sizesok = isequal(matlab_size, nrrd_size(1:ind_max));
else
    error('Argument nrrd_size is an empty matrix');
end

end
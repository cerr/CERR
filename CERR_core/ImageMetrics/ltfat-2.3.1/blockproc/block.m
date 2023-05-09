function [fs,classid] = block(source,varargin)
%-*- texinfo -*-
%@deftypefn {Function} block
%@verbatim
%BLOCK  Initialize block stream
%   Usage: block(source);
%
%   Input parameters:
%      source    : Block stream input.
%   Output parameters:
%      fs        : Sampling rate.
%      classid   : Data type.
%
%   BLOCK(source) initializes block data stream from source which
%   can be one of the following (the letter-case is ignored for strings):
%
%      'file.wav'
%         name of a wav file
%
%      'dialog'
%         shows the file dialog to choose a wav file.
%
%      data
%         input data as columns of a matrix for each input channel
%
%      'rec'
%         input is taken from a microphone/auxilary input;
%
%      {'rec','file.wav'} or {'rec','dialog'} or {'rec',data}
%         does the same as 'rec' but plays a chosen audio data simultaneously.
%
%      'playrec'
%         loopbacks the input to the output. In this case, the block size
%         (in BLOCKREAD) cannot change during the playback.
%
%   BLOCK accepts the following optional key-value pairs
%
%      'fs',fs
%         Required sampling rate - Some devices might support only a 
%         limited range of samp. frequencies. Use BLOCKDEVICES to list
%         supported sampling rates of individual devices. 
%         When the target device does not support the chosen sampling rate,
%         on-the-fly resampling will be performed in the background.
%         This option overrides sampling rate read from a wav file.
%
%         The default value is 44100 Hz, min. 4000 Hz, max. 96000 Hz
%
%      'L',L
%         Block length - Specifying L fixes the buffer length, which cannot be
%         changed in the loop.
%
%         The default is 1024. In the online mode the minimum is 32.
%
%      'devid',dev
%         Whenever more input/output devices are present in your system,
%         'devid' can be used to specify one. For the 'playrec' option the
%         devId should be a two element vector [playDevid, recDevid]. List
%         of the installed devices and their IDs can be obtained by
%         BLOCKDEVICES.
%
%      'playch',playch
%         If device supports more output channels, 'playch' can be used to
%         specify which ones should be used. E.g. for two channel device, [1,2]
%         can be used to specify channels.
%
%      'recch',recch
%         If device supports more input channels, 'recch' can be used to
%         specify which ones should be used.
%
%      'outfile','file.wav'
%         Creates a wav file header for on-the-fly storing of block data using
%         BLOCKWRITE. Existing file will be overwritten. Only 16bit fixed
%         point precision is supported in the files.
%
%      'nbuf',nbuf
%         Max number of buffers to be preloaded. Helps avoiding glitches but
%         increases delay.
%
%      'loadind',loadind
%         How to show the load indicator. loadind can  be the following:
%
%            'nobar'
%               Suppresses any load display.
%
%            'bar'
%               Displays ascii load bar in command line (Does not work in Octave).
%
%            obj
%               Java object which has a public method updateBar(double).
%
%   Optional flag groups (first is default)
%
%      'noloop', 'loop'
%         Plays the input in a loop.
%
%      'single', 'double'
%         Data type to be used. In the offline mode (see below) the flag is
%         ignored and everything is cast do double.
%
%      'online', 'offline'
%         Use offline flag for offline blockwise processing of data input or a
%         wav file without initializing and using the playrec MEX.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/block.html}
%@seealso{blockread, blockplay, blockana, blocksyn, demo_blockproc_basicloop, demo_blockproc_slidingsgram}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%   AUTHOR : Zdenek Prusa
%   The function uses the Playrec tool by Robert Humphrey
%   http://www.playrec.co.uk/ which in turn relies on
%   Portaudio lib  http://www.portaudio.com/

complainif_notenoughargs(nargin,1,'BLOCK');

definput.keyvals.devid=[];
definput.keyvals.nbuf=[];
definput.keyvals.fs=[];
definput.keyvals.playch=[];
definput.keyvals.recch=[];
definput.keyvals.outfile=[];
definput.keyvals.L=[];
definput.keyvals.loadind= 'nobar';
definput.flags.fmt={'single','double'};
definput.flags.loop={'noloop','loop'};
definput.flags.onoff={'online','offline'};
[flags,kv]=ltfatarghelper({},definput,varargin);

failIfNotPositiveInteger(kv.L,'L');
failIfNotPositiveInteger(kv.fs,'fs');
failIfNotPositiveInteger(kv.nbuf,'nbuf');

% Reset all persistent data
block_interface('reset');

if ~flags.do_offline
    % Octave version check
    skipLoadin = 0;
    if isoctave
        octs=strsplit(version,'.');
        octN=str2num(octs{1})*1000+str2num(octs{2});
        if octN<3007
          warning('%s: Using Octave < 3.7. Disabling load indicator.',mfilename);
          skipLoadin = 1;
        end
    end

    if ~skipLoadin
       if ischar(kv.loadind)
          if ~strcmpi(kv.loadind,'bar') && ~strcmpi(kv.loadind,'nobar')
             error('%s: Incorrect value parameter for the key ''loadin''.',...
                   upper(mfilename));
          end
       elseif isjava(kv.loadind)
          try
             javaMethod('updateBar',kv.loadind,0);
          catch
             error('%s: Java object does not contain updateBar method.',...
                   upper(mfilename))
          end
       end
    end

    % Store option for displaying the loop playback
    block_interface('setIsLoop',flags.do_loop);
else
    % Check whether any of incompatible params are set
    failIfInvalidOfflinePar(kv,'devid');
    failIfInvalidOfflinePar(kv,'playch');
    failIfInvalidOfflinePar(kv,'recch');
    failIfInvalidOfflinePar(kv,'nbuf');
    failIfInvalidOfflinePar(kv,'loadind',definput.keyvals.loadind);
    failIfInvalidOfflinePar(flags,'loop',definput.flags.loop{1});
    kv.loadind = 'nobar';

    % Different behavior for the fmt flag
    flags.fmt = 'double';
    % fs is maybe needed for setting fs for the output wav
    block_interface('setOffline',1);
end

playChannels = 0;
recChannels = 0;
play = 0;
record = 0;
% Here we can define priority list of the host APIs.
% If none of the preferred API devices is present, the first one is taken.
hostAPIpriorityList = {};
% Force portaudio to use buffer of the following size
pa_bufLen = -1;

do_recaudio = 0;
oldsource = source;
% Handle {'rec',...} format
if iscell(source) && strcmpi(source{1},'rec')
   recChannels = 1;
   record = 1;
   source = source{2};
   if isempty(kv.nbuf)
      kv.nbuf = 3;
   end
   do_recaudio = 1;
end

if ischar(source)
   if(strcmpi(source,'rec'))
      recChannels = 1;
      record = 1;
      if isempty(kv.nbuf)
         kv.nbuf = 3;
      end
   elseif strcmpi(source,'playrec')
      playChannels = 2;
      recChannels = 1;
      record = 1;
      play = 1;
      if isempty(kv.nbuf)
         kv.nbuf = 1;
      end
   elseif strcmpi(source,'dialog')
      [fileName,pathName] = uigetfile('*.wav','Select the *.wav file');
      if fileName == 0
         error('%s: No file chosen.',upper(mfilename));
      end
      source = fullfile(pathName,fileName);
      if isempty(kv.fs)
          [~, kv.fs] = wavload(source, 'i');
      end
      play = 1;
   elseif(numel(source)>4)
      if(strcmpi(source(end-3:end),'.wav'))
         if exist(source,'file')~=2
            error('%s: File "%s" does not exist.',upper(mfilename),source);
         end
         if isoctave
            warning('off','Octave:fopen-file-in-path');
         end
         if isempty(kv.fs)
            [~, kv.fs] = wavload(source, 'i');
         end
         play = 1;
      else
         error('%s: "%s" is not valid wav filename.',upper(mfilename),source);
      end
   else
      error('%s: Unrecognized source "%s".',upper(mfilename),source);
   end
elseif(isnumeric(source))
    if isempty(kv.fs) && flags.do_online
      kv.fs = 44100;
      warning('%s: Sampling rate not specified. Using default value %i Hz.',...
              upper(mfilename),kv.fs);
    end
    play = 1;
else
   error('%s: Unrecognized source.',upper(mfilename));
end

if play && ~record
   playChannels = 2;
   if isempty(kv.nbuf)
      kv.nbuf = 3;
   end
end

if isempty(kv.fs)
    kv.fs = 44100;
end

is_wav = ischar(source) && numel(source)>4 && strcmpi(source(end-3:end),'.wav');
is_numeric = isnumeric(source);

if flags.do_offline
    if ~is_wav && ~is_numeric
        error(['%s: In the offline mode, only wav file or a data vector can ',...
           ' be used as a source.'],upper(mfilename));
    end

    if isempty(kv.fs) && ~isempty(kv.outfile)
        error('%s: Missing fs for the output file.',upper(mfilename));
    end

end

% Store option for displaying the load bar
block_interface('setDispLoad',kv.loadind);

% Store data type.
block_interface('setClassId',flags.fmt);

% Store length of the buffer circular queue
block_interface('setBufCount',kv.nbuf);

%
if ~isempty(kv.outfile) && ~strcmpi(kv.outfile(end-3:end),'.wav')
    error('%s: %s does not contain *.wav suffix.',upper(mfilename),kv.outfile);
end

% Return parameters
classid = flags.fmt;
fs = kv.fs;


% Set block length
if isempty(kv.L)
   block_interface('setBufLen',-1);
else
   if kv.L<32 && flags.do_online
      error('%s: Minimum buffer length is 32.',upper(mfilename))
   end
   block_interface('setBufLen',kv.L);
end

% Store data
block_interface('setSource',source);
block_interface('setFs',fs);
% Handle sources with known input length
if is_wav
   [~,~,~,fid] = wavload(source,'i');
   Ls = fid(4);
   chanNo = fid(5);
   block_interface('setLs',[Ls,chanNo]);
   block_interface('setSource',@(pos,endSample)...
                               cast(wavload(source,'',endSample-pos+1,pos-1),...
                               block_interface('getClassId')) );
      % block_interface('setSource',@(pos,endSample)...
      % cast(wavread(source,[pos,endSample]),...
      %                          block_interface('getClassId')) );
elseif is_numeric
   source = comp_sigreshape_pre(source,'BLOCK');
   if size(source,2)>8
       error('%s: More than 8 channels not allowed.',upper(mfilename));
   end
   block_interface('setLs',size(source));
   block_interface('setSource',@(pos,endSample)...
                               cast(source(pos:endSample,:),...
                               block_interface('getClassId')));
end

% Modify the source just added to block_interface
if do_recaudio
    block_interface('setSource',{'rec',block_interface('getSource')});
    % By default, we only want a single speaker to be active
    playChannels = 1;
end



% Not a single playrec call has been done until now
if ~flags.do_offline
    if flags.do_online && kv.fs<4000 || kv.fs>96000
        error('%s: Sampling rate must be in range 4-96 kHz ',upper(mfilename));
    end
    

    % From now on, playrec is called
    isPlayrecInit = 0;
    try
       isPlayrecInit = playrec('isInitialised');
    catch
       err = lasterror;
       if ~isempty(strfind(err.message,'The specified module could not be found'))
          error('%s: playrec found but portaudio cannot be found.', upper(mfilename));
       end
        if ~isempty(strfind(err.message,'Undefined function'))
          error('%s: playrec could not be found.', upper(mfilename));
        end
       error('%s: Error loading playrec.',upper(mfilename));
    end

    if isPlayrecInit
       playrec('reset');
    end

    clear playrec;

    if isempty(kv.playch)
      kv.playch = 1:playChannels;
    end

    if isempty(kv.recch)
      kv.recch = 1:recChannels;
    end

    devs = playrec('getDevices');
    if isempty(devs)
       error(['%s: No sound devices available. portaudio lib is probably ',...
              'incorrectly built.'],upper(mfilename));
    end

    prioriryPlayID = -1;
    priorityRecID = -1;

    % Get all installed play devices
    playDevStructs = devs(arrayfun(@(dEl) dEl.outputChans,devs)>0);

    % Search for priority play device
    for ii=1:numel(hostAPIpriorityList)
       hostAPI = hostAPIpriorityList{ii};
       priorityHostNo = find(arrayfun(@(dEl) ...
                             ~isempty(strfind(lower(dEl.hostAPI),...
                             lower(hostAPI))),playDevStructs)>0);
       if ~isempty(priorityHostNo)
          prioriryPlayID = playDevStructs(priorityHostNo(1)).deviceID;
          break;
       end
    end

    % Get IDs of all play devices
    playDevIds = arrayfun(@(dEl) dEl.deviceID, playDevStructs);

    % Get all installed recording devices
    recDevStructs = devs(arrayfun(@(dEl) dEl.inputChans,devs)>0);
    % Search for priority rec device
    for ii=1:numel(hostAPIpriorityList)
       hostAPI = hostAPIpriorityList{ii};
       priorityHostNo = find(arrayfun(@(dEl) ...
                             ~isempty(strfind(lower(dEl.hostAPI),...
                             lower(hostAPI))),recDevStructs)>0);
       if ~isempty(priorityHostNo)
          priorityRecID = recDevStructs(priorityHostNo(1)).deviceID;
          break;
       end
    end

    % Get IDs of all rec devices
    recDevIds = arrayfun(@(dEl) dEl.deviceID,recDevStructs);

    if play && record
       if ~isempty(kv.devid)
          if(numel(kv.devid)~=2)
             error('%s: devid should be 2 element vector.',upper(mfilename));
          end
          if ~any(playDevIds==kv.devid(1))
             error('%s: There is no play device with id = %i.',...
                   upper(mfilename),kv.devid(1));
          end
          if ~any(recDevIds==kv.devid(2))
             error('%s: There is no rec device with id = %i.',...
                   upper(mfilename),kv.devid(2));
          end
       else
          % Use the priority device if present
          if prioriryPlayID~=-1 && priorityRecID~=-1
             kv.devid = [prioriryPlayID, priorityRecID];
          else
             kv.devid = [playDevIds(1), recDevIds(1)];
          end
       end
       try
           if pa_bufLen~=-1
              playrec('init', kv.fs, kv.devid(1), kv.devid(2),...
                      max(kv.playch),max(kv.recch),pa_bufLen);
           else
              playrec('init', kv.fs, kv.devid(1), kv.devid(2));
           end
       catch
           failedInit(devs,kv);
       end
       
       if ~do_recaudio
          if numel(kv.recch) >1 && numel(kv.recch) ~= numel(kv.playch)
            error('%s: Using more than one input channel.',upper(mfilename));
          end
       end
       block_interface('setPlayChanList',kv.playch);
       block_interface('setRecChanList',kv.recch);
    elseif play && ~record
       if ~isempty(kv.devid)
          if numel(kv.devid) >1
             error('%s: devid should be scalar.',upper(mfilename));
          end
          if ~any(playDevIds==kv.devid)
             error('%s: There is no play device with id = %i.',upper(mfilename),kv.devid);
          end
       else
          % Use prefered device if present
          if prioriryPlayID~=-1
             kv.devid = prioriryPlayID;
          else
             % Use the first (hopefully default) device
             kv.devid = playDevIds(1);
          end
       end
       try
           if pa_bufLen~=-1
              playrec('init', kv.fs, kv.devid, -1,max(kv.playch),-1,pa_bufLen);
           else
              playrec('init', kv.fs, kv.devid, -1);
           end
       catch
           failedInit(devs,kv);
       end
       block_interface('setPlayChanList',kv.playch);
       if(playrec('getPlayMaxChannel')<numel(kv.playch))
           error (['%s: Selected device does not support required output',...
                   ' channels.\n'],upper(mfilename));
       end
    elseif ~play && record
         if(numel(kv.devid)>1)
             error('%s: devid should be scalar.',upper(mfilename));
          end

       if ~isempty(kv.devid)
          if ~any(recDevIds==kv.devid)
             error('%s: There is no rec device with id = %i.',upper(mfilename),kv.devid);
          end
       else
          % Use asio device if present
          if priorityRecID~=-1
             kv.devid = priorityRecID;
          else
             % Use the first (hopefully default) device
             kv.devid = recDevIds(1);
          end
       end
       try
           if pa_bufLen~=-1
              playrec('init', kv.fs, -1, kv.devid,-1,max(kv.recch),pa_bufLen);
           else
              playrec('init', kv.fs, -1, kv.devid);
           end
       catch
           failedInit(devs,kv);
       end
       block_interface('setRecChanList',kv.recch);
    else
       error('%s: Play or record should have been set.',upper(mfilename));
    end

    % From the playrec author:
    % This slight delay is included because if a dialog box pops up during
    % initialisation (eg MOTU telling you there are no MOTU devices
    % attached) then without the delay Ctrl+C to stop playback sometimes
    % doesn't work.
    pause(0.1);

    if(~playrec('isInitialised'))
        error ('%s: Unable to initialise playrec correctly.',upper(mfilename));
    end

    if(playrec('pause'))
        %fprintf('Playrec was paused - clearing all previous pages and unpausing.\n');
        playrec('delPage');
        playrec('pause', 0);
    end

    % Reset skipped samples
    playrec('resetSkippedSampleCount');

    if play
       chanString = sprintf('%d,',kv.playch);
       dev = devs(find(arrayfun(@(dEl) dEl.deviceID==kv.devid(1),devs)));
       fprintf(['Play device: ID=%d, name=%s, API=%s, channels=%s, default ',...
                'latency: %d--%d ms\n'],...
                dev.deviceID,dev.name,dev.hostAPI,chanString(1:end-1),...
                floor(1000*dev.defaultLowOutputLatency),...
                floor(1000*dev.defaultHighOutputLatency));
    end

    if record
       chanString = sprintf('%d,',kv.recch);
       dev = devs(find(arrayfun(@(dEl) dEl.deviceID==kv.devid(end),devs)));
       fprintf(['Rec. device: ID=%d, name=%s, API=%s, channels=%s, default ',...
                'latency: %d--%d ms\n'],...
                dev.deviceID,dev.name,dev.hostAPI,chanString(1:end-1),...
                floor(1000*dev.defaultLowInputLatency),...
                floor(1000*dev.defaultHighInputLatency));
    end

    % Another slight delay to allow printing all messages prior to the playback
    % starts.
    pause(0.1);

end


% Handle output file
if ~isempty(kv.outfile)
   % Use number of recording channes only if mic is an input.
   if (record && ~play) || (record && play)
      blockreadChannels = numel(block_interface('getRecChanList'));
   else
      Ls = block_interface('getLs');
      blockreadChannels = Ls(2);
   end

   headerStruct = writewavheader(blockreadChannels,kv.fs,kv.outfile);
   block_interface('setOutFile',headerStruct);
end

%%%%%%%%%%%%%
% END BLOCK %
%%%%%%%%%%%%%


function failedInit(devs,kv)
% Common function for playrec initialization error messages
errmsg = '';


% playFs = devs([devs.deviceID]==kv.devid(1)).supportedSampleRates;
% if ~isempty(playFs) && ~any(playFs==kv.fs)
%   fsstr = sprintf('%d, ',playFs);
%   fsstr  = ['[',fsstr(1:end-2),']' ];
%   errmsg = [errmsg, sprintf(['Device %i does not ',...
%             'support the required fs. Supported are: %s \n'],...
%             kv.devid(1),fsstr)];
% end
% 
% if numel(kv.devid)>1
%     recFs = devs([devs.deviceID]==kv.devid(2)).supportedSampleRates;
%     if ~isempty(recFs) && ~any(recFs==kv.fs)
%       fsstr = sprintf('%d, ',recFs);
%       fsstr  = ['[',fsstr(1:end-2),']' ];
%       errmsg = [errmsg, sprintf(['Recording device %i does not ',...
%                 'support the required fs. Supported are: %s \n'],...
%                 kv.devid(2),fsstr)];
%     end
% end

if isempty(errmsg)
   err = lasterror;
   error('%s',err.message);
else
   error(errmsg);
end


function failIfInvalidOfflinePar(kv,field,defval)
% Helper function for checking if field of kv is empty or not
% equal to defval.
failed = 0;
if nargin<3
    if ~isempty(kv.(field))
        failed = 1;
    end
else
    if ~isequal(kv.(field),defval)
        failed = 1;
    end
end

if failed
     error('%s: ''%s'' is not a valid parameter in the offline mode',...
            upper(mfilename),field);
end

function failIfNotPositiveInteger(par,name)
if ~isempty(par)
   if ~isscalar(par) || ~isnumeric(par) || rem(par,1)~=0 || par<=0
       error('%s: %s should be positive integer.',upper(mfilename),name);
   end
end


function headerStruct = writewavheader(Nchan,fs,filename)
%WRITEWAVHEADER(NCHAN, FS, FILENAME)
%
%Creates a new WAV File and writes only the header into it.
%No audio data is written here.
%
%Note that this implementation is hardcoded to 16 Bits/sample.
%
%input parameters:
%   NCHAN - 1: Mono, 2: Stereo
%   FS - Sampling rate in Hz
%   FILENAME - Name of the WAVE File including the suffix '.wav'


% Original copyright:
%---------------------------------------------------------------
% Oticon A/S, Bjoern Ohl, March 9, 2012
%---------------------------------------------------------------
% Modified: Zdenek Prusa

% predefined elements:
bitspersample = 16;     % hardcoded in this implementation, as other
                        % quantizations do not seem relevant
mainchunk = 'RIFF';
chunktype = 'WAVE';
subchunk = 'fmt ';
subchunklen = 16;       % 16 for PCM
format = 1;             % 1 = PCM (linear quantization)
datachunk = 'data';

% calculated elements:
alignment = Nchan * bitspersample / 8;
%dlength = Total_Nsamp*alignment;      % total amount of audio data in bytes
dlength = 0;
flength = dlength + 36;  % dlength + 44 bytes (header) - 8 bytes (definition)
bytespersecond = fs*alignment;       % data rate in bytes/s


% write header into file:
fid = fopen(filename,'w');  %writing access

fwrite(fid, mainchunk);
fwrite(fid, flength, 'uint32');
fwrite(fid, chunktype);
fwrite(fid, subchunk);
fwrite(fid, subchunklen, 'uint32');
fwrite(fid, format, 'uint16');
fwrite(fid, Nchan, 'uint16');
fwrite(fid, fs, 'uint32');
fwrite(fid, bytespersecond, 'uint32');
fwrite(fid, alignment, 'uint16');
fwrite(fid, bitspersample, 'uint16');
fwrite(fid, datachunk);
fwrite(fid, dlength, 'uint32');

fclose(fid);    % close file

headerStruct = struct('filename',filename,'Nchan',Nchan,...
                      'alignment',alignment);


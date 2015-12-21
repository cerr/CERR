function [A,Ainfo] = readmha(fn)
%% Usage: [A,Ainfo] = readmha(fn)

fp = fopen(fn,'rb');
if (fp == -1)
  error ('Cannot open mha file for reading');
end

%% Parse header
dims = 3;
binary = 1;
binary_msb = 0;
nchannels = 1;
Ainfo = [];
for i=1:20
  %t = fgetl(fp);
  t = fgets(fp);

  [a,cnt] = sscanf(t,'NDims = %d',1);
  if (cnt > 0)
    dims = a;
    continue;
  end

  [a,cnt] = sscanf(t,'BinaryData = %s',1);
  if (cnt > 0)
    if (strcmpi(a,'true'))
      binary = 1;
    else
      binary = 0;
    end
    continue;
  end

  [a,cnt] = sscanf(t,'BinaryDataByteOrderMSB = %s',1);
  if (cnt > 0)
    if (strcmpi(a,'true'))
      binary_msb = 1;
    else
      binary_msb = 0;
    end
    continue;
  end

  %% [a,cnt,errmsg,ni] = sscanf(t,'DimSize = ',1);
  ni = strfind(t,'DimSize = ');
  if (~isempty(ni))
    ni = ni + length('DimSize = ');
    [b,cnt] = sscanf(t(ni:end),'%d');
    if (cnt == dims)
      sz = b;
      Ainfo.Dimensions = sz;
      continue;
    end
  end

  [a,cnt] = sscanf(t,'ElementNumberOfChannels = %d',1);
  if (cnt > 0)
    nchannels = a;
    continue;
  end

  [a,cnt] = sscanf(t,'ElementType = %s',1);
  if (cnt > 0)
    element_type = a;
    continue;
  end

  %% [a,cnt,errmsg,ni] = sscanf(t,'ElementSpacing = ',1);
  ni = strfind(t,'ElementSpacing = ');
  if (~isempty(ni))
    ni = ni + length('ElementSpacing = ');
    [b,cnt] = sscanf(t(ni:end),'%g');
    if (cnt == dims)
      %Ainfo.ElementSpacing = b;
      Ainfo.PixelDimensions = b;
      continue;
    end
  end
  
  %% [a,cnt,errmsg,ni] = sscanf(t,'Offset = ',1);
  ni = strfind(t,'Offset = ');
  if (~isempty(ni))
    ni = ni + length('Offset = ');
    [b,cnt] = sscanf(t(ni:end),'%g');
    if (cnt == dims)
      Ainfo.Offset = b;
      continue;
    end
  end
  
  [a,cnt] = sscanf(t,'ElementDataFile = %s',1);
  if (cnt > 0)
      data_loc = fullfile(fileparts(fn),a);
      if exist(data_loc,'file')
          %fp_data = fopen(data_loc,'rb');
          if double(t(end)) ~= 10
              fp_data = fopen(data_loc,'rb');
              %fseek(fp, -1, 0)
          end
      else
          %status = fseek(fp, -1, 0);
          fp_data = fp;
      end
      break;
  end
end

if (strcmp(element_type,'MET_FLOAT'))
  [A,count] = fread(fp_data,sz(1)*sz(2)*sz(3)*nchannels,'float');
elseif (strcmp(element_type,'MET_SHORT'))
    [A,count] = fread(fp_data,sz(1)*sz(2)*sz(3)*nchannels,'short');
elseif (strcmp(element_type,'MET_USHORT'))
    [A,count] = fread(fp_data,sz(1)*sz(2)*sz(3)*nchannels,'ushort');
elseif (strcmp(element_type,'MET_UCHAR'))
  [A,count] = fread(fp_data,sz(1)*sz(2)*sz(3)*nchannels,'uchar');
elseif (strcmp(element_type,'MET_UINT'))
  [A,count] = fread(fp_data,sz(1)*sz(2)*sz(3)*nchannels,'uint32');
elseif (strcmp(element_type,'MET_DOUBLE'))
  [A,count] = fread(fp_data,sz(1)*sz(2)*sz(3)*nchannels,'real*8');
else
  %[A,count] = fread(fp,sz(1)*sz(2)*sz(3)*nchannels,'int16');
  [A,count] = fread(fp_data,sz(1)*sz(2)*sz(3)*nchannels,'int32');
end
%% A = reshape(A,sz(1),sz(2),sz(3),nchannels);
A = reshape(A,nchannels,sz(1),sz(2),sz(3));
A = shiftdim(A,1);

fclose(fp);

return;

% PARSE_PARAMETER_LIST  Read/convert/return argument lists in various formats.
%
% Make a parameter structure of a parameter list:
%   st=parse_parameter_list({'parameter1','value1','parameter2','value2'....})
%
% Make a parameter structure of a parameter list:
%   st=parse_parameter_list({'parameter1=value1','parameter2=value2'....})
%
% Separate parameters of parameter list to second structure:
%   [st,st2]=parse_parameter_list({'parameter1','value1','parameter2','value2'....},'seppar1',.... )
%
% Separate parameters of parameter structure to second structure:
%   [st,st2]=parse_parameter_list(st,'seppar1',.... )
%
% Make a parameter list of a parameter structure:
%   lst=parse_parameter_list('cell',st)
%
% Convert strings to numbers in struct if possible:
%   lst=parse_parameter_list('str2num',st)
%
%
function [st,st2]=parse_parameter_list(varargin)
  if ischar(varargin{1})
    mode=varargin{1};
    indata=varargin{2};
    varargin=varargin(3:end);
  else
    mode='';
    indata=varargin{1};
    varargin=varargin(2:end);
  end    
  if isstruct(varargin{1}),
    st=indata;
  else
    lst={};
    for arg=indata,
      arg=arg{1};
      if isnumeric(arg), arg=num2str(arg); end
      idx=find(arg=='=');
      if isempty(idx),
	lst{end+1}=arg;
      else
	lst{end+1}=arg(1:idx(1)-1);
	lst{end+1}=arg(idx(1)+1:end);
      end
    end
    st=struct(lst{:});
  end  
  st2=struct([]);
  for arg=varargin,
    arg=arg{1};
    if isfield(st,arg),
      eval( ['st2(1).' arg '=getfield(st,arg);'] );
    end
    st=rmfield(st,arg);
  end
  switch mode,
   case 'cell':
    st=struct2cell(st);
   case 'str2num':
    st=strfields2num(st);
   case 'num2str':
    st=strfields2num(st);
   case 'jasper':
    lst=struct2cell(numfields2str(st));
    st=printf(' -O %s=%s ',lst{:});
  end
  return
  
function st=strfields2num(st)
  for fld=fieldnames(st)',
    value=getfield(st,fld{1});
    if ischar(value) & length(str2num(value)),
      st=setfield(st,fld{1},str2num(value));
    end
  end
  return;
  
function st=numfields2str(st)
  for fld=fieldnames(st)',
    value=getfield(st,fld{1});
    if isnumeric(value),
      st=setfield(st,fld{1},num2str(value,'%.20g'));
    end
  end
  return;

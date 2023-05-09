function [flags,keyvals,varargout]  = ltfatarghelper(posdepnames,definput,arglist,callfun)
%-*- texinfo -*-
%@deftypefn {Function} ltfatarghelper
%@verbatim
%LTFATARGHELPER  Parse arguments for LTFAT
%   Usage: [flags,varargout]  = ltfatarghelper(posdepnames,definput,arglist,callfun);
%
%   Input parameters:
%      posdepnames : Names of the position dependant parameters.
%      definput    : Struct to define the allowed input
%      arglist     : Commandline of the calling function (varargin)
%      callfun     : Name of calling function (optional)
%
%   Output parameters:
%      flags       : Struct with information about flags.
%      keyvals     : Struct with key / values.
%      varargout   : The position dependant pars. properly initialized
%
%   [flags,keyvals]=LTFATARGHELPER(posdepnames,definput,arglist) assists in
%   parsing input parameters for a function in LTFAT. Parameters come in
%   four categories:
%  
%    Position dependant parameters. These must not be strings. These are
%     the first parameters passed to a function, and they are really just a
%     short way of specifying key/value pairs. See below.
%
%    Flags. These are single string appearing after the position dependant
%     parameters.
%
%    Key/value pairs. The key is always a string followed by the value,
%     which can be anything.
%
%    Expansions. These appear as flags, that expand into a pre-defined list
%     of parameters.  This is a short-hand way of specifying standard sets of
%     flags and key/value pairs.
%
%   The parameters are parsed in order, so parameters appearing later in
%   varargin will override previously set values.
%
%   The following example for calling LTFATARGHELPER is taken from DGT:
%  
%     definput.keyvals.L=[];
%     definput.flags.phase={'freqinv','timeinv'};
%     [flags,kv]=ltfatarghelper({'L'},definput,varargin);
%
%   The first line defines a key/value pair with the key 'L' having an
%   initial value of [] (the empty matrix).
%
%   The second line defines a group of flags by the name of phase.  The
%   group phase contains the flags 'freqinv' and 'timeinv', which can
%   both be specified on the command line by the user. The group-name
%   phase is just for internal use, and does not appear to the user. The
%   flag mentioned first in the list will be selected by default, and only
%   one flag in a group can be selected at any time. A group can contain as
%   many flags as desired.
%  
%   The third line is the actual call to LTFATARGHELPER which defines the
%   output flags and kv.  The input {'L'} indicates that the value of
%   the parameter 'L' can also be given as the very first value in
%   varargin.
%
%   The output struct kv contains the key/value pairs, so the value
%   associated to 'L' is stored in kv.L.
%
%   The output struct flags contains information about the flags choosen
%   by the user. The value of flags.phase will be set to the selected flag
%   in the group phase and additionally, the value of flags.do_timeinv
%   will be 1 if 'timeinv' was selected and 0 otherwise, and similarly for
%   'freqinv'. This allows for easy checking of selected flags.
%
%   Advanced usage
%   --------------
%   
%   Expansion import was introduced in order to allow sharing common
%   flags and key/value pairs between functions. 
%   
%   The following example is taken from PLOTDGT and TFPLOT:
%
%       definput.import={'ltfattranslate','tfplot'};
%       [flags,kv,fs]=ltfatarghelper({'fs','dynrange'},definput,varargin);
%
%   This code instructs LTFATARGHELPER to run functions 
%   arg_ltfattranslate and arg_tfplot which define the flags and 
%   the key/value pairs. The arg_ functions must have the following signature:
%
%       function definput=arg_name(definput)
%
%   Moreover, a special flag 'argimport' is used to pass the flags 
%   and the key/value pairs from PLOTDGT to TFPLOT:
%
%       coef=tfplot(...,'argimport',flags,kv);
%   
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/ltfatarghelper.html}
%@seealso{ltfatgetdefaults, ltfatsetdefaults}
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

persistent TF_CONF;

if isempty(TF_CONF)

%  basepath=which('ltfatarghelper');
%  % Kill the function name and comp from the path.
%  basepath=basepath(1:end-22);
%  % add the base path
%  addpath(basepath);
%  ltfatstart;

  TF_CONF.fundefs = struct;
end;

if ischar(posdepnames)
  % Special interface needed for ltfatsetdefaults and ltfatgetdefaults,
  % activated when first argument is a string.

  % First input  argument, posdepnames, is a string, one of the options
  % in the "switch" section below
  % Second input argument, definput,    is a function name to get or set
  % Third  input argument, arglist ,    is a cell-array with options to set.
  
  switch(lower(posdepnames))
   case 'get'
    if isfield(TF_CONF.fundefs,definput)
      flags=TF_CONF.fundefs.(definput);
    else
      flags={};
    end;
   case 'set'
    TF_CONF.fundefs.(definput)=arglist;
   case 'all'
    flags=TF_CONF.fundefs;
   case 'clearall'
    TF_CONF.fundefs=struct; 
  end;
  return
end;

if nargin<4
  f=dbstack;  
  callfun=f(2).name;
end;

nposdep=numel(posdepnames);

% Resolve import specifications BEFORE adding our own specifications.
if isfield(definput,'import')
  for imp = definput.import;
    definput=feval(['arg_',imp{1}],definput);
  end;
end;

if isfield(definput,'flags')
  defflags=definput.flags;
else
  defflags=struct;
end;

if isfield(definput,'keyvals')
  defkeyvals=definput.keyvals;
else
  defkeyvals=struct;
end;

if isfield(definput,'groups')
  groups=definput.groups;
else
  groups=struct;
end;

total_args = numel(arglist);

% Determine the position of the first optional argument.
% If no optional argument is given, return nposdep+1
first_str_pos = 1;
while first_str_pos<=total_args && ~ischar(arglist{first_str_pos}) 
  first_str_pos = first_str_pos +1;    
end;

% If more than nposdep arguments are given, the first additional one must
% be a string
if (first_str_pos>nposdep+1)
  error('%s: Too many input arguments',upper(callfun));
end;

n_first_args=min(nposdep,first_str_pos-1);

keyvals=defkeyvals;      

% Copy the given first arguments
for ii=1:n_first_args
  keyvals.(posdepnames{ii})=arglist{ii};
end;

% Initialize the position independent parameters.
% and create reverse mapping of flag -> group
flagnames=fieldnames(defflags);
flags=struct;
% In order for flags to start with a number, it is necessary to add
% 'x_' before the flag when the flags are used a field names in
% flagreverse. Externally, flags are never used a field names in
% structs, so this is an internal problem in ltfatarghelper that is
% fixed this way.
flagsreverse=struct;
for ii=1:numel(flagnames)
  name=flagnames{ii};
  flaggroup=defflags.(name);
  flags.(name)=flaggroup{1};
  for jj=1:numel(flaggroup)
    flagsreverse.(['x_', flaggroup{jj}])=name;
    flags.(['do_',flaggroup{jj}])=0;
  end;
  flags.(['do_',flaggroup{1}])=1;
end;

%Get the rest of the arguments
restlist = arglist(first_str_pos:end);

%Check for default arguments
if isfield(TF_CONF.fundefs,callfun)
  s=TF_CONF.fundefs.(callfun);
  restlist=[s,restlist];
end;

% Check for import defaults
if isfield(definput,'importdefaults')
  % Add the importdefaults before the user specified arguments.
  restlist=[definput.importdefaults,restlist];
end;

while ~isempty(restlist)
  argname=restlist{1};
  restlist=restlist(2:end);  % pop
  found=0;
  
  % Is this name a flag? If so, set it
  if isfield(flagsreverse,['x_',argname])
    % Unset all other flags in this group
    flaggroup=defflags.(flagsreverse.(['x_',argname]));
    for jj=1:numel(flaggroup)
      flags.(['do_',flaggroup{jj}])=0;
    end;
    
    flags.(flagsreverse.(['x_',argname]))=argname;
    flags.(['do_',argname])=1;
    found=1;
  end;
  
  % Is this name the key of a key/value pair? If so, set the value.
  if isfield(defkeyvals,argname)      
    keyvals.(argname)=restlist{1};
    restlist=restlist(2:end);
    found=1;
  end;
  
  % Is this name a group definition? If so, put the group in front of the parameters
  if isfield(groups,argname)
    s=groups.(argname);
    restlist=[s,restlist];
    found=1;
  end;
  
  % Is the name == 'argimport'
  if strcmp('argimport',argname)   
    fieldnames_flags= fieldnames(restlist{1});  
    fieldnames_kvs  = fieldnames(restlist{2});        
    for ii=1:numel(fieldnames_flags)
      importname=fieldnames_flags{ii};
      flags.(importname)=restlist{1}.(importname);
    end;
    for ii=1:numel(fieldnames_kvs)
      importname=fieldnames_kvs{ii};
      keyvals.(importname)=restlist{2}.(importname);
    end;      
    restlist=restlist(3:end);
    found=1;
  end;
  
  if found==0
    if ischar(argname)
      error('%s: Unknown parameter: %s',upper(callfun),argname);
    else
      error('%s: Parameter is not a string, it is of class %s',upper(callfun),class(argname));          
    end;      
  end;
  
  %ii=ii+1;
end;

% Fill varargout

varargout=cell(1,nposdep);
for ii=1:nposdep
    varargout(ii)={keyvals.(posdepnames{ii})};
end;



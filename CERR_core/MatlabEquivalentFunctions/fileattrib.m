function [status, msg, msgid] = fileattrib (file,usrMode)
%AI 07/31/23 Modified to accept user-input mode

if ~exist('usrMode','var')
    usrMode = '';
end


if (! ischar (file))
    error ("fileattrib: FILE must be a string");
end

sts = 1;
msg = "";
msgid = "";

if (ispc ())
    files = __wglob__ (file);
else
    files = glob (file);
end
if (isempty (files))
    files = {file};
end
nfiles = numel (files);


for i = [nfiles, 1:nfiles-1]  % first time in loop extends the struct array
    [info, err, msg] = stat (files{i});
    if (! err)
        r(i).Name = canonicalize_file_name (files{i});
        
        if (isunix ())
            r(i).archive = NaN;
            r(i).system = NaN;
            r(i).hidden = NaN;
        else
            [~, attrib] = dos (sprintf ('attrib "%s"', r(i).Name));
            %% DOS never returns error status so have to check it indirectly
            if (! isempty (strfind (attrib, " -")))
                sts = 0;
                break;
            end
            attrib = regexprep (attrib, '\S+:.*', "");
            r(i).archive = any (attrib == "A");
            r(i).system = any (attrib == "S");
            r(i).hidden = any (attrib == "H");
        end
        
        r(i).directory = S_ISDIR (info.mode);
        
        modestr = info.modestr;
        r(i).GroupRead = NaN;
        r(i).GroupWrite = NaN;
        r(i).GroupExecute = NaN;
        r(i).OtherRead = NaN;
        r(i).OtherWrite = NaN;
        r(i).OtherExecute = NaN;
        
        if strfind(usrMode,'+r')
            r(i).UserRead = true;
        else
            r(i).UserRead = (modestr(2) == "r");
            if (isunix ())
                r(i).GroupRead = (modestr(5) == "r");
                r(i).OtherRead = (modestr(8) == "r");
            end
        end
        
        if strfind(usrMode,'+w')
            r(i).UserWrite = true;
        else
            r(i).UserWrite = (modestr(3) == "w");
            if (isunix ())
                r(i).GroupWrite = (modestr(6) == "w");
                r(i).OtherWrite = (modestr(9) == "w");
            end
        end
        
        if strfind(usrMode,'+x')
            r(i).UserExecute = true;
        else
            r(i).UserExecute = (modestr(4) == "x");
            if (isunix ())
                r(i).GroupExecute = (modestr(7) == "x");
                r(i).OtherExecute = (modestr(10) == "x");
            end
        end
        
    else
        sts = 0;
        break;
    end
    endfor
    
    msgid = '';
    if (nargout == 0)
        if (! sts)
            error ("fileattrib: operation failed");
        end
        status = r;
    else
        nargout
        status = sts;
        if (! sts)
            if (isempty (msg))
                msg = "operation failed";
            end
            msgid = "fileattrib";
        else
            msg = r;
        end
    end
    
  
end
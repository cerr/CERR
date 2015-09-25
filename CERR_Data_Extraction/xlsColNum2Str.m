function [colChar]=xlsColNum2Str(colNum)
%XLSCOLNUM2STR takes in an array of numbers and returns a cellular array
%of the same size with cell of corresponding Excel column names.
%
%For example:
%n=[1  10;
%   53 256]
%c=xlsColNum2Str(n);
%c={'A' , 'J';
%   'BA', 'IV'}
%Note: up to Excel 2003 the number of columns was limited to 256, as of
%Excel 2007 the number of columns has increased to 16,384 or 'XFD'
%This function is designed to take accept any integer so proper handling 
%of the number of columns should be taken care of outside this function

    colChar=cell(size(colNum)); %blank cell array
    
    % find max number of characters (AA n=2)
    numOfChars=ceil(max(colNum)/26)-1;
    n=1;
    
    while numOfChars>=1
        numOfChars=ceil(numOfChars/26)-1;
        n=n+1;
    end    
    
    remainder=num2cell(colNum);
    
    for s=n:-1:1
        if s>1
            %find limits
            % if n=2 then the columns go from AA to ZZ or 27 to 702
            L=sum(26.^(1:s-1))+1; % lower limit
            U=sum(26.^(1:s));   %upper limit
            %place current character to right of previous
            colChar(colNum>=L & colNum<=U) = ...
                cellfun(@(x,y) ([x char(ceil((y-(L-1))/26^(s-1))+64)]),...
                colChar(colNum>=L & colNum<=U),...      % x
                remainder(colNum>=L & colNum<=U),...    % y
                'UniformOutput',false);
            %calculate the remaining string
            %for example if last string was 'ABA' the 'A' was placed to the
            %right of the previous string and now 'BA' is remaining
            remainder(colNum>=L & colNum<=U)=...
                cellfun(@(x,y) (y-26^(s-1)*(double(x(end))-64)),...
                colChar(colNum>=L & colNum<=U),...
                remainder(colNum>=L & colNum<=U),'UniformOutput',false);
            colNum=cell2mat(remainder);
        else
             colChar=cellfun(@(x,y) ([x char(y+64)]),...
                 colChar,remainder,'UniformOutput',false);
        end
    end    
end
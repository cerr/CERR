function [columnFormat,dispVal] = extractValROE(parS)
% Get ROE parameter value based on input type  
% 
% AI 12/14/2020

    val = parS.val;
    switch(lower(parS.type{1}))
    case 'string'
      columnFormat = {'char','char'};
      dispVal = val;
      case'cont'
      columnFormat = {'numeric','numeric'};
      dispVal = val ;
    case 'bin'
      descV = parS.desc;
      descC = cellstr(descV);
      columnFormat = {'char',descC};
      dispVal = parS.desc{val+1};
    end
    
  end
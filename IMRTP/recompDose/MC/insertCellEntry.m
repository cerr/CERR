function myCell1 = insertCellEntry(myCell, n, val);
  % insert val into myCell at location n
  
  for i = 1:n-1, 
    myCell1{i} = myCell{i};
  end
  myCell1{n} = val;
  
  for i = n:length(myCell), 
      myCell1{i+1} = myCell{i};
  end
  

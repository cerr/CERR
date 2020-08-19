function closedImg = morphClose (img, se)
% Morphologically close image
   
  % Pad input image border by half the size of the structuring element
  % to avoid border artifacts when there are foreground pixels 
  % near the boundary of the input image. 
  padSize = ceil(size(se)/2);
  padSize = padSize(1:min(numel(padSize),ndims(img)));
  Ap = padarray(img,padSize,'both');

  M = size(Ap,1);

  % Perform filtering
  Bp = imerode (imdilate (Ap, se), se);

  %Un-pad
  if ismatrix(img)
    closedImg = Bp(padSize(1)+1:end-padSize(1), ...
        padSize(2)+1:end-padSize(2));
  elseif ndims(img)==3
    if numel(padSize)==3
        closedImg = Bp(padSize(1)+1:end-padSize(1), ...
            padSize(2)+1:end-padSize(2), ...
            padSize(3)+1:end-padSize(3));
    else
        closedImg = Bp(padSize(1)+1:end-padSize(1), ...
            padSize(2)+1:end-padSize(2), ...
            :);
    end
    
  end
  
end
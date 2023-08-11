function nhood = makeDiskStrel(r,n)
% Get neighborhood for disk morphological structuring element 

seC = {};


if (r < 3)
    % Radius is too small to use decomposition, so force n=0.
    n = 0;
end

if (n == 0)

    [xx,yy] = meshgrid(-r:r);
    nhood = xx.^2 + yy.^2 <= r^2;
    
else
    % Ref: Rolf Adams, "Radial
    % Decomposition of Discs and Spheres," CVGIP:  Graphical Models and
    % Image Processing, vol. 55, no. 5, September 1993, pp. 325-332.
    % Ronald Jones and Pierre Soille, "Periodic lines: Definition, cascades, and
    % application to granulometries," Pattern Recognition Letters,
    % vol. 17, 1996, pp. 1057-1063.
    

    switch n
        case 4
            v = [ 1 0
                1 1
                0 1
                -1 1];
            
        case 6
            v = [ 1 0
                1 2
                2 1
                0 1
                -1 2
                -2 1];
            
        case 8
            v = [ 1 0
                2 1
                1 1
                1 2
                0 1
                -1 2
                -1 1
                -2 1];
            
        otherwise
            error('Invalid value ''n''');
    end
    
    theta = pi/(2*n);
    k = 2*r/(cot(theta) + 1/sin(theta));
    
    decompC = cell(n,1);
    for q = 1:n
        rp = floor(k / norm(v(q,:)));
        if (q == 1)
            decompC{q} = makePeriodicLineStrel(rp, v(q,:));
        else
            decompC{q} = makePeriodicLineStrel(rp, v(q,:));
        end
    end
    
    for q = 1:n
      if q==1
          nhood = imdilate(1, decompC{q}, 'full');
      else
          nhood = imdilate(nhood, decompC{q}, 'full');
      end
    end
    nhood = nhood > 0;
    [rd,~] = find(nhood);
    M = size(nhood,1);
    rd = rd - floor((M+1)/2);
    max_horiz_radius = max(rd(:));
    radial_difference = r - max_horiz_radius;
    
    len = 2*(radial_difference-1) + 1;
    if (len >= 3)
        % Add horizontal and vertical line strels.
        seC{end+1} = strel('line',len,0);
        seC{end+1} = strel('line',len,90);
        
        % Update the computed neighborhood to reflect the additional strels in
        % the decomposition.
        nhood = imdilate(nhood, seC{end-1}, 'full');
        nhood = imdilate(nhood, seC{end}, 'full');
        nhood = nhood > 0;
    end
end

se = strel([]);
se.nhood = nhood;

end
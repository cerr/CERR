function nhood = makeSphereStrel(r)
% Get neighborhood for spherical morphological structuring element 


se = strel([]);
[x,y,z] = meshgrid(-r:r,-r:r,-r:r);
nhood =  ( (x/r).^2 + (y/r).^2 + (z/r).^2 ) <= 1;
se.nhood = nhood;

end
function [Vout] = dicomrt_makevertical(Vin)
% dicomrt_makevertical(Vin)
%
% Returns a vector in vertical form.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

if size(Vin,1)<size(Vin,2)
    Vin=Vin';
end

Vout=Vin;

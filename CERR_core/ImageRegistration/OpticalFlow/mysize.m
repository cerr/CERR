function dim=mysize(m)

dim = size(m);
if length(dim) == 2
	dim = [dim 1];
end

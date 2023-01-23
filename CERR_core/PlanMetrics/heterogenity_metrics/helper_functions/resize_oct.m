function y = resize_oct(x,dv)
% function y = resize_oct(x,dv)
%
% From Octave's documentation for resize

y = zeros (dv, class (x));
sz = min (dv, size (x));
for i = 1:length (sz)
    idx{i} = 1:sz(i);
end
y(idx{:}) = x(idx{:});

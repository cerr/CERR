function se = makePeriodicLineStrel(p,v)
 % Get neighborhood for periodic line morphological structuring element 
 
se = strel([]);
v = v(:)';
p = (-p:p)';
pp = repmat(p,1,2);
rc = bsxfun(@times, pp, v);
r = rc(:,1);
c = rc(:,2);
M = 2*max(abs(r)) + 1;
N = 2*max(abs(c)) + 1;
se.nhood = false(M,N);
idx = sub2ind([M N], r + max(abs(r)) + 1, c + max(abs(c)) + 1);
nhoodM = false(M,N);
nhoodM(idx) = 1;
se.nhood = nhoodM;
se.height = zeros(M,N);

end
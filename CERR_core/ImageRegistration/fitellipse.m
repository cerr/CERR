function [z, a, b, alpha] = fitellipse(x, varargin)
%FITELLIPSE   least squares fit of ellipse to 2D data
%
%   [Z, A, B, ALPHA] = FITELLIPSE(X)
%       Fit an ellipse to the 2D points in the 2xN array X. The ellipse is
%       returned in parametric form such that the equation of the ellipse
%       parameterised by 0 <= theta < 2*pi is:
%           X = Z + Q(ALPHA) * [A * cos(theta); B * sin(theta)]
%       where Q(ALPHA) is the rotation matrix
%           Q(ALPHA) = [cos(ALPHA), -sin(ALPHA); 
%                       sin(ALPHA), cos(ALPHA)]
%
%       Fitting is performed by nonlinear least squares, optimising the
%       squared sum of orthogonal distances from the points to the fitted
%       ellipse. The initial guess is calculated by a linear least squares
%       routine, by default using the Bookstein constraint (see below)
%
%   [...]            = FITELLIPSE(X, 'linear')
%       Fit an ellipse using linear least squares. The conic to be fitted
%       is of the form
%           x'Ax + b'x + c = 0
%       and the algebraic error is minimised by least squares with the
%       Bookstein constraint (lambda_1^2 + lambda_2^2 = 1, where 
%       lambda_i are the eigenvalues of A)
%
%   [...]            = FITELLIPSE(..., 'Property', 'value', ...)
%       Specify property/value pairs to change problem parameters
%          Property                  Values
%          =================================
%          'constraint'              {|'bookstein'|, 'trace'}
%                                    For the linear fit, the following
%                                    quadratic form is considered
%                                    x'Ax + b'x + c = 0. Different
%                                    constraints on the parameters yield
%                                    different fits. Both 'bookstein' and
%                                    'trace' are Euclidean-invariant
%                                    constraints on the eigenvalues of A,
%                                    meaning the fit will be invariant
%                                    under Euclidean transformations
%                                    'bookstein': lambda1^2 + lambda2^2 = 1
%                                    'trace'    : lambda1 + lambda2     = 1
%
%           Nonlinear Fit Property   Values
%           ===============================
%           'maxits'                 positive integer, default 200
%                                    Maximum number of iterations for the
%                                    Gauss Newton step
%
%           'tol'                    positive real, default 1e-5
%                                    Relative step size tolerance
%   Example:
%       % A set of points
%       x = [1 2 5 7 9 6 3 8; 
%            7 6 8 7 5 7 2 4];
% 
%       % Fit an ellipse using the Bookstein constraint
%       [zb, ab, bb, alphab] = fitellipse(x, 'linear');
%
%       % Find the least squares geometric estimate       
%       [zg, ag, bg, alphag] = fitellipse(x);
%       
%       % Plot the results
%       plot(x(1,:), x(2,:), 'ro')
%       hold on
%       % plotellipse(zb, ab, bb, alphab, 'b--')
%       % plotellipse(zg, ag, bg, alphag, 'k')
% 
%   See also PLOTELLIPSE

% Copyright Richard Brown, this code can be freely used and modified so
% long as this line is retained
error(nargchk(1, 5, nargin, 'struct'))

% Default parameters
params.fNonlinear = true;
params.constraint = 'bookstein';
params.maxits     = 200;
params.tol        = 1e-5;

% Parse inputs
[x, params] = parseinputs(x, params, varargin{:});

% Constraints are Euclidean-invariant, so improve conditioning by removing
% centroid
centroid = mean(x, 2);
x        = x - repmat(centroid, 1, size(x, 2));

% Obtain a linear estimate
switch params.constraint
    % Bookstein constraint : lambda_1^2 + lambda_2^2 = 1
    case 'bookstein'
        [z, a, b, alpha] = fitbookstein(x);
        
    % 'trace' constraint, lambda1 + lambda2 = trace(A) = 1
    case 'trace'
        [z, a, b, alpha] = fitggk(x);
end % switch

% Minimise geometric error using nonlinear least squares if required
if params.fNonlinear
    % Initial conditions
    z0     = z;
    a0     = a;
    b0     = b;
    alpha0 = alpha;
    
    % Apply the fit
    [z, a, b, alpha, fConverged] = ...
        fitnonlinear(x, z0, a0, b0, alpha0, params);
    
    % Return linear estimate if GN doesn't converge
    if ~fConverged
        warning('fitellipse:FailureToConverge', ...'
            'Gauss-Newton did not converge, returning linear estimate');
        z = z0;
        a = a0;
        b = b0;
        alpha = alpha0;
    end
end

% Add the centroid back on
z = z + centroid;

end % fitellipse

% ----END MAIN FUNCTION-----------%

function [z, a, b, alpha] = fitbookstein(x)
%FITBOOKSTEIN   Linear ellipse fit using bookstein constraint
%   lambda_1^2 + lambda_2^2 = 1, where lambda_i are the eigenvalues of A

% Convenience variables
m  = size(x, 2);
x1 = x(1, :)';
x2 = x(2, :)';

% Define the coefficient matrix B, such that we solve the system
% B *[v; w] = 0, with the constraint norm(w) == 1
B = [x1, x2, ones(m, 1), x1.^2, sqrt(2) * x1 .* x2, x2.^2];

% To enforce the constraint, we need to take the QR decomposition
[Q, R] = qr(B);

% Decompose R into blocks
R11 = R(1:3, 1:3);
R12 = R(1:3, 4:6);
R22 = R(4:6, 4:6);

% Solve R22 * w = 0 subject to norm(w) == 1
[U, S, V] = svd(R22);
w = V(:, 3);

% Solve for the remaining variables
v = -R11 \ R12 * w;

% Fill in the quadratic form
A        = zeros(2);
A(1)     = w(1);
A([2 3]) = 1 / sqrt(2) * w(2);
A(4)     = w(3);
bv       = v(1:2);
c        = v(3);

% Find the parameters
[z, a, b, alpha] = conic2parametric(A, bv, c);

end % fitellipse


function [z, a, b, alpha] = fitggk(x)
% Linear least squares with the Euclidean-invariant constraint Trace(A) = 1

% Convenience variables
m  = size(x, 2);
x1 = x(1, :)';
x2 = x(2, :)';

% Coefficient matrix
B = [2 * x1 .* x2, x2.^2 - x1.^2, x1, x2, ones(m, 1)];

v = B \ -x1.^2;

% For clarity, fill in the quadratic form variables
A        = zeros(2);
A(1,1)   = 1 - v(2);
A([2 3]) = v(1);
A(2,2)   = v(2);
bv       = v(3:4);
c        = v(5);

% find parameters
[z, a, b, alpha] = conic2parametric(A, bv, c);

end



function [z, a, b, alpha, fConverged] = fitnonlinear(x, z0, a0, b0, alpha0, params)
% Gauss-Newton least squares ellipse fit minimising geometric distance 

% Get initial rotation matrix
Q0 = [cos(alpha0), -sin(alpha0); sin(alpha0) cos(alpha0)];
m = size(x, 2);

% Get initial phase estimates
phi0 = angle( [1 i] * Q0' * (x - repmat(z0, 1, m)) )';
u = [phi0; alpha0; a0; b0; z0];

% Iterate using Gauss Newton
fConverged = false;
for nIts = 1:params.maxits
    % Find the function and Jacobian
    [f, J] = sys(u);
    
    % Solve for the step and update u
    h = -J \ f;
    u = u + h;
    
    % Check for convergence
    delta = norm(h, inf) / norm(u, inf);
    if delta < params.tol
        fConverged = true;
        break
    end
end
        
alpha = u(end-4);
a     = u(end-3);
b     = u(end-2);
z     = u(end-1:end);
        

    function [f, J] = sys(u)
        % SYS : Define the system of nonlinear equations and Jacobian. Nested
        % function accesses X (but changeth it not)
        % from the FITELLIPSE workspace

        % Tolerance for whether it is a circle
        circTol = 1e-5;
        
        % Unpack parameters from u
        phi   = u(1:end-5);
        alpha = u(end-4);
        a     = u(end-3);
        b     = u(end-2);
        z     = u(end-1:end);
        
        % If it is a circle, the Jacobian will be singular, and the
        % Gauss-Newton step won't work. 
        %TODO: This can be fixed by switching to a Levenberg-Marquardt
        %solver
        if abs(a - b) / (a + b) < circTol
            warning('fitellipse:CircleFound', ...
                'Ellipse is near-circular - nonlinear fit may not succeed')
        end
        
        % Convenience trig variables
        c = cos(phi);
        s = sin(phi);
        ca = cos(alpha);
        sa = sin(alpha);
        
        % Rotation matrices
        Q    = [ca, -sa; sa, ca];
        Qdot = [-sa, -ca; ca, -sa];
        
        % Preallocate function and Jacobian variables
        f = zeros(2 * m, 1);
        J = zeros(2 * m, m + 5);
        for i = 1:m
            rows = (2*i-1):(2*i);
            % Equation system - vector difference between point on ellipse
            % and data point
            f((2*i-1):(2*i)) = x(:, i) - z - Q * [a * cos(phi(i)); b * sin(phi(i))];
            
            % Jacobian
            J(rows, i) = -Q * [-a * s(i); b * c(i)];
            J(rows, (end-4:end)) = ...
                [-Qdot*[a*c(i); b*s(i)], -Q*[c(i); 0], -Q*[0; s(i)], [-1 0; 0 -1]];
        end
    end
end % fitnonlinear



function [z, a, b, alpha] = conic2parametric(A, bv, c)
% Diagonalise A - find Q, D such at A = Q' * D * Q
[Q, D] = eig(A);
Q = Q';

% If the determinant < 0, it's not an ellipse
if prod(diag(D)) <= 0 
    error('fitellipse:NotEllipse', 'Linear fit did not produce an ellipse');
end

% We have b_h' = 2 * t' * A + b'
t = -0.5 * (A \ bv);

c_h = t' * A * t + bv' * t + c;

z = t;
a = sqrt(-c_h / D(1,1));
b = sqrt(-c_h / D(2,2));
alpha = atan2(Q(1,2), Q(1,1));
end % conic2parametric





function [x, params] = parseinputs(x, params, varargin)
% PARSEINPUTS put x in the correct form, and parse user parameters

% CHECK x
% Make sure x is 2xN where N > 3
if size(x, 2) == 2
    x = x'; 
end
if size(x, 1) ~= 2
    error('fitellipse:InvalidDimension', ...
        'Input matrix must be two dimensional')
end
if size(x, 2) < 6
    error('fitellipse:InsufficientPoints', ...
        'At least 6 points required to compute fit')
end


% Determine whether we are solving for geometric (nonlinear) or algebraic
% (linear) distance
if ~isempty(varargin) && strncmpi(varargin{1}, 'linear', length(varargin{1}))
    params.fNonlinear = false;
    varargin(1)       = [];
else
    params.fNonlinear = true;
end

% Parse property/value pairs
if rem(length(varargin), 2) ~= 0
    error('fitellipse:InvalidInputArguments', ...
        'Additional arguments must take the form of Property/Value pairs')
end

% Cell array of valid property names
properties = {'constraint', 'maxits', 'tol'};

while length(varargin) ~= 0
    % Pop pair off varargin
    property      = varargin{1};
    value         = varargin{2};
    varargin(1:2) = [];
    
    % If the property has been supplied in a shortened form, lengthen it
    iProperty = find(strncmpi(property, properties, length(property)));
    if isempty(iProperty)
        error('fitellipse:UnknownProperty', 'Unknown Property');
    elseif length(iProperty) > 1
        error('fitellipse:AmbiguousProperty', ...
            'Supplied shortened property name is ambiguous');
    end
    
    % Expand property to its full name
    property = properties{iProperty};
    
    % Check for irrelevant property
    if ~params.fNonlinear && ismember(property, {'maxits', 'tol'})
        warning('fitellipse:IrrelevantProperty', ...
            'Supplied property has no effect on linear estimate, ignoring');
        continue
    end
        
    % Check supplied property value
    switch property
        case 'maxits'
            if ~isnumeric(value) || value <= 0
                error('fitcircle:InvalidMaxits', ...
                    'maxits must be an integer greater than 0')
            end
            params.maxits = value;
        case 'tol'
            if ~isnumeric(value) || value <= 0
                error('fitcircle:InvalidTol', ...
                    'tol must be a positive real number')
            end
            params.tol = value;
        case 'constraint'
            switch lower(value)
                case 'bookstein'
                    params.constraint = 'bookstein';
                case 'trace'
                    params.constraint = 'trace';
                otherwise
                    error('fitellipse:InvalidConstraint', ...
                        'Invalid constraint specified')
            end
    end % switch property
end % while

end % parseinputs
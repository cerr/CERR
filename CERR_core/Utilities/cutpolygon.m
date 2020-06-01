function Pc = cutpolygon(P, L, s, doSplit, doPlot, doTable)
% CUTPOLYGON - Split a 2D polygon by a line, and remove one of the sides
%
% Use CUTPOLYGON to cut alias intersect alias split alias slice a polygon P
% (being a series of connected X,Y coordinates) with a line L (defined by
% two points), removing a specified side s. L can serve as a bottom limit
% ('B'), top limit ('T'), left limit ('L'), or right limit ('R').
%
% Syntax:
%   Pc = CUTPOLYGON(P, L, s, doSplit, doPlot, doTable)
%
% Demo (cut random regular polygon with random line):
%   CUTPOLYGON demo
%
% Inputs:
%   P        Polygon coordinates [X, Y]
%   L        Line defined by two coordinates [x1, y1; x2, y2]
%   s        What side to remove, character or integer
%
% Optional switches:
%   doSplit  Add intermediate NaN entries if the polygon is split into non-connected parts (default false)
%   doPlot   Plot original and cut polygon plus line (default false)
%   doTable  Tabulate intersection and validity per polygon segment (default false)
%
% Side options:
%   1 / B = bottom  remove parts Y < intersection
%   2 / T = top     remove parts Y > intersection
%   3 / L = left    remove parts X < intersection
%   4 / R = right   remove parts X > intersection
%
% Finding the intersection:
%   http://en.wikipedia.org/wiki/Line-line_intersection
%
% Output:
%   - Pc is the polygon post-cut [X, Y]
%   - Pc can be shorter than P (points are removed)
%   - Pc can contain intermediate NaN entries if doSplit is true
%
% Version history (recent to ancient):
%   Jan 2010, Dominik Brands, fixed pure horizontal/vertical limit bug
%   Apr 2009, Jasper Menger , creation

% Demo mode (split random regular polygon with random orientation through its center)
if nargin == 1 && ischar(P) && strcmpi(P, 'demo')

    % Random parameters
    doPlot  = true;
    doTable = true;
    dx      = rand(1)*100 - 50;
    dy      = rand(1)*100 - 50;
    Alpha   = round(linspace(0, 360, round(rand(1)*10) + 3))' + round(rand(1) * 360) - 180;
    Alpha   = Alpha(1:end - 1);
    rx      = rand(1)*50 + 1;
    ry      = rand(1)*50 + 1;
    beta    = round((rand(1) - 1/2) * 2 * 360);
    z       = rand(1)*50 + 1;
    s       = round(rand(1) * 3 + 1);
    doSplit = round(rand(1));
    
    % Polygon (closed) and cutline coordinates
    P = [rx * cos(Alpha * pi/180) + dx, ry * sin(Alpha * pi/180) + dy];
    P = [P; P(1, :)];
    L = z * [-cos(beta * pi/180), -sin(beta * pi/180); +cos(beta * pi/180), +sin(beta * pi/180)];
    
    % Intersect
    Pc = cutpolygon(P, L, s, doSplit, doPlot, doTable);
    return;
    
end % of demo mode

% Optional arguments
if nargin < 4, doSplit = false; end
if nargin < 5, doPlot  = false; end
if nargin < 6, doTable = false; end

% Initialize output
Pc = P;
if isempty(P) || isempty(L), return; end

% Check side argument
if numel(s) ~= 1 || not(ischar(s) || isnumeric(s))
    error('Side argument must have length one and be a character or number');
end
if isnumeric(s)
    if round(s) ~= s || s < 1 || s > 4
        error('Side argument must be in range [1, 4] when numerical');
    end
    switch s
        case 1, s = 'B';
        case 2, s = 'T';
        case 3, s = 'L';
        case 4, s = 'R';
    end
elseif ischar(s)
    s = upper(s);
    if ~any(strcmp(s, {'B', 'T', 'L', 'R'}))
        error('Side argument must be one of {B, T, L, R} when character');
    end
end

% Line coordinates (1 - 2)
if size(L, 1) ~= 2 || size(L, 2) ~= 2, error('Line coordinate matrix L should be 2 x 2'); end
xx1 = L(1, 1); yy1 = L(1, 2);
xx2 = L(2, 1); yy2 = L(2, 2);
if xx1 == xx2 && yy1 == yy2, error('Line can not be defined through two identical points'); end
if xx1 == xx2 && any(strcmp(s, {'B', 'T'})), error('Vertical line cannot serve as bottom or top limit'); end
if yy1 == yy2 && any(strcmp(s, {'L', 'R'})), error('Horizontal line cannot serve as left or right limit'); end

% Split polygon into line segments (3 - 4)
if size(P, 2) ~= 2, error('Polygon coordinate matrix should be 2 columns wide [X, Y]'); end
if size(P, 1) <  2, error('Polygon coordinate matrix should at least contain two points [X, Y]'); end
P  = P(~isnan(sum(P, 2)), :);
n  = size(P, 1) - 1;
X3 = P(1:(end - 1), 1);
Y3 = P(1:(end - 1), 2);
X4 = P(2:end, 1);
Y4 = P(2:end, 2);

% Table header
if doTable
    frmt = '%.3f';
    fprintf('\n\n');
    fprintf('Cutline ...\n\n');
    fprintf('\tx1      \ty1      \tx2      \ty2      \ts \n');
    fprintf('\t========\t========\t========\t========\t==\n');
    fprintf('\t%s\t%s\t%s\t%s\t%s\n\n', ...
        num2fixedstr(xx1, frmt, 8), ...
        num2fixedstr(yy1, frmt, 8), ...
        num2fixedstr(xx2, frmt, 8), ...
        num2fixedstr(yy2, frmt, 8), s);
    fprintf('Polygon segments ...\n\n');
    fprintf('\t#  \tx3      \ty3      \tx4      \ty4      \td       \txp      \typ      \tv3\tv4\n');
    fprintf('\t===\t========\t========\t========\t========\t========\t========\t========\t==\t==\n');
end

% Browse the segments
for i = 1:n
    % Current polygon line segment (and initialize intersection point p)
    xx3 = X3(i); xx4 = X4(i); xp = NaN;
    yy3 = Y3(i); yy4 = Y4(i); yp = NaN;
    
    % Intersection denominator (zero if lines are parallel)
    d = (xx1-xx2) * (yy3-yy4) - (yy1-yy2) * (xx3-xx4);
    
    % Validity of start (3) and stop (4) points
    V = [true, true];
    
    if xx1 == xx2
        % Truly vertical cutline (left or right limit)
        switch s
            case 'L'
                V = [xx3 >= xx1, xx4 >= xx1];
                if xx3 < xx1 && xx4 < xx1
                    % No intersection, so discard segment
                    X3(i) = NaN; Y3(i) = NaN;
                    X4(i) = NaN; Y4(i) = NaN;
                elseif xx3 < xx1
                    % Segment start point is illegal, so move it to the intersection
                    xp    = xx1;
                    yp    = (xp - xx3) / (xx4 - xx3) * (yy4 - yy3) + yy3;
                    X3(i) = xp;
                    Y3(i) = yp;
                elseif xx4 < xx1
                    % Segment stop point is illegal, move it to the intersection
                    xp    = xx1;
                    yp    = (xp - xx4) / (xx3 - xx4) * (yy3 - yy4) + yy4;
                    X4(i) = xp;
                    Y4(i) = yp;
                end
            case 'R'
                V = [xx3 <= xx1, xx4 <= xx1];
                if xx3 > xx1 && xx4 > xx1
                    % No intersection, so discard segment
                    X3(i) = NaN; Y3(i) = NaN;
                    X4(i) = NaN; Y4(i) = NaN;
                elseif xx3 > xx1
                    % Segment start point is illegal, so move it to the intersection
                    xp    = xx1;
                    yp    = (xp - xx4) / (xx3 - xx4) * (yy3 - yy4) + yy4;
                    X3(i) = xp;
                    Y3(i) = yp;
                elseif xx4 > xx1
                    % Segment stop point is illegal, move it to the intersection
                    xp    = xx1;
                    yp    = (xp - xx3) / (xx4 - xx3) * (yy4 - yy3) + yy3;
                    X4(i) = xp; 
                    Y4(i) = yp;
                end
        end
        
    elseif yy1 == yy2
        % Truly horizontal cutline (top or bottom limit)
          switch s
            case 'T'
                V = [yy3 <= yy1, yy4 <= yy1];
                if yy3 > yy1 && yy4 > yy1
                    % No intersection, so discard segment
                    X3(i) = NaN; Y3(i) = NaN;
                    X4(i) = NaN; Y4(i) = NaN;
                elseif yy3 > yy1
                    % Segment start point is illegal, so move it to the intersection
                    yp    = yy1;
                    xp    = (yp - yy4) / (yy3 - yy4) * (xx3 - xx4) + xx4;
                    X3(i) = xp;
                    Y3(i) = yp;
                elseif yy4 > yy1
                    % Segment stop point is illegal, move it to the intersection
                    yp    = yy1;
                    xp    = (yp - yy3) / (yy4 - yy3) * (xx4 - xx3) + xx3;
                    X4(i) = xp;
                    Y4(i) = yp;
                end
            case 'B'
                V = [yy3 >= yy1, yy4 >= yy1];
                if yy3 < yy1 && yy4 < yy1
                    % No intersection, so discard segment
                    X3(i) = NaN; Y3(i) = NaN;
                    X4(i) = NaN; Y4(i) = NaN;
                elseif yy3 < yy1
                    % Segment start point is illegal, so move it to the intersection
                    yp    = yy1;
                    xp    = (yp - yy3) / (yy4 - yy3) * (xx4 - xx3) + xx3;
                    X3(i) = xp;
                    Y3(i) = yp;
                elseif yy4 < yy1
                    % Segment stop point is illegal, move it to the intersection
                    yp    = yy1;
                    xp    = (yp - yy4) / (yy3 - yy4) * (xx3 - xx4) + xx4;
                    X4(i) = xp;
                    Y4(i) = yp;
                end
        end
        
    else
        % Cutline at some arbitrary angle
        
        % Top/bottom cut on parallel lines
        if d == 0 && any(strcmp(s, {'T', 'B'})) && xx1 ~= xx2
            yi = interp1([xx1, xx2], [yy1, yy2], xx3, 'linear', 'extrap');
            if (strcmp(s, 'B') && yy3 < yi) || (strcmp(s, 'T') && yy3 > yi)
                X3(i) = NaN; Y3(i) = NaN;
                X4(i) = NaN; Y4(i) = NaN;
            end
        end
        
        % Left/right cut on parallel lines    
        if d == 0 && any(strcmp(s, {'L', 'R'})) && yy1 ~= yy2
            xi = interp1([yy1, yy2], [xx1, xx2], yy3, 'linear', 'extrap');
            if (strcmp(s, 'L') && xx3 < xi) || (strcmp(s, 'R') && xx3 > xi)
                X3(i) = NaN; Y3(i) = NaN;
                X4(i) = NaN; Y4(i) = NaN;
            end
        end
        
        % Complete or partial cut of non-parallel segment
        if d ~= 0
            % Intersection point P (on or beyond segment)
            xp = ((xx1*yy2 - yy1*xx2) * (xx3 - xx4) - (xx1 - xx2) * (xx3*yy4 - yy3*xx4)) / d;
            yp = ((xx1*yy2 - yy1*xx2) * (yy3 - yy4) - (yy1 - yy2) * (xx3*yy4 - yy3*xx4)) / d;
            
            % Check validity V of start (3) and stop (4) points through interpolation
            switch s
                case 'B'
                    yi3 = interp1([xx1, xx2], [yy1, yy2], xx3, 'linear', 'extrap');
                    yi4 = interp1([xx1, xx2], [yy1, yy2], xx4, 'linear', 'extrap');
                    V   = [yi3 <= yy3, yi4 <= yy4];
                case 'T'
                    yi3 = interp1([xx1, xx2], [yy1, yy2], xx3, 'linear', 'extrap');
                    yi4 = interp1([xx1, xx2], [yy1, yy2], xx4, 'linear', 'extrap');
                    V   = [yi3 >= yy3, yi4 >= yy4];
                case 'L'
                    xi3 = interp1([yy1, yy2], [xx1, xx2], yy3, 'linear', 'extrap');
                    xi4 = interp1([yy1, yy2], [xx1, xx2], yy4, 'linear', 'extrap');
                    V   = [xi3 <= xx3, xi4 <= xx4];
                case 'R'
                    xi3 = interp1([yy1, yy2], [xx1, xx2], yy3, 'linear', 'extrap');
                    xi4 = interp1([yy1, yy2], [xx1, xx2], yy4, 'linear', 'extrap');
                    V   = [xi3 >= xx3, xi4 >= xx4];
            end
            
            % Throw away or intersect
            throwaway = all(V == false);
            if V(1) == false && V(2) == true
                X3(i) = xp;
                Y3(i) = yp;
            elseif V(1) == true && V(2) == false
                X4(i) = xp;
                Y4(i) = yp;
            elseif V(1) == false && V(2) == false
                X3(i) = NaN; Y3(i) = NaN;
                X4(i) = NaN; Y4(i) = NaN;
            end
            
        end % of non-parallel cutting
    end % of horizontal/vertical cutline check
    
    % Display coordinates
    if doTable
        fprintf('\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            num2fixedstr(i   , '%d', 3), ...
            num2fixedstr(xx3 , frmt, 8), ...
            num2fixedstr(yy3 , frmt, 8), ...
            num2fixedstr(xx4 , frmt, 8), ...
            num2fixedstr(yy4 , frmt, 8), ...
            num2fixedstr(d   , frmt, 8), ...
            num2fixedstr(xp  , frmt, 8), ...
            num2fixedstr(yp  , frmt, 8), ...
            num2fixedstr(V(1), '%d', 2), ...
            num2fixedstr(V(2), '%d', 2));
    end        
end % of segment cutting
if doTable
    fprintf('\n\n');
end

% Assemble cut segments into polygon Pc
Pc = [];
for i = 1:n
    Pc(end + 1, 1:2) = [X3(i), Y3(i)];
    if X4(i) ~= X3(i) || Y4(i) ~= Y3(i)
        Pc(end + 1, 1:2) = [X4(i), Y4(i)];
    end    
end

% Remove intermediate NaN entries
if not(doSplit)
    Pc = Pc(~isnan(sum(Pc, 2)), :);
end

% Remove duplicate entries
i = 1;
while i < size(Pc, 1)
    if Pc(i + 1, 1) == Pc(i, 1) && Pc(i + 1, 2) == Pc(i, 2)
        % Next point is a duplicate, remove from list
        Pc = Pc([1:i, (i + 2):end], 1:2);
    else
        % Move on to next point
        i = i + 1;
    end
end

% If original polygon was a closed shape, then keep it so
if ~isempty(Pc) && all([P(end, :) - P(1, :)] == 0) && any([Pc(end, :) - Pc(1, :)] ~= 0)
    Pc(end + 1, :) = Pc(1, :);
end

% Plot result in current axes
if doPlot
    % Set up axes
    cla; hold on; grid off; box on;
    title('Cut polygon by line', 'fontweight', 'bold');
    xlabel('X');
    ylabel('Y');
    
    % Overall X & Y limits
    X_lim = [min([P(:, 1); L(:, 1)]), max([P(:, 1); L(:, 1)])];
    Y_lim = [min([P(:, 2); L(:, 2)]), max([P(:, 2); L(:, 2)])];
    X_lim = X_lim + (X_lim(2) - X_lim(1)) / 10 * [-1 +1];
    Y_lim = Y_lim + (Y_lim(2) - Y_lim(1)) / 10 * [-1 +1];
    axis equal;
    axis([X_lim, Y_lim]);
        
    % Extend cut line
    if xx1 == xx2
        X = [xx1, xx2];
        Y = Y_lim;
    elseif yy1 == yy2
        X = X_lim;
        Y = [yy1, yy2];
    else
        X = X_lim;
        Y = interp1([xx1, xx2], [yy1, yy2], X, 'linear', 'extrap');
    end
    
    % Plot cut line (red)
    plot(X, Y, '-', 'Color', [.8 0 0], 'LineWidth', 0.5);
    % Plot polygon original (grey)
    plot(P(:, 1), P(:, 2), '.-', 'Color', [.7 .7 .7], 'LineWidth', 0.5, 'MarkerSize', 10);
    % Plot polygon cut (blue thick)
    plot(Pc(:, 1), Pc(:, 2), '.-', 'Color', [0 .25, .5], 'LineWidth', 1.5, 'MarkerSize', 10);
    % Cut line coordinates (red) 
    plot([xx1, xx2], [yy1, yy2], '.', 'Color', [.8 0 0], 'MarkerSize', 10);    
    % Show legend
    legend({['cut ', s], 'polygon ori', 'polygon cut'}, -1);

    drawnow;
end

% Done!


% -----------------------------------------------------------------------------------------------------------------------------------
function txt = num2fixedstr(X, varargin)
% NUM2FIXEDSTR - Converts a number to a string with a fixed length
%
% Syntax:
%   txt = num2fixedstr(X)
%   txt = num2fixedstr(X, precision, L)
%   txt = num2fixedstr(X, precision, L, plusSign)
%
% Jasper Menger, July 2006

if islogical(X)
    X = double(X);
end
if not(isnumeric(X))
    error('Numeric input required!');
end

% Default length, precision, and sign
precision = '';     % empty -> Fexible precision
L         = 0;      % zero  -> Flexible length
plusSign  = false;  % true  -> Numbers start with +/- sign (only for fixed length!)

% Get inputs
if numel(varargin) >= 1, precision = varargin{1}; end
if numel(varargin) >= 2, L         = varargin{2}; end
if numel(varargin) >= 3, plusSign  = varargin{3}; end

% Stop here in case of empty input
if isempty(X)
    txt = repmat(' ', 1, L);
    return;
end

% Round the numbers in case of integer output
if strcmp(stringtrim(precision), '%d')
    X = round(X);
end
% Look for trailing tabs or commas in precision string
trail = '';
if any(strfind(precision, ','))
    trail = ',';
end
if any(strfind(precision, '\t'))
    trail     = sprintf('\t');
    precision = strrep(precision, '\t', '');
end

% Convert to string!
txt = '';
% Fixed length for each number
if plusSign
    precision_plus = strrep(precision, '%', '+%');
end
for i = 1:length(X)
    if isempty(precision)
        txt_i = num2str(X(i));
    else
        if plusSign && X(i) > 0
            txt_i = sprintf(precision_plus, X(i));
        else
            txt_i = sprintf(precision, X(i));
        end
    end
    L0 = length(txt_i) + 1;
    % Fixate the length of the text chunk
    if (L <= 0) || (L == Inf)
          L = length(txt_i) + 2;
    end
    txt_i = [txt_i, ' ', repmat(' ', 1, L - length(txt_i))];
    % Chop the chunk
    txt_i = txt_i(1:L);
    % Add the chunk to the output
    txt = [txt, txt_i, trail];
end

% Done!



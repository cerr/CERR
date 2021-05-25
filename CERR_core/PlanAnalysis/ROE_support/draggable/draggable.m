classdef draggable < handle
    %{
    This class is intended to be a modern enhancement of draggable.m written by
    Francois Buffard. It functions as a decorator for other graphics objects,
    making them draggable. The original reason for this version is to be usable
    with both the old Figure and Axes objects, as well as the new UIFigure and
    UIAxes objects.

    Original: (https://www.mathworks.com/matlabcentral/fileexchange/4179-draggable)

    A few features and notes are listed below. Backwards compatibility has been
    maintained. Turning the draggable functionality off and restoring the
    original functionality of the graphics objects requires deletion of the
    draggable decorator.

    The justification for using a decorator design is to have the draggable
    behave like the original graphics object, without the need for storing app
    data in parent objects, which is potentially fragile if other objects modify
    the parents. It keeps private information private, and in my opinion
    provides a cleaner, more encapsulated design.

    WARNING! To maintain portability between Figure and UIFigure objects, do not
    use gca() and gcf() in callbacks.


    Notes:

    - movefcn has been renamed on_move_callback

    - endfcn has been renamed on_release_callback

    - internal data is no longer stored using set/getappdata(), so the caller is
      responsible for storing their own draggable objects.

    - input "off" has been removed, and that functionality moved to object
      destructor. Simply delete the draggable object the way you would with any
      graphics object to restore previous behavior.


    Features:

    - choice of mouse button: users can make an object draggable only by a
      specific mouse button, or by any button. The default is the old behavior
      of any button. To use multiple buttons, create multiple objects.

    - on_click_callback: because on_move_callback is called frequently, this
function was added so that expensive singular operations only need to be
      called once when the object is first clicked.

    - clearer interface for constraints: slope, xlim and ylim are delineated
      independently as settable properties.

    - behaves transparently like underlying graphics object for properties not
      named in this class.

    - backward compatibility: No change should be required to the initial call.
      Other new features are not accessible this way.   Simply assign values to
      the appropriate properties to use them.

    (C) Copyright 2004-2020
    François Bouffard
    fbouffard@gmail.com

    (C) Copyright 2020
    William Warriner
    wwarriner@gmail.com
    %}
    properties
        button(1,1) string = "any"
        constraint(1,1) string = "none"
        slope(1,1) double {mustBeReal} = 0 % only used with DIAGONAL_CONSTRAINT
        xlim(:,2) double {mustBeReal} = [] % empty to determine automatically, 1x2
        ylim(:,2) double {mustBeReal} = [] % empty to determine automatically, 1x2
        on_click_callback(1,1) function_handle = @(varargin)[]
        on_move_callback(1,1) function_handle = @(varargin)[]
        on_release_callback(1,1) function_handle = @(varargin)[]
    end
    
    properties (SetAccess = private)
        is_dragging(1,1) logical = false
        g
    end
    
    properties (Constant)
        LEFT_BUTTON = "normal"
        RIGHT_BUTTON = "alt"
        MIDDLE_BUTTON = "extend"
        ANY_BUTTON = "any"
        
        NO_CONSTRAINT = "none" % xlim, ylim
        DIAGONAL_CONSTRAINT = "diagonal" % slope, xlim, ylim
        HORIZONTAL_CONSTRAINT = "horizontal" % xlim
        VERTICAL_CONSTRAINT = "vertical" % ylim
    end
    
    methods
        function obj = draggable(g, varargin)
            args = obj.parse(g, varargin{:});
            
            obj.figh = args.figh;
            obj.constraint = args.constraint;
            obj.slope = args.slope;
            obj.xlim = args.xlim;
            obj.ylim = args.ylim;
            obj.on_move_callback = args.on_move_callback;
            obj.on_release_callback = args.on_release_callback;
            
            obj.initial_bd_fn = g.ButtonDownFcn;
            g.ButtonDownFcn = @obj.on_button_down;
            obj.axh = g.Parent;
            obj.g = g;
        end
        
        function set.xlim(obj, value)
            assert(isempty(value) || all(size(value) == [1 2]));
            obj.xlim = value;
        end
        
        function set.ylim(obj, value)
            assert(isempty(value) || all(size(value) == [1 2]));
            obj.ylim = value;
        end
        
        function varargout = subsref(obj, s)
            switch s(1).type
                case '.'
                    if isprop(obj, s(1).subs)
                        [varargout{1:nargout}] = builtin('subsref', obj, s);
                    else
                        [varargout{1:nargout}] = builtin('subsref', obj.g, s);
                    end
                case '()'
                    if length(s) == 2 && strcmp(s(2).type,'.')
                        sub_objs = obj(s(1).subs{:});
                        [varargout{1:nargout}] = sub_objs.subsref(s(2:end));
                    else
                        [varargout{1:nargout}] = builtin('subsref', obj, s);
                    end
                case '{}'
                    [varargout{1:nargout}] = builtin('subsref', obj, s);
                otherwise
                    error('Not a valid indexing expression');
            end
        end
        
        function obj = subsasgn(obj, s, varargin)
            if isequal(obj, [])
                obj = draggable.empty;
            end
            switch s(1).type
                case '.'
                    if isprop(obj, s(1).subs)
                        obj = builtin('subsasgn', obj, s, varargin{:});
                    else
                        obj.g = builtin('subsasgn', obj.g, s, varargin{:});
                    end
                case '()'
                    if length(s) == 2 && strcmp(s(2).type,'.')
                        sub_objs = obj(s(1).subs{:});
                        sub_objs = sub_objs.subsasgn(s(2:end), varargin{:});
                        obj(s(1).subs{:}) = sub_objs;
                    else
                        obj = builtin('subsasgn', obj, s, varargin{:});
                    end
                case '{}'
                    obj = builtin('subsasgn', obj, s, varargin{:});
                otherwise
                    error('Not a valid indexing expression');
            end
        end
        
        function delete(obj)
            if isvalid(obj.g)
                obj.g.ButtonDownFcn = obj.initial_bd_fn;
            end
        end
    end
    
    properties (Access = private)
        figh
        axh
        initial_bd_fn
        
        start_point(1,2) double % mouse point
        start_extent(1,4) double % [x y w h]
        start_position(2,:) double % axes values
        wbd_fn
        wbu_fn
        wbm_fn
    end
    
    methods
        function on_button_down(obj, ~, event)
            if obj.is_dragging
                return;
            end
            
            click_type = string(obj.figh.SelectionType);
            if click_type ~= obj.button ...
                    && obj.button ~= obj.ANY_BUTTON
                return;
            end
            
            obj.start_point = obj.get_point();
            obj.start_extent = obj.get_extent();
            obj.start_position = obj.get_position();
            if isempty(obj.xlim)
                obj.xlim = obj.axh.XLim;
            end
            if isempty(obj.ylim)
                obj.ylim = obj.axh.YLim;
            end
            obj.wbd_fn = obj.figh.WindowButtonDownFcn;
            obj.wbu_fn = obj.figh.WindowButtonUpFcn;
            obj.wbm_fn = obj.figh.WindowButtonMotionFcn;
            
            obj.figh.WindowButtonUpFcn = @obj.on_button_up;
            obj.figh.WindowButtonMotionFcn = @obj.on_move;
            
            if isvalid(obj.g)
                if nargin(obj.on_click_callback) == 1
                    obj.on_click_callback(obj.g);
                else
                    obj.on_click_callback(obj.g, event);
                end
            end
            
            obj.is_dragging = true;
        end
        
        function on_move(obj, ~, event)
            if ~obj.is_dragging
                return;
            end
            
            delta_point = obj.get_point() - obj.start_point;
            X = 1;
            Y = 2;
            m_slope = obj.slope;
            xrange = obj.xlim;
            yrange = obj.ylim;
            
            % degenerate lines
            if obj.constraint == obj.DIAGONAL_CONSTRAINT
                if m_slope == 0
                    obj.constraint = obj.HORIZONTAL_CONSTRAINT;
                elseif isinf(m_slope)
                    obj.constraint = obj.VERTICAL_CONSTRAINT;
                end
            end
            
            % Computing movement range and imposing movement constraints
            % (p is always [xmin xmax ymin ymax])
            switch obj.constraint
                case obj.NO_CONSTRAINT
                    % noop
                case obj.HORIZONTAL_CONSTRAINT
                    delta_point(Y) = 0;
                case obj.VERTICAL_CONSTRAINT
                    delta_point(X) = 0;
                case obj.DIAGONAL_CONSTRAINT
                    % project onto line
                    v = [1; m_slope];
                    Pv = v * v' / (v' * v);
                    delta_point = delta_point * Pv;
            end
            
            % Computing new position. What we want is actually a bit complex: we
            % want the object to adopt the new position, unless it gets out of
            % range. If it gets out of range in a direction, we want it to stick
            % to the limit in that direction. Also, if the object is out of
            % range at the beginning of the movement, we want to be able to move
            % it back into range; movement must then be allowed.
            
            % For debugging purposes only; setting debug to 1 shows range,
            % extents, dpt, corrected dpt and in-range status of the object in
            % the command window. Note: this will clear the command window.
            initial_delta_point = delta_point;
            
            % Computing object extent in the [x y w h] format before and after
            % moving
            initial_extent = obj.start_extent;
            new_extent = initial_extent + [delta_point 0 0];
            
            % Verifying if old and new objects breach the allowed range in any
            % direction (see the function is_inside_range below)
            initial_inrange = obj.is_inside_range(initial_extent, [xrange yrange]);
            new_inrange = obj.is_inside_range(new_extent, [xrange yrange]);
            
            % Modifying dpt to stick to range limit if range violation occured,
            % but the movement won't get restricted if the object was out of
            % range to begin with.
            %
            % We use if/ends and no elseif's because once an object hits a range
            % limit, it is still free to move along the other axis, and another
            % range limit could be hit aftwards. That is, except for diagonal
            % constraints, in which a first limit hit must completely lock the
            % object until the mouse is inside the range.
            
            % In-line correction functions to dpt due to range violations
            xminc = @(dpt) [xrange(1) - initial_extent(1) dpt(Y)];
            xmaxc = @(dpt) [xrange(2) - (initial_extent(1) + initial_extent(3)) dpt(Y)];
            yminc = @(dpt) [dpt(X) yrange(1) - initial_extent(2)];
            ymaxc = @(dpt) [dpt(X) yrange(2) - (initial_extent(2) + initial_extent(4))];
            
            % We build a list of corrections to apply
            corrections = {};
            if initial_inrange(1) && ~new_inrange(1)
                % was within, now out of xmin range -- add xminc
                corrections = [corrections {xminc}];
            end
            if initial_inrange(2) && ~new_inrange(2)
                % was within, now out of xmax range -- add xmaxc
                corrections = [corrections {xmaxc}];
            end
            if initial_inrange(3) && ~new_inrange(3)
                % was within, now out of ymin range -- add yminc
                corrections = [corrections {yminc}];
            end
            if initial_inrange(4) && ~new_inrange(4)
                % was within, now out of ymax range -- add ymaxc
                corrections = [corrections {ymaxc}];
            end
            
            % Applying all corrections, except for objects following a diagonal
            % constraint, which must stop at the first one
            if ~isempty(corrections)
                if obj.constraint == obj.DIAGONAL_CONSTRAINT
                    c = corrections{1};
                    delta_point = c(delta_point);
                    % Forcing the object to remain on the diagonal constraint
                    if isequal(c, xminc) || isequal(c, xmaxc) % horizontal
                        delta_point(Y) = m_slope * delta_point(X);
                    elseif isequal(c, yminc) || isequal(c, ymaxc) % vertical
                        delta_point(X) = delta_point(Y) / m_slope;
                    end
                else
                    for c = corrections
                        delta_point = c{1}(delta_point);
                    end
                end
            end
            
            new_position = obj.compute_position(obj.start_position, delta_point);
            if isvalid(obj.g)
                obj.set_position(new_position);
                if nargin(obj.on_move_callback) == 1
                    obj.on_move_callback(obj.g);
                else
                    obj.on_move_callback(obj.g, event);
                end
            end
            
            if obj.DEBUG
                if all(new_inrange)
                    status = 'OK';
                else
                    status = 'RANGE VIOLATION';
                end
                fprintf('          range: %0.3f %0.3f %0.3f %0.3f', range);
                fprintf(' initial extent: %0.3f %0.3f %0.3f %0.3f', initial_extent);
                fprintf('     new extent: %0.3f %0.3f %0.3f %0.3f', new_extent);
                fprintf('initial inrange: %d %d %d %d', initial_inrange);
                fprintf('    new inrange: %d %d %d %d [%s]', new_inrange, status);
                fprintf('    initial dpt: %0.3f %0.3f', initial_delta_point);
                fprintf('  corrected dpt: %0.3f %0.3f', delta_point);
            end
        end
        
        function on_button_up(obj, ~, event)
            if ~obj.is_dragging
                return;
            end
            
            obj.figh.WindowButtonDownFcn = obj.wbd_fn;
            obj.figh.WindowButtonUpFcn = obj.wbu_fn;
            obj.figh.WindowButtonMotionFcn = obj.wbm_fn;
            
            if isvalid(obj.g)
                if nargin(obj.on_release_callback) == 1
                    obj.on_release_callback(obj.g);
                else
                    obj.on_release_callback(obj.g, event);
                end
            end
            
            obj.is_dragging = false;
        end
        
        function point = get_point(obj)
            point = obj.axh.CurrentPoint(1, 1:2);
        end
        
        function extent = get_extent(obj)
            if isprop(obj.g, 'Extent')
                extent = obj.g.Extent;
            elseif isprop(obj.g, 'Position')
                extent = obj.g.Position;
            elseif isprop(obj.g, 'XData')
                minx = min(obj.g.XData);
                miny = min(obj.g.YData);
                w = max(obj.g.XData) - minx;
                h = max(obj.g.YData) - miny;
                extent = [minx miny w h];
            else
                error('Unable to compute extent');
            end
        end
        
        function position = get_position(obj)
            if isprop(obj.g, 'Position')
                position = obj.g.Position(1:2).';
            elseif isprop(obj.g, 'XData')
                position = [obj.g.XData(:).'; obj.g.YData(:).'];
            else
                error('Unable to find position');
            end
        end
        
        function set_position(obj, position)
            if isprop(obj.g, 'Position')
                obj.g.Position(1:2) = position.';
            elseif isprop(obj.g, 'XData')
                obj.g.XData = position(1, :);
                obj.g.YData = position(2, :);
            else
                error('Unable to find position');
            end
        end
    end
    
    methods (Access = private, Static)
        function new_position = compute_position(position, delta_point)
            new_position = position + delta_point(:);
            assert(all(size(new_position) == size(position)));
        end
        
        function inrange = is_inside_range(extent, range)
            % extent is [x y w h], range is [xmin xmax ymin ymax], inrange is a
            % 4x1 vector of boolean values corresponding to range limits
            inrange = [...
                extent(1) >= range(1) ...
                extent(1) + extent(3) <= range(2) ...
                extent(2) >= range(3) ...
                extent(2) + extent(4) <= range(4)...
                ];
        end
        
        function args = parse(g, varargin)
            constraint = draggable.NO_CONSTRAINT;
            p = [];
            on_move_callback = @(varargin)[];
            on_release_callback = @(varargin)[];
            end_of_input = false;
            
            figh = gcbf;
            if isempty(figh)
                current_h = g;
                while ~isprop(current_h, 'numbertitle')
                    current_h = current_h.Parent;
                end
                figh = current_h;
            end
            
            for k = 1:nargin - 1
                current_arg = varargin{k};
                if isa(current_arg, "function_handle") && end_of_input
                    on_release_callback = current_arg;
                    % movefcn can still be a later argument
                    end_of_input = false;
                elseif isa(current_arg, "function_handle")
                    on_move_callback = current_arg;
                end
                if ischar(current_arg) || isstring(current_arg) || iscellstr(current_arg)
                    current_arg = string(current_arg);
                    assert(isscalar(current_arg));
                    switch lower(current_arg)
                        case {"endfcn"} % added by SMB
                            end_of_input = true;
                        otherwise
                            constraint = current_arg;
                    end
                end
                if isnumeric(current_arg)
                    p = current_arg;
                    n = length(p);
                    assert(n == 1 || n == 2 || n == 4);
                end
            end
            
            % Assigning defaults for constraint parameter
            slope = 0;
            xlim = [];
            ylim = [];
            switch lower(constraint)
                case {"n", draggable.NO_CONSTRAINT}
                    constraint = draggable.NO_CONSTRAINT;
                    if isempty(p)
                        % ok
                    elseif length(p) == 4
                        xlim = p(1:2);
                        ylim = p(3:4);
                    else
                        assert(false);
                    end
                case {"h", draggable.HORIZONTAL_CONSTRAINT}
                    constraint = draggable.HORIZONTAL_CONSTRAINT;
                    if isempty(p)
                        % ok
                    elseif length(p) == 2 || length(p) == 4
                        xlim = p(1:2);
                    else
                        assert(false);
                    end
                case {"v", draggable.VERTICAL_CONSTRAINT}
                    constraint = draggable.VERTICAL_CONSTRAINT;
                    if isempty(p)
                        % ok
                    elseif length(p) == 2
                        ylim = p(1:2);
                    elseif length(p) == 4
                        ylim = p(3:4);
                    else
                        assert(false);
                    end
                case {"d", "l", "locked", draggable.DIAGONAL_CONSTRAINT}
                    constraint = draggable.DIAGONAL_CONSTRAINT;
                    if isempty(p)
                        slope = 1;
                    elseif length(p) == 1
                        slope = p;
                    else
                        assert(false);
                    end
                otherwise
                    error('Unknown constraint type');
            end
            
            args.figh = figh;
            args.constraint = constraint;
            args.slope = slope;
            args.xlim = xlim;
            args.ylim = ylim;
            args.on_move_callback = on_move_callback;
            args.on_release_callback = on_release_callback;
        end
    end
    
    properties (Hidden)
        DEBUG = false;
    end
end

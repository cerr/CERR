function C = calcConc(s,p,s0)
% This function converts a DCE signal intensity time course to the time course of
% tissue concentration of contrast agent
% 
% INPUTS
% s : Signal time course vector.
% p : Parameter array. 
%     p(1) = R1 (mmolXsec), p(2) = TR (s), p(3) = FA, p(4) = T10 (s)
% Optional -
% s0: Signal at time t=0. If not input, s(1) is used.
% 
% OUTPUT
% C : Time course of Gd concentration (mmoles/L) in blood.
% --------------------------------------------------------------------------------------
% Knowing the relaxivity of the contrast agent, the T1 of blood without contrast, and
% the blood signal value prior to contrast, the concentration of contrast
% agent in the blood is:
%                             1/T1  = 1/T10 + R1* C(t)
% Given S/S0, 1/T1 (for each time point) can be obtained by substituting in from the
% partial saturation equation:
%                        S/S0 = (1-exp(-TR/T1)sin(theta))/(1-exp(-TR/T1)cos(theta)
% Then you go back and solve for C(t).
%
% This function returns a vector (C) containing the blood or tissue Gd concentration time course
% units are mmoles/L 
% --------------------------------------------------------------------------------------
%
% Kristen Zakian

%Get inputs
R1 = p(1); TR = p(2); FA = p(3); T10 = p(4);
a = FA*pi/180;       % calculate flip angle in radians

if nargin == 2       % if no s0 specified, then use the first point
    s0 = s(1);       
end

if s0 ~= 0          
    v = s./s0;      
else
    s0 = 0.001;      % fudge
    v = s./s0;       % fudge
    errordlg('concformula: s0 = 0!','ERROR');  %Got this error on Acevedo RT-BL
end

if T10 ~= 0
    TT = TR/T10;
    E10 = exp(-TT);
else
    error('concformula: T10 = 0!')
end

u = 1 - E10;
w = 1 - E10*cos(a);

num = w - u.*v.*cos(a);
denom = w - u.*v;
if denom ~= 0
    L = log(num./denom);
    %y = 1/R1*1/TR*(L - TT)*1000; 
    C = 1/R1*1/TR*(L - TT);
else
    error('calcconc: denom = 0');
end

for i=1:size(L,1)
    if ~isreal(L(i,:))
        C(i,:) = double(0);
    end
end

C(C <=0) = 0;


end
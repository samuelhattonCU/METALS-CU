% rough calcs for pin bearing requirements
% Samuel Hatton
% 17 May 2024

P_max = [15e3,30e3,45e3]; % 45 kN maximum load

%% Clevis Pin Through MAPS-15-ct

t = 3e-3; % 3 mm, the sample thickness (bearing thickness)
D_p = convlength(7/16,'in','m'); % about 11 mm, pin diameter

A_br = D_p * t; % approximate bearing area

S_br_req = P_max / A_br; % Pa, required pin bearing strength

% assume bearing strength S_br = 1.5 x S_t, tensile strength:
S_t_required = (2/3) * S_br_req; % Pa, required tensile strength
S_t_required_psi = convpres(S_t_required,'Pa','psi'); % psi, require tensile strength

%% Lower Grip Pins Through MAPS-15 w/ 3 lower holes

% t = 13.38e-3; % 16 mm per pin
t = 5e-3;
D_p = 4e-3; % 4mm pins, assuming perfect fit (not good)

A_br = D_p * t * 3; % We have 3 pins

S_br_req = P_max / A_br; % Pa, required pin bearing strength

% assume bearing strength S_br = 1.5 x S_t, tensile strength:
S_t_required = (2/3) * S_br_req; % Pa, required tensile strength
S_t_required_psi = convpres(S_t_required,'Pa','psi'); % psi, require tensile strength

%% Custom Grips, clevis pin bearing area
d1 = convlength(1.25,'in','m');
d2 = convlength(0.5,'in','m');
A_rod = pi * (d1/2)^2 - d1*d2; % approximate area at thinnest point, an under estimate

S_rod_req = P_max/A_rod;
S_rod_req_psi = convpres(S_rod_req,"Pa","psi");

%% Custom Grips, upper flanges w/ 3 pin holes
t_flange = 13.38e-3; % each flange is 13.5 mm thick
L_flange = 63.5e-3; % the grip is 65 mm wide
d_pin = 4e-3; % the pins have a 4mm diameter

A_flange = 2 * t_flange * (L_flange-3*d_pin);

S_flange_req = P_max/A_flange;
S_flange_req_psi = convpres(S_flange_req,"Pa","psi");

%% Upper Grip Pin Through MAPS-15

% t = 13.38e-3; % 16 mm per pin
t = 4e-3;
D_p = 5e-3; % 4mm pin, assuming perfect fit (not good)
% D_p = convlength(.5,"in","m");
A_br_upper = D_p * t; % We have 1 pins

S_br_req_upper = P_max / A_br_upper; % Pa, required pin bearing strength

% assume bearing strength S_br = 1.5 x S_t, tensile strength:
S_t_required_upper = (2/3) * S_br_req_upper; % Pa, required tensile strength
S_t_required_psi_upper = convpres(S_t_required_upper,'Pa','psi'); % psi, require tensile strength





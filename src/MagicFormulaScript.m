% === FITTING PROCESS ===

% Data files
dataFile = 'B1965run16.mat';
tirFile = 'sample.tir';

% Load the tire data into a structure
% Tire model: Hoosier 43075 16x7.5-10 LCO
% Test type: Free-rolling (cornering)
RawTireData = load("data\B1965run16.mat");

% Extract the Magic Formula inputs
% Correct some units to conform to ISO-W convention
fx = data.FX; % N
fy = data.FY; % N
fz = -data.FZ; % N (pos axis upward)
mx = data.MX; % N-m
mz = data.MZ; % N-m
n = data.N .* 2 .* pi ./ 60; % rad/s
sa = deg2rad(data.SA); % rad
v = data.V ./ 3.6; % m/s

% Load a TIR file as a starting point for the fitting
InitialParameterSet = mfeval.readTIR(tirFile);

% Set nominal parameters of the model based on reference data
InitialParameterSet.UNLOADED_RADIUS = 0.206; % Unloaded tire radius
InitialParameterSet.FNOMIN = median(fz); % Nominal load
InitialParameterSet.LONGVL = median(v); % Nominal reference speed
InitialParameterSet.NOMPRES = 55000; % Nominal inflation pressure

% Create a vector of initial lateral parameters for fitting
% NOTE: May need to include additional parameters from TIR file
x0 = zeros(1, 27);
x0(1)  = InitialParameterSet.PCY1;   %Shape factor Cfy for lateral forces
x0(2)  = InitialParameterSet.PDY1;   %Lateral friction Muy
x0(3)  = InitialParameterSet.PDY2;   %Variation of friction Muy with load
x0(4)  = InitialParameterSet.PDY3;   %Variation of friction Muy with squared camber
x0(5)  = InitialParameterSet.PEY1;   %Lateral curvature Efy at Fznom
x0(6)  = InitialParameterSet.PEY2;   %Variation of curvature Efy with load
x0(7)  = InitialParameterSet.PEY3;   %Zero order camber dependency of curvature Efy
x0(8)  = InitialParameterSet.PEY4;   %Variation of curvature Efy with camber
x0(9)  = InitialParameterSet.PEY5;   %Variation of curvature Efy with camber squared
x0(10) = InitialParameterSet.PKY1;   %Maximum value of stiffness Kfy/Fznom
x0(11) = InitialParameterSet.PKY2;   %Load at which Kfy reaches maximum value
x0(12) = InitialParameterSet.PKY3;   %Variation of Kfy/Fznom with camber
x0(13) = InitialParameterSet.PKY4;   %Curvature of stiffness Kfy
x0(14) = InitialParameterSet.PKY5;   %Peak stiffness variation with camber squared
x0(15) = InitialParameterSet.PKY6;   %Fy camber stiffness factor
x0(16) = InitialParameterSet.PKY7;   %Vertical load dependency of camber stiffness
x0(17) = InitialParameterSet.PHY1;   %Horizontal shift Shy at Fznom
x0(18) = InitialParameterSet.PHY2;   %Variation of shift Shy with load
x0(19) = InitialParameterSet.PVY1;   %Vertical shift in Svy/Fz at Fznom
x0(20) = InitialParameterSet.PVY2;   %Variation of shift Svy/Fz with load
x0(21) = InitialParameterSet.PVY3;   %Variation of shift Svy/Fz with camber
x0(22) = InitialParameterSet.PVY4;   %Variation of shift Svy/Fz with camber and load
x0(23) = InitialParameterSet.PPY1;   %influence of inflation pressure on cornering stiffness
x0(24) = InitialParameterSet.PPY2;   %influence of inflation pressure on dependency of nominal tyre load on cornering stiffness
x0(25) = InitialParameterSet.PPY3;   %linear influence of inflation pressure on lateral peak friction
x0(26) = InitialParameterSet.PPY4;   %quadratic influence of inflation pressure on lateral peak friction
x0(27) = InitialParameterSet.PPY5;   %Influence of inflation pressure on camber stiffness

% Declare an anonymous cost function using lsqnonlin
fun = @(X) costPureFy(X, RawTireData, InitialParameterSet);

% Options for the fitting function (lsqnonlin)
% TODO: Research different options

% Non-linear least squares fitting formula
% lsqnonlin will try to minimize the output of the cost function
X_OPTIM = lsqnonlin(fun, x0, [], [], options);

% Create a copy of the initial parameters and replace the fitted parameters
OptimParameterSet = InitialParameterSet;
OptimParameterSet.PCY1 = X_OPTIM(1);
OptimParameterSet.PDY1 = X_OPTIM(2);
OptimParameterSet.PDY2 = X_OPTIM(3);
OptimParameterSet.PDY3 = X_OPTIM(4);
OptimParameterSet.PEY1 = X_OPTIM(5);
OptimParameterSet.PEY2 = X_OPTIM(6);
OptimParameterSet.PEY3 = X_OPTIM(7);
OptimParameterSet.PEY4 = X_OPTIM(8);
OptimParameterSet.PEY5 = X_OPTIM(9);
OptimParameterSet.PKY1 = X_OPTIM(10);
OptimParameterSet.PKY2 = X_OPTIM(11);
OptimParameterSet.PKY3 = X_OPTIM(12);
OptimParameterSet.PKY4 = X_OPTIM(13);
OptimParameterSet.PKY5 = X_OPTIM(14);
OptimParameterSet.PKY6 = X_OPTIM(15);
OptimParameterSet.PKY7 = X_OPTIM(16);
OptimParameterSet.PHY1 = X_OPTIM(17);
OptimParameterSet.PHY2 = X_OPTIM(18);
OptimParameterSet.PVY1 = X_OPTIM(19);
OptimParameterSet.PVY2 = X_OPTIM(20);
OptimParameterSet.PVY3 = X_OPTIM(21);
OptimParameterSet.PVY4 = X_OPTIM(22);
OptimParameterSet.PPY1 = X_OPTIM(23);
OptimParameterSet.PPY2 = X_OPTIM(24);
OptimParameterSet.PPY3 = X_OPTIM(25);
OptimParameterSet.PPY4 = X_OPTIM(26);
OptimParameterSet.PPY5 = X_OPTIM(27);

% === PLOT RESULTS ===

% === COST FUNCTION ===
function [error] = costPureFy(X, Data, ParameterSet)
    % COSTPUREFY Call MFeval and calculate the error between the model and the input data.
    % Inputs:
    %   X - Structure that contains the parameters that are being fitted
    %   Data - Structure that contains the data used to measure the error of the model
    %   ParameterSet - Structure of MF6.1 parameters (used to call MFeval w/o errors)
    % Outputs:
    %   error - The overall inaccuracy of the guesses of the model compared to the actual data
end
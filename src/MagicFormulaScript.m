% === FITTING PROCESS ===

% Data files
dataFile = 'data/B1965run16.mat';
tirFile = 'data/sample.tir'; % TODO: Replace with TIR file from current tire model

% Load the tire data into a structure
% Tire model: Hoosier 43075 16x7.5-10 LCO
% Test type: Free-rolling (cornering)
RawTireData = load(dataFile);

% Load a TIR file as a starting point for the fitting
InitialParameterSet = mfeval.readTIR(tirFile);

% Set nominal parameters of the model based on reference data
InitialParameterSet.UNLOADED_RADIUS = 0.206; % Unloaded tire radius
InitialParameterSet.FNOMIN = 650; % Nominal load
InitialParameterSet.LONGVL = median(RawTireData.V); % Nominal reference speed
InitialParameterSet.NOMPRES = 70000; % Nominal inflation pressure

% Create a vector of initial lateral parameters for fitting
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
options.TolFun = 1e-08; % Function tolerance
options.MaxFunEvals = 9999; % Maximum number of function calls
options.Display = 'iter'; % Updates progress on command window

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

% Create data inputs to check the fitting quality
evalFz = ones(100, 1) * 650;
evalNull = zeros(100, 1);
evalSa = linspace(-0.22, 0.22);
evalV = ones(100, 1) * 40;
evalP = ones(100, 1) * 70000;

USE_MODE = 211;

INPUT = [evalFz evalNull evalSa evalNull evalNull evalV evalP evalNull];

% Call MFeval with optimized parameters
OUTPUT = mfeval(OptimParameterSet, INPUT, USE_MODE);

% Plot raw data vs. fitted model
sa = deg2rad(RawTireData.SA); % rad
fy = RawTireData.FY; % N

figure;
hold on;
plot(sa, fy, 'o');
plot(OUTPUT(:, 8), OUTPUT(:, 2), '-', 'linewidth', 2);
grid on;
xlabel('Slip Angle (rad)');
ylabel('Lateral Force (N)');
title('Pure Lateral Slip Fitting');
legend('Data', 'Model');

% === COST FUNCTION ===

% TODO: Fix so that lsqnonlin converges (likely due to bad TIR file)
function [error] = costPureFy(X, Data, ParameterSet)
    % COSTPUREFY Call MFeval and calculate the error between the model and the input data.
    % Inputs:
    %   X - Structure that contains the parameters that are being fitted
    %   Data - Structure that contains the data used to measure the error of the model
    %   ParameterSet - Structure of MF6.1 parameters (used to call MFeval w/o errors)
    % Outputs:
    %   error - The overall inaccuracy of the guesses of the model compared to the actual data

    % Extract the Magic Formula inputs
    % Correct some units to conform to ISO-W convention
    fy = Data.FY; % N
    fz = -Data.FZ; % N (pos axis upward)
    sl = Data.SL; % unitless
    sa = deg2rad(Data.SA); % rad
    ia = deg2rad(Data.IA); % rad
    phit = zeros(size(sa)); % 1/m
    v = Data.V ./ 3.6; % m/s
    p = Data.P .* 1000; % Pa
    n = Data.N .* 2 .* pi ./ 60; % rad/s

    % Create the inputs for MFeval
    % NOTE: Turn slip is neglected
    INPUTS = [fz sl sa ia phit v p n];

    % Select a use mode for MFeval
    % +1 -> Combined force/moment calculation
    % +10 -> Revoke alpha-star definition
    % +200 -> Ignore limit checks
    USE_MODE = 211;

    % Unpack the parameters that are being fitted
    % Replace them into the ParameterSet
    ParameterSet.PCY1	=  X(1)     ;%Shape factor Cfy for lateral forces
    ParameterSet.PDY1	=  X(2)     ;%Lateral friction Muy
    ParameterSet.PDY2	=  X(3)     ;%Variation of friction Muy with load
    ParameterSet.PDY3	=  X(4)  	;%Variation of friction Muy with squared camber
    ParameterSet.PEY1	=  X(5)  	;%Lateral curvature Efy at Fznom
    ParameterSet.PEY2	=  X(6)   	;%Variation of curvature Efy with load
    ParameterSet.PEY3	=  X(7)   	;%Zero order camber dependency of curvature Efy
    ParameterSet.PEY4	=  X(8)  	;%Variation of curvature Efy with camber
    ParameterSet.PEY5	=  X(9)   	;%Variation of curvature Efy with camber squared
    ParameterSet.PKY1	=  X(10)	;%Maximum value of stiffness Kfy/Fznom
    ParameterSet.PKY2	=  X(11) 	;%Load at which Kfy reaches maximum value
    ParameterSet.PKY3	=  X(12)   	;%Variation of Kfy/Fznom with camber
    ParameterSet.PKY4	=  X(13)   	;%Curvature of stiffness Kfy
    ParameterSet.PKY5	=  X(14)   	;%Peak stiffness variation with camber squared
    ParameterSet.PKY6	=  X(15)   	;%Fy camber stiffness factor
    ParameterSet.PKY7	=  X(16)   	;%Vertical load dependency of camber stiffness
    ParameterSet.PHY1	=  X(17)  	;%Horizontal shift Shy at Fznom
    ParameterSet.PHY2	=  X(18)   	;%Variation of shift Shy with load
    ParameterSet.PVY1	=  X(19)  	;%Vertical shift in Svy/Fz at Fznom
    ParameterSet.PVY2	=  X(20)   	;%Variation of shift Svy/Fz with load
    ParameterSet.PVY3	=  X(21)   	;%Variation of shift Svy/Fz with camber
    ParameterSet.PVY4	=  X(22)  	;%Variation of shift Svy/Fz with camber and load
    ParameterSet.PPY1	=  X(23)   	;%influence of inflation pressure on cornering stiffness
    ParameterSet.PPY2	=  X(24)  	;%influence of inflation pressure on dependency of nominal tyre load on cornering stiffness
    ParameterSet.PPY3	=  X(25)   	;%linear influence of inflation pressure on lateral peak friction
    ParameterSet.PPY4	=  X(26)   	;%quadratic influence of inflation pressure on lateral peak friction
    ParameterSet.PPY5	=  X(27)   	;%Influence of inflation pressure on camber stiffness

    % Call MFeval
    OUTPUT = mfeval(ParameterSet, INPUTS, USE_MODE);

    % Extract Fy from the MFeval output
    fy_pred = OUTPUT(:, 2);

    % Calculate prediction error against the data
    error = fy - fy_pred;
end
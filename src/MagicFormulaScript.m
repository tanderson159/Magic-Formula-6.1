% === DATA LOADING ===

% Data files
dataFile = 'data/B1965run16.mat';
tirFile = 'data/HyTech_Hoosier_8in_LC0.tir'; % TODO: Modify parameter list so file fits MF6.1

% Load the tire data into a structure
% Tire model: Hoosier 43075 16x7.5-10 LCO
% Test type: Free-rolling (cornering)
RawTireData = load(dataFile);

% Load a TIR file as a starting point for the fitting
InitialParameterSet = mfeval.readTIR(tirFile);

% Set nominal parameters of the model based on reference data
InitialParameterSet.UNLOADED_RADIUS = 0.2062; % Unloaded tire radius
InitialParameterSet.FNOMIN = 650; % Nominal load
InitialParameterSet.LONGVL = median(RawTireData.V ./ 3.6); % Nominal reference speed
InitialParameterSet.NOMPRES = 70000; % Nominal inflation pressure

% === FITTING PURE LATERAL SLIP ===

% Create a vector of initial lateral parameters for fitting
y0 = zeros(1, 27);

y0(1)  = InitialParameterSet.PCY1;   % Shape factor Cfy for lateral forces

y0(2)  = InitialParameterSet.PDY1;   % Lateral friction Muy
y0(3)  = InitialParameterSet.PDY2;   % Variation of friction Muy with load
y0(4)  = InitialParameterSet.PDY3;   % Variation of friction Muy with squared camber

y0(5)  = InitialParameterSet.PEY1;   % Lateral curvature Efy at Fznom
y0(6)  = InitialParameterSet.PEY2;   % Variation of curvature Efy with load
y0(7)  = InitialParameterSet.PEY3;   % Zero order camber dependency of curvature Efy
y0(8)  = InitialParameterSet.PEY4;   % Variation of curvature Efy with camber
y0(9)  = InitialParameterSet.PEY5;   % Variation of curvature Efy with camber squared

y0(10) = InitialParameterSet.PKY1;   % Mayimum value of stiffness Kfy/Fznom
y0(11) = InitialParameterSet.PKY2;   % Load at which Kfy reaches mayimum value
y0(12) = InitialParameterSet.PKY3;   % Variation of Kfy/Fznom with camber
y0(13) = InitialParameterSet.PKY4;   % Curvature of stiffness Kfy
y0(14) = InitialParameterSet.PKY5;   % Peak stiffness variation with camber squared
y0(15) = InitialParameterSet.PKY6;   % Fy camber stiffness factor
y0(16) = InitialParameterSet.PKY7;   % Vertical load dependency of camber stiffness

y0(17) = InitialParameterSet.PHY1;   % Horizontal shift Shy at Fznom
y0(18) = InitialParameterSet.PHY2;   % Variation of shift Shy with load

y0(19) = InitialParameterSet.PVY1;   % Vertical shift in Svy/Fz at Fznom
y0(20) = InitialParameterSet.PVY2;   % Variation of shift Svy/Fz with load
y0(21) = InitialParameterSet.PVY3;   % Variation of shift Svy/Fz with camber
y0(22) = InitialParameterSet.PVY4;   % Variation of shift Svy/Fz with camber and load

y0(23) = InitialParameterSet.PPY1;   % Influence of inflation pressure on cornering stiffness
y0(24) = InitialParameterSet.PPY2;   % Influence of inflation pressure on dependency of nominal tyre load on cornering stiffness
y0(25) = InitialParameterSet.PPY3;   % Linear influence of inflation pressure on lateral peak friction
y0(26) = InitialParameterSet.PPY4;   % Quadratic influence of inflation pressure on lateral peak friction
y0(27) = InitialParameterSet.PPY5;   % Influence of inflation pressure on camber stiffness

% Declare an anonymous cost function using lsqnonlin
fun = @(Y) costPureFy(Y, RawTireData, InitialParameterSet);

% Options for the fitting function (lsqnonlin)
options.TolFun = 1e-08; % Function tolerance
options.MaxFunEvals = 9999; % Maximum number of function calls
options.Display = 'iter'; % Updates progress on command window

% Non-linear least squares fitting formula
% lsqnonlin will try to minimize the output of the cost function
Y_OPTIM = lsqnonlin(fun, y0, [], [], options);

% Create a copy of the initial parameters and replace the fitted parameters
OptimParameterSet = InitialParameterSet;
OptimParameterSet.PCY1 = Y_OPTIM(1);
OptimParameterSet.PDY1 = Y_OPTIM(2);
OptimParameterSet.PDY2 = Y_OPTIM(3);
OptimParameterSet.PDY3 = Y_OPTIM(4);
OptimParameterSet.PEY1 = Y_OPTIM(5);
OptimParameterSet.PEY2 = Y_OPTIM(6);
OptimParameterSet.PEY3 = Y_OPTIM(7);
OptimParameterSet.PEY4 = Y_OPTIM(8);
OptimParameterSet.PEY5 = Y_OPTIM(9);
OptimParameterSet.PKY1 = Y_OPTIM(10);
OptimParameterSet.PKY2 = Y_OPTIM(11);
OptimParameterSet.PKY3 = Y_OPTIM(12);
OptimParameterSet.PKY4 = Y_OPTIM(13);
OptimParameterSet.PKY5 = Y_OPTIM(14);
OptimParameterSet.PKY6 = Y_OPTIM(15);
OptimParameterSet.PKY7 = Y_OPTIM(16);
OptimParameterSet.PHY1 = Y_OPTIM(17);
OptimParameterSet.PHY2 = Y_OPTIM(18);
OptimParameterSet.PVY1 = Y_OPTIM(19);
OptimParameterSet.PVY2 = Y_OPTIM(20);
OptimParameterSet.PVY3 = Y_OPTIM(21);
OptimParameterSet.PVY4 = Y_OPTIM(22);
OptimParameterSet.PPY1 = Y_OPTIM(23);
OptimParameterSet.PPY2 = Y_OPTIM(24);
OptimParameterSet.PPY3 = Y_OPTIM(25);
OptimParameterSet.PPY4 = Y_OPTIM(26);
OptimParameterSet.PPY5 = Y_OPTIM(27);

% === PLOT RESULTS ===
% TODO: Tune plotting output to testing data

% Extract parameters from raw tire data
fy = RawTireData.FY; % N
fz = -RawTireData.FZ; % N (pos axis upward)
sa = deg2rad(RawTireData.SA); % rad
ia = deg2rad(RawTireData.IA); % rad
p = RawTireData.P .* 1000; % Pa

% Filter data to splot specific conditions
indFz1 = fz > 1000 & fz < 1400;   % 1200 N
indFz2 = fz > 1500 & fz < 1800;   % 1650 N
indFz3 = fz > 650 & fz < 1000;    % 760 N
indIA = ia > -0.01 & ia < 0.01;   % 0 rad
indP = p > 8e4 & p < 9e4;         % 83160 Pa
indFz = indFz1 | indFz2 | indFz3;
filt = indFz & indIA & indP;

% Create data inputs to check the fitting quality
evalFz1 = ones(100,1) * 1200;
evalFz2 = ones(100,1) * 1650;
evalFz3 = ones(100,1) * 760;
evalNull = zeros(100, 1);
evalSA = linspace(-0.23, 0.23)';
evalVx = ones(100, 1) * 16;
evalP = ones(100, 1) * 83160;

MFinput1 = [evalFz1 evalNull evalSA evalNull evalNull evalVx evalP];
MFinput2 = [evalFz2 evalNull evalSA evalNull evalNull evalVx evalP];
MFinput3 = [evalFz3 evalNull evalSA evalNull evalNull evalVx evalP];

% Call MFeval with optimized parameters
MFout1 = mfeval(OptimParameterSet, MFinput1, 211);
MFout2 = mfeval(OptimParameterSet, MFinput2, 211);
MFout3 = mfeval(OptimParameterSet, MFinput3, 211);

% Plot raw data vs. fitted model
figure;
hold on;
plot(sa(filt), fy(filt),'o')
plot(MFout1(:,8), MFout1(:,2),'-', 'linewidth', 2)
plot(MFout2(:,8), MFout2(:,2),'-', 'linewidth', 2)
plot(MFout3(:,8), MFout3(:,2),'-', 'linewidth', 2)
grid on;
xlabel('Slip Angle (rad)');
ylabel('Lateral Force (N)');
title('Pure Lateral Slip Fitting');
legend('Data', 'Model: Fz = 1200N', 'Model: Fz = 1650N', 'Model: Fz = 760N');

% === FITTING PURE LONGITUDINAL SLIP ===

% Create a vector of initial longitudinal parameters for fitting
x0 = zeros(1, 19);

x0(1)  = InitialParameterSet.PCX1;  % Shape factor Cfx for longitudinal force

x0(2)  = InitialParameterSet.PDX1;  % Longitudinal friction coefficient at nominal load
x0(3)  = InitialParameterSet.PDX2;  % Variation of longitudinal friction with load
x0(4)  = InitialParameterSet.PDX3;  % Variation of longitudinal friction with squared camber

x0(5)  = InitialParameterSet.PEX1;  % Longitudinal curvature Efx at nominal load
x0(6)  = InitialParameterSet.PEX2;  % Variation of curvature with load
x0(7)  = InitialParameterSet.PEX3;  % Variation of curvature with load squared
x0(8)  = InitialParameterSet.PEX4;  % Slip-sign dependence of curvature (drive/brake asymmetry)

x0(9)  = InitialParameterSet.PKX1;  % Longitudinal slip stiffness Kfx/Fz at nominal load
x0(10) = InitialParameterSet.PKX2;  % Load dependence of the slip-stiffness prefactor
x0(11) = InitialParameterSet.PKX3;  % Exponential load dependence of slip stiffness

x0(12) = InitialParameterSet.PHX1;  % Horizontal shift Shx at nominal load
x0(13) = InitialParameterSet.PHX2;  % Variation of horizontal shift with load

x0(14) = InitialParameterSet.PVX1;  % Vertical shift Svx/Fz at nominal load
x0(15) = InitialParameterSet.PVX2;  % Variation of normalized vertical shift with load

x0(16) = InitialParameterSet.PPX1;  % Linear pressure effect on longitudinal slip stiffness
x0(17) = InitialParameterSet.PPX2;  % Quadratic pressure effect on longitudinal slip stiffness
x0(18) = InitialParameterSet.PPX3;  % Linear pressure effect on longitudinal friction
x0(19) = InitialParameterSet.PPX4;  % Quadratic pressure effect on longitudinal friction

% Declare an anonymous cost function using lsqnonlin
fun = @(X) costPureFx(X, RawTireData, InitialParameterSet);

% Non-linear least squares fitting formula
% lsqnonlin will try to minimize the output of the cost function
X_OPTIM = lsqnonlin(fun, x0, [], [], options);

% Replace the fitted parameters in the new parameter set
OptimParameterSet.PCX1 = X_OPTIM(1);
OptimParameterSet.PDX1 = X_OPTIM(2);
OptimParameterSet.PDX2 = X_OPTIM(3);
OptimParameterSet.PDX3 = X_OPTIM(4);
OptimParameterSet.PEX1 = X_OPTIM(5);
OptimParameterSet.PEX2 = X_OPTIM(6);
OptimParameterSet.PEX3 = X_OPTIM(7);
OptimParameterSet.PEX4 = X_OPTIM(8);
OptimParameterSet.PKX1 = X_OPTIM(9);
OptimParameterSet.PKX2 = X_OPTIM(10);
OptimParameterSet.PKX3 = X_OPTIM(11);
OptimParameterSet.PHX1 = X_OPTIM(12);
OptimParameterSet.PHX2 = X_OPTIM(13);
OptimParameterSet.PVX1 = X_OPTIM(14);
OptimParameterSet.PVX2 = X_OPTIM(15);
OptimParameterSet.PPX1 = X_OPTIM(16);
OptimParameterSet.PPX2 = X_OPTIM(17);
OptimParameterSet.PPX3 = X_OPTIM(18);
OptimParameterSet.PPX4 = X_OPTIM(19);

% === COST FUNCTIONS ===

function [error] = costPureFy(Y, Data, ParameterSet)
    % COSTPUREFY Call MFeval and calculate the error between the model and the input data for pure lateral slip.
    % Inputs:
    %   Y - Structure that contains the parameters that are being fitted
    %   Data - Structure that contains the data used to measure the error of the model
    %   ParameterSet - Structure of MF6.1 parameters (used to call MFeval w/o errors)
    % Outputs:
    %   error - The inaccuracy of the guesses of the model compared to the actual data

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
    ParameterSet.PCY1	=  Y(1);    %Shape factor Cfy for lateral forces
    ParameterSet.PDY1	=  Y(2);    %Lateral friction Muy
    ParameterSet.PDY2	=  Y(3);    %Variation of friction Muy with load
    ParameterSet.PDY3	=  Y(4);    %Variation of friction Muy with squared camber
    ParameterSet.PEY1	=  Y(5);    %Lateral curvature Efy at Fznom
    ParameterSet.PEY2	=  Y(6);    %Variation of curvature Efy with load
    ParameterSet.PEY3	=  Y(7);    %Zero order camber dependency of curvature Efy
    ParameterSet.PEY4	=  Y(8);    %Variation of curvature Efy with camber
    ParameterSet.PEY5	=  Y(9);    %Variation of curvature Efy with camber squared
    ParameterSet.PKY1	=  Y(10);   %Maximum value of stiffness Kfy/Fznom
    ParameterSet.PKY2	=  Y(11);   %Load at which Kfy reaches maximum value
    ParameterSet.PKY3	=  Y(12);   %Variation of Kfy/Fznom with camber
    ParameterSet.PKY4	=  Y(13);   %Curvature of stiffness Kfy
    ParameterSet.PKY5	=  Y(14);   %Peak stiffness variation with camber squared
    ParameterSet.PKY6	=  Y(15);   %Fy camber stiffness factor
    ParameterSet.PKY7	=  Y(16);   %Vertical load dependency of camber stiffness
    ParameterSet.PHY1	=  Y(17);   %Horizontal shift Shy at Fznom
    ParameterSet.PHY2	=  Y(18);   %Variation of shift Shy with load
    ParameterSet.PVY1	=  Y(19);   %Vertical shift in Svy/Fz at Fznom
    ParameterSet.PVY2	=  Y(20);   %Variation of shift Svy/Fz with load
    ParameterSet.PVY3	=  Y(21);   %Variation of shift Svy/Fz with camber
    ParameterSet.PVY4	=  Y(22);   %Variation of shift Svy/Fz with camber and load
    ParameterSet.PPY1	=  Y(23);   %influence of inflation pressure on cornering stiffness
    ParameterSet.PPY2	=  Y(24);   %influence of inflation pressure on dependency of nominal tyre load on cornering stiffness
    ParameterSet.PPY3	=  Y(25);   %linear influence of inflation pressure on lateral peak friction
    ParameterSet.PPY4	=  Y(26);   %quadratic influence of inflation pressure on lateral peak friction
    ParameterSet.PPY5	=  Y(27);   %Influence of inflation pressure on camber stiffness

    % Call MFeval
    OUTPUT = mfeval(ParameterSet, INPUTS, USE_MODE);

    % Extract Fy from the MFeval output
    fy_pred = OUTPUT(:, 2);

    % Calculate prediction error against the data
    error = fy - fy_pred;
end

function [error] = costPureFx(X, Data, ParameterSet)
    % COSTPUREFX Call MFeval and calculate the error between the model and the input data for pure longitudinal slip.
    % Inputs:
    %   X - Structure that contains the parameters that are being fitted
    %   Data - Structure that contains the data used to measure the error of the model
    %   ParameterSet - Structure of MF6.1 parameters (used to call MFeval w/o errors)
    % Outputs:
    %   error - The inaccuracy of the guesses of the model compared to the actual data
end
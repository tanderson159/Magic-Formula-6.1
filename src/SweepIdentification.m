% === TTC DATA ANALYSIS ===

% Load the data into a structure
% Tire model: Hoosier 43075 16x7.5-10 LCO
% Test type: Free-rolling (cornering)
data = load("data/B1965run16.mat");

% Available parameters (and their units):
% AMBTMP: Ambient room temperature (°C)
% ET: Elapsed time (sec)
% FX: Longitudinal force (N)
% FY: Lateral force (N)
% FZ: Normal load (N)
% IA: Inclination angle (deg)
% MX: Overturning moment (N-m)
% MZ: Aligning torque (N-m)
% N: Wheel rotational speed (rpm)
% NFX: Normalized longitudinal force (unitless)
% NFY: Normalized lateral force (unitless)
% P: Tire pressure (kPa)
% RE: Effective radius (cm)
% RL: Loaded radius (cm)
% RST: Road surface temperature (°C)
% SA: Slip angle (deg)
% SL: Slip ratio based on RE (unitless)
% SR: Slip ratio based on RL (unitless)
% TSTC: Tire surface temperature @ center (°C)
% TSTI: Tire surface temperature @ inboard (°C)
% TSTO: Tire surface temperature @ outboard (°C)
% V: Road speed (kph)

% === NOTES FROM RUN GUIDE ===
% 1) Cornering tests are broken into 2 runs
% 2) Test begins w/ 12 "cold-to-hot" SA sweeps @ one load
% 3) Break-in block occurs before main sweeps start
% 3) Main sweeps involve sweeping SA through +/- 12 deg at each op condition
% 4) Test ends w/ a block of IA sweeps @ 0 SA

% Extract the relevant parameters for graphing
% Correct some units to conform to ISO-W convention
t = data.ET; % sec
fx = data.FX; % N
fy = data.FY; % N
fz = -data.FZ; % N (pos axis upward)
ia = deg2rad(data.IA); % rad
mx = data.MX; % N-m
mz = data.MZ; % N-m
n = data.N .* 2 .* pi ./ 60; % rad/s
p = data.P .* 1000; % Pa
sa = deg2rad(data.SA); % rad
sl = data.SL; % unitless
v = data.V ./ 3.6; % m/s

% Plot some parameters vs. time to help isolate each sweep
figure
tiledlayout(4,1)

ax(1) = nexttile;
plot(t, sa);
ylabel('Slip Angle (rad)');
grid on

ax(2) = nexttile;
plot(t, fz);
ylabel('Normal Load (N)');
grid on

ax(3) = nexttile;
plot(t, p);
ylabel('Pressure (Pa)');
grid on

ax(4) = nexttile;
plot(t, ia);
ylabel('Inclination Angle (rad)');
grid on

linkaxes(ax, 'x')

% === INITIAL OBSERVATIONS ===
% 1) Pressure varies between 8 psi and 12 psi
% 2) Camber varies between 0 deg, 2 deg, and 4 deg

% Compute the differences in time between each sweep
timeDiffs = diff(t(:));

% Define a threshold for the time in between each sweep
timeThreshold = 20;

% Determine the start and end indexes
gapIdx = find(timeDiffs > timeThreshold);
startIdx = [1; gapIdx + 1];
endIdx = [gapIdx; height(data)];

% Use start and end indexes to separate each sweep
sweeps = cell(numel(startIdx), 1);
for k = 1:numel(startIdx)
    sweeps{k} = t(startIdx(k):endIdx(k), :);
end

% === SWEEP BOUNDARIES ===
% --- Camber Boundaries ---
% 1-6 -> 0 deg
% 7-11 -> 2 deg
% 12-16 -> 4 deg
% 17-22 -> 0 deg
% 23-27 -> 2 deg
% 28-32 -> 4 deg
% 33-42 -> 0 deg
% --- Pressure Boundaries ---
% 1-16 -> 8 psi
% 16-42 -> 12 psi
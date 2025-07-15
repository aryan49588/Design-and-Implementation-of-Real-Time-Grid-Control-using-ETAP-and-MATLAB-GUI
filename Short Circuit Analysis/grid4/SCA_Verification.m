clc; clear; close all;

%% System Base
Sbase = 100;  % MVA
Vbase = 230;  % kV base at Bus 4 for fault

%% Example: Sequence Impedances (approx, based on ETAP)
% Z1, Z2, Z0 per bus (in pu on 100 MVA)
Z1 = 1.81 + 1j*4.29;     % Positive seq. impedance (from ETAP, page 9)
Z2 = Z1;                 % Assuming same as Z1
Z0 = 3.48 + 1j*5.33;     % Zero seq. impedance

% Prefault Voltage
V_prefault = Vbase;   % in kV
V1 = V_prefault / sqrt(3);  % Line-neutral prefault voltage

%% 1. 3-Phase Fault at Bus 4
If_3ph = V1 / Z1;  % Fault current (A in kV base, pu)
I_3ph_rms_kA = abs(If_3ph); % in kA
fprintf('3-Phase Fault at Bus 4: %.3f kA\n', I_3ph_rms_kA);

%% 2. Line-to-Ground (LG) Fault at Bus 4
If_lg = 3 * V1 / (Z1 + Z2 + Z0);
I_lg_kA = abs(If_lg);
fprintf('Line-to-Ground Fault at Bus 4: %.3f kA\n', I_lg_kA);

%% 3. Line-to-Line (LL) Fault at Bus 4
If_ll = sqrt(3) * V1 / (Z1 + Z2);
I_ll_kA = abs(If_ll);
fprintf('Line-to-Line Fault at Bus 4: %.3f kA\n', I_ll_kA);

%% 4. Double Line-to-Ground (LLG) Fault at Bus 4
Z_eq = (Z1 * Z2 + Z2 * Z0 + Z0 * Z1) / (Z1 + Z2 + Z0);
If_llg = V1 / Z_eq;
I_llg_kA = abs(If_llg);
fprintf('Double Line-to-Ground Fault at Bus 4: %.3f kA\n', I_llg_kA);

%% Display All Fault Currents
fprintf('\n--- Short-Circuit Fault Summary at Bus 4 ---\n');
fprintf('3-Phase Fault (kA):            %.3f\n', I_3ph_rms_kA);
fprintf('Line-to-Ground Fault (kA):     %.3f\n', I_lg_kA);
fprintf('Line-to-Line Fault (kA):       %.3f\n', I_ll_kA);
fprintf('Double Line-to-Ground Fault:   %.3f\n', I_llg_kA);

%% System Base
Sbase = 100;  % MVA base
Vbase_all = [11 11 230 230 230 230 230 230 9.5];  % From ETAP, kV per bus

nbus = 9;
Z1_default = 1.81 + 1j*4.29;   % Ohms, from ETAP Bus_4
Z2_default = Z1_default;       % Assume same as Z1
Z0_default = 3.48 + 1j*5.33;   % Ohms, from ETAP Bus_4

% Preallocate matrices
I_3ph_kA = zeros(nbus, 1);
I_lg_kA = zeros(nbus, 1);
I_ll_kA = zeros(nbus, 1);
I_llg_kA = zeros(nbus, 1);

for bus = 1:nbus
    V_base_kV = Vbase_all(bus);
    V1 = V_base_kV / sqrt(3);  % Prefault line-to-neutral voltage in kV

    Z1 = Z1_default;
    Z2 = Z2_default;
    Z0 = Z0_default;

    % 1. 3-Phase Fault
    If_3ph = V1 / Z1;
    I_3ph_kA(bus) = abs(If_3ph);

    % 2. LG Fault
    If_lg = 3 * V1 / (Z1 + Z2 + Z0);
    I_lg_kA(bus) = abs(If_lg);

    % 3. LL Fault
    If_ll = sqrt(3) * V1 / (Z1 + Z2);
    I_ll_kA(bus) = abs(If_ll);

    % 4. LLG Fault
    Z_eq = (Z1 * Z2 + Z2 * Z0 + Z0 * Z1) / (Z1 + Z2 + Z0);
    If_llg = V1 / Z_eq;
    I_llg_kA(bus) = abs(If_llg);
end

%% === Grouped Bar Plot for All Faults ===
fault_matrix = [I_3ph_kA, I_lg_kA, I_ll_kA, I_llg_kA];  % size 9x4

% Labels
bus_labels = arrayfun(@(x) sprintf('Bus %d', x), 1:nbus, 'UniformOutput', false);
fault_labels = {'3-Phase', 'Line-to-Ground', 'Line-to-Line', 'Double Line-to-Ground'};

% Plot
figure('Name','Fault Current Comparison Across Buses','NumberTitle','off',...
       'Units','normalized','Position',[0.1 0.1 0.8 0.7]);
bar(fault_matrix, 'grouped');
title('Short-Circuit Fault Currents at Each Bus');
xlabel('Bus Number'); ylabel('Fault Current (kA)');
set(gca, 'XTickLabel', bus_labels, 'FontSize', 12);
legend(fault_labels, 'Location', 'northeastoutside');
grid on;


%% === Create Fault Summary Table ===
FaultTable = table((1:nbus)', Vbase_all(:), I_3ph_kA, I_lg_kA, I_ll_kA, I_llg_kA, ...
    'VariableNames', {'Bus', 'Voltage_kV', ...
    'ThreePhase_kA', 'LineToGround_kA', 'LineToLine_kA', 'DoubleLineToGround_kA'});

% Display in command window
disp('=== Short-Circuit Fault Summary Table (All Buses) ===');
disp(FaultTable);

% Optional: Display in GUI table (optional if you're not using GUI)
f_table = figure('Name','Short-Circuit Fault Summary Table','NumberTitle','off',...
    'Units','normalized','Position',[0.2 0.2 0.6 0.6]);
uitable('Data', table2cell(FaultTable), ...
        'ColumnName', FaultTable.Properties.VariableNames, ...
        'Units','normalized', 'Position',[0 0 1 1], ...
        'FontSize', 12);
%% === Relay Coordination Plot for 3-Phase Fault at Bus 4 ===

% Simulate a 3-phase fault current waveform at Bus 4
fs = 1000;              % Sampling frequency (1000 samples per second)
t = 0:1:100;            % Time vector in ms (0–100 ms)
f = 60;                 % Fault frequency in Hz
I_peak = 9.5;           % Peak fault current in kA (example from ETAP/your plot)

i_fault = I_peak * sin(2 * pi * f * t / 1000);  % Convert ms to seconds

% Relay timings from ETAP (approx)
relay_times = [20, 86.1];     % Relay 2 trip, Relay 1 trip (99.4 - 13.3)
relay_labels = {'Relay2 (20 ms)', 'Relay1 (86.1 ms)'};

% Plot
figure('Name', 'Relay Coordination Timeline for 3-Phase Fault at Bus 4', ...
       'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.6]);

plot(t, i_fault, 'b-', 'LineWidth', 2); hold on;
xlabel('Time (ms)');
ylabel('Fault Current (kA)');
title('Relay Coordination Timeline for 3-Phase Fault at Bus 4');
ylim([-1.1*I_peak, 1.1*I_peak]);

% Plot relay actions
for k = 1:length(relay_times)
    x = relay_times(k);
    y = 0.9 * I_peak;
    plot([x x], ylim, 'r--', 'LineWidth', 1.5);
    text(x + 1, y, relay_labels{k}, 'Color', 'r', 'FontSize', 10);
end

legend('Fault Current', 'Relay Trips');
grid on;

% === Updated Fault Current with Breaker Interruption ===
fs = 1000;              % 1 kHz sample rate
t = 0:1:120;            % Time from 0 to 120 ms
f = 60;                 % Frequency (Hz)
I_peak = 9.5;           % kA

i_fault = I_peak * sin(2 * pi * f * t / 1000);  % Fault current

% Simulate breaker opening at 105 ms (set current to zero after that)
i_fault(t > 105) = 0;

% Now plot this updated waveform
figure('Name', 'Relay Coordination with Current Interruption','NumberTitle','off',...
    'Units','normalized','Position',[0.1 0.1 0.8 0.6]);

plot(t, i_fault, 'b-', 'LineWidth', 2); hold on;
xlabel('Time (ms)'); ylabel('Fault Current (kA)');
title('Relay Coordination Timeline with Breaker Opening');

% Relay trip indicators
relay_times = [20, 86.1];
relay_labels = {'Relay2 (20 ms)', 'Relay1 (86.1 ms)'};
for k = 1:length(relay_times)
    x = relay_times(k); y = 0.9 * I_peak;
    plot([x x], ylim, 'r--', 'LineWidth', 1.5);
    text(x + 1, y, relay_labels{k}, 'Color', 'r', 'FontSize', 10);
end

% Breaker trip indicators
breaker_times = [99.4, 105];
breaker_labels = {'CB_7/8 (99.4 ms)', 'CB_17/18 (105 ms)'};
for k = 1:length(breaker_times)
    x = breaker_times(k); y = -0.9 * I_peak;
    plot([x x], ylim, 'g--', 'LineWidth', 1.5);
    text(x + 1, y, breaker_labels{k}, 'Color', 'g', 'FontSize', 10);
end

legend('Fault Current', 'Relay Trips', 'Breaker Opens');
grid on;



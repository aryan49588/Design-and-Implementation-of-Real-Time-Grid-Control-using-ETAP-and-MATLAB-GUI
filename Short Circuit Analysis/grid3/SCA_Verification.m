clc; clear; close all;

%% System Base
S_base = 100e6;    % 100 MVA
V_base = 20e3;     % 20 kV (line-to-line)
I_base = S_base / (sqrt(3) * V_base); % Base current in Amps

%% Bus Names
bus_names = {'Bus1','Bus2','Bus3','Bus4','Bus5','Bus6','Bus7','Bus8','Bus9'};

%% Sequence Impedance (Ohms) - Sample from Bus_6 (Page 11 of PDF)
Z1 = 0.66345 + 1i*0.66221;
Z2 = 0.65114 + 1i*0.64877;
Z0 = 2.18976 + 1i*0.39514;

%% Fault Current Calculations at All Buses
n_buses = length(bus_names);
fault_types = {'3-Phase', 'Line-Ground', 'Line-Line', 'Line-Line-Ground'};
n_faults = length(fault_types);
I_fault = zeros(n_buses, n_faults);  % In kA

for i = 1:n_buses
    % 3-Phase fault current
    I_3ph = abs(1 / Z1);

    % Line-to-Ground fault current
    I_LG = abs(3 / (Z1 + Z2 + Z0));

    % Line-to-Line fault current
    I_LL = abs(sqrt(3) / (Z1 + Z2));

    % Line-to-Line-to-Ground fault current
    Z_parallel = (Z1 + Z2) * Z0 / (Z1 + Z2 + Z0);
    I_LLG = abs(sqrt(3) / Z_parallel);

    % Convert to actual kA
    I_fault(i, :) = [I_3ph, I_LG, I_LL, I_LLG] * I_base / 1000; % in kA
end

%% Display Results in Command Window
fprintf('\nSHORT CIRCUIT CURRENT RESULTS FOR ALL BUSES (in kA)\n');
fprintf('%-8s %-12s %-12s %-12s %-12s\n', 'Bus', '3-Ph Fault', 'L-G Fault', 'L-L Fault', 'LL-G Fault');
for i = 1:n_buses
    fprintf('%-8s %-12.3f %-12.3f %-12.3f %-12.3f\n', ...
        bus_names{i}, I_fault(i,1), I_fault(i,2), I_fault(i,3), I_fault(i,4));
end

%% Bar Plot for Visual Comparison
figure('Name','Short-Circuit Currents','Units','normalized','OuterPosition',[0 0 1 1]);
bar(I_fault, 'grouped');
set(gca, 'XTickLabel', bus_names, 'FontSize', 12);
xlabel('Bus Number');
ylabel('Fault Current (kA)');
legend(fault_types, 'Location', 'northoutside', 'Orientation', 'horizontal');
title('Short-Circuit Fault Currents at All Buses');
grid on;

%% FAULT CURRENT WAVEFORM (3-Phase Symmetrical)
t = 0:0.1:150;          % Time in ms
f = 50;                 % Frequency in Hz
I_peak = 10;            % Peak fault current (kA)
I_fault = I_peak * sin(2 * pi * f * t / 1000);  % sinusoidal waveform in kA

%% RELAY & CB OPERATION FROM ETAP PDF
relay_trip_time = 99.4;  % ms
cb_trip_time = 83.3;     % ms
fault_current_kA = 2.372; % from ETAP report
relay_name = 'Relay3';

%% Plot the waveform and relay trips
figure('Name','ETAP Relay Coordination','Units','normalized','OuterPosition',[0 0 1 1]);
plot(t, I_fault, 'b-', 'LineWidth', 2); hold on;

% Relay trip vertical line
xline(relay_trip_time, '--r', 'LineWidth', 2);
text(relay_trip_time+1, 8.5, sprintf('%s (%.1f ms)', relay_name, relay_trip_time), ...
     'Color', 'r', 'FontSize', 12);

% CB1 and CB2 trip line
xline(cb_trip_time, '--m', 'LineWidth', 2);
text(cb_trip_time+1, -8.5, sprintf('CB1 & CB2 Trip (%.1f ms)', cb_trip_time), ...
     'Color', 'm', 'FontSize', 12);

% Format plot
title('Relay Coordination Timeline for 3-Phase Fault at Bus 6');
xlabel('Time (ms)');
ylabel('Fault Current (kA)');
legend('Fault Current', 'Relay Trip', 'CB Trip', 'Location', 'northeast');
grid on;
ylim([-I_peak*1.2, I_peak*1.2]);

%% DISPLAY COORDINATION INFO IN COMMAND WINDOW
fprintf('\n========== RELAY COORDINATION SUMMARY ==========\n');
fprintf('Fault Location   : Bus_6\n');
fprintf('Fault Type       : 3-Phase Symmetrical\n');
fprintf('Fault Current    : %.3f kA\n', fault_current_kA);
fprintf('Relay Involved   : %s\n', relay_name);
fprintf('Relay Trip Time  : %.1f ms\n', relay_trip_time);
fprintf('CBs Tripped      : CB1, CB2\n');
fprintf('CB Trip Time     : %.1f ms\n', cb_trip_time);
fprintf('Protection Type  : Phase - OC1 - 51 (Inverse Time)\n');
fprintf('Coordination     : Relay3 trips → sends signal to CB1 & CB2\n');
fprintf('===============================================\n');

%% === Fault Data from Your Results ===
bus_names = {'Bus1','Bus2','Bus3','Bus4','Bus5','Bus6','Bus7','Bus8','Bus9'}';
fault_types = {'3-Ph Fault','L-G Fault','L-L Fault','LL-G Fault'};
fault_data = repmat([3.080 2.222 2.693 4.717], 9, 1); % All buses same

%% === Relay Coordination Summary ===
relay_summary = sprintf([ ...
    '========== RELAY COORDINATION SUMMARY ==========\n', ...
    'Fault Location   : Bus_6\n', ...
    'Fault Type       : 3-Phase Symmetrical\n', ...
    'Fault Current    : 2.372 kA\n', ...
    'Relay Involved   : Relay3\n', ...
    'Relay Trip Time  : 99.4 ms\n', ...
    'CBs Tripped      : CB1, CB2\n', ...
    'CB Trip Time     : 83.3 ms\n', ...
    'Protection Type  : Phase - OC1 - 51 (Inverse Time)\n', ...
    'Coordination     : Relay3 trips → sends signal to CB1 & CB2\n', ...
    '===============================================']);

%% === GUI Window ===
f = figure('Name', '9-Bus Fault & Relay Analysis', ...
           'Units', 'normalized', ...
           'OuterPosition', [0 0 1 1]); % Fullscreen

tabgroup = uitabgroup(f);

%% === TAB 1: Fault Table ===
tab1 = uitab(tabgroup, 'Title', 'Fault Table');

uitable('Parent', tab1, ...
        'Data', fault_data, ...
        'ColumnName', fault_types, ...
        'RowName', bus_names, ...
        'Units', 'normalized', ...
        'Position', [0.05 0.1 0.9 0.8], ...
        'FontSize', 12);

uicontrol('Style','text','Parent',tab1,...
    'String','Fault Currents at All Buses (kA)',...
    'Units','normalized',...
    'Position',[0.3 0.9 0.4 0.05],...
    'FontSize',14,'FontWeight','bold');

%% === TAB 2: Relay Coordination Summary ===
tab2 = uitab(tabgroup, 'Title', 'Relay Coordination Summary');

uicontrol('Style', 'edit', 'Parent', tab2, ...
          'Max', 20, 'Min', 0, ...
          'String', relay_summary, ...
          'Units', 'normalized', ...
          'Position', [0.1 0.1 0.8 0.8], ...
          'FontSize', 12, ...
          'HorizontalAlignment', 'left');

%% === TAB 3: Bus vs Fault Current Plot ===
tab3 = uitab(tabgroup, 'Title', 'Bus vs Fault Currents');

ax1 = axes('Parent', tab3, 'Position', [0.1 0.15 0.85 0.75]);
bar(ax1, fault_data, 'grouped');
set(ax1, 'XTickLabel', bus_names, 'FontSize', 12);
xlabel(ax1, 'Bus Number');
ylabel(ax1, 'Fault Current (kA)');
legend(ax1, fault_types, 'Location', 'northoutside', 'Orientation', 'horizontal');
title(ax1, 'Short-Circuit Fault Currents at All Buses');

%% === TAB 4: Relay Coordination Waveform ===
tab4 = uitab(tabgroup, 'Title', 'Relay Coordination Plot');

ax2 = axes('Parent', tab4, 'Position', [0.1 0.15 0.85 0.75]);

% Simulated fault waveform
t = 0:0.1:150; f = 50; I_peak = 10;
I_fault = I_peak * sin(2 * pi * f * t / 1000);

% Relay trip markers
relay_trip_time = 99.4;
cb_trip_time = 83.3;

plot(ax2, t, I_fault, 'b-', 'LineWidth', 2); hold on;
xline(ax2, relay_trip_time, '--r', 'LineWidth', 2);
xline(ax2, cb_trip_time, '--m', 'LineWidth', 2);
text(relay_trip_time+2, 8.5, 'Relay3 (99.4 ms)', 'Color', 'r', 'FontSize', 12);
text(cb_trip_time+2, -8.5, 'CB1 & CB2 (83.3 ms)', 'Color', 'm', 'FontSize', 12);

title(ax2, 'Relay Coordination Timeline for 3-Phase Fault at Bus 6');
xlabel(ax2, 'Time (ms)');
ylabel(ax2, 'Fault Current (kA)');
ylim(ax2, [-I_peak*1.2 I_peak*1.2]);
legend(ax2, 'Fault Current', 'Relay Trip', 'CB Trip', 'Location', 'northeast');
grid(ax2, 'on');

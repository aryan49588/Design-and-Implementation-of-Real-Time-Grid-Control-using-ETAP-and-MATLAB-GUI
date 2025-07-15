clc;
clear;

% System Base Values
S_base = 100e6; % 100 MVA
V_base = 230e3; % 230 kV

% Bus data: [Bus No, Type (1=S, 2=R, 3=L), Voltage(kV), Angle(deg)]
bus_data = [
    1, 1, 230, 0;
    2, 3, 230, 0;
    3, 2, 230, 0;
    4, 3, 115, 0;
    5, 3, 115, 0;
    6, 2, 115, 0;
    7, 3, 115, 0;
    8, 3, 115, 0;
    9, 2, 115, 0
];

% Line data: [From Bus, To Bus, R(pu), X(pu), B(pu)]
line_data = [
    1, 4, 0, 0.0576, 0;
    4, 5, 0.017, 0.092, 0.158;
    5, 6, 0.039, 0.17, 0.358;
    3, 6, 0, 0.0586, 0;
    6, 7, 0.0119, 0.1008, 0.209;
    7, 8, 0.0085, 0.072, 0.149;
    8, 2, 0, 0.0625, 0;
    8, 9, 0.032, 0.161, 0.306;
    9, 4, 0.01, 0.085, 0.176
];

nbus = size(bus_data, 1);
nline = size(line_data, 1);

Z_base = (V_base)^2 / S_base;

% Initialize Ybus
Ybus = zeros(nbus);

% Construct Ybus
for k = 1:nline
    i = line_data(k, 1);
    j = line_data(k, 2);
    R = line_data(k, 3);
    X = line_data(k, 4);
    B = line_data(k, 5);

    Z = R + 1i * X;
    y = 1 / Z;
    b_shunt = 1i * B / 2;

    Ybus(i, i) = Ybus(i, i) + y + b_shunt;
    Ybus(j, j) = Ybus(j, j) + y + b_shunt;
    Ybus(i, j) = Ybus(i, j) - y;
    Ybus(j, i) = Ybus(j, i) - y;
end

Zbus = inv(Ybus);

% Fault Analysis
fault_type = {'3-phase', 'LG', 'LL', 'LLG'};
fault_results = [];

for bus = 1:nbus
    Zf = 0; % Fault impedance (assumed zero for solid fault)

    Zth = Zbus(bus, bus);
    I_3ph = 1 / Zth;

    % LG fault
    ZLG = Zth;
    I_LG = 3 / ZLG;

    % LL fault
    ZLL = Zth + Zth;
    I_LL = sqrt(3) / ZLL;

    % LLG fault
    ZLLG = (Zth * 3) / 2;
    I_LLG = 3 / ZLLG;

    % Convert to actual fault current in kA
    V_kV = bus_data(bus, 3);
    I_base = S_base / (sqrt(3) * V_kV * 1e3); % in A
    I_base_kA = I_base / 1000;

    fault_results = [fault_results; bus, abs(I_3ph)*I_base_kA, angle(I_3ph), abs(I_LG)*I_base_kA, angle(I_LG), abs(I_LL)*I_base_kA, angle(I_LL), abs(I_LLG)*I_base_kA, angle(I_LLG)];
end

% Display Results
disp('Bus  |  I_3ph (kA)  |  I_LG (kA)  |  I_LL (kA)  |  I_LLG (kA)');
disp(fault_results(:, [1,2,4,6,8]));

% Plot Fault Analysis
plot_fault_analysis(fault_results, bus_data);

% ----------------------------
% Function: Plot Fault Currents
% ----------------------------
function plot_fault_analysis(fault_results, bus_data)
    figure('Position', [100, 100, 1200, 800]);

    % Plot 1: Fault currents comparison
    subplot(2, 2, 1);
    bus_numbers = fault_results(:, 1);
    I_3ph_kA = fault_results(:, 2);
    I_LG_kA = fault_results(:, 4);
    I_LL_kA = fault_results(:, 6);
    I_LLG_kA = fault_results(:, 8);

    bar([I_3ph_kA, I_LG_kA, I_LL_kA, I_LLG_kA]);
    xlabel('Bus Number');
    ylabel('Fault Current (kA)');
    title('Fault Current Comparison by Bus');
    legend('3-Phase', 'Line-to-Ground', 'Line-to-Line', 'Line-to-Line-to-Ground');
    grid on;

    % Plot 2: Phase angles of fault currents
    subplot(2, 2, 2);
    angle_3ph = rad2deg(fault_results(:, 3));
    angle_LG = rad2deg(fault_results(:, 5));
    angle_LL = rad2deg(fault_results(:, 7));
    angle_LLG = rad2deg(fault_results(:, 9));

    plot(bus_numbers, angle_3ph, '-o', ...
         bus_numbers, angle_LG, '-s', ...
         bus_numbers, angle_LL, '-^', ...
         bus_numbers, angle_LLG, '-d');
    xlabel('Bus Number');
    ylabel('Phase Angle (degrees)');
    title('Phase Angles of Fault Currents');
    legend('3-Phase', 'Line-to-Ground', 'Line-to-Line', 'Line-to-Line-to-Ground');
    grid on;
end
%% Relay Coordination Simulation with Fault Current Timeline Plot
% This script extends the short-circuit code to add relay trip simulation and waveform display

fault_bus = 3; % You can change this to any bus number
I_fault_kA = fault_results(fault_bus, 2); % Use 3-phase fault current in kA
V_bus_kV = bus_data(fault_bus, 3);

% Define relay trip times and labels using cell array
relay_trips = {
    2.1, 'Relay1 - OC1 (50)';
    20.0, 'Relay1 - 87';
    99.4, 'Relay1 - OC1 (51)';
    103.0, 'CB4/CB5 trip by 87';
    183.0, 'CB4/CB5 trip by 51'
};

% Time vector for 0 to 200 ms
t = linspace(0, 200, 2000); % ms
f = 60; % Hz
omega = 2 * pi * f / 1000; % rad/ms

% Generate fault current waveform
I_wave = I_fault_kA * sin(omega * t);

% Zero current after final breaker operation
final_trip_time = 183; % last trip time
I_wave(t > final_trip_time) = 0;

% Plot
figure('Name','Relay Coordination Timeline', 'Color', 'w');
plot(t, I_wave, 'b-', 'LineWidth', 2); hold on;

% Annotate each relay trip as a red line with marker
for i = 1:size(relay_trips, 1)
    trip_time = relay_trips{i, 1};
    label = relay_trips{i, 2};
    xline(trip_time, 'r--', 'LineWidth', 1.2);
    text(trip_time + 1, I_fault_kA * 0.9, label, 'Color', 'r', 'FontSize', 9, 'Rotation', 90, 'VerticalAlignment','bottom');
end

xlabel('Time (ms)', 'FontWeight', 'bold');
ylabel('Fault Current (kA)', 'FontWeight', 'bold');
title(sprintf('Relay Coordination Timeline for 3-Phase Fault at Bus %d', fault_bus), 'FontWeight', 'bold');
grid on;
axis([0 200 -I_fault_kA*1.2 I_fault_kA*1.2]);
legend('Fault Current', 'Location', 'northeast');
set(gca, 'FontSize', 10);

% ---- Display Coordination in Command Window ----
fprintf('\n=== Relay & Breaker Coordination Summary ===\n');
fprintf('Time (ms) | Device         | Action\n');
fprintf('------------------------------------------\n');

for i = 1:size(relay_trips, 1)
    fprintf('%8.1f | %-14s | Triggered\n', relay_trips{i,1}, relay_trips{i,2});
end

function power_system_fault_analysis_gui()
    % Complete Power System Fault Analysis GUI
    % This GUI displays fault analysis results, relay coordination, and system data
    
    % Run the fault analysis first
    [fault_results, bus_data, relay_trips] = run_fault_analysis();
    
    % Create main figure covering entire screen
    fig = figure('Name', 'Power System Fault Analysis & Relay Coordination', ...
                 'NumberTitle', 'off', ...
                 'Units', 'normalized', ...
                 'Position', [0 0 1 1], ...
                 'Color', 'white', ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'figure', ...
                 'Resize', 'on');
    
    % Create tab group
    tabgroup = uitabgroup('Parent', fig, 'Position', [0.02 0.02 0.96 0.96]);
    
    % Tab 1: Fault Current Results Table
    create_fault_table_tab(tabgroup, fault_results, bus_data);
    
    % Tab 2: Fault Current Comparison Chart
    create_fault_comparison_tab(tabgroup, fault_results);
    
    % Tab 3: Phase Angle Analysis
    create_phase_angle_tab(tabgroup, fault_results);
    
    % Tab 4: Relay Coordination Timeline
    create_relay_coordination_tab(tabgroup, fault_results, bus_data, relay_trips);
    
    % Tab 5: System Overview
    create_system_overview_tab(tabgroup, fault_results, bus_data);
    
    % Tab 6: Detailed Analysis
    create_detailed_analysis_tab(tabgroup, fault_results, bus_data);
end

function create_fault_table_tab(tabgroup, fault_results, bus_data)
    % Create tab for fault current results table
    tab1 = uitab(tabgroup, 'Title', 'Fault Current Results');
    
    % Create title
    title_text = uicontrol('Parent', tab1, 'Style', 'text', ...
                          'String', 'Fault Current Analysis Results', ...
                          'FontSize', 20, 'FontWeight', 'bold', ...
                          'Units', 'normalized', 'Position', [0.1 0.9 0.8 0.08], ...
                          'HorizontalAlignment', 'center', 'BackgroundColor', 'white');
    
    % Prepare data for table
    table_data = cell(size(fault_results, 1), 6);
    for i = 1:size(fault_results, 1)
        table_data{i, 1} = fault_results(i, 1); % Bus Number
        table_data{i, 2} = sprintf('%.4f', fault_results(i, 2)); % I_3ph
        table_data{i, 3} = sprintf('%.4f', fault_results(i, 4)); % I_LG
        table_data{i, 4} = sprintf('%.4f', fault_results(i, 6)); % I_LL
        table_data{i, 5} = sprintf('%.4f', fault_results(i, 8)); % I_LLG
        table_data{i, 6} = sprintf('%.1f kV', bus_data(i, 3)); % Voltage Level
    end
    
    % Create table
    column_names = {'Bus No.', 'I_3ph (kA)', 'I_LG (kA)', 'I_LL (kA)', 'I_LLG (kA)', 'Voltage Level'};
    
    table_handle = uitable('Parent', tab1, ...
                          'Data', table_data, ...
                          'ColumnName', column_names, ...
                          'Units', 'normalized', ...
                          'Position', [0.1 0.2 0.8 0.65], ...
                          'FontSize', 12, ...
                          'ColumnWidth', {80, 100, 100, 100, 100, 120});
    
    % Add summary statistics
    stats_text = sprintf(['Summary Statistics:\n' ...
                         'Maximum 3-Phase Fault Current: %.4f kA (Bus %d)\n' ...
                         'Minimum 3-Phase Fault Current: %.4f kA (Bus %d)\n' ...
                         'Average 3-Phase Fault Current: %.4f kA'], ...
                         max(fault_results(:, 2)), fault_results(fault_results(:, 2) == max(fault_results(:, 2)), 1), ...
                         min(fault_results(:, 2)), fault_results(fault_results(:, 2) == min(fault_results(:, 2)), 1), ...
                         mean(fault_results(:, 2)));
    
    uicontrol('Parent', tab1, 'Style', 'text', ...
              'String', stats_text, ...
              'FontSize', 12, 'FontWeight', 'bold', ...
              'Units', 'normalized', 'Position', [0.1 0.05 0.8 0.12], ...
              'HorizontalAlignment', 'left', 'BackgroundColor', 'white');
end

function create_fault_comparison_tab(tabgroup, fault_results)
    % Create tab for fault current comparison chart
    tab2 = uitab(tabgroup, 'Title', 'Fault Current Comparison');
    
    % Create axes
    ax = axes('Parent', tab2, 'Position', [0.1 0.15 0.8 0.75]);
    
    % Extract data
    bus_numbers = fault_results(:, 1);
    I_3ph_kA = fault_results(:, 2);
    I_LG_kA = fault_results(:, 4);
    I_LL_kA = fault_results(:, 6);
    I_LLG_kA = fault_results(:, 8);
    
    % Create grouped bar chart
    bar_data = [I_3ph_kA, I_LG_kA, I_LL_kA, I_LLG_kA];
    bar_handle = bar(ax, bus_numbers, bar_data, 'grouped');
    
    % Customize colors
    bar_handle(1).FaceColor = [0.2 0.6 0.8]; % Blue for 3-phase
    bar_handle(2).FaceColor = [0.8 0.2 0.2]; % Red for LG
    bar_handle(3).FaceColor = [0.2 0.8 0.2]; % Green for LL
    bar_handle(4).FaceColor = [0.8 0.6 0.2]; % Orange for LLG
    
    % Labels and formatting
    xlabel(ax, 'Bus Number', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(ax, 'Fault Current (kA)', 'FontSize', 14, 'FontWeight', 'bold');
    title(ax, 'Fault Current Comparison by Bus and Fault Type', 'FontSize', 16, 'FontWeight', 'bold');
    legend(ax, '3-Phase', 'Line-to-Ground', 'Line-to-Line', 'Line-to-Line-to-Ground', ...
           'Location', 'northeast', 'FontSize', 12);
    grid(ax, 'on');
    
    % Set axis properties
    ax.XTick = bus_numbers;
    ax.FontSize = 12;
    ax.GridAlpha = 0.3;
end

function create_phase_angle_tab(tabgroup, fault_results)
    % Create tab for phase angle analysis
    tab3 = uitab(tabgroup, 'Title', 'Phase Angle Analysis');
    
    % Create axes
    ax = axes('Parent', tab3, 'Position', [0.1 0.15 0.8 0.75]);
    
    % Extract data
    bus_numbers = fault_results(:, 1);
    angle_3ph = rad2deg(fault_results(:, 3));
    angle_LG = rad2deg(fault_results(:, 5));
    angle_LL = rad2deg(fault_results(:, 7));
    angle_LLG = rad2deg(fault_results(:, 9));
    
    % Create line plots
    plot(ax, bus_numbers, angle_3ph, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.2 0.6 0.8]);
    hold(ax, 'on');
    plot(ax, bus_numbers, angle_LG, '-s', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.8 0.2 0.2]);
    plot(ax, bus_numbers, angle_LL, '-^', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.2 0.8 0.2]);
    plot(ax, bus_numbers, angle_LLG, '-d', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.8 0.6 0.2]);
    
    % Labels and formatting
    xlabel(ax, 'Bus Number', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(ax, 'Phase Angle (degrees)', 'FontSize', 14, 'FontWeight', 'bold');
    title(ax, 'Phase Angles of Fault Currents', 'FontSize', 16, 'FontWeight', 'bold');
    legend(ax, '3-Phase', 'Line-to-Ground', 'Line-to-Line', 'Line-to-Line-to-Ground', ...
           'Location', 'best', 'FontSize', 12);
    grid(ax, 'on');
    
    % Set axis properties
    ax.XTick = bus_numbers;
    ax.FontSize = 12;
    ax.GridAlpha = 0.3;
    hold(ax, 'off');
end

function create_relay_coordination_tab(tabgroup, fault_results, bus_data, relay_trips)
    % Create tab for relay coordination timeline
    tab4 = uitab(tabgroup, 'Title', 'Relay Coordination');
    
    % Create axes for timeline plot
    ax1 = axes('Parent', tab4, 'Position', [0.1 0.55 0.8 0.35]);
    
    % Parameters for relay coordination
    fault_bus = 3; % Default fault bus
    I_fault_kA = fault_results(fault_bus, 2); % 3-phase fault current
    
    % Time vector for 0 to 200 ms
    t = linspace(0, 200, 2000);
    f = 60; % Hz
    omega = 2 * pi * f / 1000; % rad/ms
    
    % Generate fault current waveform
    I_wave = I_fault_kA * sin(omega * t);
    
    % Zero current after final breaker operation
    final_trip_time = 183;
    I_wave(t > final_trip_time) = 0;
    
    % Plot waveform
    plot(ax1, t, I_wave, 'b-', 'LineWidth', 2);
    hold(ax1, 'on');
    
    % Add relay trip lines
    colors = {'r', 'g', 'm', 'c', 'k'};
    for i = 1:size(relay_trips, 1)
        trip_time = relay_trips{i, 1};
        label = relay_trips{i, 2};
        xline(ax1, trip_time, '--', 'Color', colors{mod(i-1, 5)+1}, 'LineWidth', 1.5);
        text(ax1, trip_time + 1, I_fault_kA * 0.9, label, ...
             'Color', colors{mod(i-1, 5)+1}, 'FontSize', 10, ...
             'Rotation', 90, 'VerticalAlignment', 'bottom');
    end
    
    % Formatting
    xlabel(ax1, 'Time (ms)', 'FontWeight', 'bold');
    ylabel(ax1, 'Fault Current (kA)', 'FontWeight', 'bold');
    title(ax1, sprintf('Relay Coordination Timeline for 3-Phase Fault at Bus %d', fault_bus), 'FontWeight', 'bold');
    grid(ax1, 'on');
    axis(ax1, [0 200 -I_fault_kA*1.2 I_fault_kA*1.2]);
    legend(ax1, 'Fault Current', 'Location', 'northeast');
    hold(ax1, 'off');
    
    % Create table for relay coordination summary
    table_data = cell(size(relay_trips, 1), 2);
    for i = 1:size(relay_trips, 1)
        table_data{i, 1} = sprintf('%.1f ms', relay_trips{i, 1});
        table_data{i, 2} = relay_trips{i, 2};
    end
    
    column_names = {'Time', 'Device/Action'};
    table_handle = uitable('Parent', tab4, ...
                          'Data', table_data, ...
                          'ColumnName', column_names, ...
                          'Units', 'normalized', ...
                          'Position', [0.1 0.1 0.8 0.35], ...
                          'FontSize', 12, ...
                          'ColumnWidth', {100, 300});
end

function create_system_overview_tab(tabgroup, fault_results, bus_data)
    % Create tab for system overview
    tab5 = uitab(tabgroup, 'Title', 'System Overview');
    
    % Create title
    uicontrol('Parent', tab5, 'Style', 'text', ...
              'String', 'Power System Overview', ...
              'FontSize', 18, 'FontWeight', 'bold', ...
              'Units', 'normalized', 'Position', [0.1 0.9 0.8 0.08], ...
              'HorizontalAlignment', 'center', 'BackgroundColor', 'white');
    
    % System parameters
    system_info = {
        'System Base Values:', '';
        'Base Power (S_base):', '100 MVA';
        'Base Voltage (V_base):', '230 kV';
        '', '';
        'Bus Configuration:', '';
        'Total Buses:', sprintf('%d', size(bus_data, 1));
        '230 kV Buses:', sprintf('%d', sum(bus_data(:, 3) == 230));
        '115 kV Buses:', sprintf('%d', sum(bus_data(:, 3) == 115));
        '', '';
        'Fault Analysis Summary:', '';
        'Highest 3-Phase Fault:', sprintf('%.4f kA at Bus %d', max(fault_results(:, 2)), fault_results(fault_results(:, 2) == max(fault_results(:, 2)), 1));
        'Lowest 3-Phase Fault:', sprintf('%.4f kA at Bus %d', min(fault_results(:, 2)), fault_results(fault_results(:, 2) == min(fault_results(:, 2)), 1));
        'Average 3-Phase Fault:', sprintf('%.4f kA', mean(fault_results(:, 2)));
    };
    
    % Create table for system information
    table_handle = uitable('Parent', tab5, ...
                          'Data', system_info, ...
                          'ColumnName', {'Parameter', 'Value'}, ...
                          'Units', 'normalized', ...
                          'Position', [0.1 0.3 0.8 0.55], ...
                          'FontSize', 14, ...
                          'ColumnWidth', {250, 200});
    
    % Add bus data table
    bus_table_data = cell(size(bus_data, 1), 4);
    bus_types = {'Slack', 'PV', 'PQ'};
    for i = 1:size(bus_data, 1)
        bus_table_data{i, 1} = bus_data(i, 1); % Bus Number
        bus_table_data{i, 2} = bus_types{bus_data(i, 2)}; % Bus Type
        bus_table_data{i, 3} = sprintf('%.0f kV', bus_data(i, 3)); % Voltage
        bus_table_data{i, 4} = sprintf('%.1f°', bus_data(i, 4)); % Angle
    end
    
    uitable('Parent', tab5, ...
            'Data', bus_table_data, ...
            'ColumnName', {'Bus No.', 'Type', 'Voltage', 'Angle'}, ...
            'Units', 'normalized', ...
            'Position', [0.1 0.05 0.8 0.2], ...
            'FontSize', 12, ...
            'ColumnWidth', {80, 80, 80, 80});
end

function create_detailed_analysis_tab(tabgroup, fault_results, bus_data)
    % Create tab for detailed analysis
    tab6 = uitab(tabgroup, 'Title', 'Detailed Analysis');
    
    % Create subplot for fault type comparison
    ax1 = axes('Parent', tab6, 'Position', [0.05 0.55 0.4 0.35]);
    
    % Pie chart for fault severity distribution
    fault_types = {'3-Phase', 'Line-to-Ground', 'Line-to-Line', 'Line-to-Line-to-Ground'};
    avg_faults = [mean(fault_results(:, 2)), mean(fault_results(:, 4)), ...
                  mean(fault_results(:, 6)), mean(fault_results(:, 8))];
    
    pie(ax1, avg_faults, fault_types);
    title(ax1, 'Average Fault Current Distribution', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Create subplot for voltage level analysis
    ax2 = axes('Parent', tab6, 'Position', [0.55 0.55 0.4 0.35]);
    
    % Group by voltage level
    voltage_230 = fault_results(bus_data(:, 3) == 230, 2);
    voltage_115 = fault_results(bus_data(:, 3) == 115, 2);
    
    boxplot(ax2, [voltage_230; voltage_115], [ones(length(voltage_230), 1); 2*ones(length(voltage_115), 1)]);
    ax2.XTickLabel = {'230 kV', '115 kV'};
    ylabel(ax2, 'Fault Current (kA)', 'FontSize', 12, 'FontWeight', 'bold');
    title(ax2, 'Fault Current by Voltage Level', 'FontSize', 14, 'FontWeight', 'bold');
    grid(ax2, 'on');
    
    % Create detailed statistics table
    stats_data = {
        'Fault Type', 'Min (kA)', 'Max (kA)', 'Mean (kA)', 'Std Dev (kA)';
        '3-Phase', sprintf('%.4f', min(fault_results(:, 2))), sprintf('%.4f', max(fault_results(:, 2))), sprintf('%.4f', mean(fault_results(:, 2))), sprintf('%.4f', std(fault_results(:, 2)));
        'Line-to-Ground', sprintf('%.4f', min(fault_results(:, 4))), sprintf('%.4f', max(fault_results(:, 4))), sprintf('%.4f', mean(fault_results(:, 4))), sprintf('%.4f', std(fault_results(:, 4)));
        'Line-to-Line', sprintf('%.4f', min(fault_results(:, 6))), sprintf('%.4f', max(fault_results(:, 6))), sprintf('%.4f', mean(fault_results(:, 6))), sprintf('%.4f', std(fault_results(:, 6)));
        'Line-to-Line-to-Ground', sprintf('%.4f', min(fault_results(:, 8))), sprintf('%.4f', max(fault_results(:, 8))), sprintf('%.4f', mean(fault_results(:, 8))), sprintf('%.4f', std(fault_results(:, 8)));
    };
    
    uitable('Parent', tab6, ...
            'Data', stats_data, ...
            'Units', 'normalized', ...
            'Position', [0.05 0.05 0.9 0.4], ...
            'FontSize', 12, ...
            'ColumnWidth', {150, 100, 100, 100, 100});
end

function [fault_results, bus_data, relay_trips] = run_fault_analysis()
    % Run the complete fault analysis
    
    % System Base Values
    S_base = 100e6; % 100 MVA
    V_base = 230e3; % 230 kV
    
    % Bus data: [Bus No, Type (1=S, 2=R, 3=L), Voltage(kV), Angle(deg)]
    bus_data = [
        1, 1, 230, 0;
        2, 3, 230, 0;
        3, 2, 230, 0;
        4, 3, 115, 0;
        5, 3, 115, 0;
        6, 2, 115, 0;
        7, 3, 115, 0;
        8, 3, 115, 0;
        9, 2, 115, 0
    ];
    
    % Line data: [From Bus, To Bus, R(pu), X(pu), B(pu)]
    line_data = [
        1, 4, 0, 0.0576, 0;
        4, 5, 0.017, 0.092, 0.158;
        5, 6, 0.039, 0.17, 0.358;
        3, 6, 0, 0.0586, 0;
        6, 7, 0.0119, 0.1008, 0.209;
        7, 8, 0.0085, 0.072, 0.149;
        8, 2, 0, 0.0625, 0;
        8, 9, 0.032, 0.161, 0.306;
        9, 4, 0.01, 0.085, 0.176
    ];
    
    nbus = size(bus_data, 1);
    nline = size(line_data, 1);
    
    % Initialize Ybus
    Ybus = zeros(nbus);
    
    % Construct Ybus
    for k = 1:nline
        i = line_data(k, 1);
        j = line_data(k, 2);
        R = line_data(k, 3);
        X = line_data(k, 4);
        B = line_data(k, 5);
        
        Z = R + 1i * X;
        y = 1 / Z;
        b_shunt = 1i * B / 2;
        
        Ybus(i, i) = Ybus(i, i) + y + b_shunt;
        Ybus(j, j) = Ybus(j, j) + y + b_shunt;
        Ybus(i, j) = Ybus(i, j) - y;
        Ybus(j, i) = Ybus(j, i) - y;
    end
    
    Zbus = inv(Ybus);
    
    % Fault Analysis
    fault_results = [];
    
    for bus = 1:nbus
        Zth = Zbus(bus, bus);
        I_3ph = 1 / Zth;
        
        % LG fault
        ZLG = Zth;
        I_LG = 3 / ZLG;
        
        % LL fault
        ZLL = Zth + Zth;
        I_LL = sqrt(3) / ZLL;
        
        % LLG fault
        ZLLG = (Zth * 3) / 2;
        I_LLG = 3 / ZLLG;
        
        % Convert to actual fault current in kA
        V_kV = bus_data(bus, 3);
        I_base = S_base / (sqrt(3) * V_kV * 1e3); % in A
        I_base_kA = I_base / 1000;
        
        fault_results = [fault_results; bus, abs(I_3ph)*I_base_kA, angle(I_3ph), ...
                        abs(I_LG)*I_base_kA, angle(I_LG), abs(I_LL)*I_base_kA, angle(I_LL), ...
                        abs(I_LLG)*I_base_kA, angle(I_LLG)];
    end
    
    % Define relay trips
    relay_trips = {
        2.1, 'Relay1 - OC1 (50)';
        20.0, 'Relay1 - 87';
        99.4, 'Relay1 - OC1 (51)';
        103.0, 'CB4/CB5 trip by 87';
        183.0, 'CB4/CB5 trip by 51'
    };
end

% Run the GUI
power_system_fault_analysis_gui();
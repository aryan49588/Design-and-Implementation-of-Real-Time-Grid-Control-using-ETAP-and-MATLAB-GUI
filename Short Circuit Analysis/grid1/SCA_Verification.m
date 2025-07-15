clc;
clear;

% --- Base values ---
base_MVA = 100;
base_kV = 11.33;  % Average nominal bus voltage
Z_base = (base_kV^2) / base_MVA;

% --- Define Bus Labels ---
bus_labels = {'Bus_1', 'Bus_2', 'Bus_3', 'Bus_4', 'Bus_5', ...
              'Bus_6', 'Bus_7', 'Bus_8', 'Bus_9'};

% --- Impedance Data (Ohms) for each bus (approximated from ETAP Page 9 & 11) ---
% Format: [R1 X1 R0 X0]
impedance_data = [
    0.249 8.5    8.5   8.5   ;  % Bus_1
    0.515 21.8   37.1  82.2  ;  % Bus_2
    0.426 24.5   20.6  106   ;  % Bus_3
    0.477 17.3   17.3  18.4  ;  % Bus_4
    0.484 0.465  1.363 0.268 ;  % Bus_5 (from ETAP page 11)
    0.847 16.9   0     0     ;  % Bus_6
    0.571 15.0   57.1  150   ;  % Bus_7
    0.602 60.2   71.6  207   ;  % Bus_8
    0.847 16.9   0     0     ;  % Bus_9
];

% --- Initialize arrays to store fault currents ---
I_3ph_all = zeros(1, 9);
I_LG_all  = zeros(1, 9);
I_LL_all  = zeros(1, 9);
I_LLG_all = zeros(1, 9);

% --- Loop through each bus ---
for i = 1:9
    R1 = impedance_data(i,1);
    X1 = impedance_data(i,2);
    R0 = impedance_data(i,3);
    X0 = impedance_data(i,4);
    
    Z1 = R1 + 1i*X1;
    Z2 = Z1;  % Assumption
    Z0 = R0 + 1i*X0;
    Zf = 0;   % Solid fault
    V_pre = 1;  % 1 pu
    
    % 3-phase fault
    I_3ph = V_pre / (Z1 + Zf);
    I_3ph_all(i) = abs(I_3ph) * base_kV / sqrt(3);
    
    % LG fault
    Z_LG = Z1 + Z2 + Z0;
    I_LG = 3 * V_pre / (Z_LG + 3*Zf);
    I_LG_all(i) = abs(I_LG) * base_kV / sqrt(3);
    
    % LL fault
    Z_LL = Z1 + Z2;
    I_LL = sqrt(3) * V_pre / (Z_LL + Zf);
    I_LL_all(i) = abs(I_LL) * base_kV / sqrt(3);
    
    % LLG fault
    Z_LLG = (Z1*(Z2 + Z0) + Z2*Z0) / (Z1 + Z2 + Z0);
    I_LLG = V_pre / (Z_LLG + Zf);
    I_LLG_all(i) = abs(I_LLG) * base_kV / sqrt(3);
end

% --- Display Fault Current Magnitudes for All Buses ---
fprintf('\n--- Fault Current Magnitudes (in kA) ---\n');
fprintf('Bus\t\t3-Phase\t\tLG\t\tLL\t\tLLG\n');
for i = 1:9
    fprintf('%s\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\n', ...
        bus_labels{i}, I_3ph_all(i), I_LG_all(i), I_LL_all(i), I_LLG_all(i));
end


%% --- Bar Graph for Fault Currents ---
figure;
bar([I_3ph_all; I_LG_all; I_LL_all; I_LLG_all]', 'grouped');
xticklabels(bus_labels);
ylabel('Fault Current (kA)', 'FontSize', 12);
xlabel('Bus Number', 'FontSize', 12);
legend({'3-Phase','LG','LL','LLG'}, 'Location','northeastoutside');
title('Short Circuit Fault Currents at All Buses');
grid on;
set(gca,'FontSize',10);

% --- Relay Coordination Timeline for Bus 5 (Modified to Cut Fault Current) ---
% ETAP relay operation times for Bus 5
relay_names = {'Relay2', 'T1\_HS2', 'T1\_LS2'};
relay_times = [20.0, 83.3, 83.3];  % in milliseconds

% Simulate ideal current waveform for Bus 5 fault
fs = 10000;          % Sampling rate (Hz)
t = 0:1/fs:0.1;      % Time vector: 0 to 100 ms
f = 50;              % System frequency
I_bus5_peak = max(I_3ph_all);  % 3-phase fault current magnitude
I_fault = I_bus5_peak * sin(2*pi*f*t);  % Fault current waveform

% Simulate breaker clearing the fault at 83.3 ms
I_fault(t*1000 > 83.3) = 0;  % Zero current after breaker opens

% Plot waveform with relay markers
figure;
plot(t*1000, I_fault, 'b', 'LineWidth', 1.5); hold on;

for i = 1:length(relay_times)
    x = relay_times(i);
    y = I_bus5_peak * sin(2*pi*f*x/1000);
    plot([x x], [-I_bus5_peak I_bus5_peak], 'r--', 'LineWidth', 1);
    text(x + 1, y, [relay_names{i} ' (' num2str(x) ' ms)'], ...
        'FontSize', 10, 'Color', 'red');
end

xlabel('Time (ms)');
ylabel('Fault Current (kA)');
title('Relay Coordination Timeline with Breaker Clearing at Bus 5');
legend('Fault Current','Relay Trips');
grid on;

clc;
clear;
close all;

% --- Base values ---
base_MVA = 100;
base_kV = 11.33; % Average nominal bus voltage
Z_base = (base_kV^2) / base_MVA;

% --- Define Bus Labels ---
bus_labels = {'Bus_1', 'Bus_2', 'Bus_3', 'Bus_4', 'Bus_5', ...
             'Bus_6', 'Bus_7', 'Bus_8', 'Bus_9'};

% --- Impedance Data (Ohms) for each bus (approximated from ETAP Page 9 & 11) ---
% Format: [R1 X1 R0 X0]
impedance_data = [
    0.249 8.5   8.5   8.5  ; % Bus_1
    0.515 21.8  37.1  82.2 ; % Bus_2
    0.426 24.5  20.6  106  ; % Bus_3
    0.477 17.3  17.3  18.4 ; % Bus_4
    0.484 0.465 1.363 0.268; % Bus_5 (from ETAP page 11)
    0.847 16.9  0     0    ; % Bus_6
    0.571 15.0  57.1  150  ; % Bus_7
    0.602 60.2  71.6  207  ; % Bus_8
    0.847 16.9  0     0    ; % Bus_9
];

% --- Initialize arrays to store fault currents ---
I_3ph_all = zeros(1, 9);
I_LG_all = zeros(1, 9);
I_LL_all = zeros(1, 9);
I_LLG_all = zeros(1, 9);

% --- Loop through each bus ---
for i = 1:9
    R1 = impedance_data(i,1);
    X1 = impedance_data(i,2);
    R0 = impedance_data(i,3);
    X0 = impedance_data(i,4);
    
    Z1 = R1 + 1i*X1;
    Z2 = Z1; % Assumption
    Z0 = R0 + 1i*X0;
    Zf = 0; % Solid fault
    V_pre = 1; % 1 pu
    
    % 3-phase fault
    I_3ph = V_pre / (Z1 + Zf);
    I_3ph_all(i) = abs(I_3ph) * base_kV / sqrt(3);
    
    % LG fault
    Z_LG = Z1 + Z2 + Z0;
    I_LG = 3 * V_pre / (Z_LG + 3*Zf);
    I_LG_all(i) = abs(I_LG) * base_kV / sqrt(3);
    
    % LL fault
    Z_LL = Z1 + Z2;
    I_LL = sqrt(3) * V_pre / (Z_LL + Zf);
    I_LL_all(i) = abs(I_LL) * base_kV / sqrt(3);
    
    % LLG fault
    Z_LLG = (Z1*(Z2 + Z0) + Z2*Z0) / (Z1 + Z2 + Z0);
    I_LLG = V_pre / (Z_LLG + Zf);
    I_LLG_all(i) = abs(I_LLG) * base_kV / sqrt(3);
end

% --- Display Fault Current Magnitudes for All Buses ---
fprintf('\n--- Fault Current Magnitudes (in kA) ---\n');
fprintf('Bus\t\t3-Phase\t\tLG\t\tLL\t\tLLG\n');
for i = 1:9
    fprintf('%s\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\n', ...
        bus_labels{i}, I_3ph_all(i), I_LG_all(i), I_LL_all(i), I_LLG_all(i));
end

% --- Create Main Figure with Tabs ---
main_fig = figure('Name', 'Power System Fault Analysis', 'NumberTitle', 'off');
set(main_fig, 'WindowState', 'maximized'); % Full screen

% Create tab group
tabgroup = uitabgroup(main_fig);

% --- TAB 1: Fault Current Table ---
tab1 = uitab(tabgroup, 'Title', 'Fault Current Table');

% Create table data
table_data = [I_3ph_all', I_LG_all', I_LL_all', I_LLG_all'];
column_names = {'3-Phase (kA)', 'LG (kA)', 'LL (kA)', 'LLG (kA)'};
row_names = bus_labels;

% Create uitable
fault_table = uitable(tab1, 'Data', table_data, ...
                      'ColumnName', column_names, ...
                      'RowName', row_names, ...
                      'Position', [50 50 600 300]);

% Add title and summary statistics
uicontrol(tab1, 'Style', 'text', ...
          'String', 'Fault Current Analysis Results', ...
          'FontSize', 16, 'FontWeight', 'bold', ...
          'Position', [50 400 600 30]);

% Add summary statistics
summary_text = sprintf(['Summary Statistics:\n' ...
                       'Maximum 3-Phase Fault Current: %.3f kA at %s\n' ...
                       'Maximum LG Fault Current: %.3f kA at %s\n' ...
                       'Maximum LL Fault Current: %.3f kA at %s\n' ...
                       'Maximum LLG Fault Current: %.3f kA at %s'], ...
                       max(I_3ph_all), bus_labels{find(I_3ph_all == max(I_3ph_all), 1)}, ...
                       max(I_LG_all), bus_labels{find(I_LG_all == max(I_LG_all), 1)}, ...
                       max(I_LL_all), bus_labels{find(I_LL_all == max(I_LL_all), 1)}, ...
                       max(I_LLG_all), bus_labels{find(I_LLG_all == max(I_LLG_all), 1)});

uicontrol(tab1, 'Style', 'text', ...
          'String', summary_text, ...
          'FontSize', 12, ...
          'HorizontalAlignment', 'left', ...
          'Position', [700 200 400 150]);

% --- TAB 2: Bar Graph for Fault Currents ---
tab2 = uitab(tabgroup, 'Title', 'Fault Current Comparison');

% Create axes in tab2
ax2 = axes('Parent', tab2);
bar_data = [I_3ph_all; I_LG_all; I_LL_all; I_LLG_all]';
bar(ax2, bar_data, 'grouped');
set(ax2, 'XTickLabel', bus_labels);
ylabel(ax2, 'Fault Current (kA)', 'FontSize', 12);
xlabel(ax2, 'Bus Number', 'FontSize', 12);
legend(ax2, {'3-Phase','LG','LL','LLG'}, 'Location', 'best');
title(ax2, 'Short Circuit Fault Currents at All Buses', 'FontSize', 14, 'FontWeight', 'bold');
grid(ax2, 'on');
set(ax2, 'FontSize', 10);

% Add color coding for better visualization
colormap(ax2, [0.2 0.6 0.8; 0.8 0.2 0.2; 0.2 0.8 0.2; 0.8 0.8 0.2]);

% --- TAB 3: Relay Coordination Timeline for Bus 5 ---
tab3 = uitab(tabgroup, 'Title', 'Relay Coordination');

% ETAP relay operation times for Bus 5
relay_names = {'Relay2', 'T1\_HS2', 'T1\_LS2'};
relay_times = [20.0, 83.3, 83.3]; % in milliseconds

% Simulate ideal current waveform for Bus 5 fault
fs = 10000; % Sampling rate (Hz)
t = 0:1/fs:0.1; % Time vector: 0 to 100 ms
f = 50; % System frequency
I_bus5_peak = max(I_3ph_all); % 3-phase fault current magnitude
I_fault = I_bus5_peak * sin(2*pi*f*t); % Fault current waveform

% Simulate breaker clearing the fault at 83.3 ms
I_fault(t*1000 > 83.3) = 0; % Zero current after breaker opens

% Create axes in tab3
ax3 = axes('Parent', tab3);
plot(ax3, t*1000, I_fault, 'b', 'LineWidth', 2); 
hold(ax3, 'on');

% Add relay operation markers
for i = 1:length(relay_times)
    x = relay_times(i);
    y = I_bus5_peak * sin(2*pi*f*x/1000);
    plot(ax3, [x x], [-I_bus5_peak I_bus5_peak], 'r--', 'LineWidth', 2);
    text(ax3, x + 1, y, [relay_names{i} ' (' num2str(x) ' ms)'], ...
         'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold');
end

% Add fault initiation marker
plot(ax3, [0 0], [-I_bus5_peak I_bus5_peak], 'g--', 'LineWidth', 2);
text(ax3, 2, I_bus5_peak*0.8, 'Fault Initiation', ...
     'FontSize', 10, 'Color', 'green', 'FontWeight', 'bold');

xlabel(ax3, 'Time (ms)', 'FontSize', 12);
ylabel(ax3, 'Fault Current (kA)', 'FontSize', 12);
title(ax3, 'Relay Coordination Timeline with Breaker Clearing at Bus 5', ...
      'FontSize', 14, 'FontWeight', 'bold');
legend(ax3, {'Fault Current', 'Relay Operations', 'Fault Initiation'}, 'Location', 'best');
grid(ax3, 'on');
set(ax3, 'FontSize', 10);

% Add annotation box with relay information
annotation(tab3, 'textbox', [0.7 0.7 0.25 0.2], ...
           'String', sprintf(['Relay Coordination Data:\n' ...
                             'Bus 5 Fault Current: %.3f kA\n' ...
                             'Relay2 Operation: %.1f ms\n' ...
                             'T1_HS2 Operation: %.1f ms\n' ...
                             'T1_LS2 Operation: %.1f ms\n' ...
                             'Fault Cleared at: %.1f ms'], ...
                             I_3ph_all(5), relay_times(1), relay_times(2), ...
                             relay_times(3), 83.3), ...
           'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');

% --- Additional Features ---

% Add a fourth tab for individual fault type analysis
tab4 = uitab(tabgroup, 'Title', 'Individual Fault Analysis');

% Create subplot for each fault type
ax4 = axes('Parent', tab4);

% Create subplots for each fault type
subplot(2,2,1, 'Parent', tab4);
bar(I_3ph_all, 'FaceColor', [0.2 0.6 0.8]);
set(gca, 'XTickLabel', bus_labels);
title('3-Phase Fault Currents', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current (kA)');
grid on;

subplot(2,2,2, 'Parent', tab4);
bar(I_LG_all, 'FaceColor', [0.8 0.2 0.2]);
set(gca, 'XTickLabel', bus_labels);
title('Line-to-Ground Fault Currents', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current (kA)');
grid on;

subplot(2,2,3, 'Parent', tab4);
bar(I_LL_all, 'FaceColor', [0.2 0.8 0.2]);
set(gca, 'XTickLabel', bus_labels);
title('Line-to-Line Fault Currents', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current (kA)');
xlabel('Bus Number');
grid on;

subplot(2,2,4, 'Parent', tab4);
bar(I_LLG_all, 'FaceColor', [0.8 0.8 0.2]);
set(gca, 'XTickLabel', bus_labels);
title('Line-to-Line-to-Ground Fault Currents', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current (kA)');
xlabel('Bus Number');
grid on;

% Add overall title for the subplot
sgtitle('Individual Fault Type Analysis for All Buses', 'FontSize', 16, 'FontWeight', 'bold');

fprintf('\n=== Analysis Complete ===\n');
fprintf('Full-screen tabbed interface created with:\n');
fprintf('• Tab 1: Fault Current Table with Summary Statistics\n');
fprintf('• Tab 2: Comparative Bar Graph for All Fault Types\n');
fprintf('• Tab 3: Relay Coordination Timeline for Bus 5\n');
fprintf('• Tab 4: Individual Fault Type Analysis\n');
fprintf('Navigate between tabs to explore different aspects of the analysis.\n');

% Add overall title for the subplot
sgtitle('Individual Fault Type Analysis for All Buses', 'FontSize', 16, 'FontWeight', 'bold');

% --- VERIFICATION CHECKLIST ---
fprintf('\n=== VERIFICATION CHECKLIST ===\n');
fprintf('Please verify the following results against ETAP simulation:\n');
fprintf('-----------------------------------------------------------\n');

% 3-Phase Fault Verification
fprintf('\n1. 3-PHASE FAULT CURRENT VERIFICATION:\n');
for i = 1:9
    fprintf('   %s: %.3f kA - [ ] Matches ETAP results\n', bus_labels{i}, I_3ph_all(i));
end

% Line-to-Ground Fault Verification
fprintf('\n2. LINE-TO-GROUND FAULT CURRENT VERIFICATION:\n');
for i = 1:9
    fprintf('   %s: %.3f kA - [ ] Matches ETAP results\n', bus_labels{i}, I_LG_all(i));
end

% Line-to-Line Fault Verification
fprintf('\n3. LINE-TO-LINE FAULT CURRENT VERIFICATION:\n');
for i = 1:9
    fprintf('   %s: %.3f kA - [ ] Matches ETAP results\n', bus_labels{i}, I_LL_all(i));
end

% Line-to-Line-to-Ground Fault Verification
fprintf('\n4. LINE-TO-LINE-TO-GROUND FAULT CURRENT VERIFICATION:\n');
for i = 1:9
    fprintf('   %s: %.3f kA - [ ] Matches ETAP results\n', bus_labels{i}, I_LLG_all(i));
end

% Relay Coordination Verification
fprintf('\n5. RELAY COORDINATION VERIFICATION (Bus 5):\n');
fprintf('   Relay2 Operation Time: %.1f ms - [ ] Matches ETAP results\n', relay_times(1));
fprintf('   T1_HS2 Operation Time: %.1f ms - [ ] Matches ETAP results\n', relay_times(2));
fprintf('   T1_LS2 Operation Time: %.1f ms - [ ] Matches ETAP results\n', relay_times(3));
fprintf('   Fault Clearing Time: 83.3 ms - [ ] Matches ETAP results\n');

% System Parameters Verification
fprintf('\n6. SYSTEM PARAMETERS VERIFICATION:\n');
fprintf('   Base MVA: %.0f MVA - [ ] Matches ETAP system base\n', base_MVA);
fprintf('   Base kV: %.2f kV - [ ] Matches ETAP system base\n', base_kV);
fprintf('   Base Impedance: %.3f Ohms - [ ] Matches ETAP calculations\n', Z_base);

% Critical Bus Identification
fprintf('\n7. CRITICAL BUS ANALYSIS:\n');
[max_3ph, max_3ph_idx] = max(I_3ph_all);
[max_LG, max_LG_idx] = max(I_LG_all);
[max_LL, max_LL_idx] = max(I_LL_all);
[max_LLG, max_LLG_idx] = max(I_LLG_all);

fprintf('   Highest 3-Phase Fault Current: %s (%.3f kA) - [ ] Matches ETAP critical bus\n', ...
        bus_labels{max_3ph_idx}, max_3ph);
fprintf('   Highest LG Fault Current: %s (%.3f kA) - [ ] Matches ETAP critical bus\n', ...
        bus_labels{max_LG_idx}, max_LG);
fprintf('   Highest LL Fault Current: %s (%.3f kA) - [ ] Matches ETAP critical bus\n', ...
        bus_labels{max_LL_idx}, max_LL);
fprintf('   Highest LLG Fault Current: %s (%.3f kA) - [ ] Matches ETAP critical bus\n', ...
        bus_labels{max_LLG_idx}, max_LLG);

% Impedance Data Verification
fprintf('\n8. IMPEDANCE DATA VERIFICATION:\n');
fprintf('   Verify the following impedance values match ETAP Pages 9 & 11:\n');
for i = 1:9
    fprintf('   %s: R1=%.3f, X1=%.3f, R0=%.3f, X0=%.3f Ohms - [ ] Matches ETAP\n', ...
            bus_labels{i}, impedance_data(i,1), impedance_data(i,2), ...
            impedance_data(i,3), impedance_data(i,4));
end

% Calculation Method Verification
fprintf('\n9. CALCULATION METHOD VERIFICATION:\n');
fprintf('   [ ] Positive sequence impedance (Z1) used correctly\n');
fprintf('   [ ] Negative sequence impedance (Z2 = Z1) assumption verified\n');
fprintf('   [ ] Zero sequence impedance (Z0) values match ETAP\n');
fprintf('   [ ] Fault impedance (Zf = 0) for solid faults confirmed\n');
fprintf('   [ ] Pre-fault voltage (V = 1.0 pu) assumption verified\n');

% Conversion Factor Verification
fprintf('\n10. CONVERSION FACTOR VERIFICATION:\n');
conversion_factor = base_kV / sqrt(3);
fprintf('    Current conversion factor: %.4f - [ ] Matches ETAP conversion\n', conversion_factor);
fprintf('    Formula: I_actual = I_pu * (base_kV / sqrt(3))\n');

fprintf('\n=== END OF VERIFICATION CHECKLIST ===\n');
fprintf('-----------------------------------------------------------\n');
fprintf('NOTE: Check each box [ ] after verifying against ETAP results\n');
fprintf('If any values do not match, review impedance data and calculation methods.\n');

fprintf('\n=== Analysis Complete ===\n');
fprintf('Full-screen tabbed interface created with:\n');
fprintf('• Tab 1: Fault Current Table with Summary Statistics\n');
fprintf('• Tab 2: Comparative Bar Graph for All Fault Types\n');
fprintf('• Tab 3: Relay Coordination Timeline for Bus 5\n');
fprintf('• Tab 4: Individual Fault Type Analysis\n');
fprintf('Navigate between tabs to explore different aspects of the analysis.\n');
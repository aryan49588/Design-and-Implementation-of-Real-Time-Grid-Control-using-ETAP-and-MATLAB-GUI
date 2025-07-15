
%% System Base Values
S_base = 100e6;  % 100 MVA
n_bus = 9;

% Nominal voltage of each bus (in kV)
V_base = [11.3 20 20 20 11 20 20 20 55];

% Base impedance for each bus
Z_base = (V_base.^2) * 1e3 / S_base;

%% Approximate Zbus Positive Sequence (simplified estimate)
Zbus_pos = [
    0.10 0.01 0    0    0    0    0    0    0;
    0.01 0.25 0.02 0    0    0.1  0    0    0;
    0    0.02 0.30 0.03 0    0    0    0    0;
    0    0    0.03 0.28 0.02 0    0.1  0    0;
    0    0    0    0.02 0.15 0    0    0    0;
    0    0.1  0    0    0    0.22 0.04 0.01 0;
    0    0    0    0.1  0    0.04 0.18 0.02 0;
    0    0    0    0    0    0.01 0.02 0.20 0.05;
    0    0    0    0    0    0    0    0.05 0.12
];

% Assumed Z0 = 0.81 + j2.15 for all buses (same as Bus 7)
Z0 = 0.81 + 2.15j;

fprintf('Bus | 3ϕ Fault (kA) | LG Fault (kA) | LL Fault (kA) | LLG Fault (kA)\n');
fprintf('----|----------------|----------------|----------------|----------------\n');


%% System Base Values
S_base = 100e6;  % 100 MVA
n_bus = 9;

% Nominal voltage of each bus (in kV)
V_base = [11.3 20 20 20 11 20 20 20 55];

%% Base Impedance
Z_base = (V_base.^2) * 1e3 / S_base;

%% Approximated Zbus Positive Sequence (from ETAP)
Zbus_pos = [
    0.10 0.01 0    0    0    0    0    0    0;
    0.01 0.25 0.02 0    0    0.1  0    0    0;
    0    0.02 0.30 0.03 0    0    0    0    0;
    0    0    0.03 0.28 0.02 0    0.1  0    0;
    0    0    0    0.02 0.15 0    0    0    0;
    0    0.1  0    0    0    0.22 0.04 0.01 0;
    0    0    0    0.1  0    0.04 0.18 0.02 0;
    0    0    0    0    0    0.01 0.02 0.20 0.05;
    0    0    0    0    0    0    0    0.05 0.12
];

Z0 = 0.81 + 2.15j;  % Assumed zero-sequence impedance

% Storage Arrays
If_3ph = zeros(1, n_bus);
If_lg  = zeros(1, n_bus);
If_ll  = zeros(1, n_bus);
If_llg = zeros(1, n_bus);

%% Fault Current Calculations
for bus = 1:n_bus
    V_kV = V_base(bus);
    Z1 = Zbus_pos(bus, bus);  % Positive sequence
    Z2 = Z1;                  % Assuming Z1 = Z2

    % 3-Phase Fault
    If_3ph(bus) = abs((V_kV * 1e3) / (sqrt(3) * Z1));

    % LG Fault
    If_lg(bus) = abs(3 * (V_kV * 1e3) / (Z1 + Z2 + Z0));

    % LL Fault
    If_ll(bus) = abs((V_kV * 1e3) / (Z1 + Z2));

    % LLG Fault (approximate as 1.5 × LG)
    If_llg(bus) = 1.5 * If_lg(bus);
end

%% Convert to kA
If_3ph = If_3ph / 1e3;
If_lg  = If_lg  / 1e3;
If_ll  = If_ll  / 1e3;
If_llg = If_llg / 1e3;

%% Plotting
bus_ids = 1:n_bus;

figure('Name','Short-Circuit Fault Currents at All Buses','NumberTitle','off','Color','w', ...
       'Units','normalized','Position',[0.05 0.1 0.9 0.8]);

subplot(2,2,1)
bar(bus_ids, If_3ph, 'FaceColor', [0.2 0.6 1])
title('3-Phase Fault Current at Each Bus')
xlabel('Bus Number')
ylabel('Current (kA)')
grid on

subplot(2,2,2)
bar(bus_ids, If_lg, 'FaceColor', [0.8 0.4 0.4])
title('Line-to-Ground (LG) Fault Current')
xlabel('Bus Number')
ylabel('Current (kA)')
grid on

subplot(2,2,3)
bar(bus_ids, If_ll, 'FaceColor', [0.4 0.8 0.6])
title('Line-to-Line (LL) Fault Current')
xlabel('Bus Number')
ylabel('Current (kA)')
grid on

subplot(2,2,4)
bar(bus_ids, If_llg, 'FaceColor', [0.7 0.5 1])
title('Line-to-Line-to-Ground (LLG) Fault Current')
xlabel('Bus Number')
ylabel('Current (kA)')
grid on

for bus = 1:n_bus
    V_kV = V_base(bus);
    Z1 = Zbus_pos(bus, bus); % Z1 = Z2 assumed same
    Z2 = Z1;

    %% 1. 3-Phase Fault
    If_3ph = (V_kV * 1e3) / (sqrt(3) * Z1);

    %% 2. LG Fault
    If_lg = 3 * (V_kV * 1e3) / (Z1 + Z2 + Z0);

    %% 3. LL Fault
    If_ll = (V_kV * 1e3) / (Z1 + Z2);

    %% 4. LLG Fault (approx as 1.5 × LG)
    If_llg = 1.5 * If_lg;

    %% Display Results
    fprintf(' %2d |    %8.2f    |    %8.2f    |    %8.2f    |    %8.2f\n', ...
        bus, abs(If_3ph)/1e3, abs(If_lg)/1e3, abs(If_ll)/1e3, abs(If_llg)/1e3);
end

%% Relay Coordination Data (from ETAP report page 12)

% Relay and Breaker coordination times (in ms)
relays = {
    'Relay3 - OC1-50', 2.1, 12.714;
    'Relay4 - OC1-50', 2.1, 17.067;
    'Relay6 - OC1-50', 2.1, 12.285;
    'Relay1 - 87',    20.0, 20.0;
    'Relay4 - 87',    20.0, 20.0;
    'Relay5 - 87',    20.0, 20.0;
    'Relay1 - OC1-51',99.4, 6.655;
    'Relay3 - OC1-51',99.4, 12.714;
    'Relay4 - OC1-51',99.4, 17.067;
    'Relay6 - OC1-51',99.4, 12.285;
};

breakers = {
    'CB_4', 52.1;
    'CB_3', 85.4;
    'CB_5', 85.4;
    'CB_12',85.4;
    'CB_13',85.4;
    'CB_1', 103;
    'CB_2', 103;
    'CB_10',103;
    'CB_4 (OC1-51)', 149;
    'CB_1 (OC1-51)', 183;
    'CB_2 (OC1-51)', 183;
    'CB_3 (OC1-51)', 183;
    'CB_5 (OC1-51)', 183;
    'CB_12 (OC1-51)',183;
    'CB_13 (OC1-51)',183;
};

%% Plot Relay Pickup and Breaker Tripping Timeline
figure('Name','Relay Coordination Timeline','NumberTitle','off','Color','w', ...
       'Units','normalized','Position',[0.2 0.2 0.6 0.6]);

% Relay pickups
subplot(2,1,1)
hold on
for i = 1:size(relays,1)
    bar(i, relays{i,2}, 0.5, 'FaceColor', [0.6 0.2 0.8])
end
title('Relay Pickup Times')
ylabel('Time (ms)')
set(gca, 'XTick', 1:size(relays,1), 'XTickLabel', relays(:,1), 'XTickLabelRotation', 45)
grid on

% Breaker trips
subplot(2,1,2)
hold on
for i = 1:size(breakers,1)
    bar(i, breakers{i,2}, 0.5, 'FaceColor', [0.2 0.6 1])
end
title('Breaker Trip Times')
ylabel('Time (ms)')
set(gca, 'XTick', 1:size(breakers,1), 'XTickLabel', breakers(:,1), 'XTickLabelRotation', 45)
grid on

%% Fault Current Signal Parameters
f = 60;                        % Fault frequency in Hz
t = 0:0.1:100;                 % Time in ms
omega = 2 * pi * f / 1000;     % Angular frequency in ms
I_peak = 10;                   % Peak fault current (kA)
Ifault = I_peak * sin(omega * t);  % Fault current waveform

%% Relay Trip Data (Sample from ETAP)
relays = {
    'Relay3 - OC1-50', 12.714;
    'Relay4 - OC1-50', 17.067;
    'Relay6 - OC1-50', 12.285;
    'Relay1 - 87',     20.000;
};

%% ✅ Display Relay Coordination Info in Command Window
fprintf('\n=== Relay Coordination Results ===\n');
fprintf('%-20s | Trip Time (ms)\n', 'Relay Name');
fprintf('----------------------|----------------\n');
for i = 1:size(relays, 1)
    fprintf('%-20s |    %6.3f\n', relays{i,1}, relays{i,2});
end

%% ✅ Plotting Relay Coordination on Fault Current
figure('Name','Relay Coordination on Fault Current','Color','w', ...
       'Units','normalized','Position',[0.15 0.1 0.7 0.6]);

plot(t, Ifault, 'b', 'LineWidth', 2)
hold on

for i = 1:size(relays, 1)
    trip_time = relays{i,2};
    xline(trip_time, '--r', 'LineWidth', 1.5);
    text(trip_time + 1, 0.5 * I_peak, ...
        sprintf('%s (%.1f ms)', relays{i,1}, trip_time), ...
        'Color', 'r', 'FontSize', 9);
end

title('Relay Coordination Timeline for 3-Phase Fault at Bus 7')
xlabel('Time (ms)')
ylabel('Fault Current (kA)')
ylim([-1.1*I_peak, 1.1*I_peak])
legend('Fault Current', 'Relay Trips', 'Location', 'northeast')
grid on



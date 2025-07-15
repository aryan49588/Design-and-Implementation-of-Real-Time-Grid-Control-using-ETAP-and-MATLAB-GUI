function GridControl_GUI()
    % Load ETAP data from analyzed PDFs (Simulated Here - Replace with Parsed Data)
    gridData = loadETAPData();
    
    % Global variables for real-time monitoring
    global monitoringActive plotHandles timeData voltageData powerData;
    monitoringActive = false(5,1);
    plotHandles = struct();
    timeData = cell(5,1);
    voltageData = cell(5,1);
    powerData = cell(5,1);
    
    % Initialize data arrays
    for g = 1:5
        timeData{g} = [];
        voltageData{g} = [];
        powerData{g} = [];
    end

    % Create the main GUI figure (fullscreen)
    scr = get(0,'ScreenSize');
    hFig = figure('Name','Unified Grid Control Center','NumberTitle','off',...
                  'MenuBar','none','ToolBar','none','Color',[0.94 0.94 0.94],...
                  'Position', [0 0 scr(3) scr(4)]);

    % Create tab group for 7 tabs
    tgroup = uitabgroup('Parent',hFig);
    tabNames = {"Grid 1 - Load Flow & Faults", "Grid 2 - Load Flow & Faults", ...
                "Grid 3 - Load Flow & Faults", "Grid 4 - Load Flow & Faults", ...
                "Grid 5 - Load Flow & Faults", "Unified Real-Time Grid Control", ...
                "Alert & Abnormalities Monitor"};

    for i = 1:length(tabNames)
        tabs(i) = uitab('Parent',tgroup,'Title',tabNames{i});
    end

    %% Tab 1 to 5: Grid Visualization with ETAP Values
    for g = 1:5
        data = gridData(g);

        % 1st Quarter (Top Left): System Overview
        uitable('Parent',tabs(g), 'Data', data.overview, 'ColumnName', data.headers, ...
                'Units','normalized', 'Position',[0.01 0.51 0.48 0.48], 'FontSize',10);

        % 2nd Quarter (Top Right): Voltage Profile
        ax1 = axes('Parent',tabs(g), 'Position',[0.51 0.51 0.48 0.48]);
        bar(ax1, data.bus, data.voltages, 'FaceColor', [0.2 0.6 1]);
        title(ax1, sprintf('Grid %d: Bus Voltages', g));
        xlabel(ax1, 'Bus Number'); ylabel(ax1, 'Voltage (p.u.)');
        grid(ax1, 'on');

        % 3rd Quarter (Bottom Left): Fault Current Table
        faultTable = [num2cell(data.bus)', num2cell(data.fault_3ph)', num2cell(data.fault_LG)', ...
                      num2cell(data.fault_LL)', num2cell(data.fault_LLG)'];
        uitable('Parent',tabs(g), 'Data', faultTable, 'ColumnName', {'Bus','3-Ph','LG','LL','LLG'}, ...
                'Units','normalized', 'Position',[0.01 0.01 0.48 0.48], 'FontSize',10);

        % 4th Quarter (Bottom Right): Fault Current Plots
        ax2 = axes('Parent',tabs(g), 'Position',[0.51 0.01 0.48 0.48]);
        hold(ax2,'on');
        plot(ax2, data.bus, data.fault_3ph, '-or','DisplayName','3-Ph');
        plot(ax2, data.bus, data.fault_LG, '-ob','DisplayName','L-G');
        plot(ax2, data.bus, data.fault_LL, '-og','DisplayName','L-L');
        plot(ax2, data.bus, data.fault_LLG, '-om','DisplayName','L-L-G');
        title(ax2, sprintf('Grid %d: Fault Current at Each Bus', g));
        xlabel(ax2, 'Bus Number'); ylabel(ax2, 'Current (kA)');
        legend(ax2, 'Location','best');
        grid(ax2,'on');
        hold(ax2,'off');
    end

    %% Tab 6: Unified Grid Control - FIXED SPACING
    controlPanelTitles = {"Grid 1", "Grid 2", "Grid 3", "Grid 4", "Grid 5"};
    sliderHandles = struct();
    
    for g = 1:5
        xOffset = 0.02 + (g-1)*0.19;
        panel = uipanel('Parent',tabs(6), 'Title', controlPanelTitles{g}, 'FontSize', 12, 'Position', [xOffset, 0.05, 0.18, 0.9]);

        % UI Labels, Sliders, and Value Display
        labels = {'Voltage (p.u.)', 'Power (MW)', 'Load Factor', 'Loading (%)'};
        mins = [0.9, 0, 0.5, 0];
        maxs = [1.1, 100, 1.5, 100];
        values = [1.0, 50, 1.0, 70];
        sliderFields = {'V','P','LF','LD'};

        for i = 1:4
            ypos = 0.90 - (i-1)*0.12;
            
            % Label
            uicontrol('Parent',panel, 'Style','text', 'String', labels{i}, 'Units','normalized', ...
                'Position',[0.05 ypos 0.9 0.04], 'HorizontalAlignment','center', 'FontSize', 10);
            
            % Slider
            sliderHandles(g).(sliderFields{i}) = uicontrol('Parent',panel, 'Style','slider', 'Min', mins(i), 'Max', maxs(i), 'Value', values(i), ...
                'Units','normalized', 'Position',[0.05 ypos-0.04 0.6 0.03], 'Tag', sprintf('G%d_%s', g, sliderFields{i}));
            
            % Value display
            sliderHandles(g).([sliderFields{i} '_Label']) = uicontrol('Parent',panel, 'Style','text', 'String', sprintf('%.2f', values(i)), ...
                'Units','normalized', 'Position',[0.7 ypos-0.04 0.25 0.03], 'HorizontalAlignment','center', 'FontSize', 9);
            
            % Add callback for interactive update
            set(sliderHandles(g).(sliderFields{i}), 'Callback', @(src,~) updateSliderValue(src, sliderHandles(g).([sliderFields{i} '_Label'])));
        end

        % Real-time Plot Areas (moved down to avoid overlap)
        axV = axes('Parent',panel, 'Units','normalized', 'Position',[0.05 0.25 0.4 0.12]);
        axP = axes('Parent',panel, 'Units','normalized', 'Position',[0.55 0.25 0.4 0.12]);
        title(axV, 'Bus Voltage Monitoring', 'FontSize', 8); 
        xlabel(axV,'Time (s)', 'FontSize', 8); ylabel(axV,'Voltage (p.u.)', 'FontSize', 8);
        title(axP, 'Power Flow Monitoring', 'FontSize', 8); 
        xlabel(axP,'Time (s)', 'FontSize', 8); ylabel(axP,'Power (MW)', 'FontSize', 8);
        grid(axV, 'on'); grid(axP, 'on');
        
        % Store axes handles
        plotHandles(g).axV = axV;
        plotHandles(g).axP = axP;

        % Start/Stop Buttons (moved up to fit better)
        uicontrol('Parent',panel, 'Style','pushbutton', 'String','Start Monitoring', 'BackgroundColor',[0.2 0.8 0.2], ...
            'Units','normalized', 'Position',[0.05 0.08 0.4 0.06], 'FontSize', 9, ...
            'Callback', @(~,~) startMonitoring(g, sliderHandles(g)));
        uicontrol('Parent',panel, 'Style','pushbutton', 'String','Stop Monitoring', 'BackgroundColor',[0.8 0.2 0.2], ...
            'Units','normalized', 'Position',[0.55 0.08 0.4 0.06], 'FontSize', 9, ...
            'Callback', @(~,~) stopMonitoring(g));
    end

    %% Tab 7: Alert Monitor
    for g = 1:5
        xOffset = 0.02 + (g-1)*0.19;
        panel = uipanel('Parent',tabs(7), 'Title', sprintf('Grid %d Alerts & Events', g), ...
            'FontSize', 12, 'Position', [xOffset, 0.05, 0.18, 0.9]);

        % System Status Section
        uicontrol('Parent',panel, 'Style','text', 'String','System Status', 'Units','normalized', ...
            'Position',[0.05 0.85 0.9 0.05], 'HorizontalAlignment','center', 'FontWeight','bold');

        % Status Light Indicators
        statusLabels = {'Voltage', 'Frequency', 'Loading'};
        statusColors = {'green', 'green', 'yellow'}; % Different statuses
        if g == 2, statusColors{1} = 'red'; end % Grid 2 has voltage issue
        if g == 4, statusColors{3} = 'red'; end % Grid 4 has loading issue

        for i = 1:3
            ypos = 0.75 - (i-1)*0.08;
            % Status label
            uicontrol('Parent',panel, 'Style','text', 'String', statusLabels{i}, 'Units','normalized', ...
                'Position',[0.05 ypos 0.6 0.05], 'HorizontalAlignment','left', 'FontSize', 9);
            % Status indicator
            uicontrol('Parent',panel, 'Style','text', 'String', '●', 'Units','normalized', ...
                'Position',[0.7 ypos 0.2 0.05], 'HorizontalAlignment','center', 'FontSize', 14, ...
                'ForegroundColor', statusColors{i});
        end

        % Alerts & Events List
        uicontrol('Parent',panel, 'Style','text', 'String','Alerts & Events', 'Units','normalized', ...
            'Position',[0.05 0.45 0.9 0.05], 'HorizontalAlignment','center', 'FontWeight','bold');

        % Generate alerts based on grid
        alertMessages = generateAlerts(g);
        
        % Scrollable listbox for alerts
        alertListbox = uicontrol('Parent',panel, 'Style','listbox', 'Units','normalized', ...
            'Position',[0.05 0.05 0.9 0.38], 'FontSize', 8, 'String', alertMessages);
        
        % Auto-scroll to bottom
        if ~isempty(alertMessages)
            set(alertListbox, 'Value', length(alertMessages));
        end
    end

    % Start a timer for real-time updates
    tmr = timer('TimerFcn', @(~,~) updateRealTimeData(), 'Period', 0.5, 'ExecutionMode', 'fixedSpacing');
    start(tmr);
    
    % Store timer in figure for cleanup
    setappdata(hFig, 'Timer', tmr);
    
    % Cleanup function
    set(hFig, 'CloseRequestFcn', @(~,~) cleanupGUI(hFig));
end

%% Helper Functions

function updateSliderValue(sliderHandle, labelHandle)
    value = get(sliderHandle, 'Value');
    set(labelHandle, 'String', sprintf('%.2f', value));
end

function startMonitoring(gridNum, handles)
    global monitoringActive timeData voltageData powerData;
    monitoringActive(gridNum) = true;
    
    % Initialize data arrays
    timeData{gridNum} = [];
    voltageData{gridNum} = [];
    powerData{gridNum} = [];
    
    fprintf('Started monitoring for Grid %d\n', gridNum);
end

function stopMonitoring(gridNum)
    global monitoringActive plotHandles;
    monitoringActive(gridNum) = false;
    
    % Clear plots
    cla(plotHandles(gridNum).axV);
    cla(plotHandles(gridNum).axP);
    title(plotHandles(gridNum).axV, 'Bus Voltage Monitoring', 'FontSize', 8);
    title(plotHandles(gridNum).axP, 'Power Flow Monitoring', 'FontSize', 8);
    grid(plotHandles(gridNum).axV, 'on');
    grid(plotHandles(gridNum).axP, 'on');
    
    fprintf('Stopped monitoring for Grid %d\n', gridNum);
end

function updateRealTimeData()
    global monitoringActive plotHandles timeData voltageData powerData;
    
    for g = 1:5
        if monitoringActive(g)
            % Generate new data point
            if isempty(timeData{g})
                timeData{g} = 0;
                voltageData{g} = 0.95 + 0.05*rand();
                powerData{g} = 60 + 10*rand();
            else
                timeData{g}(end+1) = timeData{g}(end) + 0.5;
                % Add some realistic variation
                voltageData{g}(end+1) = 0.95 + 0.05*sin(0.1*timeData{g}(end)) + 0.01*rand();
                powerData{g}(end+1) = 60 + 10*sin(0.15*timeData{g}(end)) + 5*rand();
            end
            
            % Keep only last 60 data points (30 seconds)
            if length(timeData{g}) > 60
                timeData{g} = timeData{g}(end-59:end);
                voltageData{g} = voltageData{g}(end-59:end);
                powerData{g} = powerData{g}(end-59:end);
            end
            
            % Update plots
            try
                % Voltage plot
                plot(plotHandles(g).axV, timeData{g}, voltageData{g}, 'b-', 'LineWidth', 1.5);
                title(plotHandles(g).axV, 'Bus Voltage Monitoring', 'FontSize', 8);
                xlabel(plotHandles(g).axV, 'Time (s)', 'FontSize', 8);
                ylabel(plotHandles(g).axV, 'Voltage (p.u.)', 'FontSize', 8);
                grid(plotHandles(g).axV, 'on');
                ylim(plotHandles(g).axV, [0.9 1.1]);
                
                % Power plot
                plot(plotHandles(g).axP, timeData{g}, powerData{g}, 'r-', 'LineWidth', 1.5);
                title(plotHandles(g).axP, 'Power Flow Monitoring', 'FontSize', 8);
                xlabel(plotHandles(g).axP, 'Time (s)', 'FontSize', 8);
                ylabel(plotHandles(g).axP, 'Power (MW)', 'FontSize', 8);
                grid(plotHandles(g).axP, 'on');
                ylim(plotHandles(g).axP, [40 90]);
                
                drawnow limitrate;
            catch ME
                % Handle any plotting errors
                fprintf('Plot update error for Grid %d: %s\n', g, ME.message);
            end
        end
    end
end

function alerts = generateAlerts(gridNum)
    % Generate realistic alerts based on grid number
    % Fixed: Using proper cell array concatenation
    
    % Base alerts - always present
    alerts = {};
    alerts{end+1} = sprintf('[%s] System Initialized', datestr(now, 'HH:MM:SS'));
    alerts{end+1} = sprintf('[%s] Grid %d monitoring started', datestr(now-0.001, 'HH:MM:SS'), gridNum);
    alerts{end+1} = sprintf('[%s] All parameters nominal', datestr(now-0.002, 'HH:MM:SS'));
    
    % Add specific alerts based on grid number
    switch gridNum
        case 1
            alerts{end+1} = sprintf('[%s] Transformer T1 loading: 82.8%% (Normal)', datestr(now-0.003, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Bus voltage stable', datestr(now-0.004, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Power factor: 0.92 (Good)', datestr(now-0.005, 'HH:MM:SS'));
            
        case 2
            alerts{end+1} = sprintf('[%s] WARNING: Undervoltage at Bus 5 (94.6%%)', datestr(now-0.003, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Voltage regulator activated', datestr(now-0.004, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Adjusting voltage levels...', datestr(now-0.005, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Tap changer operation initiated', datestr(now-0.006, 'HH:MM:SS'));
            
        case 3
            alerts{end+1} = sprintf('[%s] Frequency deviation: 50.2 Hz', datestr(now-0.003, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Load shedding protocol standby', datestr(now-0.004, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Governor response activated', datestr(now-0.005, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Frequency returning to normal', datestr(now-0.006, 'HH:MM:SS'));
            
        case 4
            alerts{end+1} = sprintf('[%s] ALERT: Transformer overload (95.4%%)', datestr(now-0.003, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Load transfer initiated', datestr(now-0.004, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Cooling system activated', datestr(now-0.005, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Temperature rising: 78°C', datestr(now-0.006, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Backup transformer on standby', datestr(now-0.007, 'HH:MM:SS'));
            
        case 5
            alerts{end+1} = sprintf('[%s] Cable loading: 56.4%% (Normal)', datestr(now-0.003, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Power factor correction active', datestr(now-0.004, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Capacitor bank switched in', datestr(now-0.005, 'HH:MM:SS'));
            alerts{end+1} = sprintf('[%s] Reactive power balanced', datestr(now-0.006, 'HH:MM:SS'));
    end
    
    % Add some random operational messages
    if rand > 0.7
        alerts{end+1} = sprintf('[%s] Daily load peak expected at 18:00', datestr(now-0.008, 'HH:MM:SS'));
    end
    
    if rand > 0.8
        alerts{end+1} = sprintf('[%s] Maintenance scheduled for tomorrow', datestr(now-0.009, 'HH:MM:SS'));
    end
end

function cleanupGUI(figHandle)
    % Clean up timer and close figure
    tmr = getappdata(figHandle, 'Timer');
    if ~isempty(tmr) && isvalid(tmr)
        stop(tmr);
        delete(tmr);
    end
    delete(figHandle);
end

%% Simulated Data Extraction Function (To Replace with Actual Parsing)
function gridData = loadETAPData()
    % Replace this block with actual PDF parsed data
    for g = 1:5
        gridData(g).bus = 1:9;
        gridData(g).voltages = 0.95 + 0.05*rand(1,9); % Replace with actual ETAP voltages
        gridData(g).fault_3ph = 3 + 0.5*rand(1,9);
        gridData(g).fault_LG = 2.2 + 0.3*rand(1,9);
        gridData(g).fault_LL = 2.7 + 0.4*rand(1,9);
        gridData(g).fault_LLG = 4.7 + 0.6*rand(1,9);

        % Overview Table with matching ETAP values (replace with parsed table)
        gridData(g).headers = {'Bus','Voltage (kV)','Angle','P_gen','Q_gen','P_load','Q_load'};
        gridData(g).overview = [num2cell((1:9)'), ...
                                num2cell(11 + rand(9,1)), ...
                                num2cell(rand(9,1)*10), ...
                                num2cell(rand(9,1)*30), ...
                                num2cell(rand(9,1)*20), ...
                                num2cell(rand(9,1)*30), ...
                                num2cell(rand(9,1)*20)];
    end
end
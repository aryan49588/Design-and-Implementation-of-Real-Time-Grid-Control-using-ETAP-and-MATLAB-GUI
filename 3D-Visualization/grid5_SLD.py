# ============================================================
# 3D POWER SYSTEM VISUALIZATION – 9-BUS MULTI-VOLTAGE NETWORK
# ============================================================

import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import numpy as np
from matplotlib.lines import Line2D

# --------------------------
# 1. SYSTEM DEFINITION
# --------------------------

# Bus positions by voltage level (z-axis represents voltage hierarchy)
bus_positions = {
    'Bus_1': (0, 0, 3),     # 132 kV (Swing Bus)
    'Bus_2': (4, 2, 2),     # 129.4 kV
    'Bus_3': (8, 0, 2),     # 129.5 kV
    'Bus_4': (12, 2, 2),    # 129.4 kV
    'Bus_5': (16, 0, 1),    # 10.76 kV
    'Bus_6': (20, 2, 1),    # 10.76 kV (Voltage Control)
    'Bus_7': (12, -2, 2),   # 129.4 kV
    'Bus_8': (8, -4, 1),    # 10.8 kV (Voltage Control)
    'Bus_9': (4, -2, 0),    # 0.414 kV
}

# Bus voltages
bus_voltages = {
    'Bus_1': '132.0 kV', 'Bus_2': '129.4 kV', 'Bus_3': '129.5 kV',
    'Bus_4': '129.4 kV', 'Bus_5': '10.76 kV', 'Bus_6': '10.76 kV',
    'Bus_7': '129.4 kV', 'Bus_8': '10.8 kV',  'Bus_9': '0.414 kV'
}

# Bus types
bus_types = {
    'Bus_1': 'Swing Bus',
    'Bus_6': 'Voltage Control',
    'Bus_8': 'Voltage Control'
}

# Transmission line connections
connections = [
    ('Bus_2', 'Bus_3'),
    ('Bus_3', 'Bus_4'),
    ('Bus_5', 'Bus_6')
]

# Transformers
transformers = {
    'T1 (50 MVA)': ('Bus_1', 'Bus_2'),
    'T3 (25 MVA)': ('Bus_5', 'Bus_4'),
    'T7 (30 MVA)': ('Bus_8', 'Bus_3'),
    'T10 (15 MVA)': ('Bus_8', 'Bus_9'),
    'T12 (20 MVA)': ('Bus_6', 'Bus_7')
}

# Generators
generators = {
    'Gen1 (Swing Bus)': 'Bus_1',
    'Gen2 (60 MW)': 'Bus_6',
    'Gen3 (40 MW)': 'Bus_8'
}

# Loads
loads = {
    'Load (45.2 MW, 32.1 Mvar)': 'Bus_2',
    'Load (28.7 MW, 22.3 Mvar)': 'Bus_3',
    'Load (33.6 MW, 25.8 Mvar)': 'Bus_4',
    'Load (18.9 MW, 15.2 Mvar)': 'Bus_5',
    'Load (22.4 MW, 17.8 Mvar)': 'Bus_7',
    'Load (12.3 MW, 9.6 Mvar)': 'Bus_9'
}

# --------------------------
# 2. PLOTTING STARTS
# --------------------------

fig = plt.figure(figsize=(16, 12))
ax = fig.add_subplot(111, projection='3d')

# Voltage level colors
voltage_colors = {
    3: 'red',      # 132 kV
    2: 'blue',     # 129 kV
    1: 'green',    # 11 kV
    0: 'orange'    # 0.4 kV
}

# Plot buses
for bus, (x, y, z) in bus_positions.items():
    color = voltage_colors[z]
    size = 150
    if bus == 'Bus_1':
        marker = 'D'
        size = 250
    elif bus in ['Bus_6', 'Bus_8']:
        marker = 's'
        size = 200
    else:
        marker = 'o'
    
    ax.scatter(x, y, z, color=color, s=size, alpha=0.8, edgecolor='black', marker=marker)
    v_str = bus_voltages[bus]
    label_type = bus_types.get(bus, 'Load Bus')
    ax.text(x, y, z + 0.2, f"{bus}\n{v_str}\n{label_type}", ha='center', va='bottom',
            fontsize=8, weight='bold', color='black')

# Transmission lines
for b1, b2 in connections:
    x_vals = [bus_positions[b1][0], bus_positions[b2][0]]
    y_vals = [bus_positions[b1][1], bus_positions[b2][1]]
    z_vals = [bus_positions[b1][2], bus_positions[b2][2]]
    ax.plot(x_vals, y_vals, z_vals, color='gray', linewidth=2, alpha=0.7)

# Transformers
for name, (b1, b2) in transformers.items():
    x_vals = [bus_positions[b1][0], bus_positions[b2][0]]
    y_vals = [bus_positions[b1][1], bus_positions[b2][1]]
    z_vals = [bus_positions[b1][2], bus_positions[b2][2]]
    ax.plot(x_vals, y_vals, z_vals, color='purple', linewidth=3, alpha=0.8)
    
    # Midpoint label and symbol
    mx, my, mz = np.mean(x_vals), np.mean(y_vals), np.mean(z_vals)
    ax.scatter(mx, my, mz, color='purple', marker='s', s=100)
    ax.text(mx, my, mz + 0.15, name, fontsize=7, color='purple', ha='center')

# Generators
for gen, bus in generators.items():
    x, y, z = bus_positions[bus]
    gen_z = z + 0.8
    ax.plot([x, x], [y, y], [z, gen_z], color='darkgreen', linewidth=2)
    ax.scatter(x, y, gen_z, color='darkgreen', marker='^', s=120)
    ax.text(x + 0.5, y, gen_z + 0.1, gen, color='darkgreen', fontsize=8)

# Loads
offset = 0
for load, bus in loads.items():
    x, y, z = bus_positions[bus]
    load_z = z - 0.8 - offset * 0.1
    ax.plot([x, x], [y, y], [z, load_z], color='darkred', linewidth=2)
    ax.scatter(x, y, load_z, color='darkred', marker='v', s=100)
    ax.text(x - 0.5, y, load_z - 0.1, load, color='darkred', fontsize=7)
    offset += 1

# Voltage planes
xx, yy = np.meshgrid(np.linspace(-2, 22, 8), np.linspace(-5, 4, 8))
plane_defs = [(0, 'lightyellow', '0.4 kV'),
              (1, 'lightgreen', '11 kV'),
              (2, 'lightblue', '129 kV'),
              (3, 'lightcoral', '132 kV')]
for level, color, label in plane_defs:
    zz = np.full_like(xx, level)
    ax.plot_surface(xx, yy, zz, color=color, alpha=0.1)
    ax.text(22, 0, level, label, fontsize=10, weight='bold')

# Axis settings
ax.set_title('Grid 5: IEEE 9 Bus Network', fontsize=16, fontweight='bold')
ax.set_xlabel('X-axis (Geographic Distance)', fontsize=12)
ax.set_ylabel('Y-axis (Geographic Distance)', fontsize=12)
ax.set_zlabel('Z-axis (Voltage Level)', fontsize=12)
ax.set_zticks([0, 1, 2, 3])
ax.set_zticklabels(['0.4 kV\n(Distribution)', '11 kV\n(Sub-transmission)', '129 kV\n(Transmission)', '132 kV\n(High Voltage)'])
ax.grid(True, alpha=0.3)
ax.view_init(elev=25, azim=45)

# Legend
legend_items = [
    Line2D([0], [0], marker='D', color='w', markerfacecolor='red', markersize=12, label='Swing Bus (132 kV)'),
    Line2D([0], [0], marker='s', color='w', markerfacecolor='green', markersize=10, label='Voltage Control Bus (11 kV)'),
    Line2D([0], [0], marker='o', color='w', markerfacecolor='blue', markersize=10, label='Load Bus (129 kV)'),
    Line2D([0], [0], marker='o', color='w', markerfacecolor='orange', markersize=10, label='Load Bus (0.4 kV)'),
    Line2D([0], [0], marker='^', color='w', markerfacecolor='darkgreen', markersize=10, label='Generators'),
    Line2D([0], [0], marker='v', color='w', markerfacecolor='darkred', markersize=10, label='Loads'),
    Line2D([0], [0], color='gray', linewidth=2, label='Transmission Lines'),
    Line2D([0], [0], color='purple', linewidth=3, label='Transformers'),
    Line2D([0], [0], marker='s', color='w', markerfacecolor='purple', markersize=8, label='Transformer Points'),
    Line2D([0], [0], color='darkgreen', linewidth=2, label='Generator Connections'),
    Line2D([0], [0], color='darkred', linewidth=2, label='Load Connections')
]
ax.legend(handles=legend_items, loc='upper left', bbox_to_anchor=(0, 1))
print("\n" + "="*70)
print("9-BUS HIERARCHICAL POWER SYSTEM DETAILED SUMMARY - GRID TOPOLOGY")
print("="*70)

print(f"\nSYSTEM OVERVIEW:")
print(f"├── Total Buses: {len(bus_positions)}")
print(f"├── Total Generators: {len(generators)}")
print(f"├── Total Loads: {len(loads)}")
print(f"├── Total Transmission Lines: {len(connections)}")
print(f"└── Total Transformers: {len(transformers)}")

print(f"\nBUS INFORMATION & VOLTAGE RATINGS:")
print("-" * 50)
for i, (bus, voltage) in enumerate(bus_voltages.items(), 1):
    bus_type = bus_types.get(bus, 'Load Bus')
    pos = bus_positions[bus]
    print(f"{i:2d}. {bus:<8} | Voltage: {voltage:<12} | Type: {bus_type:<15} | Position: {pos}")

print(f"\nBUS CONNECTIONS (TRANSMISSION LINES):")
print("-" * 50)
for i, (bus1, bus2) in enumerate(connections, 1):
    v1 = bus_voltages.get(bus1, 'N/A')
    v2 = bus_voltages.get(bus2, 'N/A')
    print(f"{i:2d}. {bus1} ({v1}) ↔ {bus2} ({v2})")

print(f"\nTRANSFORMER CONNECTIONS:")
print("-" * 50)
for i, (trans_name, (bus1, bus2)) in enumerate(transformers.items(), 1):
    v1 = bus_voltages.get(bus1, 'N/A')
    v2 = bus_voltages.get(bus2, 'N/A')
    print(f"{i}. {trans_name}")
    print(f"   └── {bus1} ({v1}) ↔ {bus2} ({v2})")

print(f"\nGENERATOR CONNECTIONS:")
print("-" * 50)
total_gen_capacity = 100.0  # Swing + 60 MW + 40 MW
for i, (gen_name, bus) in enumerate(generators.items(), 1):
    voltage = bus_voltages.get(bus, 'N/A')
    print(f"{i}. {gen_name}")
    print(f"   └── Connected to: {bus} ({voltage})")
print(f"\nTotal Generation Capacity: {total_gen_capacity} MW")

print(f"\nLOAD CONNECTIONS:")
print("-" * 50)
total_load_capacity = 161.1  # Total load capacity
for i, (load_name, bus) in enumerate(loads.items(), 1):
    voltage = bus_voltages.get(bus, 'N/A')
    print(f"{i:2d}. {load_name}")
    print(f"    └── Connected to: {bus} ({voltage})")
print(f"\nTotal Load Capacity: {total_load_capacity} MVA")

print(f"\nVOLTAGE LEVEL ANALYSIS:")
print("-" * 50)
voltage_levels = {}
for bus, voltage in bus_voltages.items():
    if voltage not in voltage_levels:
        voltage_levels[voltage] = []
    voltage_levels[voltage].append(bus)

for voltage, buses in sorted(voltage_levels.items(), key=lambda x: float(x[0].split()[0]), reverse=True):
    print(f"• {voltage}: {', '.join(buses)}")

print(f"\nSYSTEM CHARACTERISTICS:")
print("-" * 50)
print(f"• Voltage Range: 0.414 kV to 132.0 kV")
print(f"• Voltage Levels: 4 (132 kV, 129 kV, 11 kV, 0.4 kV)")
print(f"• High Voltage Level: 132.0 kV ({len([v for v in bus_voltages.values() if v == '132.0 kV'])} bus)")
print(f"• Transmission Level: 129.4-129.5 kV ({len([v for v in bus_voltages.values() if '129' in v])} buses)")
print(f"• Sub-transmission Level: 10.76-10.8 kV ({len([v for v in bus_voltages.values() if '10.' in v])} buses)")
print(f"• Distribution Level: 0.414 kV ({len([v for v in bus_voltages.values() if v == '0.414 kV'])} bus)")
print(f"• Generation-Load Ratio: {total_gen_capacity/total_load_capacity:.2f}")
print(f"• Total Transformer Capacity: 140 MVA")
print(f"• Network Type: Hierarchical multi-voltage power system")
print(f"• Topology: Radial with interconnections at transmission level")
print(f"• System Frequency: 50 Hz")

print(f"\nLOAD DISTRIBUTION BY VOLTAGE LEVEL:")
print("-" * 50)
load_details = {
    'Bus_2 (129.4 kV)': '45.2 MW, 32.1 Mvar',
    'Bus_3 (129.5 kV)': '28.7 MW, 22.3 Mvar',
    'Bus_4 (129.4 kV)': '33.6 MW, 25.8 Mvar',
    'Bus_5 (10.76 kV)': '18.9 MW, 15.2 Mvar',
    'Bus_7 (129.4 kV)': '22.4 MW, 17.8 Mvar',
    'Bus_9 (0.414 kV)': '12.3 MW, 9.6 Mvar'
}

for bus, load_info in load_details.items():
    print(f"• {bus}: {load_info}")

print(f"\nTRANSFORMER CAPACITY ANALYSIS:")
print("-" * 50)
transformer_details = {
    'T1 (50 MVA)': '132 kV → 129.4 kV',
    'T3 (25 MVA)': '10.76 kV → 129.4 kV',
    'T7 (30 MVA)': '10.8 kV → 129.5 kV',
    'T10 (15 MVA)': '10.8 kV → 0.414 kV',
    'T12 (20 MVA)': '10.76 kV → 129.4 kV'
}

for trans, connection in transformer_details.items():
    print(f"• {trans}: {connection}")

print("\n" + "="*70)

# Set view angle for better visibility
ax.view_init(elev=25, azim=45)

# Adjust layout
plt.subplots_adjust(left=0.05, right=0.95, top=0.95, bottom=0.05)

plt.show()

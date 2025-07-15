import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import numpy as np

# Define bus positions (improved layout for better visibility)
bus_positions = {
    'Bus1': (0, 0, 0),
    'Bus2': (3, 2, 0),
    'Bus3': (6, 0, 0),
    'Bus4': (9, 2, 0),
    'Bus5': (12, 0, 0),
    'Bus6': (15, 2, 0),
    'Bus7': (9, -2, 0),
    'Bus8': (6, -4, 0),
    'Bus9': (3, -2, 0),
}

# Define all line connections based on the system topology
# Including transformer connections and transmission lines
connections = [
    # Main transmission lines based on the circuit diagram
    ('Bus1', 'Bus2'),
    ('Bus2', 'Bus3'),
    ('Bus3', 'Bus4'),
    ('Bus4', 'Bus5'),
    ('Bus5', 'Bus6'),
    ('Bus4', 'Bus7'),
    ('Bus7', 'Bus8'),
    ('Bus8', 'Bus9'),
    ('Bus9', 'Bus2'),
    
    # Additional connections for mesh topology
    ('Bus1', 'Bus9'),
    ('Bus3', 'Bus8'),
    ('Bus5', 'Bus7'),
    
    # Cable connections from diagram
    ('Bus2', 'Bus6'),  # Cable2-6
    ('Bus4', 'Bus7'),  # Cable4-7
    ('Bus7', 'Bus8'),  # Cable_7-8
]

# Define components connected to buses with their ratings
generators = {
    'Gen1 (163.2 MW)': 'Bus1',
    'Gen5 (108.8 MW)': 'Bus4',
    'Gen9 (120 MW)': 'Bus9'
}

loads = {
    'Solar Farm (10 MVA)': 'Bus2',
    'Great Lakes Tech Park (10 MVA)': 'Bus3',
    'Sewage Treatment (15 MVA)': 'Bus5',
    'Hospital (17 MVA)': 'Bus6',
    'Data Center (15 MVA)': 'Bus7',
    'Water Treatment Plant (16 MVA)': 'Bus8'
}

# Transformers
transformers = {
    'TR_1 (100 MVA)': ('Bus1', 'Bus2'),
    'TR_2 (100 MVA)': ('Bus3', 'Bus4'),
    'TR_3 (100 MVA)': ('Bus8', 'Bus9')
}

# Bus voltage levels (from the updated network)
bus_voltages = {
    'Bus1': '11.3 kV',
    'Bus2': '20 kV',
    'Bus3': '20 kV',
    'Bus4': '20 kV',
    'Bus5': '11 kV',
    'Bus6': '20 kV',
    'Bus7': '20 kV',
    'Bus8': '20 kV',
    'Bus9': '55 kV'
}

# Create the 3D plot
fig = plt.figure(figsize=(16, 12))
ax = fig.add_subplot(111, projection='3d')

# Plot buses with voltage labels
for name, (x, y, z) in bus_positions.items():
    ax.scatter(x, y, z, color='blue', s=150, alpha=0.8, edgecolor='black')
    voltage = bus_voltages.get(name, '')
    ax.text(x, y, z + 0.5, f'{name}\n{voltage}', color='black', fontsize=8, ha='center')

# Plot transmission line connections
for b1, b2 in connections:
    if b1 in bus_positions and b2 in bus_positions:
        x_vals = [bus_positions[b1][0], bus_positions[b2][0]]
        y_vals = [bus_positions[b1][1], bus_positions[b2][1]]
        z_vals = [bus_positions[b1][2], bus_positions[b2][2]]
        ax.plot(x_vals, y_vals, z_vals, color='gray', linewidth=2, alpha=0.7)

# Plot transformer connections (in different color)
for trans_name, (b1, b2) in transformers.items():
    if b1 in bus_positions and b2 in bus_positions:
        x_vals = [bus_positions[b1][0], bus_positions[b2][0]]
        y_vals = [bus_positions[b1][1], bus_positions[b2][1]]
        z_vals = [bus_positions[b1][2], bus_positions[b2][2]]
        ax.plot(x_vals, y_vals, z_vals, color='orange', linewidth=3, alpha=0.8)
        
        # Add transformer symbol at midpoint
        mid_x = (x_vals[0] + x_vals[1]) / 2
        mid_y = (y_vals[0] + y_vals[1]) / 2
        mid_z = (z_vals[0] + z_vals[1]) / 2
        ax.scatter(mid_x, mid_y, mid_z, color='orange', marker='s', s=100)
        ax.text(mid_x, mid_y, mid_z + 0.3, trans_name, color='orange', fontsize=7, ha='center')

# Plot generators with connection lines
for gen, bus in generators.items():
    if bus in bus_positions:
        x, y, z = bus_positions[bus]
        gen_z = z + 1
        
        # Draw connection line from bus to generator
        ax.plot([x, x], [y, y], [z, gen_z], color='green', linewidth=2, alpha=0.7)
        
        # Plot generator symbol
        ax.scatter(x, y, gen_z, color='green', marker='^', s=120, alpha=0.8)
        ax.text(x + 0.5, y, gen_z + 0.2, gen, color='green', fontsize=8)

# Plot loads with connection lines
load_offset = 0
for load, bus in loads.items():
    if bus in bus_positions:
        x, y, z = bus_positions[bus]
        load_z = z - 1 - load_offset*0.2
        
        # Draw connection line from bus to load
        ax.plot([x, x], [y, y], [z, load_z], color='red', linewidth=2, alpha=0.7)
        
        # Plot load symbol
        ax.scatter(x, y, load_z, color='red', marker='v', s=100, alpha=0.8)
        ax.text(x - 0.5, y, load_z - 0.2, load, color='red', fontsize=7)
        load_offset += 1

# Enhance aesthetics
ax.set_title('Grid 2: IEEE 9 bus Network', fontsize=16, fontweight='bold')
ax.set_xlabel('X-axis (Distance)', fontsize=12)
ax.set_ylabel('Y-axis (Distance)', fontsize=12)
ax.set_zlabel('Z-axis (Height)', fontsize=12)

# Add grid
ax.grid(True, alpha=0.3)

# Add legend
from matplotlib.lines import Line2D
legend_elements = [
    Line2D([0], [0], marker='o', color='w', markerfacecolor='blue', markersize=10, label='Buses'),
    Line2D([0], [0], marker='^', color='w', markerfacecolor='green', markersize=10, label='Generators'),
    Line2D([0], [0], marker='v', color='w', markerfacecolor='red', markersize=10, label='Loads'),
    Line2D([0], [0], color='gray', linewidth=2, label='Transmission Lines'),
    Line2D([0], [0], color='orange', linewidth=3, label='Transformers'),
    Line2D([0], [0], marker='s', color='w', markerfacecolor='orange', markersize=8, label='Transformer Points'),
    Line2D([0], [0], color='green', linewidth=2, label='Generator Connections'),
    Line2D([0], [0], color='red', linewidth=2, label='Load Connections')
]
ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(0, 1))

# Print detailed system summary
print("\n" + "="*70)
print("9-BUS POWER SYSTEM DETAILED SUMMARY - UPDATED NETWORK")
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
    print(f"{i:2d}. {bus:<8} | Voltage: {voltage}")

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
total_gen_capacity = 0
for i, (gen_name, bus) in enumerate(generators.items(), 1):
    voltage = bus_voltages.get(bus, 'N/A')
    capacity = float(gen_name.split('(')[1].split(' MW')[0])
    total_gen_capacity += capacity
    print(f"{i}. {gen_name}")
    print(f"   └── Connected to: {bus} ({voltage})")
print(f"\nTotal Generation Capacity: {total_gen_capacity} MW")

print(f"\nLOAD CONNECTIONS:")
print("-" * 50)
total_load_capacity = 0
for i, (load_name, bus) in enumerate(loads.items(), 1):
    voltage = bus_voltages.get(bus, 'N/A')
    capacity = float(load_name.split('(')[1].split(' MVA')[0])
    total_load_capacity += capacity
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

for voltage, buses in sorted(voltage_levels.items()):
    print(f"• {voltage}: {', '.join(buses)}")

print(f"\nSYSTEM CHARACTERISTICS:")
print("-" * 50)
print(f"• Voltage Range: 11 kV to 55 kV")
print(f"• Primary Voltage Level: 20 kV ({len([v for v in bus_voltages.values() if v == '20 kV'])} buses)")
print(f"• Generation-Load Ratio: {total_gen_capacity/total_load_capacity:.2f}")
print(f"• Transformer Capacity: 300 MVA total")
print(f"• Network Type: Mixed transmission/distribution with high voltage Bus9")

print("\n" + "="*70)

# Set view angle for better visibility
ax.view_init(elev=20, azim=45)

# Adjust layout
plt.tight_layout()

# Display the plot
plt.show()

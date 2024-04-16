clock_frequency = 2000000
notes = [
{"note": "C1", "freq": 55.00},
{"note": "C#1", "freq": 58.27},
{"note": "D1", "freq": 61.74},
{"note": "D#1", "freq": 65.41},
{"note": "E1", "freq": 69.30},
{"note": "F1", "freq": 73.42},
{"note": "F#1", "freq": 77.78},
{"note": "G1", "freq": 82.41},
{"note": "G#1", "freq": 87.31},
{"note": "A1", "freq": 92.50},
{"note": "A#1", "freq": 98.00},
{"note": "B1", "freq": 103.83},
{"note": "C2", "freq": 110.00},
{"note": "C#2", "freq": 116.54},
{"note": "D2", "freq": 123.47},
{"note": "D#2", "freq": 130.81},
{"note": "E2", "freq": 138.59},
{"note": "F2", "freq": 146.83},
{"note": "F#2", "freq": 155.56},
{"note": "G2", "freq": 164.81},
{"note": "G#2", "freq": 174.61},
{"note": "A2", "freq": 185.00},
{"note": "A#2", "freq": 196.00},
{"note": "B2", "freq": 207.65},
{"note": "C3", "freq": 220.00},
{"note": "C#3", "freq": 233.08},
{"note": "D3", "freq": 246.94},
{"note": "D#3", "freq": 261.63},
{"note": "E3", "freq": 277.18},
{"note": "F3", "freq": 293.66},
{"note": "F#3", "freq": 311.13},
{"note": "G3", "freq": 329.63},
{"note": "G#3", "freq": 349.23},
{"note": "A3", "freq": 369.99},
{"note": "A#3", "freq": 392.00},
{"note": "B3", "freq": 415.30},
{"note": "C4", "freq": 440.00},
{"note": "C#4", "freq": 466.16},
{"note": "D4", "freq": 493.88},
{"note": "D#4", "freq": 523.25},
{"note": "E4", "freq": 554.37},
{"note": "F4", "freq": 587.33},
{"note": "F#4", "freq": 622.25},
{"note": "G4", "freq": 659.26},
{"note": "G#4", "freq": 698.46},
{"note": "A4", "freq": 739.99},
{"note": "A#4", "freq": 783.99},
{"note": "B4", "freq": 830.61},
{"note": "C5", "freq": 880.00},
{"note": "C#5", "freq": 932.33},
{"note": "D5", "freq": 987.77},
{"note": "D#5", "freq": 1046.50},
{"note": "E5", "freq": 1108.73},
{"note": "F5", "freq": 1174.66},
{"note": "F#5", "freq": 1244.51},
{"note": "G5", "freq": 1318.51},
{"note": "G#5", "freq": 1396.91},
{"note": "A5", "freq": 1479.98},
{"note": "A#5", "freq": 1567.98},
{"note": "B5", "freq": 1661.22},
{"note": "C6", "freq": 1760.00},
{"note": "C#6", "freq": 1864.66},
{"note": "D6", "freq": 1975.53},
{"note": "D#6", "freq": 2093.00},
{"note": "E6", "freq": 2217.46},
{"note": "F6", "freq": 2349.32},
{"note": "F#6", "freq": 2489.02},
{"note": "G6", "freq": 2637.02},
{"note": "G#6", "freq": 2793.83},
{"note": "A6", "freq": 2959.96},
{"note": "A#6", "freq": 3135.96},
{"note": "B6", "freq": 3322.44},
{"note": "C7", "freq": 3520.00},
{"note": "C#7", "freq": 3729.31},
{"note": "D7", "freq": 3951.07},
{"note": "D#7", "freq": 4186.01},
{"note": "E7", "freq": 4434.92},
{"note": "F7", "freq": 4698.64},
{"note": "F#7", "freq": 4978.03},
{"note": "G7", "freq": 5274.04},
{"note": "G#7", "freq": 5587.65},
{"note": "A7", "freq": 5919.91},
{"note": "A#7", "freq": 6271.93},
{"note": "B7", "freq": 6644.88}
]

# Calculate divider values for each note
divider_values = {}
for rec in notes:
    divider = int(clock_frequency / (32.0 * rec['freq']))
    divider_values[rec['note']] = divider

# Print the assembly table with split values
print("; SN76489AN TONE Registers Table - 2MHz")
print("notes:")
counter = 0
for note, divider in divider_values.items():
    upper = divider >> 4
    lower = divider & 0x0F
    print(f"\t.byte\t${lower:02X}, ${upper:02X} ; {note}\t0x{counter:02x}")
    counter += 2


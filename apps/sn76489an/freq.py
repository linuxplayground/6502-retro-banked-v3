import math

def calculate_frequency(note, octave):
    """
    Calculate the frequency of a note at a given octave.
    Formula: 2^(n/12) * 440 Hz, where n is the number of semitones from A4.
    """
    semitones_from_a4 = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    semitones_difference = semitones_from_a4.index(note)
    return 2 ** ((semitones_difference + (octave - 4) * 12) / 12) * 440.0

def generate_note_list():
    """
    Generate a list of frequencies and their note names from C1 to B7.
    """
    note_names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    note_list = []

    for octave in range(1, 8):
        for note in note_names:
            frequency = calculate_frequency(note, octave)
            note_list.append((note + str(octave), frequency))
    
    return note_list

if __name__ == "__main__":
    note_list = generate_note_list()
    sorted_note_list = sorted(note_list, key=lambda x: x[1])  # Sort by frequency
    print("[")
    for note, frequency in sorted_note_list:
        print("{",end="")
        print(f'"note": "{note}", "freq": {frequency:.2f}', end="")
        print("},")
    print("]")


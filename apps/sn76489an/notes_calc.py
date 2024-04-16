
clock = 2000000
freqs = [{"name": "C", "freq":262},
         {"name": "CS","freq":277},
         {"name": "D", "freq":294},
         {"name": "DS","freq":311},
         {"name": "E", "freq":330},
         {"name": "F", "freq":349},
         {"name": "FS","freq":370},
         {"name": "G", "freq":392},
         {"name": "GS","freq":415},
         {"name": "A", "freq":440},
         {"name": "AS","freq":466},
         {"name": "B", "freq":494}]

divisor = clock / 32

for f in freqs:
    val = int(round(divisor / f["freq"], 0))
    b1 = val>>6
    b2 = val & 0x3F
    print(f'F_{f["name"]:<2} = {b1:02x}\t;  {f["freq"]}')
    print(f'S_{f["name"]:<2} = {b2:02x}\t;  {val:010b}')

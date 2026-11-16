"""Generate fictional multifamily sample data for the dbt practice project.

All names, properties and people are invented. Fixed random seed, so the
output is the same on every run.
"""
import csv, random, sys
from datetime import date, timedelta

random.seed(42)
OUT = sys.argv[1]
TODAY = date(2026, 11, 14)

def add_months(d, m):
    y, mo = divmod(d.month - 1 + m, 12)
    y += d.year
    mo += 1
    day = min(d.day, [31, 29 if y % 4 == 0 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][mo - 1])
    return date(y, mo, day)

properties = [
    ("P001", "Maple Ridge Commons", "Houston", "TX", 2014),
    ("P002", "Cypress Bend Flats", "Tampa", "FL", 2018),
    ("P003", "Harbor Oak Residences", "Atlanta", "GA", 2011),
    ("P004", "Silver Creek Lofts", "Charlotte", "NC", 2021),
]
with open(f"{OUT}/raw_properties.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["property_id", "property_name", "city", "state", "year_built"])
    w.writerows(properties)

# Unit types are deliberately messy (case, spaces) so Silver has work to do.
messy_types = {"1BR": ["1BR", "1br", " 1 BR"], "2BR": ["2BR", "2 br", "2BR "], "3BR": ["3BR", "3br"]}
base = {"1BR": (650, 1350), "2BR": (980, 1750), "3BR": (1300, 2150)}
city_factor = {"P001": 1.0, "P002": 1.08, "P003": 1.04, "P004": 1.12}
units = []
for pid, *_ in properties:
    for n in range(1, 31):
        ut = random.choices(["1BR", "2BR", "3BR"], [5, 4, 1])[0]
        sqft = {"1BR": random.randint(640, 780), "2BR": random.randint(950, 1150), "3BR": random.randint(1250, 1450)}[ut]
        rent = round(base[ut][1] * city_factor[pid] / 5) * 5
        units.append({"unit_id": f"{pid}-{100 + n}", "property_id": pid,
                      "unit_number": str(100 + n), "unit_type": random.choice(messy_types[ut]),
                      "square_feet": sqft, "market_rent": rent, "_type": ut})
with open(f"{OUT}/raw_units.csv", "w", newline="") as f:
    w = csv.DictWriter(f, ["unit_id", "property_id", "unit_number", "unit_type", "square_feet", "market_rent"], extrasaction="ignore")
    w.writeheader(); w.writerows(units)

first = ["Ava", "Liam", "Noah", "Mia", "Ethan", "Zoe", "Lucas", "Chloe", "Omar", "Priya", "Diego", "Hana",
         "Kai", "Nora", "Ravi", "Elena", "Jonah", "Amara", "Theo", "Leah", "Marco", "Yuki", "Sam", "Iris"]
last = ["Nguyen", "Patel", "Garcia", "Smith", "Kim", "Okafor", "Rossi", "Chen", "Brown", "Silva",
        "Haddad", "Martin", "Lopez", "Walker", "Singh", "Moreau", "Tanaka", "Reyes", "Clark", "Ali"]
residents, leases = [], []
rid = 0

def new_resident():
    global rid
    rid += 1
    fn, ln = random.choice(first), random.choice(last)
    email = f"{fn}.{ln}{rid}@example.com"
    if random.random() < 0.3:
        email = email.upper()  # messy casing for Silver to clean
    residents.append({"resident_id": f"R{rid:04d}", "first_name": fn, "last_name": ln,
                      "email": email, "phone": f"555-{random.randint(100,999)}-{random.randint(1000,9999)}"})
    return f"R{rid:04d}"

lid = 0
for u in units:
    start = date(2023, random.randint(1, 6), 1)
    res = new_resident()
    rent = round(u["market_rent"] * random.uniform(0.9, 0.97) / 5) * 5
    renewal = False
    while start <= date(2026, 10, 31):
        lid += 1
        end = add_months(start, 12) - timedelta(days=1)
        signed = start - timedelta(days=random.randint(7, 35))
        renews = end < TODAY and random.random() < 0.55
        if end >= TODAY:
            status, move_out = "active", ""
        else:
            status = "expired"
            move_out = "" if renews else end.isoformat()
        leases.append({"lease_id": f"L{lid:05d}", "unit_id": u["unit_id"], "resident_id": res,
                       "signed_date": signed.isoformat(), "lease_start_date": start.isoformat(),
                       "lease_end_date": end.isoformat(),
                       "move_in_date": "" if renewal else start.isoformat(),
                       "move_out_date": move_out, "monthly_rent": rent,
                       "is_renewal": str(renewal).lower(), "lease_status": status})
        if end >= TODAY:
            break
        if renews:
            start = end + timedelta(days=1)
            rent = round(rent * random.uniform(1.03, 1.05) / 5) * 5
            renewal = True
        else:
            start = end + timedelta(days=random.randint(10, 45))
            res = new_resident()
            rent = round(u["market_rent"] * random.uniform(0.95, 1.02) / 5) * 5
            renewal = False

with open(f"{OUT}/raw_residents.csv", "w", newline="") as f:
    w = csv.DictWriter(f, ["resident_id", "first_name", "last_name", "email", "phone"])
    w.writeheader(); w.writerows(residents)
with open(f"{OUT}/raw_leases.csv", "w", newline="") as f:
    w = csv.DictWriter(f, list(leases[0].keys()))
    w.writeheader(); w.writerows(leases)

# Rent update file for the SCD Type 2 exercise (step 6 in the README).
with open(f"{OUT}/../setup/raw_units_rent_update.csv", "w", newline="") as f:
    w = csv.DictWriter(f, ["unit_id", "property_id", "unit_number", "unit_type", "square_feet", "market_rent"], extrasaction="ignore")
    w.writeheader()
    for u in units:
        v = dict(u)
        if v["property_id"] == "P002":
            v["market_rent"] = round(v["market_rent"] * 1.04 / 5) * 5
        w.writerow(v)

print(len(properties), "properties,", len(units), "units,", len(residents), "residents,", len(leases), "leases")

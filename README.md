# Multifamily Data Products: Snowflake + dbt Practice Project

A small medallion-style data warehouse for a fictional apartment company.
It uses Snowflake, dbt, Kimball dimensional modelling, data quality tests and PII masking.
All properties, people and numbers are invented.

## What you will build

| Layer | Content | Who writes it |
|---|---|---|
| **Bronze** | 4 raw CSV seeds: properties, units, residents, leases. Some values are messy on purpose. | Given |
| **Silver** | 4 cleaned staging views (`stg_*`) with tests | Given (read them first) |
| **Snapshot** | `snap_units`: SCD Type 2 history of unit market rent | Given |
| **Gold** | Star schema: 4 dimensions, 2 facts, 1 KPI mart | **You** (`dim_property` is a worked example) |
| **Governance** | Masking policy and sensitivity tag on resident PII | **You** run the SQL |

```
            dim_date        dim_property        dim_resident
                \               |                  /
   fct_unit_occupancy_monthly   |     fct_leases ----- dim_unit (SCD2, from snap_units)
     (periodic snapshot)        |   (accumulating snapshot)
                \               |        /
               mart_property_kpis_monthly   <- enterprise metrics
```

Two different fact types, on purpose:
- **fct_leases**: accumulating snapshot. One row per lease, with milestone dates (signed, start, move-in, end, move-out).
- **fct_unit_occupancy_monthly**: periodic snapshot. One row per unit per month end.

## Step 1: Snowflake setup (15 min)

1. Log in to your Snowflake trial (Snowsight).
2. Open a new SQL worksheet. Paste `setup/01_snowflake_setup.sql`.
3. Change `YOUR_USERNAME` to your user name. Run all.
4. Check that the trial is **Enterprise** edition (Admin > Billing, or ask your account page). You need Enterprise for step 7.

## Step 2: Install dbt on your computer (15 min)

```bash
python3 -m venv ~/dbt-venv
source ~/dbt-venv/bin/activate          # Windows: ~/dbt-venv/Scripts/activate
pip install --upgrade dbt-snowflake      # needs dbt 1.10 or later
dbt --version
```

## Step 3: Connect dbt to Snowflake (10 min)

1. Copy `profiles.example.yml` to `~/.dbt/profiles.yml`.
2. Fill in `account` and `user`.
3. Set your password as an environment variable:
   `export SNOWFLAKE_PASSWORD='...'` (Windows PowerShell: `$env:SNOWFLAKE_PASSWORD='...'`)
4. In the project folder, run:

```bash
dbt debug        # "All checks passed!" means the connection works
dbt deps         # installs dbt_utils
```

## Step 4: Build Bronze, Silver and the snapshot (15 min)

```bash
dbt seed         # loads the CSVs into BRONZE
dbt snapshot     # first version of unit history in SNAPSHOTS
dbt build        # Silver views + tests, and dim_property
```

Expected: 23 steps pass. Then, in Snowsight, look at `BRONZE.RAW_UNITS.UNIT_TYPE`
and `SILVER.STG_UNITS.UNIT_TYPE`. See how Silver cleans the messy values.

Read the four `models/silver/*.sql` files and `_silver.yml` before you go on.

## Step 5: Write the Gold layer (main work, 2 to 4 evenings)

Write the models in this order. Each file in `models/gold/` has the grain, the columns
and the rules in its comments. When a model is ready, remove its `config(enabled=false)` line.

| Order | Model | Kimball concept you practise |
|---|---|---|
| 1 | `dim_date` | Calendar dimension, date spine |
| 2 | `dim_resident` | SCD Type 1, surrogate keys |
| 3 | `dim_unit` | **SCD Type 2**, valid_from / valid_to |
| 4 | `fct_leases` | **Accumulating snapshot**, point-in-time join to SCD2, window functions |
| 5 | `fct_unit_occupancy_monthly` | **Periodic snapshot**, dense grid (cross join + left join) |
| 6 | `mart_property_kpis_monthly` | Enterprise metrics, metric definitions |

After each model:

```bash
dbt build --select <model_name>
```

The tests in `models/gold/_gold.yml` are your acceptance criteria. Unique keys, not-null
keys, relationships between facts and dimensions, and an occupancy range of 0 to 1.

**Use Claude Code** to help you write the SQL. Ask it to explain each choice, and make sure
you can explain every line yourself. This gives you a true answer to the JD requirement
"leveraging AI tools to accelerate delivery".

**Compare with `solutions/`** only after `dbt build` passes, or if you are stuck for more than 30 minutes.

## Step 6: SCD Type 2 in action (15 min)

Property P002 increases its market rents by about 4%.

```bash
cp setup/raw_units_rent_update.csv seeds/raw_units.csv
dbt seed --select raw_units
dbt snapshot
dbt build --select dim_unit+
```

Then query `GOLD.DIM_UNIT` for unit `P002-101`. You should see two rows: the old rent
(now closed) and the new rent (current). Old leases still point to the old version.

## Step 7: Governance: mask PII (20 min)

Run `setup/02_masking_policy.sql` in Snowsight. It:
- creates a masking policy for email and phone,
- adds a `SENSITIVITY = 'pii'` tag,
- shows the difference between the `ANALYST` role (masked) and the `TRANSFORMER` role (clear).

**Stretch goal:** `dbt build` recreates the table and drops the policy. Add a `post_hook`
to `dim_resident.sql` so dbt applies the policy on every run.

## Step 8: Data quality rule and docs (30 min)

1. Write a singular test `tests/assert_no_overlapping_leases.sql`: one unit can never
   have two leases on the same day. The test fails if the query returns rows.
2. Generate the docs and the lineage graph:

```bash
dbt docs generate
dbt docs serve     # opens the docs site; click the lineage icon (bottom right)
```

## Step 9: Put it on GitHub (15 min)

```bash
git init && git add . && git commit -m "Multifamily Snowflake + dbt practice project"
```

Create a public repository and push. `.gitignore` already excludes `target/`, `dbt_packages/` and `logs/`.
Do not commit `profiles.yml` or your password.

Take two screenshots for the interview: the dbt lineage graph and the masked vs clear query results.

## Step 10: Shut down to save credits

The warehouse suspends after 60 seconds. When you are done with the trial, you can run
`DROP DATABASE MULTIFAMILY_PRACTICE;`.

## Checklist

- [ ] Snowflake setup done, `dbt debug` passes
- [ ] Bronze, Silver and snapshot built (23 steps pass)
- [ ] dim_date, dim_resident, dim_unit written and tested
- [ ] fct_leases written and tested
- [ ] fct_unit_occupancy_monthly written and tested
- [ ] mart_property_kpis_monthly written; numbers make sense
- [ ] SCD2 rent change done
- [ ] PII masking done (and the post_hook stretch goal)
- [ ] Overlapping-lease test written
- [ ] Docs and lineage generated; screenshots taken
- [ ] Pushed to GitHub

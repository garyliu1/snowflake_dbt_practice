-- EXERCISE: unit dimension (SCD Type 2)
-- Grain: one row per unit per version. Source: ref('snap_units')
-- Columns: unit_key (surrogate key on unit_id + dbt_valid_from), unit_id, property_id,
--          unit_number, unit_type, square_feet, market_rent, valid_from, valid_to, is_current
-- Rules:
--   * The snapshot keeps RAW values: clean unit_type the same way as stg_units.
--   * valid_to: use 9999-12-31 when dbt_valid_to is null (the current version).
--   * Watch out: the first snapshot run stamps TODAY as dbt_valid_from, but leases
--     start in 2023. How will fct_leases find the correct unit version for an old lease?

select 
    {{ dbt_utils.generate_surrogate_key(['unit_id', 'dbt_valid_from']) }} as unit_key,
    unit_id,
    property_id,
    unit_number,
    upper(replace(trim(unit_type), ' ', '')) as unit_type,
    square_feet,
    market_rent,
    case when dbt_valid_from = min(dbt_valid_from) over (partition by unit_id)
        then cast('1900-01-01' as date)
        else cast(dbt_valid_from as date)
    end as valid_from,
    cast(coalesce(dbt_valid_to, '9999-12-31') as date) as valid_to,
    (dbt_valid_to is null) as is_current
from {{ ref('snap_units') }}
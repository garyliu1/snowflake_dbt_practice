-- WORKED EXAMPLE: use this pattern for the other dimensions.
-- Grain: one row per property (SCD Type 1)
select
    {{ dbt_utils.generate_surrogate_key(['property_id']) }} as property_key,
    property_id,
    property_name,
    city,
    state,
    year_built
from {{ ref('stg_properties') }}

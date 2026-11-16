-- Cleans the messy unit_type values ("1br", " 1 BR", "2BR ") into 1BR / 2BR / 3BR
select
    unit_id,
    property_id,
    cast(unit_number as varchar)                          as unit_number,
    upper(replace(trim(unit_type), ' ', ''))              as unit_type,
    cast(square_feet as integer)                          as square_feet,
    cast(market_rent as numeric(10, 2))                   as market_rent
from {{ ref('raw_units') }}

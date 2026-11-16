select
    property_id,
    trim(property_name)        as property_name,
    trim(city)                 as city,
    upper(trim(state))         as state,
    cast(year_built as integer) as year_built
from {{ ref('raw_properties') }}

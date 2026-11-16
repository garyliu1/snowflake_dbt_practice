select
    resident_id,
    trim(first_name)     as first_name,
    trim(last_name)      as last_name,
    lower(trim(email))   as email,
    phone
from {{ ref('raw_residents') }}

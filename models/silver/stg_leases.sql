select
    lease_id,
    unit_id,
    resident_id,
    cast(signed_date as date)         as signed_date,
    cast(lease_start_date as date)    as lease_start_date,
    cast(lease_end_date as date)      as lease_end_date,
    cast(move_in_date as date)        as move_in_date,
    cast(move_out_date as date)       as move_out_date,
    cast(monthly_rent as numeric(10, 2)) as monthly_rent,
    cast(is_renewal as boolean)       as is_renewal,
    lower(lease_status)               as lease_status
from {{ ref('raw_leases') }}

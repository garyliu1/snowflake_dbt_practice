
-- EXERCISE: periodic snapshot fact
-- Grain: one row per unit per month end, from 2023-01-31 to today.
-- Columns: month_end, unit_id, property_key, is_occupied, rent_in_effect
-- Rules:
--   * A unit is occupied at month end if a lease covers that date
--     (lease_start_date <= month_end <= lease_end_date).
--   * Every unit must have a row for every month end, occupied or not.
--     Hint: cross join units with the month ends from dim_date, then left join leases.

with months as (
    select 
        date_day 
    from {{ ref('dim_date') }}
    where is_month_end = true and date_day <= current_date 
),
unit as (
    select 
        un.unit_id,
        p.property_key,
    from {{ ref('stg_units') }} un
    join {{ ref('dim_property') }} p
        on un.property_id = p.property_id
),
final as (
    select 
        m.date_day as month_end,
        u.unit_id as unit_id,
        u.property_key as property_key,
        l.lease_id is not null as is_occupied,
        l.monthly_rent as rent_in_effect
    from unit u 
    cross join months m
    left join {{ ref('stg_leases') }} l 
        on u.unit_id = l.unit_id 
        and m.date_day between l.lease_start_date and l.lease_end_date
)
select * from final
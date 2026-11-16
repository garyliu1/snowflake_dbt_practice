
-- EXERCISE: accumulating snapshot fact
-- Grain: one row per lease. Source: ref('stg_leases') + the three dimensions.
-- Columns: lease_id, resident_key, unit_key, property_key,
--          signed_date, lease_start_date, move_in_date, lease_end_date, move_out_date,
--          monthly_rent, market_rent_at_start, is_renewal, lease_status,
--          days_signed_to_start, vacant_days_before_lease
-- Rules:
--   * unit_key: join to the dim_unit version that was valid on lease_start_date.
--   * vacant_days_before_lease (turn time): for a NEW lease (not a renewal), the days
--     between the previous lease's move_out_date on the same unit and this lease's start.
--     Hint: lag() over (partition by unit_id order by lease_start_date)
--   * Use dbt.datediff(start, end, 'day') so the SQL works on Snowflake and other databases.
with leases as (
    select 
        lease_id,
        unit_id,
        resident_id,
        signed_date,
        lease_start_date,
        lease_end_date,
        move_in_date,
        move_out_date,
        monthly_rent,
        is_renewal,
        lease_status,
        lag(move_out_date) over (partition by unit_id order by lease_start_date) as prev_move_out_date
    from {{ ref('stg_leases') }} 
),
unit_versions as (
    select
        l.lease_id,
        u.property_id, 
        u.unit_key,
        u.market_rent as market_rent_at_start
    from leases l
    join {{ ref('dim_unit') }} u
        on  l.unit_id = u.unit_id
        and l.lease_start_date >= u.valid_from
        and l.lease_start_date <  u.valid_to
),
final as (
    select 
        l.lease_id,
        r.resident_key,
        v.unit_key,
        p.property_key,
        l.signed_date,
        l.lease_start_date,
        l.move_in_date,
        l.lease_end_date,
        l.move_out_date,
        l.monthly_rent,
        v.market_rent_at_start,
        l.is_renewal,
        l.lease_status,
        {{ dbt.datediff('signed_date', 'lease_start_date', 'day') }} as days_signed_to_start,
        case when not is_renewal
            then {{ dbt.datediff('prev_move_out_date', 'lease_start_date', 'day') }}
        end as vacant_days_before_lease
    from leases l
    left join unit_versions v
        on l.lease_id = v.lease_id
    left join {{ ref('dim_resident') }} r
        on l.resident_id = r.resident_id
    left join {{ ref('dim_property') }} p 
        on v.property_id = p.property_id
)
select * from final

-- EXERCISE: enterprise metrics (Gold data product)
-- Grain: one row per property per month end.
-- Columns: property_id, property_name, month_end, total_units, occupied_units,
--          occupancy_rate, avg_rent_occupied, leases_expiring, leases_renewed,
--          renewal_rate, avg_turn_days
-- Metric definitions (write them in _gold.yml too; this is metric governance):
--   * occupancy_rate = occupied units / total units at month end
--   * renewal_rate   = leases renewed / leases that expired in the month
--                      (renewed = the NEXT lease on the same unit is a renewal)
--   * avg_turn_days  = average vacant_days_before_lease for new leases that started in the month
-- Sanity check: occupancy is about 95-100%, renewal rate about 50-55%, turn time about 27 days.

with occupancy as (
    select 
        p.property_id,
        p.property_name,
        f.month_end,
        COUNT(*) as total_units,
        count_if(f.is_occupied) as occupied_units,
        AVG(f.rent_in_effect) as avg_rent_occupied
    from {{ ref('fct_unit_occupancy_monthly') }} f 
    join {{ ref('dim_property') }} p 
        on f.property_key = p.property_key
    group by p.property_id, p.property_name, f.month_end
),
leases_next as (
    select 
        l.unit_id,
        u.property_id,
        l.lease_end_date,
        lead(l.is_renewal) over (partition by l.unit_id order by l.lease_start_date) as next_is_renewal
    from {{ ref('stg_leases') }} l
    join {{ ref('stg_units') }} u
        on l.unit_id = u.unit_id
),
renewals as (
    select
        property_id,
        last_day(lease_end_date) as month_end, 
        count(*) as leases_expiring,
        count_if(next_is_renewal) as leases_renewed
    from leases_next
    group by property_id, last_day(lease_end_date)
),
turns as (
    select 
        p.property_id,
        last_day(f.lease_start_date) as month_end,
        avg(f.vacant_days_before_lease) as avg_turn_days
    from {{ ref('fct_leases') }} f 
    join {{ ref('dim_property') }} p 
        on f.property_key = p.property_key
    group by p.property_id, last_day(f.lease_start_date)
),
final as (
    select
        o.property_id,
        o.property_name,
        o.month_end,
        o.total_units,
        o.occupied_units,
        o.occupied_units/nullif(o.total_units, 0) as occupancy_rate,
        round(o.avg_rent_occupied,2) as avg_rent_occupied,
        r.leases_expiring,
        r.leases_renewed,
        r.leases_renewed/nullif(r.leases_expiring, 0) as renewal_rate,
        round(t.avg_turn_days,1) as avg_turn_days
    from occupancy o 
    left join renewals r  
        on o.property_id = r.property_id and o.month_end = r.month_end
    left join turns t
        on o.property_id = t.property_id and o.month_end = t.month_end
)
select * from final
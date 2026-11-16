-- Test for leases overlapping

    select 
        a.unit_id,
        a.lease_id as lease_id_a,
        b.lease_id as lease_id_b,
        a.lease_start_date as start_a,
        a.lease_end_date as end_a,
        b.lease_start_date as start_b,
        b.lease_end_date as end_b
    from {{ ref('stg_leases') }} a
    join {{ ref('stg_leases') }} b
        on a.unit_id = b.unit_id 
        and a.lease_id < b.lease_id 
        and a.lease_start_date <= b.lease_end_date 
        and b.lease_start_date <= a.lease_end_date

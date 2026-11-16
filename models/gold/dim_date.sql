
-- EXERCISE: calendar dimension
-- Grain: one row per day, 2023-01-01 to 2027-12-31.
-- Columns: date_day, year, quarter, month, month_start, month_end, is_month_end
-- Hint: dbt_utils.date_spine(datepart="day", start_date=..., end_date=...)

with days as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2023-01-01' as date)",
        end_date="cast('2028-01-01' as date)"
    ) }}
),
calendar as (
    select
        cast(date_day as date) as date_day,
        extract(year from date_day) as year,
        extract(quarter from date_day) as quarter,
        extract(month from date_day) as month,
        cast(date_trunc('month', date_day) as date) as month_start,
        cast(last_day(date_day) as date) as month_end,
    from days
)
select 
    *,
    date_day = month_end as is_month_end
from calendar
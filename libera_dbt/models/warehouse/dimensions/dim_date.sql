{{ config(materialized='table') }}

with date_spine as (

    select explode(
        sequence(
            to_date('2018-01-01'),
            to_date('2030-12-31'),
            interval 1 day
        )
    ) as date_day

)

select
    date_day,
    year(date_day) as year,
    quarter(date_day) as quarter,
    month(date_day) as month,
    date_format(date_day, 'MMMM') as month_name,
    day(date_day) as day_of_month,
    dayofweek(date_day) as day_of_week,
    date_format(date_day, 'EEEE') as day_name,
    weekofyear(date_day) as week_of_year,

    case
        when dayofweek(date_day) in (1, 7) then true
        else false
    end as is_weekend

from date_spine
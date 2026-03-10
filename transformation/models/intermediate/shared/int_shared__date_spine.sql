{{ 
  config(tags=['intermediate','shared','date'])
}}

with date_spine as (

    {{ dbt_utils.date_spine(
        datepart='day',
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    ) }}
),

final as (
    select
        cast(strftime(date_day,'%Y%m%d') as int) as date_key,
        date_day as calendar_date,
        cast(strftime(date_day,'%Y') as int) as year_number,
        cast(strftime(date_day,'%m') as int) as month_number,
        cast(strftime(date_day,'%d') as int) as day_of_month,
        cast(strftime(date_day,'%w') as int) as day_of_week,
        cast(strftime(date_day,'%W') as int) as week_of_year,
        strftime(date_day, '%A') as day_name,
        case when strftime(date_day, '%w') in ('0', '6') then 1 else 0 end as is_weekend
    from date_spine
)
select * from final
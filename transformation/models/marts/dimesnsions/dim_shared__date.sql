{{ config(tags = ['dimension','marts','date']) }}

with date_spine as (

    select * from {{ ref('int_shared__date_spine') }}

),
final as (

    select
        date_key,
       calendar_date,
       year_number,
       month_number,
       day_of_month,
       week_of_year,
       day_name,
       is_weekend,
       cast(date_trunc('month',calendar_date) as date) as month_start_date,
       cast(last_day(calendar_date) as date) as month_end_date,
       case when day_of_month = 1 then true else false end as is_month_start,
         case when calendar_date = last_day(calendar_date) then true else false end as is_month_end,
         case when month_number in (1,2,3) then 'Q1' 
                when month_number in (4,5,6) then 'Q2' 
                when month_number in (7,8,9) then 'Q3' 
                else 'Q4' 
        end as quarter_number
    from date_spine

)
select * from final
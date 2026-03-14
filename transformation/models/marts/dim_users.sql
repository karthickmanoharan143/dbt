{{ config(
    materialized='table',
    tags=['marts', 'dimensions']
) }}

with users as (
    select * from {{ ref('stg_users') }}
),
dim_users as (
    select
        {{ dbt_utils.generate_surrogate_key(['user_id']) }} as user_sk,
        user_id,
        user_name,
        email,
        phone,
        department,
        title,
        created_date,
        current_timestamp as loaded_at
    from users
)
select * from dim_users
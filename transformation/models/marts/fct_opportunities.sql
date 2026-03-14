{{ config(
    materialized='table',
    tags=['marts', 'facts']
) }}

with opp_details as (
    select * from {{ ref('int_opportunities_with_details') }}
),
fct_opportunities as (
    select
        {{ dbt_utils.generate_surrogate_key(['opportunity_id']) }} as opportunity_fk,
        opportunity_id,
        account_id,
        owner_id,
        account_name,
        owner_name,
        opportunity_name,
        stage,
        amount,
        is_won,
        is_closed,
        close_date,
        created_date,
        last_modified_date,
        current_timestamp as loaded_at
    from opp_details
)
select * from fct_opportunities
{{ config(
    materialized='table',
    tags=['intermediate']
) }}

with accounts as (
    select * from {{ ref('stg_accounts') }}
),
opportunities as (
    select * from {{ ref('stg_opportunities') }}
),
leads as (
    select * from {{ ref('stg_leads') }}
),
account_opp_metrics as (
    select
        a.account_id,
        a.account_name,
        count(distinct o.opportunity_id) as total_opportunities,
        count(distinct case when o.stage = 'Closed Won' then o.opportunity_id end) as won_opportunities,
        sum(case when o.stage = 'Closed Won' then o.amount else 0 end) as total_won_value,
        sum(o.amount) as total_opportunity_value
    from accounts a
    left join opportunities o on a.account_id = o.account_id
    group by a.account_id, a.account_name
),
account_lead_metrics as (
    select
        a.account_id,
        count(distinct l.lead_id) as total_leads
    from accounts a
    left join leads l on a.account_id = l.company_id
    group by a.account_id
)
select
    am.*,
    coalesce(lm.total_leads, 0) as total_leads
from account_opp_metrics am
left join account_lead_metrics lm on am.account_id = lm.account_id
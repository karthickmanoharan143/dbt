{{ config(tags = ['fact','marts','sales']) }}

{% set date_key_mapping = [
    {'source_column': 'close_date', 'alias': 'close_date_key'},
    {'source_column': 'created_date', 'alias': 'created_date_key'}
] %}

{% set additive_metrics = ['amount', 'expected_revenue'] %}

with opportunity as (

    select * from {{ ref('int_salesforce__opportunity_enriched') }}

),
latest_stage as (

    select
        opportunity_id,
        stage_name as latest_stagename,
        previous_stage_name,
        is_stage_transition,
        stage_changed_at as latest_stage_change_at
    from {{ ref('int_salesforce__opportunity_stage_history') }}
    where is_latest_stage_record

),

stage_targets as (

    select
        * from {{ ref('seed_salesforce__opportunity_stage_targets') }}

),

account_dim as (

    select account_sk, account_id from {{ ref('dim_salesforce__account') }}

),
user_dim as (

    select user_sk, user_id from {{ ref('dim_salesforce__user') }}

),
campaign_dim as (

    select campaign_sk, campaign_id from {{ ref('dim_salesforce__campaign') }}

),
final as (

    select
        opportunity.opportunity_sk,
        opportunity.opportunity_id,
        account_dim.account_sk,
        user_dim.user_sk as owner_user_sk,
        campaign_dim.campaign_sk,
        {% for date_key in date_key_mapping %}
        cast(strftime(cast(opportunity.{{ date_key.source_column }} as date), '%Y%m%d') as int) as {{ date_key.alias }}{% if not loop.last %},{% endif %}
        {% endfor %},
        opportunity.name as opportunity_name,
        opportunity.account_id,
        opportunity.contact_id,
        opportunity.campaign_id,
        opportunity.owner_user_id,
        coalesce(latest_stage.latest_stagename, opportunity.stage_name) as current_stage_name,
        coalesce(stage_targets.previous_stage_name, 'other') as previous_stage_name,
        opportunity.stagebucket,
        opportunity.forecastcategoryname as forecast_category,
        opportunity.deliveryinstallationstatus__c as delivery_installation_status,
        {% for metric in additive_metrics %}
            cast(coalesce(opportunity.{{ metric }},0) as float) as {{ metric }}{% if not loop.last %},{% endif %}
        {% endfor %},
        stage_targets.target_win_probability as target_win_probability,
        {% if var('include_stage_target_gap', true) %}
        opportunity.expected_revenue - (opportunity.amount * stage_targets.target_win_probability) as expected_revenue_gap,
        {% endif %}
        opportunity.isclosed,
        opportunity.iswon,
        case
            when opportunity.closedate < {{ dbt_date.today(tz=var('dbt_date:time_zone')) }} and opportunity.isclosed = 'false' then true
            else false
        end as is_overdue,
        opportunity.createddate as created_date,
        opportunity.laststagechangedate  as last_modified_date,
        latest_stage.latest_stage_change_at,
        count(*) over (partition by opportunity.account_id) as opportunities_per_account,
          {% for metric in additive_metrics %}
          sum(coalesce(opportunity.{{ metric }},0)) over (partition by opportunity.account_id order by opportunity.createddate rows between unbounded preceding and current row) as total_{{ metric }}_per_account{% if not loop.last %},{% endif %}
          {% endfor %}
    from opportunity
    left join latest_stage on opportunity.opportunity_id = latest_stage.opportunity_id
    left join stage_targets on latest_stage.latest_stagename = stage_targets.stage_name
    left join account_dim on opportunity.account_id = account_dim.account_id
    left join user_dim on opportunity.owner_user_id = user_dim.user_id
    left join campaign_dim on opportunity.campaign_id = campaign_dim.campaign_id

)
select * from final
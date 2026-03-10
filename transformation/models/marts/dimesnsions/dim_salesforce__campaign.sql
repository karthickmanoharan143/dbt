{{ config(tags = ['dimension','marts','campaign']) }}

with campaign as (

    select * from {{ ref('stg_salesforce__campaign') }}

),
owner as (

    select user_id,firstname,lastname,isactive from {{ ref('stg_salesforce__user') }}

),
final as (

    select
        {{ sf_generate__surrogate_key(['campaign.campaign_id']) }} as campaign_sk,
        campaign.campaign_id,
        campaign.name as campaign_name,
        campaign.type as campaign_type,
        campaign.status as campaign_status,
        campaign.startdate as campaign_start_date,
        campaign.enddate as campaign_end_date,
        campaign.expectedrevenue as expected_revenue,
        campaign.budgetedcost as budgeted_cost,
        campaign.actualcost as actual_cost,
        campaign.numberofleads as number_of_leads,
        campaign.numberofopportunities as number_of_opportunities,
        campaign.numberofwonopportunities as number_of_won_opportunities,
        campaign.amountallopportunities as amount_all_opportunities,
        campaign.amountwonopportunities as amount_won_opportunities,
        cast(coalesce(campaign.isactive,'false') as boolean) as is_active,
        campaign.ownerid,
        {{ sf_clean_text("coalesce(owner.firstname,'') || ' ' || coalesce(owner.lastname,'')") }} as owner_full_name,
        campaign.createddate as campaign_created_date,
        campaign.lastmodifieddate as campaign_last_modified_date
    from campaign
    left join owner on campaign.ownerid = owner.user_id

)
select * from final
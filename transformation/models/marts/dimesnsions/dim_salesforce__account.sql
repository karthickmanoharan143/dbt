{{ config(tags = ['dimension','marts','account']) }}

with account as (

    select * from {{ ref('stg_salesforce__account') }}
),
owner as (

    select user_id,firstname,lastname,isactive from {{ ref('stg_salesforce__user') }}

),

final as (

    select
        {{ sf_generate__surrogate_key(['account.account_id']) }} as account_sk,
        account.account_id,
        account.name as account_name,
        account.type as account_type,
        account.industry,
        account.accountsource as account_source,
        account.rating,
        account.annualrevenue as annual_revenue,
        account.numberofemployees as number_of_employees,
        account.numberoflocations__c as number_of_locations,
        account.billingcity as billing_city,
        account.billingstate as billing_state,
        account.billingcountry as billing_country,
        account.shippingcity as shipping_city,
        account.shippingstate as shipping_state,
        account.shippingcountry as shipping_country,
        cast(coalesce(account.active__c,'false') as boolean) as is_active,
        cast(coalesce(account.isdeleted, false) as boolean) as is_deleted,
        account.ownerid,
        account.createddate as account_created_date,
        account.lastmodifieddate as account_last_modified_date,
        {{ sf_clean_text("coalesce(owner.firstname,'') || ' ' || coalesce(owner.lastname,'')") }} as owner_full_name,
        cast(coalesce(owner.isactive,'false') as boolean) as owner_is_active
    from account
    left join owner on account.ownerid = owner.user_id

)
select * from final
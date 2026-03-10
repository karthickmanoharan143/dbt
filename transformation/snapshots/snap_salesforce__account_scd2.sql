{% {% snapshot snap_salesforce__account_scd2 %}

{{
   config(
       target_schema='snapshots',
       unique_key='account_id',
       strategy='timestamp',
       updated_at='lastmodifieddate',
       invalidate_hard_deletes=True,
       tags=['snapshot','account']
   )
}}

select
    account_id,
    name,
    type,
    industry,
    billingcity,
    billingstate,
    billingcountry,
    annualrevenue,
    numberofemployees,
    ownerid,
    lastmodifieddate
from  {{ ref('stg_salesforce__account') }}

{% endsnapshot %}%}
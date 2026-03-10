{{ config(tags = ['fact','marts','support']) }}
with case_event as (

    select * from {{ ref('int_salesforce__case_events') }}

),
account_dim as (

    select account_sk, account_id, account_name from {{ ref('dim_salesforce__account') }}

),
user_dim as (

    select user_sk, user_id, full_name from {{ ref('dim_salesforce__user') }}

),
final as (
    
    select
        case_event.case_event_sk,
        case_event.case_id,
        account_dim.account_sk,
        user_dim.user_sk as owner_user_sk,
        cast(strftime(case_event.event_timestamp, '%Y%m%d%H%M%S') as int) as event_timestamp_key,
        case_event.account_id,
        case_event.contact_id,
        case_event.owner_user_id,
        case_event.event_type,
        user_dim.full_name as owner_full_name,
        case_event.event_type,
        case_event.status_after_event,
        case_event.status_before_event,
        case_event.priority,
        case_event.origin,
        case_event.is_closed,
        case_event.is_escalated,
        case_event.event_timestamp,
        row_number() over (partition by case_event.case_id order by case_event.event_timestamp,case_event.case_event_sk) as case_event_sequence,
        lead(case_event.event_timestamp) over (partition by case_event.case_id order by case_event.event_timestamp,case_event.case_event_sk) as next_event_timestamp
    from case_event
    left join account_dim on case_event.account_id = account_dim.account_id
    left join user_dim on case_event.owner_user_id = user_dim.user_id

)
select * from final
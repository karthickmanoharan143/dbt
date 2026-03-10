
    {{
      config(
        materialized = 'incremental',
        unique_key = 'case_event_sk',
        incremental_strategy = 'delete+insert',
        tags = ['intermediate','support','incremental']
        )
    }}

{% set shared_case_columns = ['priority', 'origin', 'systemmodstamp'] %}
{% set status_boolean_flags = ['is_closed', 'is_escalated'] %}
{% set initial_event_start_ts = var('case_events_initial_load_start_ts' , '1900-01-01 00:00:00')%}

with case_base as (

    select * from {{ ref('stg_salesforce__case') }}

),

case_history as (

    select * from {{ ref('stg_salesforce__case_history_2') }}

),

case_created_events as (

    select
        {{ sf_generate__surrogate_key(['case_id', "'created'", 'createddate']) }} as case_event_sk,
        case_id,
        accountid as account_id,
        contactid as contact_id,
        ownerid as owner_user_id,
        'Created' as event_type,
        createddate as event_timestamp,
        status as status_after_event,
        cast(null as string) as status_before_event,
        {{ sf_clean_text('priority') }} as priority,
        {{ sf_clean_text('origin') }} as origin,
            nullif(trim(cast(systemmodstamp as varchar)), '') as systemmodstamp,
        {% for column_name in shared_case_columns %}
            {{ sf_clean_text(column_name) }} as {{ column_name }},
        {% endfor %}
        {% for flag in status_boolean_flags %}
            {{ flag }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from case_base

),

status_history_events as (

    select
        {{ sf_generate__surrogate_key(['caseid', "'status_change'", 'lastmodifieddate','status']) }} as case_event_sk,
        caseid as case_id,
        case_base.accountid as account_id,
        case_base.contactid as contact_id,
        coalese(case_history.ownerid, case_base.ownerid) as owner_user_id,
        case_history.lastmodifieddate as event_timestamp,
        'Status Change' as event_type,
        case_history.status as status_after_event,
        case_history.previousupdate as status_before_event,
        {% for column_name in shared_case_columns %}
            {% if column_name == 'systemmodstamp' %}
                nullif(trim(cast(case_base.systemmodstamp as varchar)), '') as systemmodstamp{% if not loop.last %}, {% endif %}
            {% else %}
                {{ column_name }} as {{ column_name }}{% if not loop.last %}, {% endif %}
            {% endif %}
            {% for flag in status_boolean_flags %}
                {{ flag }}{% if not loop.last %}, {% endif %}
            {% endfor %}
        {% endfor %}
    from case_history
    left join case_base on case_history.caseid = case_base.case_id

),

all_events as (

    select * from case_created_events
    union all
    select * from status_history_events

),

ranked_events as (

    select
        case_event_sk,
        case_id,
        account_id,
        contact_id,
        owner_user_id,
        event_timestamp,
        event_type,
        status_after_event,
        status_before_event,
        lag(status_after_event) over (partition by case_id order by event_timestamp, case_event_sk) as prior_status,
        priority,
        origin,
        {% for flag in status_boolean_flags %}
            cast(coalesce({{ flag }}, false) as boolean) as {{ flag | replace('is', 'is_') }}{% if not loop.last %}, {% endif %}
        {% endfor %},
        systemmodstamp
    from all_events
),

final as (

    select
        case_event_sk,
        case_id,
        account_id,
        contact_id,
        owner_user_id,
        event_timestamp,
        event_type,
        status_after_event,
        coalesce(status_before_event, prior_status) as status_before_event,
        priority,
        origin,
        is_closed,
        is_escalated,
        systemmodstamp
    from ranked_events
    {% if is_incremental() %}
        where event_timestamp > (select coalesce(max(event_timestamp), cast('{{ initial_event_start_ts }}') from {{ this }})
    {% endif %}

)
select * from final
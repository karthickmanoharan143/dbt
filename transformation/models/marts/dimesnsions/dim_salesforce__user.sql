{{ config(tags = ['dimension','marts','user']) }}

with user as (

    select * from {{ ref('stg_salesforce__user') }}

),
user_role as (

    select * from {{ ref('stg_salesforce__user_role') }}

),
final as (

    select
        {{ sf_generate__surrogate_key(['user.user_id']) }} as user_sk,
        user.user_id,
        user.username,
        {{ sf_clean_text("coalesce(user.firstname,'') || ' ' || coalesce(user.lastname,'')") }} as full_name,
        user.firstname,
        user.lastname,
        user.email,
        user.department,
        user.title,
        user.usertype,
        user.usersubtype,
        user.userroleid as user_role_id,
        user_role.name as role_name,
        user.managerid as manager_user_id,
        cast(coalesce(user.isactive,'false') as boolean) as is_active,
        user.lastlogindate as last_login_at,
        user.createddate as user_created_date,
        user.lastmodifieddate as user_last_modified_date,
    from user
    left join user_role on user.userroleid = user_role.user_role_id

)
select * from final
{{ config(severity='warn') }}

-- Only the states present in the reference data are checked
select u.user_id, u.state, u.zip_code
from {{ ref('stg_users') }} u
join (select distinct state from {{ ref('zip_ranges') }}) s on u.state = s.state
where not exists (
    select 1
    from {{ ref('zip_ranges') }} z
    where z.state = u.state
      and u.zip_code between z.zip_min and z.zip_max
)

with source as (
    select * from {{ source('bronze', 'users') }}
),

typed as (
    select
        cast(uuid as uuid) as user_id,
        trim(username) as username,
        lower(trim(username)) as username_normalized,
        trim(name) as name,
        upper(trim(sex)) as sex,
        lower(trim(mail)) as email,
        cast(birthdate as date) as birthdate,
        split_part(address, chr(10), 1) as street,
        split_part(address, chr(10), 2) as address_line_2
    from source
),

first_orders as (
    select user_id, min(ordered_at) as first_ordered_at
    from {{ ref('stg_orders') }}
    group by user_id
)

select
    t.user_id,
    t.username,
    t.username_normalized,
    t.name,
    t.sex,
    t.email,
    -- A birthdate later than the first order is impossible: replace it with NULL
    case when f.first_ordered_at < t.birthdate then null else t.birthdate end as birthdate,
    -- True when the original birthdate passed the validation
    coalesce(not (f.first_ordered_at < t.birthdate), true) as birthdate_is_valid,
    t.street,
    nullif(regexp_extract(t.address_line_2, '^(.+), [A-Z]{2} \d{5}$', 1), '') as city,
    regexp_extract(t.address_line_2, '([A-Z]{2}) (\d{5})$', 1) as state,
    regexp_extract(t.address_line_2, '([A-Z]{2}) (\d{5})$', 2) as zip_code
from typed t
left join first_orders f on t.user_id = f.user_id

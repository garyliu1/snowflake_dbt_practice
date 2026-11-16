
-- EXERCISE: resident dimension (SCD Type 1)
-- Grain: one row per resident. Source: ref('stg_residents')
-- Columns: resident_key (surrogate key on resident_id), resident_id, first_name,
--          last_name, email, phone
-- email and phone are PII. You will mask them in Snowflake in step 7.
{{ config(
    post_hook=[
        "alter table {{ this }} modify column email set masking policy governance.mask_pii",
        "alter table {{ this }} modify column phone set masking policy governance.mask_pii"
    ]
) }}

select 
    {{ dbt_utils.generate_surrogate_key(['resident_id']) }} as resident_key,
    resident_id,
    first_name,
    last_name,
    email,
    phone
from {{ ref('stg_residents') }}
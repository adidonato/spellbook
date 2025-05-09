{% set blockchain = 'avalanche_c' %}

{{ config(
        schema = 'metrics_' + blockchain
        , alias = 'transfers_daily'
        , materialized = 'view'
        )
}}

SELECT *
FROM {{ source('tokens_avalanche_c', 'net_transfers_daily') }}

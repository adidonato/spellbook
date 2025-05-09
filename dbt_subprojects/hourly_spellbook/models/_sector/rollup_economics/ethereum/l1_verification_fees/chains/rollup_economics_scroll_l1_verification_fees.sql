{{ config(
    schema = 'rollup_economics_scroll'
    , alias = 'l1_verification_fees'  
    , materialized = 'incremental'
    , file_format = 'delta'
    , incremental_strategy = 'merge'
    , unique_key = ['name', 'tx_hash']
    , incremental_predicates = [incremental_predicate('DBT_INTERNAL_DEST.block_time')]
)}}

SELECT
    'scroll' AS name
    , cast(date_trunc('month', t.block_time) AS date) AS block_month
    , cast(date_trunc('day', t.block_time) AS date) AS block_date
    , t.block_time
    , t.block_number
    , t.hash AS tx_hash
    , t.index AS tx_index
    , t.gas_price
    , t.gas_used
    , (t.gas_price / 1e18) * t.gas_used AS verification_fee_native
    , {{ evm_get_calldata_gas_from_data('t.data') }} AS calldata_gas_used
    , 44*32 / cast(1024 AS double) / cast(1024 AS double) AS proof_size_mb
FROM {{ source('ethereum', 'transactions') }} t
WHERE t.to IN (
    0xa13BAF47339d63B743e7Da8741db5456DAc1E556
)
AND bytearray_substring(t.data, 1, 4) IN (
    0x31fa742d -- finalizeBatchWithProof
    , 0x00b0f4d7 -- finalizeBatchWithProof4844
    , 0x4f099e3d -- finalizeBundleWithProof
    , 0xc1aa4e19 -- finalizeBundlePostEuclidV2 (post-Euclid  upgrade)
)
AND t.block_time >= TIMESTAMP '2023-10-07'
{% if is_incremental() %}
AND {{incremental_predicate('t.block_time')}}
{% endif %}

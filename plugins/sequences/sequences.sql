with raw_sequences as (
select sq.relname, pn.nspname, sqs.increment_by, sqs.min_value,
case
	when min_value < 0 then -1
	else 256 ^ pa.attlen / 2
end
as max_value,
coalesce(sqs.last_value, sqs.min_value) as last_value
from pg_class sq
	join pg_depend dp on sq.oid = dp.objid
	join pg_class pc on pc.oid = dp.refobjid
	join pg_attribute pa on pa.attrelid = pc.oid and pa.attnum = dp.refobjsubid
	join pg_type pt on pa.atttypid = pt.oid
	join pg_namespace pn on pn.oid = pc.relnamespace
	join pg_sequences sqs on sqs.sequencename = sq.relname and pn.nspname = sqs.schemaname
where sq.relkind = 'S'
),
qsequences as(
select *, (max_value - min_value) / increment_by as total_values,
(max_value - coalesce(last_value, min_value)) / increment_by as remain_values from raw_sequences
)
select
extract(epoch from now())::int - (extract(epoch from now())::int % $1),
jsonb_build_object(
	'sequence_name', current_database() || '.' || nspname || '.' || relname,
	'last_value', last_value,
	'max_value', max_value,
	'remaining_capacity', remain_values::float / total_values::float * 100
)
from qsequences

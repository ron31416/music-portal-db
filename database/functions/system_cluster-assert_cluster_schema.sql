do $$begin raise exception 'do not run this file'; end$$;

create or replace function system_cluster.assert_cluster_schema(
    p_cluster_name      text,
    p_schema_name       text
)
returns void
language plpgsql
as $$

declare
    _inet_addr_expected inet;
    _inet_addr_actual   inet;

begin

execute format(
   'select inet_addr 
    from %I.v_cluster_schema 
    where cluster_name = %L 
      and schema_name  = %L',
    p_schema_name,
    p_cluster_name,
    p_schema_name
)
into _inet_addr_expected;

if _inet_addr_expected is null then
    raise exception 
        'Entry in %.v_cluster_schema missing for cluster_name "%", schema_name "%".',
        p_schema_name, 
        p_cluster_name, 
        p_schema_name;
end if;

select inet_server_addr()
into _inet_addr_actual;

if _inet_addr_actual is null then
    raise exception 
        'Entry in inet_server_addr() missing.';
end if;

if _inet_addr_expected <> _inet_addr_actual then
    raise exception 
        'Entry in inet_server_addr() is %, should be %.', 
        _inet_addr_actual,
        _inet_addr_expected;
end if;

end;
$$;

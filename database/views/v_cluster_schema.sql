do $$begin raise exception 'do not run this file'; end$$;

--drop view music_portal.v_cluster_schema;
create or replace view music_portal.v_cluster_schema as
select
    c.cluster_name      as cluster_name,
    c.cluster_url       as cluster_url,
    c.inet_addr         as inet_addr,
    cs.schema_name      as schema_name
from  music_portal.cluster_schema   as cs
 join system_cluster.cluster        as c
   on cs.cluster_name = c.cluster_name;


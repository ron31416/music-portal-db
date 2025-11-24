
begin;

do $$
declare
  v_system_environment_name text;
begin
  select system_environment_name
  into v_system_environment_name
  from public.system_environment
  limit 1;

  if v_system_environment_name is null then
    raise exception 'Guard failed: public.system_environment is empty or missing';
  end if;

  if v_system_environment_name <> 'music-portal-prod' then
    raise exception 'This script is only for the music-portal-staging database (found %)',
      v_system_environment_name;
  end if;
end
$$ language plpgsql;

--on each cluster (dev, staging, prod)
create schema system_cluster;
create schema music_portal;

create table system_cluster.cluster (
    cluster_id          smallint    default 1,
    cluster_name        text        not null,
    cluster_url         text        not null,
    inet_addr           inet        not null,
    inserted_datetime   timestamptz not null default now(),
    updated_datetime    timestamptz not null default now(),
    constraint pk_cluster primary key (
    cluster_id
    ),
    constraint uk00_cluster unique (
        cluster_name
    ),
    constraint uk01_cluster unique (
        cluster_url
    ),
    constraint uk02_cluster unique (
        inet_addr
    ),
    constraint ch00_cluster check 
        (cluster_id = 1)
);

-- on prod cluster
-- insert one row ('prod')
insert into system_cluster.cluster (
    cluster_name,
    cluster_url,
    inet_addr
)
    values (
        'prod', 
        'db.nmqyrqgrasiqmbdsiefe.supabase.co', 
        '2600:1f16:1cd0:3328:1159:35d8:5d29:739a'
);

-- on each cluster (dev, staging, prod)
create table system_cluster.cluster_schema (
    cluster_schema_id   int         generated always as identity,
    cluster_name        text        not null,
    schema_name         text        not null,
    inserted_datetime   timestamptz not null default now(),
    updated_datetime    timestamptz not null default now(),
    constraint pk_cluster_schema primary key (
        cluster_schema_id
    ),
    constraint uk00_cluster_schema unique (
        cluster_name,
        schema_name
    ),
    constraint fk00_cluster foreign key (
        cluster_name
    )
        references system_cluster.cluster (
            cluster_name
    )
);

-- on prod cluster
-- insert one row per schema ('music_portal')
insert into system_cluster.cluster_schema (
    cluster_name,
    schema_name
)
    values (
        'prod',
        'music_portal'
);

-- on each cluster (dev, staging, prod)
create table music_portal.cluster_schema (
    cluster_schema_id   int         default 1,
    cluster_name        text        not null,
    schema_name         text        not null,
    inserted_datetime   timestamptz not null default now(),
    updated_datetime    timestamptz not null default now(),
    constraint pk_cluster_schema primary key (
        cluster_schema_id
    ),
    constraint fk00_cluster_schema foreign key (
        cluster_name,
        schema_name
    )
        references system_cluster.cluster_schema (
            cluster_name,
            schema_name
    ),
    constraint ch00_cluster_schema check 
        (cluster_schema_id = 1)
);

-- on prod cluster in media_portal schema
-- insert one row ('prod'|'music_portal')
insert into music_portal.cluster_schema (
    cluster_name,
    schema_name
)
    values (
        'prod',
        'music_portal'
);

create or replace view music_portal.v_cluster_schema as
select
    c.cluster_name      as cluster_name,
    c.cluster_url       as cluster_url,
    c.inet_addr         as inet_addr,
    cs.schema_name      as schema_name
from  music_portal.cluster_schema   as cs
 join system_cluster.cluster        as c
   on cs.cluster_name = c.cluster_name;

select * from music_portal.v_cluster_schema;

drop table public.system_environment;

rollback;
--commit;
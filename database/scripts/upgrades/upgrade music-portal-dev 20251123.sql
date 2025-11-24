--do $$begin raise exception 'do not run this file'; end$$;

begin;

--on each cluster (dev, staging, prod)
create schema host;
create table host.cluster (
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

-- on dev cluster
-- insert one row ('dev')
insert into host.cluster (
    cluster_name,
    cluster_url,
    inet_addr
)
    values (
        'dev', 
        'db.arxvzfwzjbzwgirzaekn.supabase.co', 
        '2600:1f16:1cd0:3328:16fc:820a:48c5:b1ca'
);

/*
-- on staging cluster
-- insert one row ('staging')
insert into host.cluster (
    cluster_name,
    cluster_url,
    inet_addr
)
    values (
        'staging', 
        'db.egmodwcvdsyqcbnropoo.supabase.co', 
        '2600:1f18:2e13:9d2d:157a:c41d:ac2a:c532'
);

-- on prod cluster
-- insert one row ('prod')
insert into host.cluster (
    cluster_name,
    cluster_url,
    inet_addr
)
    values (
        'prod', 
        'db.nmqyrqgrasiqmbdsiefe.supabase.co', 
        '2600:1f16:1cd0:3328:1159:35d8:5d29:739a'
);
*/

-- on each cluster (dev, staging, prod)
create table host.cluster_schema (
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
        references host.cluster (
            cluster_name
        )
);

-- on dev cluster
-- insert one row per schema ('music_portal', 'media_hub')
insert into host.cluster_schema (
    cluster_name,
    schema_name
)
values (
    'dev',
    'music_portal'
);
insert into host.cluster_schema (
    cluster_name,
    schema_name
)
    values (
        'dev',
        'media_hub'
);

/*
-- on staging cluster
-- insert one row per schema ('music_portal', 'media_hub')
insert into host.cluster_schema (
    cluster_name,
    schema_name
)
    values (
        'staging',
        'music_portal'
);
insert into host.cluster_schema (
    cluster_name,
    schema_name
)
    values (
        'staging',
        'media_hub'
);

-- on prod cluster
-- insert one row per schema ('music_portal', 'media_hub')
insert into host.cluster_schema (
    cluster_name,
    schema_name
)
    values (
        'prod',
        'music_portal'
);
insert into host.cluster_schema (
    cluster_name,
    schema_name
)
    values (
        'prod',
        'media_hub'
);
*/

-- on each cluster (dev, staging, prod)
create schema music_portal;
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
        references host.cluster_schema (
            cluster_name,
            schema_name
    ),
    constraint ch00_cluster_schema check 
        (cluster_schema_id = 1)
);

-- on dev cluster in media_portal schema
-- insert one row ('dev'|'music_portal')
insert into music_portal.cluster_schema (
    cluster_name,
    schema_name
)
    values (
        'dev',
        'music_portal'
);

--one row ('dev')
select * from host.cluster; 
--one row per schema ('music_portal', 'media_hub')              
select * from host.cluster_schema; 
--one row ('dev'|'music_portal')         
select * from music_portal.cluster_schema;  

select
    c.cluster_name,
    c.cluster_url,
    c.inet_addr,
    cs.schema_name
from  music_portal.cluster_schema as cs
 join host.cluster                as c
   on cs.cluster_name = c.cluster_name;

rollback;
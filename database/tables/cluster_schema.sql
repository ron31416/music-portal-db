do $$begin raise exception 'do not run this file'; end$$;

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

do $$begin raise exception 'do not run this file'; end$$;

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

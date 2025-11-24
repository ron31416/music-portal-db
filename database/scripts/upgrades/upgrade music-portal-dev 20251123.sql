do $$begin raise exception 'do not run this file'; end$$;

begin;

create schema host;

create table host.cluster (
    cluster_id          int         generated always as identity,
    cluster_name        text        not null,
    project_ref         text        not null,
    inet_server_addr    inet        not null,
    inet_server_port    smallint    not null,
    inserted_datetime   timestamptz not null default now(),
    updated_datetime    timestamptz not null default now(),
    constraint pk_cluster primary key (
    cluster_id
    ),
    constraint uk00_cluster unique (
        cluster_name
    )
);

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

create table public.cluster_schema (
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
    constraint fk00_cluster_schema foreign key (
        cluster_name,
        schema_name
    )
        references host.cluster_schema (
            cluster_name,
            schema_name
        )
);

rollback;
do $$begin raise exception 'do not run this file'; end$$;


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

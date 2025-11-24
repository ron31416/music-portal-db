select * from song;
select * from user_song;


select user_song_get(1,1);


select * from public.user_role_list()

select * from public.user_song_measure_list(1,1)

select
  inet_server_addr(),
  inet_server_port(),
  version() as pg_version;

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

  if v_system_environment_name <> 'music-portal-staging' then
    raise exception 'This script is only for the music-portal-staging database (found %)',
      v_system_environment_name;
  end if;
end
$$ language plpgsql;

do $$
declare
    v_count int;
begin
    select count(*)
      into v_count
      from public.system_environment
      where system_environment_name = 'music-portal-dev';

    raise notice 'v_count = %', v_count;
end $$;

create table public.system_environment (
  environment_name text primary key,  -- dev | staging | prod  (or music-portal-dev, your call)
  project_ref text not null,          -- Supabase project ref
  ip_address text not null            -- expected inet_server_addr()::text
);
create table system_environment (
    application_name  text,      -- e.g. 'music-portal'
    environment_name  text,      -- e.g. 'dev' | 'staging' | 'prod'
    project_ref       text,      -- Supabase project ref
    ip_address        text,      -- expected inet_server_addr()
    schema_name       text,      -- e.g. 'music_portal'
    primary key (application_name, environment_name)
);


create table cluster (
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

create table cluster_schema (
    cluster_schema_id   int         generated always as identity,
    cluster_name        text        not null,
    schema_name         text        not null,
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
        references cluster (
            cluster_name
        )
);


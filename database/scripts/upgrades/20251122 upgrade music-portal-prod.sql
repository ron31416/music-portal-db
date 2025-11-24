
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


create or replace function public.skill_level_list()
returns table (
    skill_level_number  int,
    skill_level_name    text
)
language plpgsql
stable
as $$
begin
    return query
    select
      sl.skill_level_number, 
      sl.skill_level_name
    from  public.skill_level as sl
    order by
      sl.skill_level_number;
end
$$;

revoke all on function public.skill_level_list()
  from public, authenticated, anon;
grant execute on function public.skill_level_list()
  to service_role;


create or replace function public.song_upsert(
    p_song_id               int,
    p_song_title            text,
    p_composer_first_name   text,
    p_composer_last_name    text,
    p_skill_level_number    int,
    p_file_name             text,
    p_song_mxl              bytea
)
returns int
language plpgsql
as $$
declare
    v_song_id int;
begin
    if p_song_id is null then
        insert into public.song (
            song_title,
            composer_first_name,
            composer_last_name,
            skill_level_number,
            file_name,
            song_mxl
        )
        values (
            p_song_title,
            p_composer_first_name,
            p_composer_last_name,
            p_skill_level_number,
            p_file_name,
            p_song_mxl
        )
        returning song_id into v_song_id;
        return v_song_id;
    else
        update public.song
        set
            song_title           = p_song_title,
            composer_first_name  = p_composer_first_name,
            composer_last_name   = p_composer_last_name,
            skill_level_number   = p_skill_level_number,
            file_name            = p_file_name,
            song_mxl             = p_song_mxl,
            updated_datetime     = now()
        where song_id = p_song_id;
        if found then
            return p_song_id;
        else
            raise exception 'song_id % not found', p_song_id
               using errcode = 'P0002';  -- no_data_found
        end if;
    end if;
end
$$;

revoke all on function public.song_upsert(int, text, text, text, int, text, bytea)
  from public, authenticated, anon;
grant execute on function public.song_upsert(int, text, text, text, int, text, bytea)
  to service_role;


create or replace function public.user_role_list()
returns table (
    user_role_number  integer,
    user_role_name    text
)
language plpgsql
stable
as $$
begin
    return query
    select
      ur.user_role_number, 
      ur.user_role_name
    from  public.user_role as ur
    order by
      ur.user_role_number;
end
$$;

revoke all on function public.user_role_list()
  from public, authenticated, anon;
grant execute on function public.user_role_list()
  to service_role;


create or replace function public.user_song_get(
  p_user_id int,
  p_song_id int
)
returns table (
  user_song_id int,
  user_id      int,
  song_id      int,
  inserted_datetime timestamptz,
  updated_datetime  timestamptz
)
language plpgsql
stable
as $$
begin
  return query
  select
    us.user_song_id,
    us.user_id,
    us.song_id,
    us.inserted_datetime,
    us.updated_datetime
  from public.user_song as us
  where us.user_id = p_user_id
    and us.song_id = p_song_id;
end
$$;

revoke all on function public.user_song_get(int, int)
  from public, authenticated, anon;
grant execute on function public.user_song_get(int, int)
  to service_role;


create or replace function public.user_song_insert(
  p_user_id         int,
  p_song_id         int
)
returns int
language plpgsql
as $$
declare
    v_user_song_id int;
begin
    insert into public.user_song (
        user_id,
        song_id
    )
    values (
        p_user_id,
        p_song_id
    )
    returning user_song_id into v_user_song_id;
    return v_user_song_id;
end
$$;

revoke all on function public.user_song_insert(int, int)
  from public, authenticated, anon;
grant execute on function public.user_song_insert(int,int)
  to service_role;


create or replace function public.user_song_measure_insert(
  p_user_id          int,
  p_song_id          int,
  p_measure_number   smallint,
  p_annotations_json jsonb
)
returns int
language plpgsql
as $$
declare
    v_user_song_measure_id int;
begin
    insert into public.user_song_measure (
        user_id,
        song_id,
        measure_number,
        annotations_json
    )
    values (
        p_user_id,
        p_song_id,
        p_measure_number,
        p_annotations_json
    )
    returning user_song_measure_id into v_user_song_measure_id;
    return v_user_song_measure_id;
end
$$;

revoke all on function public.user_song_measure_insert(int, int, smallint, jsonb)
  from public, authenticated, anon;
grant execute on function public.user_song_measure_insert(int, int, smallint, jsonb)
  to service_role;


create or replace function public.user_song_measure_list(
  p_user_id         int,
  p_song_id         int
)
returns table (
  measure_number        smallint,
  annotations_json      jsonb,
  inserted_datetime     timestamptz,
  updated_datetime      timestamptz
)
language plpgsql
stable
as $$
begin
    return query
    select
        usm.measure_number,
        usm.annotations_json,
        usm.inserted_datetime,
        usm.updated_datetime
    from  public.user_song_measure as usm
    where usm.user_id = p_user_id and
          usm.song_id = p_song_id
    order by usm.measure_number;
end
$$;

revoke all on function public.user_song_measure_list(int, int)
  from public, authenticated, anon;
grant execute on function public.user_song_measure_list(int, int)
  to service_role;


create or replace function public.user_song_measure_update(
  p_user_id          int,
  p_song_id          int,
  p_measure_number   smallint,
  p_annotations_json jsonb
)
returns int
language plpgsql
as $$
declare
    v_user_song_measure_id int;
begin
    update public.user_song_measure as usm
    set
        annotations_json = p_annotations_json,
        updated_datetime = now()
    where usm.user_id        = p_user_id
      and usm.song_id        = p_song_id
      and usm.measure_number = p_measure_number
    returning usm.user_song_measure_id into v_user_song_measure_id;

    if not found then
        raise exception
          'user_song_measure not found for (user_id %, song_id %, measure_number %)',
          p_user_id, p_song_id, p_measure_number
          using errcode = 'P0002';  -- no_data_found
    end if;

    return v_user_song_measure_id;
end
$$;

revoke all on function public.user_song_measure_update(int, int, smallint, jsonb)
  from public, authenticated, anon;
grant execute on function public.user_song_measure_update(int, int, smallint, jsonb)
  to service_role;


rollback;
--commit;

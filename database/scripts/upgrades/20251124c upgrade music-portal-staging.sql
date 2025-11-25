begin;

select system_cluster.assert_cluster_schema('staging', 'music_portal');

revoke usage on schema music_portal from public, anon, authenticated;
grant usage on schema music_portal to service_role;

alter table public.skill_level set schema music_portal;
alter table public.song set schema music_portal;
alter table public.user_role set schema music_portal;
alter table public.site_user set schema music_portal;
alter table public.user_song set schema music_portal;
alter table public.user_song_measure set schema music_portal;

alter function public.skill_level_list() set schema music_portal;
create or replace function music_portal.skill_level_list()
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
    from  music_portal.skill_level as sl
    order by
      sl.skill_level_number;
end
$$;
revoke all on function music_portal.skill_level_list() from public, authenticated, anon;
grant execute on function music_portal.skill_level_list() to service_role;

alter function public.song_delete(int) set schema music_portal;
create or replace function music_portal.song_delete(
  p_song_id int
)
returns int
language plpgsql
as $$
declare
  v_count int;
begin
  delete from music_portal.song as s
    where s.song_id = p_song_id;
  get diagnostics v_count = row_count;
  return v_count;
end
$$;
revoke all on function music_portal.song_delete(int) from public, authenticated, anon;
grant execute on function music_portal.song_delete(int) to service_role;

alter function public.song_list(text, text) set schema music_portal;
create or replace function music_portal.song_list(
  p_sort_column     text default 'composer_last_name',
  p_sort_direction  text default 'asc'
)
returns table (
  song_id               int,
  song_title            text,
  composer_first_name   text,
  composer_last_name    text,
  skill_level_number    int,
  skill_level_name      text,
  file_name             text,
  inserted_datetime     timestamptz,
  updated_datetime      timestamptz
)
language plpgsql
stable
as $$
declare
  order_clause text;
begin
  if p_sort_direction not in ('asc', 'desc') then
    raise exception 'Invalid sort_direction: %, must be "asc" or "desc"', p_sort_direction
      using errcode = '22023'; -- invalid_parameter_value
  end if;
  case p_sort_column
    when 'composer_last_name' then
      order_clause := format('s.composer_last_name %s, s.composer_first_name ASC, s.song_title ASC, s.skill_level_number ASC', p_sort_direction);
    when 'composer_first_name' then
      order_clause := format('s.composer_first_name %s, s.composer_last_name ASC, s.song_title ASC, s.skill_level_number ASC', p_sort_direction);
    when 'song_title' then
      order_clause := format('s.song_title %s, s.composer_last_name ASC, s.composer_first_name ASC, s.skill_level_number ASC', p_sort_direction);
    when 'skill_level_name', 'skill_level_number' then
      order_clause := format('s.skill_level_number %s, s.composer_last_name ASC, s.composer_first_name ASC, s.song_title ASC', p_sort_direction);
    when 'updated_datetime' then
      order_clause := format('s.updated_datetime %s, s.composer_last_name ASC, s.composer_first_name ASC, s.song_title ASC, s.skill_level_number ASC', p_sort_direction);
    when 'inserted_datetime' then
      order_clause := format('s.inserted_datetime %s, s.composer_last_name ASC, s.composer_first_name ASC, s.song_title ASC, s.skill_level_number ASC', p_sort_direction);
    when 'file_name' then
      order_clause := format('s.file_name %s', p_sort_direction);
    else
      order_clause := format('s.composer_last_name %s, s.composer_first_name ASC, s.song_title ASC, s.skill_level_number ASC', p_sort_direction);
  end case;
  return query execute format(
    'select
       s.song_id,
       s.song_title,
       s.composer_first_name,
       s.composer_last_name,
       s.skill_level_number,
       sl.skill_level_name,
       s.file_name,
       s.inserted_datetime,
       s.updated_datetime
     from  music_portal.song as s
      join music_portal.skill_level as sl
        on sl.skill_level_number = s.skill_level_number
     order by %s', order_clause
  );
end
$$;
revoke all on function music_portal.song_list(text, text) from public, authenticated, anon;
grant execute on function music_portal.song_list(text, text) to service_role;

alter function public.song_mxl_get(int) set schema music_portal;
create or replace function music_portal.song_mxl_get(
  p_song_id int
)
returns table (
    song_mxl    bytea
)
language plpgsql
stable
as $$
begin
    return query
    select 
      s.song_mxl
    from  music_portal.song as s
    where s.song_id = p_song_id;
end
$$;
revoke all on function music_portal.song_mxl_get(int) from public, authenticated, anon;
grant execute on function music_portal.song_mxl_get(int) to service_role;

alter function public.song_upsert(int, text, text, text, int, text, bytea) set schema music_portal;
create or replace function music_portal.song_upsert(
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
        insert into music_portal.song (
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
        update music_portal.song
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
revoke all on function music_portal.song_upsert(int, text, text, text, int, text, bytea) from public, authenticated, anon;
grant execute on function music_portal.song_upsert(int, text, text, text, int, text, bytea) to service_role;

alter function public.user_delete(int) set schema music_portal;
create or replace function music_portal.user_delete(
  p_user_id int
)
returns int
language plpgsql
as $$
declare
  v_count int;
begin
  delete from music_portal.site_user
  where user_id = p_user_id;
  get diagnostics v_count = row_count;
  return v_count;
end
$$;
revoke all on function music_portal.user_delete(int) from public, authenticated, anon;
grant execute on function music_portal.user_delete(int) to service_role;

alter function public.user_get(int, text) set schema music_portal;
create or replace function music_portal.user_get(
  p_user_id    int   default null,
  p_user_email text  default null
)
returns table (
  user_id           int,
  user_email        text,
  user_first_name   text,
  user_last_name    text,
  user_role_number  int,
  user_role_name    text,
  inserted_datetime timestamptz,
  updated_datetime  timestamptz
)
language plpgsql
stable
as $$
declare
  v_user_email text := 
    case
    when p_user_email is null then null
    else lower(btrim(p_user_email))
    end;
begin
  if (p_user_id is null and v_user_email is null) or 
     (p_user_id is not null and v_user_email is not null) then
    raise exception 'Provide exactly one of (user_id, user_email)'
      using errcode = '22023'; -- invalid_parameter_value
  end if;
  if p_user_id is not null then
    return query
    select
      u.user_id, 
      u.user_email, 
      u.user_first_name, 
      u.user_last_name,
      u.user_role_number, 
      ur.user_role_name,
      u.inserted_datetime, 
      u.updated_datetime
    from music_portal.site_user as u
    join music_portal.user_role as ur
      on ur.user_role_number = u.user_role_number
    where u.user_id = p_user_id
    limit 1;
    return;
  end if;
  if v_user_email = '' then
    raise exception 'User_email is required when user_id is null'
      using errcode = '22023';
  end if;
  return query
  select
    u.user_id, 
    u.user_email, 
    u.user_first_name, 
    u.user_last_name,
    u.user_role_number, 
    ur.user_role_name,
    u.inserted_datetime, 
    u.updated_datetime
  from music_portal.site_user as u
  join music_portal.user_role as ur
    on ur.user_role_number = u.user_role_number
  where u.user_email = v_user_email
  limit 1;
end
$$;
revoke all on function music_portal.user_get(int, text) from public, authenticated, anon;
grant execute on function music_portal.user_get(int, text) to service_role;

alter function public.user_list(text, text) set schema music_portal;
create or replace function music_portal.user_list(
  p_sort_column     text default 'user_email',
  p_sort_direction  text default 'asc'
)
returns table (
  user_id           int,
  user_email        text,
  user_first_name   text,
  user_last_name    text,
  user_role_number  int,
  user_role_name    text,
  inserted_datetime timestamptz,
  updated_datetime  timestamptz
)
language plpgsql
stable
as $$
declare
  v_sort_column    text := lower(coalesce(p_sort_column, 'user_email'));
  v_sort_direction text := lower(coalesce(p_sort_direction, 'asc'));
  order_clause     text;
begin
  if v_sort_direction not in ('asc', 'desc') then
    raise exception 'Invalid sort_direction: %, must be "asc" or "desc"', v_sort_direction
      using errcode = '22023';
  end if;
  case v_sort_column
    when 'user_email' then
      order_clause := format('u.user_email %s', v_sort_direction);
    when 'user_first_name' then
      order_clause := format('u.user_first_name %s, u.user_last_name asc, u.user_email asc', v_sort_direction);
    when 'user_last_name' then
      order_clause := format('u.user_last_name %s, u.user_first_name asc, u.user_email asc', v_sort_direction);
    when 'user_role_number' then
      order_clause := format('u.user_role_number %s, u.user_email asc', v_sort_direction);
    when 'updated_datetime' then
      order_clause := format('u.updated_datetime %s, u.user_email asc', v_sort_direction);
    when 'inserted_datetime' then
      order_clause := format('u.inserted_datetime %s, u.user_email asc', v_sort_direction);
    else
      order_clause := format('u.user_email %s', v_sort_direction);
  end case;

  return query execute format(
    'select
       u.user_id,
       u.user_email,
       u.user_first_name,
       u.user_last_name,
       u.user_role_number,
       ur.user_role_name,
       u.inserted_datetime,
       u.updated_datetime
     from music_portal.site_user as u
     join music_portal.user_role as ur
       on ur.user_role_number = u.user_role_number
     order by %s', order_clause
  );
end
$$;
revoke all on function music_portal.user_list(text, text) from public, authenticated, anon;
grant execute on function music_portal.user_list(text, text) to service_role;

alter function public.user_role_list() set schema music_portal;
create or replace function music_portal.user_role_list()
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
    from  music_portal.user_role as ur
    order by
      ur.user_role_number;
end
$$;
revoke all on function music_portal.user_role_list() from public, authenticated, anon;
grant execute on function music_portal.user_role_list() to service_role;

alter function public.user_song_get(int, int) set schema music_portal;
create or replace function music_portal.user_song_get(
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
  from music_portal.user_song as us
  where us.user_id = p_user_id
    and us.song_id = p_song_id;
end
$$;
revoke all on function music_portal.user_song_get(int, int) from public, authenticated, anon;
grant execute on function music_portal.user_song_get(int, int) to service_role;

alter function public.user_song_insert(int,int) set schema music_portal;
create or replace function music_portal.user_song_insert(
  p_user_id         int,
  p_song_id         int
)
returns int
language plpgsql
as $$
declare
    v_user_song_id int;
begin
    insert into music_portal.user_song (
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
revoke all on function music_portal.user_song_insert(int, int) from public, authenticated, anon;
grant execute on function music_portal.user_song_insert(int,int) to service_role;

alter function public.user_song_measure_insert(int, int, smallint, jsonb) set schema music_portal;
create or replace function music_portal.user_song_measure_insert(
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
    insert into music_portal.user_song_measure (
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
revoke all on function music_portal.user_song_measure_insert(int, int, smallint, jsonb) from public, authenticated, anon;
grant execute on function music_portal.user_song_measure_insert(int, int, smallint, jsonb) to service_role;

alter function public.user_song_measure_list(int, int) set schema music_portal;
create or replace function music_portal.user_song_measure_list(
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
    from  music_portal.user_song_measure as usm
    where usm.user_id = p_user_id and
          usm.song_id = p_song_id
    order by usm.measure_number;
end
$$;
revoke all on function music_portal.user_song_measure_list(int, int) from public, authenticated, anon;
grant execute on function music_portal.user_song_measure_list(int, int) to service_role;

alter function public.user_song_measure_update(int, int, smallint, jsonb) set schema music_portal;
create or replace function music_portal.user_song_measure_update(
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
    update music_portal.user_song_measure as usm
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
revoke all on function music_portal.user_song_measure_update(int, int, smallint, jsonb) from public, authenticated, anon;
grant execute on function music_portal.user_song_measure_update(int, int, smallint, jsonb) to service_role;

alter function public.user_upsert(int, text, text, text, int) set schema music_portal;
create or replace function music_portal.user_upsert(
  p_user_id           int,
  p_user_email        text,
  p_user_first_name   text,
  p_user_last_name    text,
  p_user_role_number  int
) returns int
language plpgsql
as $$
declare
  v_user_id            int;
  v_user_email         text := lower(btrim(coalesce(p_user_email, '')));
  v_user_first_name    text := btrim(coalesce(p_user_first_name, ''));
  v_user_last_name     text := btrim(coalesce(p_user_last_name, ''));
begin
  if v_user_email = '' then
    raise exception 'User email is required' using errcode = '22000';
  end if;
  if v_user_first_name = '' then
    raise exception 'User first name is required' using errcode = '22000';
  end if;
  if p_user_id is null then
    insert into music_portal.site_user (
      user_email,
      user_first_name,
      user_last_name,
      user_role_number
    )
    values (
      v_user_email,
      v_user_first_name,
      v_user_last_name,
      p_user_role_number
    )
    returning user_id into v_user_id;
    return v_user_id;
  else
    update music_portal.site_user
    set user_email       = v_user_email,
        user_first_name  = v_user_first_name,
        user_last_name   = v_user_last_name,
        user_role_number = p_user_role_number,
        updated_datetime = now()
    where user_id = p_user_id;

    if found then
      return p_user_id;
    else
      raise exception 'user_id % not found', p_user_id
        using errcode = 'P0002'; -- no_data_found
    end if;
  end if;
end
$$;
revoke all on function music_portal.user_upsert(int, text, text, text, int) from public, authenticated, anon;
grant execute on function music_portal.user_upsert(int, text, text, text, int) to service_role;

rollback;
--commit;

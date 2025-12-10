do $$begin raise exception 'do not run this file'; end$$;

--drop function music_portal.user_song_upsert(int, text, int);
create or replace function music_portal.user_song_upsert(
  p_user_id         int   default null,
  p_user_email      text  default null,
  p_song_id         int   default null
)
returns int
language plpgsql
set search_path = music_portal
as $$
declare
  v_user_id       int;
  v_user_email    text := 
    case
    when p_user_email is null then null
    else lower(btrim(p_user_email))
    end;
  v_user_song_id  int;
begin
    v_user_id = p_user_id;
    if v_user_id is null then
      if v_user_email is null then
        raise exception 'User Id or Email is required' using errcode = '22000';
      end if;
      select
          u.user_id
        into
          v_user_id
      from site_user as u
      where u.user_email = v_user_email
      limit 1;
      if v_user_id is null then
        raise exception 'User Email is invalid' using errcode = '22000';
      end if;
    end if;
    insert into user_song (
        user_id,
        song_id
    )
    values (
        v_user_id,
        p_song_id
    )
    on conflict (user_id, song_id)
    do update
      set updated_datetime = now()
    returning user_song_id
      into v_user_song_id;

    return v_user_song_id;
end
$$;
revoke all on function music_portal.user_song_upsert(int, text, int) from public, authenticated, anon;
grant execute on function music_portal.user_song_upsert(int, text, int) to service_role;

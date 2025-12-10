do $$begin raise exception 'do not run this file'; end$$;


--drop function if exists music_portal.user_song_get(int, int);
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
set search_path = music_portal
as $$
begin
  return query
  select
    us.user_song_id,
    us.user_id,
    us.song_id,
    us.inserted_datetime,
    us.updated_datetime
  from user_song as us
  where us.user_id = p_user_id
    and us.song_id = p_song_id;
end
$$;
revoke all on function music_portal.user_song_get(int, int) from public, authenticated, anon;
grant execute on function music_portal.user_song_get(int, int) to service_role;

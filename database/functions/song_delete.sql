do $$begin raise exception 'do not run this file'; end$$;


--drop function music_portal.song_delete(int)
create or replace function music_portal.song_delete(
  p_song_id int
)
returns int
language plpgsql
set search_path = music_portal
as $$
declare
  v_count int;
begin
  delete 
  from song as s
  where s.song_id = p_song_id;
  get diagnostics v_count = row_count;
  return v_count;
end
$$;
revoke all on function music_portal.song_delete(int) from public, authenticated, anon;
grant execute on function music_portal.song_delete(int) to service_role;


do $$begin raise exception 'do not run this file'; end$$;


--drop function music_portal.song_mxl_get(int)
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


do $$begin raise exception 'do not run this file'; end$$;


--drop function music_portal.user_song_insert(int,int)
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



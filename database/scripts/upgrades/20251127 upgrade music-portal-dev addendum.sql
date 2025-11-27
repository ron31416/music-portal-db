begin;

select system_cluster.assert_cluster_schema('dev', 'music_portal');

drop function music_portal.user_song_insert(int,int);

create or replace function music_portal.user_song_upsert(
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
    on conflict (user_id, song_id)
    do update
      set updated_datetime = now()
    returning user_song_measure_id
      into v_user_song_id;

    return v_user_song_id;
end
$$;
revoke all on function music_portal.user_song_upsert(int,int) from public, authenticated, anon;
grant execute on function music_portal.user_song_upsert(int,int) to service_role;

rollback;
--commit;

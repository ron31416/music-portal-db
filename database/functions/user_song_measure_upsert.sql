do $$begin raise exception 'do not run this file'; end$$;


--drop function music_portal.user_song_measure_upsert(int, int, smallint, jsonb);
create or replace function music_portal.user_song_measure_upsert(
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
    on conflict (user_id, song_id, measure_number)
    do update
      set annotations_json = excluded.annotations_json,
          updated_datetime = now()
    returning user_song_measure_id
      into v_user_song_measure_id;

    return v_user_song_measure_id;
end
$$;
revoke all on function music_portal.user_song_measure_upsert(int, int, smallint, jsonb) from public, authenticated, anon;
grant execute on function music_portal.user_song_measure_upsert(int, int, smallint, jsonb) to service_role;

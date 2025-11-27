begin;

select system_cluster.assert_cluster_schema('staging', 'music_portal');

drop function music_portal.user_song_measure_update(int, int, smallint, jsonb);

drop function music_portal.user_song_measure_insert(int, int, smallint, jsonb);

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

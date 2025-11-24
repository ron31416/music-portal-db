do $$begin raise exception 'do not run this file'; end$$;


--drop function music_portal.user_song_measure_list(int, int);
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


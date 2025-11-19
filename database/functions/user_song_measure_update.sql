do $$begin raise exception 'do not run this file'; end$$;


--drop function public.user_song_measure_update(int, int, smallint, jsonb)
create function public.user_song_measure_update(
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
    update public.user_song_measure as usm
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

revoke all on function public.user_song_measure_update(int, int, smallint, jsonb)
  from public, authenticated, anon;
grant execute on function public.user_song_measure_update(int, int, smallint, jsonb)
  to service_role;
do $$begin raise exception 'do not run this file'; end$$;


--drop function public.user_song_measure_insert(int, int, smallint, jsonb);
create or replace function public.user_song_measure_insert(
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
    insert into public.user_song_measure (
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
    returning user_song_measure_id into v_user_song_measure_id;
    return v_user_song_measure_id;
end
$$;

revoke all on function public.user_song_measure_insert(int, int, smallint, jsonb)
  from public, authenticated, anon;
grant execute on function public.user_song_measure_insert(int, int, smallint, jsonb)
  to service_role;
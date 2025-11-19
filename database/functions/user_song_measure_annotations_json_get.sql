do $$begin raise exception 'do not run this file'; end$$;


--drop function public.user_song_measure_annotations_json_get(int, int, smallint);
create or replace function public.user_song_measure_annotations_json_get(
  p_user_id         int,
  p_song_id         int,
  p_measure_number  smallint
)
returns table (
  annotations_json  jsonb
)
language plpgsql
stable
as $$
begin
    return query
    select
        usm.annotations_json
    from public.user_song_measure as usm
    where usm.user_id        = p_user_id and
          usm.song_id        = p_song_id and
          usm.measure_number = p_measure_number
    ;
end
$$;

revoke all on function public.user_song_measure_annotations_json_get(int, int, smallint)
  from public, authenticated, anon;
grant execute on function public.user_song_measure_annotations_json_get(int, int, smallint)
  to service_role;

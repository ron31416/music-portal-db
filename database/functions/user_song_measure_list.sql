do $$begin raise exception 'do not run this file'; end$$;


--drop function public.user_song_measure_list(int, int);
create or replace function public.user_song_measure_list(
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
        measure_number,
        annotations_json,
        inserted_datetime,
        updated_datetime
    from  public.user_song_measure as usm
    where usm.user_id = p_user_id and
          usm.song_id = p_song_id
    order by usm.measure_number;
end
$$;

revoke all on function public.user_song_measure_list(int, int)
  from public, authenticated, anon;
grant execute on function public.user_song_measure_list(int, int)
  to service_role;


do $$begin raise exception 'do not run this file'; end$$;


--drop function music_portal.user_delete(int);
create or replace function music_portal.user_delete(
  p_user_id int
)
returns int
language plpgsql
as $$
declare
  v_count int;
begin
  delete from music_portal.site_user
  where user_id = p_user_id;
  get diagnostics v_count = row_count;
  return v_count;
end
$$;
revoke all on function music_portal.user_delete(int) from public, authenticated, anon;
grant execute on function music_portal.user_delete(int) to service_role;


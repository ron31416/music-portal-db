do $$begin raise exception 'do not run this file'; end$$;


--drop function music_portal.user_role_list();
create or replace function music_portal.user_role_list()
returns table (
    user_role_number  integer,
    user_role_name    text
)
language plpgsql
stable
set search_path = music_portal
as $$
begin
    return query
    select
      ur.user_role_number, 
      ur.user_role_name
    from user_role as ur
    order by
      ur.user_role_number;
end
$$;
revoke all on function music_portal.user_role_list() from public, authenticated, anon;
grant execute on function music_portal.user_role_list() to service_role;


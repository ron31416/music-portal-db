do $$begin raise exception 'do not run this file'; end$$;


--drop function music_portal.skill_level_list();
create or replace function music_portal.skill_level_list()
returns table (
    skill_level_number  int,
    skill_level_name    text
)
language plpgsql
stable
set search_path = music_portal
as $$
begin
    return query
    select
      sl.skill_level_number, 
      sl.skill_level_name
    from skill_level as sl
    order by
      sl.skill_level_number;
end
$$;
revoke all on function music_portal.skill_level_list() from public, authenticated, anon;
grant execute on function music_portal.skill_level_list() to service_role;


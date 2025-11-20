do $$begin raise exception 'do not run this file'; end$$;


--drop function public.skill_level_list(int, text);
create or replace function public.skill_level_list()
returns table (
    skill_level_number  int,
    skill_level_name    text
)
language plpgsql
stable
as $$
begin
    select
      sl.skill_level_number, 
      sl.skill_level_name
    from  public.skill_level as sl
    order by
      sl.skill_level_number;
end
$$;

revoke all on function public.skill_level_list()
  from public, authenticated, anon;
grant execute on function public.skill_level_list()
  to service_role;


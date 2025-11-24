do $$begin raise exception 'do not run this file'; end$$;


--drop table music_portal.skill_level;
create table music_portal.skill_level (
  skill_level_id      int         generated always as identity,
  skill_level_number  int         not null,
  skill_level_name    text        not null,
  inserted_datetime   timestamptz not null default now(),
  updated_datetime    timestamptz not null default now(),
  constraint pk_skill_level primary key (
    skill_level_id
  ),
  constraint uk00_skill_level unique (
    skill_level_number
  ),
  constraint uk01_skill_level unique (
    skill_level_name
  )
);

insert into music_portal.skill_level (skill_level_number, skill_level_name) values (1, 'Beginner');
insert into music_portal.skill_level (skill_level_number, skill_level_name) values (2, 'Intermediate');
insert into music_portal.skill_level (skill_level_number, skill_level_name) values (3, 'Advanced');


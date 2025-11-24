do $$begin raise exception 'do not run this file'; end$$;

create schema music_portal;

revoke usage on schema music_portal from public, anon, authenticated;
grant usage on schema music_portal to service_role;


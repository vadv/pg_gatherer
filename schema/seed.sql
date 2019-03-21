-- agent
create user gatherer;
alter user gatherer password  'gatherer_password';
grant usage on schema gatherer to gatherer;
grant execute on all functions in schema gatherer to gatherer;

-- manager
insert into manager.host (name, agent_token, databases) values ('localhost', 'Reech2ee', '{postgres}'::text[]);
create user agent password 'agent_password';
grant usage on schema agent to agent;
grant execute on all functions in schema agent to agent;
create user manager with password 'manager_password';
grant usage on schema manager to manager;
grant SELECT ON ALL tables in schema  manager to manager;
grant execute on all functions in schema manager to manager;
alter default privileges in schema manager grant select ON tables TO manager ;

create user grafana_reader password 'grafana_reader_password';
grant USAGE on SCHEMA manager to grafana_reader;
grant SELECT on ALL tables in schema manager to grafana_reader;
 alter default privileges in schema manager grant select ON tables TO grafana_reader ;

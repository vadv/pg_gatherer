-- agent
create user gatherer;
alter user gatherer password  'gatherer_password';
grant usage on schema gatherer to gatherer;
grant execute on all functions in schema gatherer to gatherer;

-- manager
insert into manager.host (name, agent_token) values ('localhost', 'Reech2ee');
grant usage on schema agent to agent;
grant execute on all functions in schema agent to agent;

create user grafana_reader password 'grafana_reader_password';
grant USAGE on SCHEMA manager to grafana_reader;
grant SELECT on ALL tables in schema manager to grafana_reader;

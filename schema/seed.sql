-- agent
create user gatherer;
alter user gatherer password  'gatherer_password';
grant usage on schema gatherer to gatherer;
grant execute on all functions in schema gatherer to gatherer;

-- manager
insert into manager.host (name, agent_token) values ('localhost', 'Reech2ee');
grant usage on schema agent to agent;
grant execute on all functions in schema agent to agent;

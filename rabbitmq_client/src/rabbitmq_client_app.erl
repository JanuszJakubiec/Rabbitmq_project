%%%-------------------------------------------------------------------
%% @doc rabbitmq_client public API
%% @end
%%%-------------------------------------------------------------------

-module(rabbitmq_client_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, [ClientName]) ->
    ets:new(environment_variables, [set, protected, named_table]),
    ets:insert(environment_variables, {client_name, ClientName}),
    rabbitmq_client_sup:start_link(ClientName).

stop(_State) ->
    ok.

%% internal functions

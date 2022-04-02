%%%-------------------------------------------------------------------
%% @doc rabbitmq_admin public API
%% @end
%%%-------------------------------------------------------------------

-module(rabbitmq_admin_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    rabbitmq_admin_sup:start_link().

stop(_State) ->
    ok.

%% internal functions

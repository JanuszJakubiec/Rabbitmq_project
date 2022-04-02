%%%-------------------------------------------------------------------
%% @doc rabbitmq_client top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(rabbitmq_client_sup).

-behaviour(supervisor).

-export([start_link/1]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link(ClientName) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, [ClientName]).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([ClientName]) ->
    SupFlags = #{strategy => one_for_one,
                 intensity => 0,
                 period => 1},
    ChildSpecs = [#{id => ClientName,
                    start => {rabbitmq_client_listener, start, [ClientName]}
                   }],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions

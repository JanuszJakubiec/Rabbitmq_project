%%%-------------------------------------------------------------------
%% @doc rabbitmq_producent top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(rabbitmq_producent_sup).

-behaviour(supervisor).

-export([start_link/1]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link(Data) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, Data).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([ProducentsName, Products]) ->
    SupFlags = #{strategy => one_for_all,
                 intensity => 0,
                 period => 1},
    ChildSpecs = [#{id => ProducentsName,
                    start => {rabbitmq_producent_listener, start, [ProducentsName]}
                   }],
    ChildSpecsExtended = lists:foldl(fun(Product, Acc) ->
        Acc ++ [#{id => <<ProducentsName/binary, Product/binary>>,
                  start => {rabbitmq_message_broker, start, [ProducentsName, Product]}}]
    end, ChildSpecs, Products),
    {ok, {SupFlags, ChildSpecsExtended}}.

%% internal functions

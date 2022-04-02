%%%-------------------------------------------------------------------
%% @doc rabbitmq_producent public API
%% @end
%%%-------------------------------------------------------------------

-module(rabbitmq_producent_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, [ProducentsName, Products]) ->
    {Connection, Channel} = objects_creator:create_new_connection(),
    ProductsExchange = <<"ProductsExchange">>,
    ProducentsExchange = <<"ProducentExchange">>,
    AdminProducentsExchange = <<"AdminProducentExchange">>,
    ProducentsQueue = <<ProducentsName/binary, <<"Queue">>/binary>>,

    objects_creator:create_exchange(Channel, ProductsExchange, <<"topic">>),
    objects_creator:create_exchange(Channel, ProducentsExchange, <<"topic">>),
    objects_creator:create_exchange(Channel, AdminProducentsExchange, <<"fanout">>),
    objects_creator:create_queue(Channel, ProducentsQueue),
    objects_creator:bind_queue(Channel, ProducentsQueue, ProducentsExchange, ProducentsName),
    objects_creator:bind_queue(Channel, ProducentsQueue, AdminProducentsExchange, ProducentsName),

    lists:foreach(fun(ProductName) ->
        objects_creator:create_queue(Channel, ProductName),
        objects_creator:bind_queue(Channel, ProductName, ProductsExchange, ProductName)
    end, Products),
    amqp_channel:close(Channel),
    amqp_connection:close(Connection),
    rabbitmq_producent_sup:start_link([ProducentsName, Products]).

stop(_State) ->
    ok.

%% internal functions

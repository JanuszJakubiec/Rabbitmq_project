-module(rabbitmq_admin_listener).

-include_lib("amqp_client/include/amqp_client.hrl").

-behaviour(gen_server).

-type gen_server_start() :: {ok, pid()} | ignore | {error, any()}.

-export([start/0, init/1, handle_continue/2, terminate/2]).

-spec start() -> gen_server_start().
start() ->
    gen_server:start_link(?MODULE, {}, []).


init(_) ->
    {Connection, Channel} = objects_creator:create_new_connection(),
    Queue = <<"AdminQueue">>,
    create_infrastructure(Channel, Queue),
    Tag = objects_creator:subscribe_to_queue(Channel, Queue),
    {ok, {Connection, Channel, Tag}, {continue, []}}.

create_infrastructure(Channel, QueueName) ->
    objects_creator:create_queue(Channel, QueueName),
    objects_creator:bind_queue(Channel, QueueName, <<"ClientsExchange">>, <<"*">>),
    objects_creator:bind_queue(Channel, QueueName, <<"ProductsExchange">>, <<"*">>),
    objects_creator:bind_queue(Channel, QueueName, <<"ProducentExchange">>, <<"*">>).

handle_continue(_, {Connection, Channel, Tag}) ->
    receive
        #'basic.consume_ok'{} ->
            {noreply, {Connection, Channel, Tag}, {continue, []}};
        #'basic.cancel_ok'{} ->
            {stop, <<"disconnected\n">>, {}};
        {#'basic.deliver'{delivery_tag = DeliveryTag}, Content} ->
            #amqp_msg{payload = Message} = Content,
            io:format(<<<<"Message in system: ">>/binary, Message/binary>>),
            io:format(<<"\n">>),
            amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = DeliveryTag}),
            {noreply, {Connection, Channel, Tag}, {continue, []}}
    end.

terminate(Reason, {}) ->
    io:format(Reason),
    ok.

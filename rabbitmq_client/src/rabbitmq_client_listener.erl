-module(rabbitmq_client_listener).

-include_lib("amqp_client/include/amqp_client.hrl").

-behaviour(gen_server).

-type gen_server_start() :: {ok, pid()} | ignore | {error, any()}.

-export([start/1, init/1, handle_continue/2, terminate/2]).

-spec start(binary()) -> gen_server_start().
start(ClientName) ->
    gen_server:start_link(?MODULE, ClientName, []).


%-spec init(binary()) -> {noreply, {binary(),}}
init(ClientName) ->
    {Connection, Channel} = objects_creator:create_new_connection(),
    Queue = <<ClientName/binary, <<"Queue">>/binary>>,
    create_infrastructure(Channel, ClientName, Queue),
    Tag = objects_creator:subscribe_to_queue(Channel, Queue),
    {ok, {ClientName, Connection, Channel, Tag}, {continue, []}}.

create_infrastructure(Channel, ClientName, QueueName) ->
    objects_creator:create_queue(Channel, QueueName),
    objects_creator:create_exchange(Channel, <<"ClientsExchange">>, <<"topic">>),
    objects_creator:create_exchange(Channel, <<"AdminClientsExchange">>, <<"fanout">>),
    objects_creator:bind_queue(Channel, QueueName, <<"ClientsExchange">>, ClientName),
    objects_creator:bind_queue(Channel, QueueName, <<"AdminClientsExchange">>, ClientName).

handle_continue(_, {ClientName, Connection, Channel, Tag}) ->
    receive
        #'basic.consume_ok'{} ->
            {noreply, {ClientName, Connection, Channel, Tag}, {continue, []}};
        #'basic.cancel_ok'{} ->
            {stop, <<"disconnected\n">>, {}};
        {#'basic.deliver'{delivery_tag = DeliveryTag}, Content} ->
            #amqp_msg{payload = Message} = Content,
            io:format("Received | "),
            io:format(Message),
            io:format(<<"\n">>),
            amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = DeliveryTag}),
            {noreply, {ClientName, Connection, Channel, Tag}, {continue, []}}
    end.

terminate(Reason, {}) ->
    io:format(Reason),
    ok.

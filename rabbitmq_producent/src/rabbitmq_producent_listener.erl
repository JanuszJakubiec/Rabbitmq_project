-module(rabbitmq_producent_listener).

-include_lib("amqp_client/include/amqp_client.hrl").

-behaviour(gen_server).

-type gen_server_start() :: {ok, pid()} | ignore | {error, any()}.

-export([start/1, init/1, handle_continue/2, terminate/2]).

start(ProducentsName) ->
    gen_server:start_link(?MODULE, ProducentsName, []).


init(ProducentsName) ->
    {Connection, Channel} = objects_creator:create_new_connection(),
    Queue = <<ProducentsName/binary, <<"Queue">>/binary>>,
    Tag = objects_creator:subscribe_to_queue(Channel, Queue),
    {ok, {ProducentsName, Connection, Channel, Tag}, {continue, []}}.

handle_continue(_, {ProducentsName, Connection, Channel, Tag}) ->
    receive
        #'basic.consume_ok'{} ->
            {noreply, {ProducentsName, Connection, Channel, Tag}, {continue, []}};
        #'basic.cancel_ok'{} ->
            {stop, <<"disconnected\n">>, {}};
        {#'basic.deliver'{delivery_tag = DeliveryTag}, Content} ->
            #amqp_msg{payload = Message} = Content,
            [ClientName, ParsedMessage] = string:split(Message, <<"$">>),
            proccess_message(ClientName, ParsedMessage, Channel, ProducentsName),
            amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = DeliveryTag}),
            {noreply, {ProducentsName, Connection, Channel, Tag}, {continue, []}}
    end.

proccess_message(<<"Admin">>, Message, _, _) ->
    io:format(<<<<"Message from Admin: ">>/binary, Message/binary>>),
    io:format(<<"\n">>);
proccess_message(ClientName, OrderType, Channel, ProducentsName) ->
    io:format(<<<<"Order from: ">>/binary, ClientName/binary,
                <<" for: ">>/binary, OrderType/binary>>),
    io:format(<<"\n">>),
    Payload = <<ProducentsName/binary, <<": ">>/binary, OrderType/binary>>,
    Publish = #'basic.publish'{exchange = <<"ClientsExchange">>,
                               routing_key = ClientName},
    io:format(<<<<"Sending Message: ">>/binary, Payload/binary>>),
    io:format(<<"\n">>),
    amqp_channel:cast(Channel, Publish, #amqp_msg{payload = Payload}).

terminate(Reason, {}) ->
    io:format(Reason),
    ok.

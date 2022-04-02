-module(rabbitmq_message_broker).

-include_lib("amqp_client/include/amqp_client.hrl").

-type gen_server_start() :: {ok, pid()} | ignore | {error, any()}.

-export([start/2, init/1, handle_continue/2, terminate/2]).

-spec start(binary(), binary()) -> gen_server_start().
start(ProducentsName, Product) ->
    gen_server:start_link(?MODULE, {ProducentsName, Product}, []).


%-spec init(binary()) -> {noreply, {binary(),}}
init({ProducentsName, Product}) ->
    {Connection, Channel} = objects_creator:create_new_connection(),
    Tag = objects_creator:subscribe_to_queue(Channel, Product),
    {ok, {ProducentsName, Product, Connection, Channel, Tag}, {continue, []}}.

handle_continue(_, {ProducentsName, Product, Connection, Channel, Tag}) ->
    receive
        #'basic.consume_ok'{} ->
            {noreply, {ProducentsName, Product, Connection, Channel, Tag}, {continue, []}};
        #'basic.cancel_ok'{} ->
            {stop, <<"disconnected\n">>, {}};
        {#'basic.deliver'{delivery_tag = DeliveryTag}, Content} ->
            #amqp_msg{payload = Message} = Content,
            MyName = <<ProducentsName/binary, Product/binary, <<"Broker">>/binary>>,
            io:format(<<MyName/binary, <<" received: ">>/binary, Message/binary>>),
            io:format(<<"\n">>),
            Publish = #'basic.publish'{exchange = <<"ProducentExchange">>, routing_key = ProducentsName},
            amqp_channel:cast(Channel, Publish, #amqp_msg{payload = Message}),
            amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = DeliveryTag}),
            {noreply, {ProducentsName, Product, Connection, Channel, Tag}, {continue, []}}
    end.

terminate(Reason, {}) ->
    io:format(Reason),
    ok.
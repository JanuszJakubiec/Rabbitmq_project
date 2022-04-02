-module(objects_creator).

-include_lib("amqp_client/include/amqp_client.hrl").

-export([create_queue/2, create_exchange/3, bind_queue/4, subscribe_to_queue/2, create_new_connection/0]).

create_new_connection() ->
    {ok, Connection} = amqp_connection:start(#amqp_params_network{}),
    {ok, Channel} = amqp_connection:open_channel(Connection),
    {Connection, Channel}.

create_queue(Channel, QueueName) ->
    Declare = #'queue.declare'{queue = QueueName,
                               durable = true
                              },
    #'queue.declare_ok'{} = amqp_channel:call(Channel, Declare).

create_exchange(Channel, ExchangeName, Type) ->
    Declare = #'exchange.declare'{exchange = ExchangeName,
                                  type = Type},
    #'exchange.declare_ok'{} = amqp_channel:call(Channel, Declare).

bind_queue(Channel, Queue, Exchange, Key) ->
    Binding = #'queue.bind'{queue       = Queue,
                            exchange    = Exchange,
                            routing_key = Key},
    #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding).

subscribe_to_queue(Channel, Queue) ->
    #'basic.consume_ok'{consumer_tag = Tag} =
        amqp_channel:call(Channel, #'basic.consume'{queue = Queue}),
    Tag.

-module(rabbitmq_admin_sender).

-include_lib("amqp_client/include/amqp_client.hrl").

-export([send_to_clients/1, send_to_producents/1, send_to_all/1]).

send_to_clients(Message) ->
    {Connection, Channel} = objects_creator:create_new_connection(),
    Payload = <<<<"Admin$">>/binary, Message/binary>>,
    Publish = #'basic.publish'{exchange = <<"AdminClientsExchange">>, routing_key = <<"">>},
    amqp_channel:cast(Channel, Publish, #amqp_msg{payload = Payload}),
    amqp_channel:close(Channel),
    amqp_connection:close(Connection).

send_to_producents(Message) ->
    {Connection, Channel} = objects_creator:create_new_connection(),
    Payload = <<<<"Admin$">>/binary, Message/binary>>,
    Publish = #'basic.publish'{exchange = <<"AdminProducentExchange">>, routing_key = <<"">>},
    amqp_channel:cast(Channel, Publish, #amqp_msg{payload = Payload}),
    amqp_channel:close(Channel),
    amqp_connection:close(Connection).

send_to_all(Message) ->
    {Connection, Channel} = objects_creator:create_new_connection(),
    Payload = <<<<"Admin$">>/binary, Message/binary>>,
    PublishClients = #'basic.publish'{exchange = <<"AdminClientsExchange">>, routing_key = <<"">>},
    amqp_channel:cast(Channel, PublishClients, #amqp_msg{payload = Payload}),
    PublishProducents = #'basic.publish'{exchange = <<"AdminProducentExchange">>, routing_key = <<"">>},
    amqp_channel:cast(Channel, PublishProducents, #amqp_msg{payload = Payload}),
    amqp_channel:close(Channel),
    amqp_connection:close(Connection).
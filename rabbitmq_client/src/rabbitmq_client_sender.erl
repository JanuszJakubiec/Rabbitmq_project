-module(rabbitmq_client_sender).

-include_lib("amqp_client/include/amqp_client.hrl").

-export([order_product/1]).

order_product(ProductName) ->
    [{client_name, ClientName}] = ets:lookup(environment_variables, client_name),
    {Connection, Channel} = objects_creator:create_new_connection(),
    Payload = <<ClientName/binary, <<"$">>/binary, ProductName/binary>>,
    Publish = #'basic.publish'{exchange = <<"ProductsExchange">>, routing_key = ProductName},
    amqp_channel:cast(Channel, Publish, #amqp_msg{payload = Payload}),
    amqp_channel:close(Channel),
    amqp_connection:close(Connection).
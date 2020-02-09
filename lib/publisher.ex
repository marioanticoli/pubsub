defmodule PubSub.Publisher do
  def publish(topic, msg) do
    PubSub.Server.broadcast(topic, msg)
  end
end

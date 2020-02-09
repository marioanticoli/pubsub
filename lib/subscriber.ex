defmodule PubSub.Subscriber do
  def create(topics) do
    parent = self()

    spawn(fn ->
      pid = self()

      topics
      |> Enum.each(fn topic ->
        PubSub.Server.join_topic(topic, pid)
      end)

      listen(parent)
    end)
  end

  def list(topic) do
    PubSub.Server.list_subscribers(topic)
  end

  defp listen(parent) do
    receive do
      msg ->
        send(parent, {self(), msg})
    end

    listen(parent)
  end
end

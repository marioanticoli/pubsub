defmodule PubSub.Server do
  use GenServer

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def handle_cast({:join_topic, topic, pid}, state) do
    new_list =
      case subscribers(state, topic) do
        [] -> [pid]
        l -> [pid | l] |> Enum.dedup()
      end

    {:noreply, state |> Map.put(topic, new_list)}
  end

  def handle_cast({:broadcast, topic, msg}, state) do
    subscribers(state, topic)
    |> Enum.each(fn s ->
      send(s, msg)
    end)

    {:noreply, state}
  end

  def handle_call({:list_subscribers, topic}, _from, state) do
    {:reply, subscribers(state, topic), state}
  end

  def init(state), do: {:ok, state}

  def join_topic(topic, pid), do: GenServer.cast(__MODULE__, {:join_topic, topic, pid})

  def broadcast(topic, msg), do: GenServer.cast(__MODULE__, {:broadcast, topic, msg})

  def list_subscribers(topic), do: GenServer.call(__MODULE__, {:list_subscribers, topic})

  defp subscribers(s, t) do
    case s |> Map.get(t) do
      nil -> []
      l -> l
    end
  end
end

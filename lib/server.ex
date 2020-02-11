defmodule PubSub.Server do
  use GenServer

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def handle_call({:join_topic, topic, pid}, _from, state) do
    if is_valid_topic?(topic) do
      new_list =
        case subscribers(state, topic) do
          [] -> [pid]
          l -> [pid | l] |> Enum.dedup()
        end

      {:reply, new_list, state |> Map.put(topic, new_list)}
    else
      {:reply, nil, state}
    end
  end

  def handle_call({:list_subscribers, topic}, _from, state) do
    {:reply, subscribers(state, topic), state}
  end

  def handle_cast({:broadcast, topic, msg}, state) do
    subscribers_to_topic(topic, state)
    |> Enum.each(fn s ->
      send(s, msg)
    end)

    {:noreply, state}
  end

  def init(state), do: {:ok, state}

  def join_topic(topic, pid), do: GenServer.call(__MODULE__, {:join_topic, topic, pid})

  def list_subscribers(topic), do: GenServer.call(__MODULE__, {:list_subscribers, topic})

  def broadcast(topic, msg), do: GenServer.cast(__MODULE__, {:broadcast, topic, msg})

  defp subscribers(state, topic) do
    case state |> Map.get(topic) do
      nil -> []
      l -> l
    end
  end

  defp is_valid_topic?(topic) do
    r = ~r<^(/[a-zA-Z0-9]+|/\++)*(/#)?$>
    String.match?(topic, r)
  end

  defp subscribers_to_topic(topic, state) do
    state
    |> Map.keys()
    |> Enum.filter(fn s ->
      s
      |> String.trim_leading("/")
      |> topic_match?(topic)
    end)
    |> Enum.reduce([], fn k, acc ->
      Map.get(state, k) ++ acc
    end)
  end

  defp topic_match?(subscription, topic) do
    subscription == topic
  end
end

defmodule PubSub.Server do
  use GenServer

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def handle_call({:join_topic, topic, pid}, _from, state) do
    new_list =
      case subscribers(state, topic) do
        [] -> [pid]
        l -> [pid | l] |> Enum.dedup()
      end

    {:reply, new_list, state |> Map.put(topic, new_list)}
  end

  def handle_call({:list_subscribers, topic}, _from, state) do
    {:reply, subscribers(state, topic), state}
  end

  def handle_cast({:broadcast, topic, msg}, state) do
    subscribers(state, topic)
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
    if valid_topic?(topic) do
      [_hd | topic_list] = topic |> String.split("/")

      state
      |> Map.keys()
      |> Enum.reduce([], fn t, acc ->
        nil
      end)
    else
      []
    end
  end

  defp valid_topic?(topic) do
    String.last(topic) != "/" &&
      String.match?(topic, ~r(/[a-zA-Z0-9/])) &&
      case String.split("#") do
        [_str] -> true
        [_str, ""] -> true
        _ -> false
      end
  end
end

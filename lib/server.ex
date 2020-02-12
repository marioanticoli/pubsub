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
    if topic |> is_valid_topic?() do
      subscribers_to_topic(topic, state)
      |> Enum.each(fn s ->
        send(s, msg)
      end)
    end

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
      s |> topic_match?(topic)
    end)
    |> Enum.reduce([], fn k, acc ->
      Map.get(state, k) ++ acc
    end)
  end

  def topic_match?(subscription, topic) do
    diff = String.myers_difference(subscription, topic)
    diff |> IO.inspect()

    case diff do
      [eq: _] -> true
      [eq: _, del: "/#"] -> true
      [eq: _, del: "#", ins: _] -> true
      _ -> match_single_level?(subscription |> String.split("/"), topic |> String.split("/"))
    end
  end

  defp match_single_level?(subsc_list, topic_list) do
    cond do
      subsc_list == topic_list -> true
      subsc_list |> length != topic_list |> length -> false
      true -> false
    end
  end
end

defmodule PubSub.Server do
  use GenServer

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def handle_call({:join_topic, topic, pid}, _from, state) do
    if is_valid_topic?(topic) do
      new_list =
        case subscribers(topic, state) do
          [] -> [pid]
          l -> [pid | l] |> Enum.dedup()
        end

      {:reply, new_list, state |> Map.put(topic, new_list)}
    else
      {:reply, nil, state}
    end
  end

  def handle_call({:list_subscribers, topic}, _from, state) do
    {:reply, subscribers_to_topic(topic, state), state}
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

  defp subscribers(topic, state) do
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
    ["" | subscription_list] = subscription |> String.split("/")
    ["" | topic_list] = topic |> String.split("/")

    cond do
      subscription == topic ->
        true

      !Enum.member?(subscription_list, "#") && topic_list |> length != subscription_list |> length ->
        false

      Enum.member?(subscription_list, "+") ->
        matching_levels?(subscription_list, topic_list)

      true ->
        List.myers_difference(subscription_list, topic_list) |> matching?()
    end
  end

  defp matching?(del: ["#"], ins: _), do: true
  defp matching?(eq: _, del: ["#"], ins: _), do: true
  defp matching?(eq: _, del: ["#"]), do: false
  defp matching?(eq: _, del: _), do: false
  defp matching?(_any), do: false

  defp matching_levels?(subsc_list, topic_list) do
    Enum.zip(subsc_list, topic_list)
    |> Enum.reduce(true, fn {s, t}, acc ->
      acc &&
        if s == "#" do
          true
        else
          s == t || s == "+"
        end
    end)
  end
end

defmodule PubSub.Supervisor do
  use Supervisor

  def start(:normal, opts) do
    start_link(opts)
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {PubSub.Server, %{}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Htop do
  use GenServer

  @moduledoc """
  Htop keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def get_cpu do
    GenServer.call(__MODULE__, {:get, :cpu})
  end

  def get_cpu_history do
    GenServer.call(__MODULE__, {:get, :history})
  end

  def start_link(init_args) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    port = Port.open({:spawn, "top -n 1"}, [:binary])
    {:ok, %{port: port}}
  end

  @impl true
  def handle_info({_, {:data, data}}, state) do
    data = parse_top_data(data)

    state =
      state
      |> Map.put(:cpu, data)
      |> Map.update(:history, [], &([data | &1] |> Enum.take(10)))

    Phoenix.PubSub.broadcast(
      Htop.PubSub,
      "metrics",
      {:data, Map.take(state, [:cpu, :history])}
    )

    {:noreply, state}
  end

  @impl true
  def handle_call({:get, key}, _payload, state) do
    {:reply, state[key], state}
  end

  defp parse_top_data(data) do
    regex = ~r/\d+\.\d+/

    [user, system, idle] =
      data
      |> String.split("\n")
      |> Enum.find(&(&1 =~ "CPU usage:"))
      |> String.split(",")
      |> Enum.flat_map(&Regex.run(regex, &1))

    %{user: user, system: system, idle: idle}
  end
end

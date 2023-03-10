defmodule Htop.Metrics do
  use GenServer

  def get_cpu do
    GenServer.call(__MODULE__, {:get, :cpu})
  end

  def get_cpu_history do
    GenServer.call(__MODULE__, {:get, :history})
  end

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    schedule_get_cpu()
    # port = Port.open({:spawn, "top -n 1"}, [:binary])
    # {:ok, %{port: port}}

    {:ok, %{}}
  end

  @impl true
  def handle_info(:get_cpu, state) do
    cpu_per_core = Htop.SystemInfo.get_cpu()

    Phoenix.PubSub.broadcast(
      Htop.PubSub,
      "metrics",
      {:cpu_per_core, cpu_per_core}
    )

    schedule_get_cpu()

    {:noreply, cpu_per_core}
  end

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

  defp schedule_get_cpu do
    Process.send_after(self(), :get_cpu, 500)
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

defmodule HtopWeb.Live.Metrics do
  use HtopWeb, :live_view

  @default %{
    user: "12.8",
    system: "62.4",
    idle: "24.8"
  }
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Htop.PubSub, "metrics")
    socket = assign(socket, cpu_per_core: [])
    {:ok, socket}
  end

  def handle_info({:data, %{cpu: cpu}}, socket) do
    socket = assign(socket, cpu: cpu)
    {:noreply, socket}
  end

  def handle_info({:cpu_per_core, cpu_per_core}, socket) do
    cpu_per_core =
      Enum.map(cpu_per_core, fn {name, usage} ->
        case Integer.parse(usage) do
          {usage, _} -> {name, usage}
          _ -> {name, usage}
        end
      end)

    socket = assign(socket, cpu_per_core: cpu_per_core)
    {:noreply, socket}
  end

  defp percent(val) do
    "transition: width 500ms ease-in-out; width: #{val}%"
  end
end

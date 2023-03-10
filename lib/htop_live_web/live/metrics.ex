defmodule HtopWeb.Live.Metrics do
  use HtopWeb, :live_view

  @default %{
    user: "0",
    system: "0",
    idle: "0"
  }
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Htop.PubSub, "metrics")
    socket = assign(socket, cpu: @default)
    {:ok, socket}
  end

  def handle_info({:data, %{cpu: cpu}}, socket) do
    socket = assign(socket, cpu: cpu)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div>
        System: <%= @cpu.system %>
      </div>
      <div>
        User: <%= @cpu.user %>
      </div>
      <div>
        Idle: <%= @cpu.idle %>
      </div>
    </div>
    """
  end
end

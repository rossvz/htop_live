
The goal for this mini-project is to get CPU stats showing in a LiveView Page
![image](https://user-images.githubusercontent.com/9866589/224439140-06e1dc22-4c0d-4f14-b920-e59e465154a8.png)

# Approach
- Spin up new phoenix live view project
- Determine how to read CPU/system info
- Create a stateful store of CPU metrics, update on interval
- Broadcast cpu changes to connected LiveViews

# Update Phoenix new
`mix archive.install hex phx_new`

# Read CPU
The big issue here was getting this data from Elixir environment.

Current Approach:
- Rust `sysinfo` crate allows us to get statistics.
- In order to accurately read CPU usage, it needs to query CPU stats over an interval. This means we can't query directly from Elixir because it would be a long, blocking function call.
- Without a ton of Rust understanding of async/thread stuff - my quick workaround is:
  - Elixir starts an infinite loop in Rust, where we query the the CPU usage and write to a local file
  - Elixir reads from this file on a short interval and updates UI

Tried:
- :os_mon from erlang will send alerts when CPU crosses an alert threshold. Not really what I want.
- Some other suggestions involved :observer which doesn't work on my machine
- Initial approach was using `Port` directly from elixir
```elixir

port = Port.open({:spawn, "top"}, :binary)

receive do
  {^port, {:data, data}} -> IO.inspect(data)
end
```

This will wait for top to send a message to stdio, and capture the binary response. I just open a port, run top and wait for a message then close the port again. Doing some basic string parsing, we get a result like
```elixir
%{idle: "31.95", system: "49.48", user: "18.55"}
```

Which isn't 100% what I wanted - I wanted percentage use per CPU core, but this is as close as I can get at the moment.

# Store CPU Metrics
Ok, clearly I'm learning about processes and messages still.
My previous attempt was to open a port, receive a message, and close the port, only to loop the same function recursively.

However, `top` sends data to stdio on an interval, and we can continue to receive data with a `GenServer`.  Eg

```elixir

def handle_info({_port, {:data, data}}, state ) do
    data = parse_top_data(data)

	# store latest CPU data as `:cpu` and last 10 metrics as `:history`
    state =
      state
      |> Map.put(:cpu, data)
      |> Map.update(:history, [], &([data | &1] |> Enum.take(10)))

    {:noreply, state}
end

```

Now our metrics are being collected. 

# Display in LiveView

This part was pretty straightforward
- New route pointing to new live view
- On mount, schedule interval refresh
- Refresh grabs state from our GenServer and renders
- 
- ![[Pasted image 20230308224132.png]]

Something I don't love here is that the GenServer is automatically updating, so polling the GenServer ever `x` milliseconds feels redundant. Lets see if we can use PubSub instead.

As expected - this was as easy as I thought:
```elixir
# in our GenServer
Phoenix.PubSub.broadcast(
      Htop.PubSub,
      "metrics",
      {:data, Map.take(state, [:cpu, :history])}
    )

# when our LiveView Mounts

Phoenix.PubSub.subscribe(Htop.PubSub, "metrics")

# in our LiveView, handle messages as they arrive
def handle_info({:data, %{cpu: cpu}}, socket) do
    socket = assign(socket, cpu: cpu)
    {:noreply, socket}
end
```

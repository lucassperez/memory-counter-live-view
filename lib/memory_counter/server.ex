defmodule MemoryCounter.Server do
  use GenServer

  alias MemoryCounter.Counter

  @initial_state %{last_added_id: nil, counters: []}
  @server_name :counters_server

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @server_name)
  end

  def server_name, do: @server_name

  def show, do: GenServer.call(@server_name, :show)
  def create, do: GenServer.call(@server_name, :create)
  def reset, do: GenServer.call(@server_name, :reset)
  def zero_all, do: GenServer.call(@server_name, :zero_all)
  def delete_all, do: GenServer.call(@server_name, :delete_all)

  def delete(id) when is_binary(id), do: delete(String.to_integer(id))
  def delete(id), do: GenServer.call(@server_name, {:delete, id})

  def increment(id) when is_binary(id), do: increment(String.to_integer(id))
  def increment(id), do: GenServer.call(@server_name, {:increment, id})

  def decrement(id) when is_binary(id), do: decrement(String.to_integer(id))
  def decrement(id), do: GenServer.call(@server_name, {:decrement, id})

  @impl true
  def init(_) do
    {:ok, @initial_state}
  end

  @impl true
  def handle_call(:show, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:create, _from, %{last_added_id: last_id, counters: counters} = state) do
    new_id = (last_id || 0) + 1
    new_counter = Counter.new() |> Map.put(:id, new_id)
    new_state = %{state | last_added_id: new_counter.id, counters: [new_counter | counters]}

    broadcast_event(:create, new_state)

    {:reply, new_counter, new_state}
  end

  def handle_call(:reset, _from, _state) do
    broadcast_event(:reset, @initial_state)
    {:reply, @initial_state, @initial_state}
  end

  def handle_call(:zero_all, _from, state) do
    new_state = %{state | counters: Enum.map(state.counters, fn c -> Map.put(c, :value, 0) end)}
    broadcast_event(:zero_all, new_state)
    {:reply, @initial_state, new_state}
  end

  def handle_call(:delete_all, _from, state) do
    new_state = %{state | counters: []}
    broadcast_event(:delete_all, new_state)
    {:reply, @initial_state, new_state}
  end

  def handle_call({:delete, id}, _from, %{counters: counters} = state) do
    with to_be_deleted = %Counter{} <- Enum.find(counters, fn c -> c.id == id end),
         new_counters <- Enum.filter(counters, fn c -> c.id != id end) do
      new_state = %{state | counters: new_counters}

      broadcast_event(:delete, new_state)

      {:reply, to_be_deleted, new_state}
    else
      nil ->
        {:reply, nil, state}
    end
  end

  def handle_call({:increment, id}, _from, %{counters: counters} = state) do
    {updated_counter, new_counters} = change_value(id, counters, +1)
    new_state = %{state | counters: new_counters}

    broadcast_event(:update, new_state)

    {:reply, updated_counter, new_state}
  end

  def handle_call({:decrement, id}, _from, %{counters: counters} = state) do
    {updated_counter, new_counters} = change_value(id, counters, -1)
    new_state = %{state | counters: new_counters}

    broadcast_event(:update, new_state)

    {:reply, updated_counter, new_state}
  end

  defp change_value(id, counters, sum_value) do
    case Enum.find(counters, fn c -> c.id == id end) do
      nil ->
        {nil, counters}

      counter = %Counter{} ->
        new_counter = Map.put(counter, :value, counter.value + sum_value)
        new_counters = put_counter_in_list(new_counter, counters)
        {new_counter, new_counters}
    end
  end

  defp put_counter_in_list(_, []) do
    []
  end

  defp put_counter_in_list(%{id: target_id} = new_counter, [%Counter{id: id} | tail])
       when target_id == id do
    [new_counter | tail]
  end

  defp put_counter_in_list(new_counter, [head | tail]) do
    [head | put_counter_in_list(new_counter, tail)]
  end

  defp broadcast_event(event, payload) do
    Phoenix.PubSub.broadcast(MemoryCounter.PubSub, "counters", {event, payload})
  end
end

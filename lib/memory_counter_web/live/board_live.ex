defmodule MemoryCounterWeb.BoardLive do
  use MemoryCounterWeb, :live_view

  alias MemoryCounter.Server

  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(MemoryCounter.PubSub, "counters")

    %{counters: counters} = Server.show()

    socket = assign(socket, counters: counters)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 class="font-bold text-xl">Contadores</h1>
    <hr class="my-4" />
    <div class="flex items-center justify-between">
      <div class="flex space-x-2">
        <button
          phx-click="create_counter"
          class="
          border-2 border-black rounded-lg
          py-1 px-2
          bg-green-100 hover:bg-green-300 active:bg-green-500
          "
          type="button"
        >
          Criar
        </button>
        <button
          phx-click="zero_all"
          class="
          border-2 border-black rounded-lg
          py-1 px-2
          bg-yellow-100 hover:bg-yellow-300 active:bg-yellow-500
          "
          type="button"
        >
          Zerar
        </button>
        <button
          phx-click="reset_current_counters"
          class="
          border-2 border-black rounded-lg
          py-1 px-2
          bg-red-200 hover:bg-red-300 active:bg-red-500
          "
          type="button"
        >
          Limpar
        </button>
      </div>
      <div class="flex space-x-2">
        <button
          phx-click="reset_server_counters"
          class="
          border-2 border-black rounded-lg
          py-1 px-2
          bg-black hover:bg-gray-700 active:bg-gray-500
          text-white font-bold
          "
          type="button"
        >
          Recomeçar
        </button>
      </div>
    </div>
    <div class="grid grid-cols-3">
      <%= for c <- Enum.reverse(@counters) do %>
        <div
          class="
          relative
          border-4 border-gray-300 bg-gray-50 hover:bg-[#f4f5f6] rounded-lg
          p-4 mr-4 mt-2 mb-2
          "
          id={"counter-#{c.id}"}
        >
          <button
            type="button"
            class="
            absolute
            top-0
            right-0
            pr-1
            pl-1
            text-gray-600 hover:text-gray-900
            rounded-lg
            hover:bg-red-200 active:bg-red-400
            "
            phx-click={
              JS.transition(
                {"ease-out duration-200", "opacity-100", "opacity-0"},
                to: "#counter-#{c.id}",
                time: 200
              )
              |> JS.push("delete_counter", value: %{"id" => c.id})
            }
            phx-value-id={c.id}
          >
            &times;
          </button>
          <h3>Contador #{c.id}</h3>
          <hr class="my-1" />
          <div class="flex justify-between items-center">
            <p>{c.value}</p>
            <div class="flex space-x-2">
              <button
                class="px-2 ml-2 mt-2 rounded-xl bg-green-100 hover:bg-green-200 active:bg-green-300"
                phx-click="increment_counter"
                phx-value-id={c.id}
              >
                &plus;
              </button>
              <button
                class="px-2 ml-1 mt-2 rounded-xl bg-red-100 hover:bg-red-200 active:bg-red-300"
                phx-click="decrement_counter"
                phx-value-id={c.id}
              >
                &minus;
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("create_counter", _params, socket) do
    Server.create()
    {:noreply, socket}
  end

  def handle_event("reset_server_counters", _params, socket) do
    Server.reset()
    {:noreply, socket}
  end

  def handle_event("reset_current_counters", _params, socket) do
    Server.delete_all()
    {:noreply, socket}
  end

  def handle_event("zero_all", _, socket) do
    Server.zero_all()
    {:noreply, socket}
  end

  def handle_event("delete_counter", %{"id" => id}, socket) do
    Server.delete(id)
    {:noreply, socket}
  end

  def handle_event("increment_counter", %{"id" => id}, socket) do
    Server.increment(id)
    {:noreply, socket}
  end

  def handle_event("decrement_counter", %{"id" => id}, socket) do
    Server.decrement(id)
    {:noreply, socket}
  end

  def handle_info({event, new_state}, socket)
      when event in ~w[create delete update reset zero_all delete_all]a,
      do: {:noreply, assign(socket, %{new_state | counters: new_state.counters})}
end

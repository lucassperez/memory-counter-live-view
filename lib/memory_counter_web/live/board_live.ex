defmodule MemoryCounterWeb.BoardLive do
  use MemoryCounterWeb, :live_view

  alias MemoryCounter.Server

  def mount(params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(MemoryCounter.PubSub, "counters")

    locale = params["locale"] || Gettext.get_locale(MemoryCounterWeb.Gettext) || "en"
    Gettext.put_locale(MemoryCounterWeb.Gettext, locale)

    %{counters: counters} = Server.show()

    socket = assign(socket, counters: counters, locale: locale)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.title_and_locale_buttons />

    <% left = [
      {gettext("Create"), "create_counter", "bg-green-100 hover:bg-green-300 active:bg-green-500"},
      {gettext("Zero All"), "zero_all", "bg-yellow-100 hover:bg-yellow-300 active:bg-yellow-500"},
      {gettext("Clean Up"), "reset_current_counters", "bg-red-200 hover:bg-red-300 active:bg-red-500"}
    ]

    right = [
      {gettext("Restart"), "reset_server_counters",
       "bg-black hover:bg-gray-700 active:bg-gray-500 text-white font-bold"}
    ] %>

    <.board_buttons right={right} left={left} />

    <.counter_cards counters={@counters} />
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

  def handle_event("switch_locale", %{"locale" => locale}, socket) do
    Gettext.put_locale(MemoryCounterWeb.Gettext, locale)
    {:noreply, redirect(socket, to: "/board?locale=#{locale}")}
  end

  def handle_info({event, new_state}, socket)
      when event in ~w[create delete update reset zero_all delete_all]a,
      do: {:noreply, assign(socket, new_state)}

  # Components

  attr :counters, :list, required: true

  defp counter_cards(assigns) do
    ~H"""
    <div class="grid grid-cols-3 gap-x-4">
      <%= for c <- Enum.reverse(@counters) do %>
        <.counter_card counter={c} />
      <% end %>
    </div>
    """
  end

  attr :counter, MemoryCounter.Counter, required: true

  defp counter_card(assigns) do
    ~H"""
    <div
      class="
          relative
          border-4 border-gray-300 bg-gray-50 hover:bg-[#f4f5f6] rounded-lg
          p-4 my-2
          "
      id={"counter-#{@counter.id}"}
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
            to: "#counter-#{@counter.id}",
            time: 200
          )
          |> JS.push("delete_counter", value: %{"id" => @counter.id})
        }
        phx-value-id={@counter.id}
      >
        &times;
      </button>
      <h3>{gettext("Counter")} #{@counter.id}</h3>
      <hr class="my-1" />
      <div class="flex justify-between items-center">
        <p>{@counter.value}</p>
        <div class="flex space-x-2">
          <% mini_button_class = "px-2 ml-2 mt-2 rounded-xl" %>
          <button
            class={[mini_button_class, "bg-green-100 hover:bg-green-200 active:bg-green-300"]}
            phx-click="increment_counter"
            phx-value-id={@counter.id}
          >
            &plus;
          </button>
          <button
            class={[mini_button_class, "bg-red-100 hover:bg-red-200 active:bg-red-300"]}
            phx-click="decrement_counter"
            phx-value-id={@counter.id}
          >
            &minus;
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp title_and_locale_buttons(assigns) do
    ~H"""
    <div class="flex justify-between">
      <h1 class="font-bold text-xl">{gettext("Counters")}</h1>

      <div class="flex justify-end space-x-2">
        <button phx-click="switch_locale" phx-value-locale="en">
          &#127988;&#917607;&#917602;&#917605;&#917614;&#917607;&#917631;
        </button>
        <button phx-click="switch_locale" phx-value-locale="pt">
          &#127463;&#127479;
        </button>
      </div>
    </div>

    <hr class="my-2 mb-4" />
    """
  end

  # attr :buttons, :map, required: true
  attr :right, :list
  attr :left, :list

  defp board_buttons(assigns) do
    ~H"""
    <div class="flex justify-between">
      <div class="flex space-x-2 justify-start">
        <%= for {inner_block, phx_click, class} <- @left do %>
          <.board_button phx-click={phx_click} class={class}>{inner_block}</.board_button>
        <% end %>
      </div>
      <div class="flex space-x-2 justify-end">
        <%= for {inner_block, phx_click, class} <- @right do %>
          <.board_button phx-click={phx_click} class={class}>{inner_block}</.board_button>
        <% end %>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :"phx-click", :string, required: true
  slot :inner_block, required: true

  defp board_button(assigns) do
    ~H"""
    <button phx-click={assigns[:"phx-click"]} class={["
          border-2 border-black rounded-lg
          py-1 px-2
          ", @class]} type="button">
      {render_slot(@inner_block)}
    </button>
    """
  end
end

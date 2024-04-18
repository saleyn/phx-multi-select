defmodule Phoenix.LiveView.Components.InPlaceEdit do
  use Phoenix.LiveComponent
  use Phoenix.Component

  attr :id, :string, required: true
  attr :content, :string, required: true
  attr :on_save, :any, default: nil
  attr :rest, :global
  def editable(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id={@id} content={@content} on_save={@on_save} rest={@rest} />
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex border-0 outline-none">
        <input type="text"
          id={@id}
          phx-hook="InPlaceEdit"
          phx-keydown="cancel"
          phx-keyup="key"
          phx-key="escape"
          phx-target={@myself}
          contenteditable="true"
          class="p-2 flex w-full gap-1 min-h-fit border rounded-t-lg bg-white border-gray-300 dark:border-gray-600 disabled:bg-gray-100 disabled:cursor-not-allowed shadow-sm dark:bg-gray-800 dark:text-gray-300 dark:disabled:bg-gray-700 rounded-b-lg"
          {@rest}
          value={@content}
        >
      </div>

    </div>
    """
  end

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
    }
  end

  def handle_event("update", %{"content" => content}, socket) do
    IO.inspect(content, label: "Content")
    case socket.assigns.on_save do
      {%{} = record, attr} -> send(self(), {record, %{attr => content}})
      _ -> nil
    end

    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    {:noreply, push_event(socket, "cancel", %{content: socket.assigns.content})}
  end

  def handle_event("key", params, socket) do
    IO.inspect(params, label: "Key")
    {:noreply, socket}
  end
end

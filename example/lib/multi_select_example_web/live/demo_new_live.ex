defmodule MultiSelectExampleWeb.DemoNewLive do
  use MultiSelectExampleWeb, :live_view

  alias MultiSelectExampleWeb.SampleData
  alias Phoenix.LiveView.Components.MultiSelect
  alias Phoenix.LiveView.Components.MultiSelect.Option

  @id "multi"

  @impl true
  def mount(_params, _session, socket) do
    options = for t <- SampleData.list_topics(), do: Option.new(t)

    socket =
      socket
      |> assign_new(:id, fn -> "multi-select-example" end)
      |> assign_new(:wrap, fn -> true end)
      |> assign_new(:max_selected, fn -> SampleData.topics_count() end)
      |> assign_new(:topics, fn -> options end)

    {:ok, socket}
  end

  @impl true
  def handle_info({:updated_options, options}, socket) do
    # Update the assigns of the list of quotes and the selected topics
    {:noreply, assign(socket, :topics, options)}
  end

  @impl true
  def handle_event("save", params, socket) do
    # Get all selected values
    case params[@id] do
      nil ->
        {:noreply, socket}

      map ->
        params = Map.keys(map) |> Enum.join(",")
        {:noreply, push_redirect(socket, to: ~p"/demo_result?values=#{params}")}
    end
  end

  def handle_event("validate", %{"_target" => ["wrap"]} = params, socket) do
    wrap = params["wrap"] == "on"
    MultiSelect.update_settings(@id, wrap: wrap)
    {:noreply, assign(socket, :wrap, wrap)}
  end

  def handle_event("validate", %{"_target" => ["max_selected"]} = params, socket) do
    value = String.to_integer(params["max_selected"])
    MultiSelect.update_settings(@id, max_selected: value)
    {:noreply, assign(socket, :max_selected, value)}
  end
end

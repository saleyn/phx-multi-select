defmodule MultiSelectExampleWeb.DemoLive do
  use MultiSelectExampleWeb, :live_view

  alias MultiSelectExampleWeb.SampleData
  alias Phoenix.LiveView.Components.MultiSelect
  alias Phoenix.LiveView.Components.MultiSelect.Option

  @impl true
  def mount(_params, _session, socket) do
    options = for t <- SampleData.list_topics(), do: Option.new(t)
    socket  =
      socket
      |> assign(:id, "multi-select-example")
      |> update_assigns(options)

    {:ok, socket}
  end

  @impl true
  def handle_info({:updated_options, options}, socket) do
    # Update the assigns of the list of quotes and the selected topics
    {:noreply, update_assigns(socket, options)}
  end

  @impl true
  def handle_event("save", params, socket) do
    # Get all selected values
    params = Map.keys(params["multi"]) |> Enum.join(",")

    {:noreply, push_redirect(socket, to: ~p"/result?values=#{params}")}
  end

  defp update_assigns(socket, options) do
    socket
    |> assign(:quotes, filter_quotes(options))
    |> assign(:topics, options)
  end

  defp filter_quotes(options) do
    selected_options = for opt <- options, opt.selected, do: opt.id
    selected_options == [] && SampleData.sample_data()
                           || SampleData.sample_data_by_topic(selected_options)
  end

end

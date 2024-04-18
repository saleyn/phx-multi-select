defmodule MultiSelectExampleWeb.DemoLive do
  use MultiSelectExampleWeb, :live_view

  alias MultiSelectExample.SampleData
  alias Phoenix.LiveView.Components.MultiSelect
  alias Phoenix.LiveView.Components.MultiSelect.Option
  alias Phoenix.LiveView.Components.ComboBox

  @id "multi"

  @impl true
  def mount(_params, _session, socket) do
    options     = SampleData.list_topics()
    options_gen = fn(value) ->
      case value do
        "" ->
          SampleData.list_topics()
        _  ->
          val = String.downcase(value)
          Enum.reduce(options, [], fn(opt, acc) ->
            o = Option.new(opt)
            String.contains?(o.value_lc, val) && [o | acc] || acc
          end)
          |> Enum.reverse()
      end
    end

    socket  =
      socket
      |> assign_new(:id,           fn -> "multi-select-example" end)
      |> assign_new(:wrap,         fn -> false end)
      |> assign_new(:max_selected, fn -> SampleData.topics_count() end)
      |> assign_new(:user,         fn -> "" end)
      |> assign_new(:options_generator, fn -> options_gen end)
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
    case params[@id] do
      nil ->
        {:noreply, socket}
      map ->
        params = Map.keys(map) |> Enum.join(",")
        {:noreply, push_redirect(socket, to: ~p"/result?values=#{params}")}
    end
  end

  def handle_event("validate", %{"_target" => ["wrap"]} = params, socket) do
    wrap = params["wrap"] == "on"
    MultiSelect.update_settings(@id, wrap: wrap)
    {:noreply, assign(socket, :wrap, wrap)}
  end

  def handle_event("validate", %{"_target" => _}, socket) do
    {:noreply, socket}
  end

  defp update_assigns(socket, options) do
    selected = for opt <- options, opt.selected, do: opt.id
    quotes   =
      if selected == [],
        do:   SampleData.sample_data(),
        else: SampleData.sample_data_by_topic(selected)
    socket
    |> assign(:quotes, quotes)
    |> assign(:topics, options)
  end

end

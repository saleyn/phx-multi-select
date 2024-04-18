defmodule MultiSelectExampleWeb.ComboBoxLive do
  use MultiSelectExampleWeb, :live_view

  alias MultiSelectExample.SampleData
  alias Phoenix.LiveView.Components.ComboBox

  @id "multi"

  @impl true
  def mount(_params, _session, socket) do
    data =
      SampleData.long_data()
      |> Enum.map(fn %{value: val} = opt -> Map.put(opt, :value_lc, String.downcase(val)) end)

    options_gen = fn(value, from_page, per_page) ->
      val = String.downcase(value)
      reduce(data, val, (from_page-1)*per_page, per_page, [])
    end

    socket  =
      socket
      |> assign_new(:id,      fn -> "multi-select-example" end)
      |> assign_new(:value,   fn -> ""                     end)
      |> assign(:options, fn -> options_gen            end)

    {:ok, socket}
  end

  defp reduce([%{value_lc: v} = opt | tail], val, skip, limit, acc) do
    case val == "" || String.contains?(v, val) do
      true when skip > 0 ->
        reduce(tail, val, skip-1, limit, acc)
      true when limit > 0 ->
        reduce(tail, val, skip, limit-1, [opt | acc])
      true when limit < 0 ->
        {false, :lists.reverse(acc)}
      true ->
        reduce(tail, val, skip, limit-1, acc)
      false ->
        reduce(tail, val, skip, limit, acc)
    end
  end
  defp reduce([], _val, _skip, _limit, acc), do: {true, :lists.reverse(acc)}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex w-1/2 gap-3">
      <div id={@id} class="flex gap-2 w-full">
        <.form :let={f} for={%{}} as={:input} id={"#{@id}-ms-form"}
                class="w-96 gap-2" phx-change="validate" phx-submit="save">
          <ComboBox.combobox
            id={@id<>"-cbox"}
            options_generator={@options_generator}
            form={f}
            on_change={fn opts -> send(self(), {:updated_options, opts}) end}
            placeholder="Select topic..."
            title="Select tipics to filter quotes"
          />
        </.form>
        <div>
          <button name="submit" class="p-2.5 rounded-md font-medium text-sm text-white bg-primary-600 hover:bg-primary-500">Submit</button>
        </div>
      </div>
    </div>
    """
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

  def handle_event("validate", %{"_target" => _}, socket) do
    {:noreply, socket}
  end
end

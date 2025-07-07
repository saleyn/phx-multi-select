defmodule MultiSelectExampleWeb.ResultNewLive do
  use MultiSelectExampleWeb, :live_view
  alias MultiSelectExampleWeb.SampleData

  def mount(params, _session, socket) do
    vals =
      (params["values"] || "")
      |> String.split(",")
      |> Enum.map(&(String.to_integer(&1) |> SampleData.topic_by_id()))

    socket =
      socket
      |> assign(:topics, vals)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div class="relative overflow-x-auto shadow-md sm:rounded-lg">
        <table class="max-w-2xl text-sm text-left">
          <thead class="text-xs text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-700">
            <tr>
              <th scope="col" class="px-6 py-3">Selected Topic Values</th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={cat <- @topics}
              class="bg-white dark:bg-gray-800 border-b border-gray-300 dark:border-gray-900 hover:bg-gray-50 dark:hover:bg-gray-600"
            >
              <td class="px-6 py-2"><%= cat %></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="flex justify-center">
      <button
        id="result-ok"
        phx-click={JS.navigate(~p"/demo")}
        phx-disable-with
        class="py-2 px-3 mt-4 rounded-md text-white bg-blue-500 hover:bg-blue-600"
      >
        OK
      </button>
    </div>
    """
  end
end

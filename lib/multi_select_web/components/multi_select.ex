defmodule Phoenix.LiveView.Components.MultiSelect.Option do
  defstruct \
    id:       nil,
    label:    nil,
    selected: false,
    visible:  true

  @type t :: %__MODULE__{
    id:       integer,
    label:    String.t,
    selected: boolean,
    visible:  true
  }

  def new(%{} = map) do
    %__MODULE__{id: map[:id], label: map[:label], selected: map[:selected]}
  end
end

defmodule Phoenix.LiveView.Components.MultiSelect do
  use    Phoenix.LiveComponent
  alias  Phoenix.LiveView.JS

  attr :id,        :string,  required: true
  attr :debounce,  :integer, default:  400
  attr :options,   :list,    default:  []
  attr :form,      :any,     required: true
  attr :on_change, :any,     required: true   # Lambda `(options) -> ok`

  def multi_select(assigns) do
    ~H"""
    <.live_component
      id={@id}
      module={__MODULE__}
      options={@options}
      form={@form}
      selected={@on_change}
      debounce={@debounce}
    />
    """
  end

  def mount(socket) do
    {:ok,
      socket
      |> assign(:filter,                        "")
      |> assign(:placeholder, "Select category...")
      |> assign(:max_shown,                      5)
      |> assign(:cur_shown,                      5)
      |> assign(:height,                    "3rem")
      |> assign(:filter_checked,             false)
      |> assign(:option_count,                   0)
      |> assign(:selected_count,                 0)
      |> assign(:filtered_count,                 0)
    }
  end

  def update(%{options: options} = assigns, socket) do
    socket =
      socket
      |> assign(:checked_options, filter_checked_options(options))
      |> assign(assigns)

    {:ok, socket}
  end

  def render(%{selected_count: sel_cnt, option_count: opt_cnt, filtered_count: filt_cnt} = assigns) do
    hide_filter_icon = opt_cnt == 0 or sel_cnt == 0 or sel_cnt == opt_cnt
    assigns =
      assigns
      |> assign(:filter_icon_visibility, hide_filter_icon && "hidden" || "visible")
      |> assign(:filter_icon_color,
          (opt_cnt > 0 and sel_cnt == filt_cnt) && "fill-zinc-400 hover:fill-zinc-500"
                                                || "fill-blue-600 hover:fill-blue-700")
      |> assign(:filter_icon_title,
          (opt_cnt > 0 and sel_cnt == filt_cnt) && "Clear selected items filter"
                                                || "Filter selected items")
    ~H"""
    <div id={@id} style={"height: #{@height}"} class={"flex flex-col w-96 py-[7px] gap-1 relative sm:text-sm"}>
      <div id={"#{@id}-main"} tabindex="0" class={"p-2 flex w-full gap-1 min-h-fit border rounded-t-lg rounded-b-lg" <> add_color_class()} phx-click={toggle_open(@id)}>
        <div id={"#{@id}-tags"} class="flex flex-wrap gap-1 w-full" phx-hook="MultiSelectHook" data-target={@myself}>
          <%= case @selected_count do %>
            <% 0 -> %>
              <span class="select-none opacity-50 self-center"><%= @placeholder %></span>
            <% n when n > @cur_shown -> %>
              <span class="bg-blue-600 rounded-md p-1 gap-1 select-none text-white flex place-items-center flex">
                <span><%= @selected_count %> items selected</span>
                <.svg type={:close} size="4" color="" on_click="checked" params={[{"uncheck", "all"}, {"id", @id}]} target={@myself}/>
              </span>
            <% _ -> %>
              <%= for option <- @checked_options do %>
                <span id={"#{@id}-tag-#{option.id}"} class="bg-blue-600 rounded-md p-1 gap-1 text-white flex flex-wrap shrink-0 place-items-center select-none">
                  <span><%= option.label %></span>
                  <.svg type={:close} size="4" color="" on_click="checked" params={[{"uncheck", option.id}, {"id", @id}]} target={@myself}/>
                </span>
              <% end %>
          <% end %>
        </div>
        <div class="right-2 self-center py-1 pl-1 z-10 flex place-items-center">
          <.svg type={:clear} :if={@selected_count > 1 and @selected_count <= @cur_shown}
            title="Clear Selected Items" on_click="checked" params={[{"uncheck", "all"}, {"id", @id}]} target={@myself}/>
          <.svg type={:updown} size="6" on_click={toggle_open(@id)}/>
        </div>
      </div>
      <div id={"#{@id}-opts"} tabindex="0" style={"top: #{@height}"} class={"hidden absolute w-96 p-2 ml-0 z-5 outline-none flex flex-col border-x border-b rounded-b-lg shadow-md" <> add_color_class()}
        phx-click-away={toggle_open(@id)}>
        <div class="w-full p-0 relative">
          <div class="absolute inset-y-0 right-2 flex items-center">
            <.svg type={:check} title={@filter_icon_title} color={@filter_icon_color} on_click="filter" params={[{"icon", "checked"}]} target={@myself}/>
            <.svg type={:clear} title="Clear Filter" on_click="filter" params={[{"icon", "clear"}]} target={@myself}/>
          </div>
          <input id={"#{@id}-filter"} name={"#{@id}-filter"} type="text" autocomplete="off"
            class={"mb-2 block w-full pl-2 pr-12 px-[11px] rounded-lg focus:outline-none focus:ring-1 sm:text-sm sm:leading-6 phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5" <> add_color_class()}
            placeholder="Search..." value={@filter}
            phx-debounce={@debounce}
            phx-change="search" phx-target={@myself}>
        </div>
        <div class="overflow-auto max-h-48 pt-1 pl-1 scrollbar scrollbar-thumb-zinc-400 scrollbar-track-zinc-200 dark:scrollbar-thumb-gray-700 dark:scrollbar-track-gray-900">
          <%= for opt <- @options, id = "#{@id}[#{opt.id}]" do %>
            <div class="form-check pr-0" hidden={!opt.visible}>
              <label class="form-cl flex text-sm font-medium text-gray-900 dark:text-gray-300 place-items-center"
                     for={id}>
                <input id={id} name={id} type="checkbox" phx-change="checked" phx-target={@myself}
                      checked={opt.selected} value="on"
                      class="form-ci rounded w-4 h-4 mr-2 dark:checked:bg-blue-500 border border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-1 dark:bg-gray-700 dark:border-gray-600 cursor-pointer transition duration-200"
                />
                <%= opt.label %>
              </label>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("validate", %{"_target" => [target]} = params, %{assigns: %{id: id}} = socket) do
    case id <> "-filter" do
      ^target ->
        params |> IO.inspect(label: "Validate")
    end
    {:noreply, socket}
  end

  def handle_event("search", params, %{assigns: %{id: id}} = socket) do
    k = id <> "-filter"
    case Map.fetch(params, k) do
      {:ok, word} ->
        options = for opt <- socket.assigns.options, do: %{opt | visible: opt.label =~ word}
        socket =
          socket
          |> assign(:options, options)
          |> assign(:filter, word)

        {:noreply, socket}
      nil ->
        {:noreply, socket}
    end
  end

  ## Event triggered by pushEventTo from the MultiSelectHook when the tags
  ## in this component get wrapped to more than one line or become a single line
  def handle_event("wrapped", %{"value" => wrapped, "count" => count}, socket) do
    IO.puts("Wrapped: #{wrapped}, count: #{count}, cur=#{socket.assigns.cur_shown}, max=#{socket.assigns.max_shown}")
    {:noreply, assign(socket, :cur_shown, wrapped && count || socket.assigns.max_shown)}
  end

  ## Checkbox [✓] clicked on a selected tag
  ## E.g.:
  ##   on:  %{"_target" => ["multi", "1"], "multi" => %{"1" => "on"}}
  ##   off: %{"_target" => ["multi", "1"]}}
  def handle_event("checked", %{"_target" => [id, idx]} = params, %{assigns: %{id: id}} = socket) do
    map       = params[id]
    selected? = is_map(map) and (map[idx] == "on")
    set_selected(socket, idx, selected?)
  end

  ## Checkbox [✓] unchecked on a selected tag
  def handle_event("checked", %{"uncheck" => item, "id" => id}, %{assigns: %{id: id}} = socket) do
    set_selected(socket, item, false)
  end

  ## Icon [✓] or [X] clicked on the "Search..." filter input
  def handle_event("filter", %{"icon" => icon}, %{assigns: assigns} = socket) do
    socket =
      case icon do
        "clear" ->    # `[X]` icon - clear filter when the filter field is empty
          socket
          |> assign(:filter, "")
          |> assign(:filter_checked, false)
          |> apply_filter(true)

        "checked" ->  # `[✓]` icon - toggle showing selected
          case assigns.selected_count do
            0  ->
              socket
            _  ->
              socket
              |> assign(:filter_checked, not assigns.filter_checked) # Toggle `[✓]` icon
              |> apply_filter()
          end
      end
    {:noreply, socket}
  end

  defp set_selected(socket, "all", selected?) do
    {count, options} =
      Enum.reduce(socket.assigns.options, {0, []}, fn
        (opt, {n, acc}) -> {n+1, [struct(opt, selected: selected?) | acc]}
      end)
    sel_count = selected? && count || 0
    set_selected2(socket, Enum.reverse(options), count, sel_count)
  end
  defp set_selected(socket, idx, selected?) do
    index   = String.to_integer(idx)
    sel_inc = selected? && 1 || 0
    {count, sel_count, options} =
      Enum.reduce(socket.assigns.options, {0, 0, []}, fn opt, {n, s, acc} ->
        if opt.id == index do
          {n+1, s + sel_inc, [%{opt | selected: selected?} | acc]}
        else
          {n+1, s + (opt.selected && 1 || 0), [opt | acc]}
        end
      end)
    set_selected2(socket, Enum.reverse(options), count, sel_count)
  end

  defp set_selected2(socket, options, count, sel_count) do
    socket =
      socket
      |> assign(:options,        options)
      |> assign(:option_count,   count)
      |> assign(:selected_count, sel_count)
#      |> then(& (sel_count == 0 && apply_filter(&1) || socket))

    # Notify LiveView of the changes
    socket.assigns.selected.(options)
    {:noreply, socket}
  end

  defp toggle_open(id) do
    %JS{}
    |> toggle_class(id <> "-updown-icon", "rotate-180")
    |> toggle_class(id <> "-main", "rounded-b-lg")
    |> JS.toggle(to: "##{id}-opts")
  end

  defp toggle_class(js, id, class) do
    js
    |> JS.remove_class(class, to: "##{id}.#{class}")
    |> JS.add_class(class,    to: "##{id}:not(.#{class})")
  end

  defp apply_filter(%{assigns: %{options: options} = assigns} = socket, show_all \\ nil) do
    show_all = show_all || not assigns.filter_checked
    fcount   = show_all && assigns.option_count || assigns.selected_count
    IO.puts("==> ShowAll: #{show_all}, FilterChecked: #{assigns.filter_checked}, FCount: #{fcount}")
    opts     = for opt <- options, do: %{opt | visible: show_all || opt.selected}
    socket
    |> assign(:options, opts)
    |> assign(:filtered_count, fcount)
  end

  defp filter_checked_options(options) do
    Enum.filter(options, fn opt -> opt.selected == true or opt.selected == "true" end)
  end

  defp add_color_class() do
    " bg-white border-gray-300 dark:border-gray-600 disabled:bg-gray-100 disabled:cursor-not-allowed shadow-sm dark:bg-gray-800 dark:text-gray-300 dark:disabled:bg-gray-700" # focus:outline-none focus:ring-primary-500 focus:border-primary-500"
  end

  attr :type,     :atom,    values:   [:close, :clear, :check, :updown]
  attr :size,     :string,  default:  "5"
  attr :color,    :string,  default:  "fill-zinc-400 hover:fill-zinc-500"
  attr :on_click, :any,     required: true
  attr :params,   :list,    default: []
  attr :target,   :integer
  attr :title,    :string,  default: nil

  defp svg(assigns) do
    size    = assigns[:size]
    color   = assigns[:color]
    target  = assigns[:target]
    rest    = Enum.map(assigns[:params], fn {k,v} -> {"phx-value-#{k}", v} end)
    rest    = target && [{"phx-target", target} | rest] || rest
    vbox    = assigns[:type] == :check && "0 0 24 24" || "0 0 20 20"
    assigns =
      assigns
      |> assign(:rest,  rest)
      |> assign(:vbox,  vbox)
      |> assign(:class, "w-#{size} h-#{size} cursor-pointer #{color}")
      |> assign(:path,
          case assigns.type do
            :close  -> ~S|<path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"/>|
            :clear  -> ~S|<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd"/>|
            :check  -> ~S|<path d="M19 3H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h14c1.103 0 2-.897 2-2V5c0-1.103-.897-2-2-2zm-7.933 13.481-3.774-3.774 1.414-1.414 2.226 2.226 4.299-5.159 1.537 1.28-5.702 6.841z"/>|
            :updown -> ~S|<path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/>|
          end)
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" viewBox={@vbox} fill="currentColor"
      phx-click={@on_click} {@rest}>
      <title :if={@title}><%= @title %></title>
      <%= {:safe, @path} %>
    </svg>
    """
  end
end

defmodule Phoenix.LiveView.Components.MultiSelect do
  use    Phoenix.LiveComponent
  import Phoenix.HTML
  alias  Phoenix.LiveView.JS

  defmodule Option do
    @doc """
    The option struct is passed to
    """
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
      %__MODULE__{
        id:       Map.get(map, :id),
        label:    Map.get(map, :label),
        selected: Map.get(map, :selected) || false,
      }
    end
  end

  @doc """
  MultiSelect LiveView stateful component.

  The component implements a number of configuration options:

    * `:id` - the required unique ID of the HTML element for this component

    * `:debounce` - the integer controlling a `phx-debounce` value for the
      search input

    * `:options` - a required list of `%{id: any(), label: string()}` maps to
      select from

    * `:form` - the required form name owning this component

    * `:on_change` - a lambda `(options :: [%Multiselect.Option{}]) -> ok`
      called on change of selected items

    * `:class` - class added to the main `div` of the component
    * `:max_selected` - max number of selected items
    * `:wrap` - allow to wrap selected tags to multiple lines
    * `:title` - component's title to use as the tooltip
    * `:placeholder` - component's placeholder text
    * `:filter_side` - apply item filtering on client or server (default: client)
  """
  attr :id,           :string,  required: true
  attr :debounce,     :integer, default:  350
  attr :options,      :list,    default:  [],    doc: "List of `%{id: String.t, label: String.t}` maps"
  attr :form,         :any,     required: true
  attr :on_change,    :any,     required: true,  doc: "Lambda `(options) -> ok` to be called on selecting items"
  attr :class,        :string,  default:  nil
  attr :max_selected, :integer, default:  nil,   doc: "Max number of items selected"
  attr :wrap,         :boolean, default:  false, doc: "Permit multiline wrapping of selected items"
  attr :title,        :string,  default:  nil,   doc: "Component tooltip title"
  attr :placeholder,  :string,  default:  "Select...", doc: "Placeholder shown on empty input"
  attr :filter_side,  :atom,    default: :client, values: [:client, :server]

  def multi_select(assigns) do
    assigns = %{assigns | options: (for o <- assigns.options, do: Option.new(o))}
    ~H"""
    <.live_component
      id={@id}
      module={__MODULE__}
      options={@options}
      form={@form}
      selected={@on_change}
      debounce={@debounce}
      class={@class}
      max_selected={@max_selected}
      wrap={@wrap}
      placeholder={@placeholder}
      title={@title}
    />
    """
  end

  def update_settings(id, attrs) when is_list(attrs) do
    send_update(__MODULE__, [{:id, id} | attrs])
  end

  def mount(socket) do
    {:ok,
      socket
      |> assign_new(:placeholder,    fn -> "Select..." end)
      |> assign_new(:filter,         fn -> ""     end)
      |> assign_new(:max_shown,      fn -> 5      end)
      |> assign_new(:cur_shown,      fn -> 5      end)
      |> assign_new(:max_selected,   fn -> nil    end)
      |> assign_new(:wrap,           fn -> false  end)
      |> assign_new(:filter_checked, fn -> false  end)
      |> assign_new(:option_count,   fn -> 0      end)
      |> assign_new(:selected_count, fn -> 0      end)
      |> assign_new(:filtered_count, fn -> 0      end)
      |> assign_new(:title,          fn -> nil    end)
    }
  end

  def update(%{options: options} = assigns, socket) do
    socket =
      socket
      |> assign(:checked_options, filter_checked_options(options))
      |> assign(assigns)

    {:ok, socket}
  end

  def update(%{id: id} = params, %{assigns: %{id: id}} = socket) do
    {:ok, update2(socket, Map.delete(params, :id))}
  end

  defp update2(socket, attrs) do
    Enum.reduce(attrs, socket, fn
      ({:wrap         = k, v}, s) when is_boolean(v) -> assign(s, k, v)
      ({:max_selected = k, v}, s) when is_integer(v) -> assign(s, k, v)
    end)
  end

  ## This setting allows to customize CSS classes. It supposed to return the
  ## module that has `apply_css(key, css_classes) -> css_classes :: String.t` function.
  @class_callback Application.compile_env(:live_view, :multi_select, %{})[:class_callback] || __MODULE__

  ## Customize the class name shared by the outer div
  @class_prefix   Application.compile_env(:live_view, :multi_select, %{})[:class_prefix]   || "phx-msel"

  ## Metadata with all CSS attributes for the MultiSelect component
  @css %{
    component:    @class_prefix <> " h-12 flex flex-col w-96 py-[7px] gap-1 relative sm:text-sm",
    main:         " p-2 flex w-full gap-1 min-h-fit border rounded-t-lg rounded-b-lg",
    tags:         " flex flex-wrap gap-1 w-full",
    placeholder:  " select-none opacity-50 self-center",
    tag:          " bg-blue-600 rounded-md p-1 gap-1 select-none text-white flex place-items-center",
    main_icons:   " right-2 self-center py-1 pl-1 z-10 flex place-items-center",
    body:         " hidden -mt-[4px] w-96 p-2 ml-0 z-5 outline-none flex flex-col border-x border-b rounded-b-lg shadow-md",
    filter:       " mb-2 block w-full pl-2 pr-12 px-[11px] rounded-lg focus:outline-none focus:ring-1 sm:text-sm sm:leading-6 phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5",
    filter_icons: " absolute inset-y-0 right-2 flex items-center",
    options:      " overflow-auto max-h-48 pt-1 pl-1 scrollbar scrollbar-thumb-zinc-400 scrollbar-track-zinc-200 dark:scrollbar-thumb-gray-700 dark:scrollbar-track-gray-900",
    option_label: " flex text-sm font-medium text-gray-900 dark:text-gray-300 place-items-center",
    option_input: " rounded w-4 h-4 mr-2 dark:checked:bg-blue-500 border border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-1 dark:bg-gray-700 dark:border-gray-600 transition duration-200",
    colors:       " bg-white border-gray-300 dark:border-gray-600 disabled:bg-gray-100 disabled:cursor-not-allowed shadow-sm dark:bg-gray-800 dark:text-gray-300 dark:disabled:bg-gray-700",
  }

  defmacro css(key, add_color_class \\ false) do
    quote do
      value = unquote(add_color_class) && (@css[unquote(key)] <> @css[:colors]) || @css[unquote(key)]
      @class_callback.apply_css(unquote(key), value)
    end
  end

  def render(%{selected_count: sel_cnt, option_count: opt_cnt, filtered_count: filt_cnt} = assigns) do
    hide_filter_icon = opt_cnt == 0 or sel_cnt == 0 or sel_cnt == opt_cnt
    assigns =
      assigns
      |> assign(:filter_icon_visibility, hide_filter_icon && "hidden" || "visible")
      |> assign(:filter_icon_color,
          (opt_cnt > 0 and sel_cnt == filt_cnt) && "fill-blue-600 hover:fill-blue-700"
                                                || "fill-zinc-400 hover:fill-zinc-500")
      |> assign(:filter_icon_title,
          (opt_cnt > 0 and sel_cnt == filt_cnt) && "Clear filter of selected items"
                                                || "Filter selected items")
      |> assign(:filter_id, "#{assigns.id}-filter")

    assigns[:filter] |> IO.inspect(label: "Filter")
    ~H"""
    <div id={@id} style={} class={build_class([@class, css(:component)])}>
      <div id={"#{@id}-main"} tabindex="0" class={css(:main, true)} phx-click={toggle_open(@id)}  title={@title}>
        <div id={"#{@id}-tags"} class={css(:tags)} phx-hook="MultiSelectHook" data-target={@myself} data-wrap={Atom.to_string(@wrap)}>
          <%= cond do %>
            <% @selected_count == 0 -> %>
              <span class={css(:placeholder)}><%= @placeholder %></span>
            <% @selected_count > @cur_shown and not @wrap -> %>
              <span class={css(:tag)}>
                <span><%= @selected_count %> items selected</span>
                <.svg type={:close} size="4" color="" on_click="checked" params={[{"uncheck", "all"}, {"id", @id}]} target={@myself}/>
              </span>
            <% true -> %>
              <%= for option <- @checked_options do %>
                <span id={"#{@id}-tag-#{option.id}"} class={css(:tag) <> " flex-wrap shrink-0"}>
                  <span><%= option.label %></span>
                  <.svg type={:close} size="4" color="" on_click="checked" params={[{"uncheck", option.id}, {"id", @id}]} target={@myself}/>
                </span>
              <% end %>
          <% end %>
        </div>
        <div class={css(:main_icons)}>
          <.svg type={:clear} :if={@selected_count > 1 and @selected_count <= @cur_shown}
            title="Clear all selected items" on_click="checked" params={[{"uncheck", "all"}, {"id", @id}]} target={@myself}/>
          <.svg type={:updown} size="6" on_click={toggle_open(@id)}/>
        </div>
      </div>
      <div id={"#{@id}-dropdown"} tabindex="0" class={css(:body, true)}
        phx-click-away={toggle_open(@id)}>
        <div class="w-full p-0 relative">
          <div class={css(:filter_icons)}>
            <.svg type={:check} title={@filter_icon_title} color={@filter_icon_color} on_click="filter" params={[{"icon", "checked"}]} target={@myself}/>
            <.svg type={:clear} title="Clear Filter" on_click="filter" params={[{"icon", "clear"}]} target={@myself}/>
          </div>
          <input id={@filter_id} type="text" autocomplete="off" phx-target={@myself} phx-change={JS.set_attribute({'q', :undefined}, to: @filter_id)}
            class={css(:filter, true)}
            placeholder="Search..." value={@filter}
            {[] #phx-debounce={@debounce}
            }
            {[] #phx-change="search" phx-target={@myself}
            }
            {[] #onkeypress={{:safe, "(function(e) { if (e.value == '') e.removeAttribute('name'); else e['name'] = e.id; })(this)"}}
            }
            >
        </div>
        <div id={"#{@id}-opts"} class={css(:options)}>
          <%=
            for opt <- @options,
                id        = "#{@id}[#{opt.id}]",
                (disabled = disabled(@selected_count, @max_selected, opt.selected)) || true,
                rest      = disabled && [disabled: true] || [],
                cursor    = disabled && " cursor-not-allowed" || " cursor-pointer"
            do
          %>
            <div class="pr-0" hidden={!opt.visible}>
              <label for={id} class={css(:option_label)}
              ><input id={id} name={id} type="checkbox" phx-change="checked" phx-target={@myself}
                      checked={opt.selected} value="on" class={css(:option_input) <> cursor}
                      {rest}><%= opt.label %></label>
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
  def handle_event("validate", %{"_target" => ["undefined"]}, socket) do
    {:noreply, socket}
  end

  ## Event sent when the client typed something in the 'Search' input, and
  ## JS hook notified us of the change.
  def handle_event("search", %{"filter" => word}, %{assigns: assigns} = socket) do
    #options = for opt <- socket.assigns.options, do: %{opt | visible: opt.label =~ word}
    #socket = assign(socket, :options, options)

    # We don't want to trigger a re-render, that's why we are using `Map.put()`
    # call, unless we need to requery the data:
    assigns = Map.put(assigns, :filter, word)
    {:noreply, %{socket | assigns: assigns}}
  end

  ## Event triggered by pushEventTo from the MultiSelectHook when the tags
  ## in this component get wrapped to more than one line or become a single line
  def handle_event("wrapped", %{"value" => wrapped, "count" => count}, socket) do
    #IO.puts("Wrapped: #{wrapped}, count: #{count}, cur=#{socket.assigns.cur_shown}, max=#{socket.assigns.max_shown}")
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
              apply_filter(socket)
            _  ->
              socket
              |> assign(:filter_checked, not assigns.filter_checked) # Toggle `[✓]` icon
              |> apply_filter()
          end
      end
    {:noreply, socket}
  end

  @doc false
  def apply_css(_key, value), do: value

  defp set_selected(socket, "all", selected?) do
    {count, options} =
      Enum.reduce(socket.assigns.options, {0, []}, fn
        (opt, {n, acc}) -> {n+1, [struct(opt, selected: selected?) | acc]}
      end)
    sel_count = selected? && count || 0
    set_selected2(socket, Enum.reverse(options), count, sel_count)
  end
  defp set_selected(%{assigns: assigns} = socket, idx, selected?) do
    index       = String.to_integer(idx)
    sel_inc     = selected? && 1 || 0
    filtered    = assigns.filter_checked
    has_search  = assigns.filter != nil
    search_str  = assigns.filter
    visible     = fn o ->
      (filtered   and o.id   == index and selected?) or
      (has_search and o.label =~ search_str)
    end

    {count, sel_count, options} =
      Enum.reduce(assigns.options, {0, 0, []}, fn opt, {n, s, acc} ->
        if opt.id == index do
          {n+1, s + sel_inc,
            [%{opt | selected: selected?, visible: visible.(opt)} | acc]}
        else
          {n+1, s + (opt.selected && 1 || 0), [%{opt | visible: visible.(opt)} | acc]}
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

    # Notify LiveView of the changes
    socket.assigns.selected.(options)
    {:noreply, socket}
  end

  defp toggle_open(id) do
    %JS{}
    |> toggle_class(id <> "-updown-icon", "rotate-180")
    |> toggle_class(id <> "-main", "rounded-b-lg")
    |> JS.toggle(to: "##{id}-dropdown")
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

  defp disabled(_sel_cnt, _max,      true),                    do: false
  defp disabled(sel_cnt,   max, _selected) when sel_cnt < max, do: false
  defp disabled(_sel_cnt, _max, _selected),                    do: true

  defp filter_checked_options(options) do
    Enum.filter(options, fn opt -> opt.selected == true or opt.selected == "true" end)
  end

  defp build_class([]),      do: []
  defp build_class([nil|t]), do: build_class(t)
  defp build_class([""|t]),  do: build_class(t)
  defp build_class([h|t]),   do: "#{h} " <> build_class(t)


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
    assigns =
      assigns
      |> assign(:rest,  rest)
      |> assign(:svg_class, "w-#{size} h-#{size} cursor-pointer #{color}")
      |> assign(:path,
          case assigns.type do
            :close  -> ~S|<path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"/>|
            :clear  -> ~S|<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd"/>|
            :check  -> ~S|<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>|
            :updown -> ~S|<path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/>|
          end)
    ~H"""
    <svg class={@svg_class} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"
      phx-click={@on_click} {@rest}>
      <title :if={@title}><%= @title %></title>
      <%= raw @path %>
    </svg>
    """
  end
end

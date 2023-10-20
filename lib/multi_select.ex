defmodule Phoenix.LiveView.Components.MultiSelect do
  @moduledoc """
  Multi-select component for Phoenix LiveView.

  Use in your HEEX templates with:
  ```
  <.multi_select
    id="multi"
    options={
      %{id: 1, label: "One"},
      %{id: 2, label: "Two"},
    }
  >
  ```

  See `multi_select/1` for details.
  """
  use    Phoenix.LiveComponent
  import Phoenix.HTML
  alias  Phoenix.LiveView.JS

  def __using__(_) do
    quote do
      import Phoenix.LiveView.Components.MultiSelect, only: [multi_select: 1]
    end
  end

  defmodule Option do
    @doc """
    The option struct can be used for passing a list of option values to the
    `multi_select` component.
    """
    defstruct \
      id:       nil,
      label:    nil,
      selected: false

    @type t :: %__MODULE__{
      id:       integer,
      label:    String.t,
      selected: boolean
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

    * `:options` - a required list of `%{id: any(), label: string()}` options to
      select from

    * `:form` - the required form name owning this component

    * `:on_change` - a lambda `(options :: [%Multiselect.Option{}]) -> ok`
      called on change of selected items

    * `:class` - class added to the main `div` of the component
    * `:max_selected` - max number of selected items
    * `:wrap` - allow to wrap selected tags to multiple lines
    * `:title` - component's title to use as the tooltip
    * `:placeholder` - component's placeholder text
    * `:search_placeholder` - placeholder for the search input box
    * `:search_cbox_titles` - titles `on|off` of the checked icon in the search checkbox
      (default: "Clear filter of selected items|Filter selected items")
    * `:filter_side` - apply item filtering on client or server (default: client)
  """
  attr :id,                 :string,  required: true
  attr :debounce,           :integer, default:  350
  attr :options,            :list,    default:  [],    doc: "List of `%{id: String.t, label: String.t}` maps"
  attr :form,               :any,     required: true
  attr :on_change,          :any,                      doc: "Lambda `(options) -> ok` to be called on selecting items"
  attr :class,              :string,  default:  nil
  attr :max_selected,       :integer, default:  nil,   doc: "Max number of items selected"
  attr :max_shown,          :integer, default:  100000,doc: "Max number of shown selected tags"
  attr :wrap,               :boolean, default:  false, doc: "Permit multiline wrapping of selected items"
  attr :title,              :string,  default:  nil,   doc: "Component tooltip title"
  attr :placeholder,        :string,  default:  "Select...", doc: "Placeholder shown on empty input"
  attr :search_placeholder, :string,  default:  "Search...", doc: "Placeholder for the search input"
  attr :search_cbox_titles, :string,  default:  "Clear filter of selected items|Filter selected items",
                                                       doc: "Titles `on|off` of the checked icon in the search checkbox"
  attr :filter_side,        :atom,    default:  :client, values: [:client, :server]

  def multi_select(assigns) do
    assigns = assign(assigns, :options, (for o <- assigns.options, do: Option.new(o)))
    rest    = Phoenix.Component.assigns_to_attributes(assigns, [])
    assigns = assign(assigns, :rest,    rest)
    ~H"""
    <.live_component module={__MODULE__} {@rest}/>
    """
  end

  @doc """
  Call this function to notify the LiveView to update the settings of the
  multi_select component identified by the `id`.
  """
  def update_settings(id, attrs) when is_list(attrs) do
    send_update(__MODULE__, [{:id, id} | attrs])
  end

  ## This setting allows to customize CSS classes. It supposed to return the
  ## module that has `apply_css(id, key, css_classes) -> css_classes :: String.t` function.
  @class_callback Application.compile_env(:phoenix_multi_select, :class_module) || __MODULE__

  ## Customize the class name shared by the outer div
  @class_prefix   Application.compile_env(:phoenix_multi_select, :class_prefix) || "phx-msel"

  ## When true, the component will use Alpinejs. Otherwise - Phoenix.LiveView.JS
  @use_alpinejs   Application.compile_env(:phoenix_multi_select, :use_alpinejs) || false

  ## Metadata with all CSS attributes for the MultiSelect component
  @css %{
    component:        @class_prefix <> " h-12 flex flex-col w-96 py-[7px] gap-1 relative sm:text-sm",
    main:             "p-2 flex w-full gap-1 min-h-fit border rounded-t-lg rounded-b-lg",
    tags:             "flex flex-wrap gap-1 w-full",
    placeholder:      "select-none opacity-50 self-center",
    tag:              "bg-primary-600 rounded-md p-1 gap-1 select-none text-white flex place-items-center",
    main_icons:       "right-2 self-center py-1 pl-1 z-10 flex place-items-center",
    body:             "-mt-[4px] w-96 p-2 ml-0 z-5 outline-none flex flex-col border-x border-b rounded-b-lg shadow-md" <> (@use_alpinejs && "" || " hidden"),
    filter:           "mb-2 block w-full pl-2 pr-12 rounded-lg focus:outline-none focus:ring-1 sm:text-sm sm:leading-6 phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5",
    filter_icons:     "absolute inset-y-0 right-2 flex items-center" <> (@use_alpinejs && " mb-2" || ""),
    icon_color:       "fill-zinc-400 hover:fill-zinc-500",
    icon_check_color: "fill-zinc-400 hover:fill-zinc-500 | fill-primary-600 hover:fill-primary-700", # Two sets of colors `on|off`
    options:          "overflow-auto max-h-48 pt-1 pl-1 scrollbar scrollbar-thumb-zinc-400 scrollbar-track-zinc-200 dark:scrollbar-thumb-gray-700 dark:scrollbar-track-gray-900",
    option_label:     "flex text-sm font-medium text-gray-900 dark:text-gray-300 place-items-center",
    option_input:     "rounded w-4 h-4 mr-2 dark:checked:bg-primary-500 border border-gray-300 focus:ring-primary-500 dark:focus:ring-primary-600 dark:ring-offset-gray-800 focus:ring-1 dark:bg-gray-700 dark:border-gray-600 transition duration-200",
    colors:           "bg-white border-gray-300 dark:border-gray-600 disabled:bg-gray-100 disabled:cursor-not-allowed shadow-sm dark:bg-gray-800 dark:text-gray-300 dark:disabled:bg-gray-700",
  }

  @doc false
  defmacro css(id, key, add_color_class \\ false) do
    quote do
      value =
        unquote(key)
        |> unquote(__MODULE__).css_fetch(unquote(add_color_class))
      @class_callback.apply_css(unquote(id), unquote(key), value)
    end
  end

  @doc false
  defmacro init_rest(assigns, from_mount) when is_boolean(from_mount) do
    quote do
      if @use_alpinejs do
        unquote(from_mount) && add_alpinejs_assigns(unquote(assigns)) || unquote(assigns)
      else
        unquote(from_mount) && unquote(assigns) || add_js_assigns(unquote(assigns))
      end
    end
  end

  @doc false
  def css_fetch(k, true),  do: [@css[k], @css[:colors]] |> build_class()
  def css_fetch(k, false), do: [@css[k]]                |> build_class()

  @doc false
  def apply_css(_id, _key, value), do: value

  @doc false
  defp add_alpinejs_assigns(assigns) do
    assigns
    |> assign_new(:top_rest,     fn -> [{"x-data",         "{open: false}"}] end)
    |> assign_new(:main_rest,    fn -> [{"x-bind:class",   "{'rounded-b-lg': !open}"},
                                        {"@click",         "open=!open"}] end)
    |> assign_new(:tags_rest,    fn -> [] end)
    |> assign_new(:ddown_events, fn -> [{"@click.outside", "open=!open"},
                                        {"x-show",         "open"}] end)
    |> assign_new(:updown_rest,  fn -> [{"x-bind:class",   "{'rotate-180': open}"}] end)
  end

  @doc false
  defp add_js_assigns(assigns) do
    assigns
    |> assign_new(:top_rest,     fn -> [] end)
    |> assign_new(:main_rest,    fn -> [{"phx-click",      toggle_open(assigns[:id])}] end)
    |> assign_new(:tags_rest,    fn -> [] end)
    |> assign_new(:ddown_events, fn -> [{"phx-click-away", toggle_open(assigns[:id])}] end)
    |> assign_new(:updown_rest,  fn -> [] end)
  end

  @doc false
  def mount(%{assigns: assigns} = socket) do
    assigns =
      assigns
      |> assign(:filter,            "")
      |> assign(:cur_shown,      10000)
      |> assign(:filter_checked, false)
      |> assign(:option_count,       0)
      |> assign(:selected_count,     0)
      |> init_rest(true)

    {:ok, Map.put(socket, :assigns, assigns)}
  end

  @doc false
  def update(%{options: options} = params, socket) do
    socket  = assign(socket, params)
    assigns = socket.assigns
    assigns =
      assigns
      |> assign_new(:filter_id,   fn -> "#{assigns.id}-filter" end)
      |> assign(:checked_options, filter_checked_options(options))
      |> assign(:selected_count, get_selected_count(options))
      |> init_rest(false)

    {:ok, Map.put(socket, :assigns, assigns)}
  end

  def update(%{id: id} = params, %{assigns: %{id: id}} = socket) do
    {:ok, update2(socket, Map.delete(params, :id))}
  end

  defp get_selected_count(options), do: Enum.count(options, fn opt -> opt.selected end)

  defp update2(socket, attrs) do
    Enum.reduce(attrs, socket, fn
      ({:wrap         = k, v}, s) when is_boolean(v) -> assign(s, k, v)
      ({:max_selected = k, v}, s) when is_integer(v) -> assign(s, k, v)
    end)
  end

  @doc false
  def render(assigns) do
    ~H"""
    <div id={@id} style={} class={build_class([@class, css(@id, :component)])} {@top_rest}>
      <div id={@id <> "-main"} tabindex="0" class={css(@id, :main, true)} title={@title} {@main_rest}>
        <div id={@id <> "-tags"} class={css(@id, :tags)} phx-hook="MultiSelectHook"
             data-target={@myself} data-wrap={Atom.to_string(@wrap)} data-filterside={@filter_side} {@tags_rest}>
          <%= cond do %>
            <% @selected_count == 0 -> %>
              <span class={css(@id, :placeholder)}><%= @placeholder %></span>
            <% @selected_count > @cur_shown and not @wrap -> %>
              <span class={css(@id, :tag)}>
                <span><%= @selected_count %> items selected</span>
                <.svg type={:close} size="4" color="" on_click="checked" params={[{"uncheck", "all"}, {"id", @id}]} target={@myself}/>
              </span>
            <% true -> %>
              <%= for option <- @checked_options do %>
                <span id={"#{@id}-tag-#{option.id}"} class={css(@id, :tag) <> " flex-wrap shrink-0"}>
                  <span><%= option.label %></span>
                  <.svg type={:close} size="4" color="" on_click="checked" params={[{"uncheck", option.id}, {"id", @id}]} target={@myself}/>
                </span>
              <% end %>
          <% end %>
        </div>
        <div class={css(@id, :main_icons)}>
          <.svg type={:clear} :if={@selected_count > 1}
            title="Clear all selected items" on_click="checked"
            params={[{"uncheck", "all"}, {"id", @id}]} target={@myself}/>
          <.svg id={@id <> "-updown-icon"} type={:updown} size="6" {@updown_rest}/>
        </div>
      </div>
      <div id={"#{@id}-dropdown"} tabindex="0" class={css(@id, :body, true)} {@ddown_events}>
        <div class="w-full p-0 relative">
          <div class={css(@id, :filter_icons)}>
            <.svg id={"#{@id}-flt-check"} type={:check} titles={@search_cbox_titles} color={css(@id, :icon_check_color)}
                  class={@selected_count == 0 && "opacity-20 pointer-events-none" || nil}/>
            <input name={"#{@id}-flt-check"} type="hidden" value={@filter_checked}>
            <.svg id={"#{@id}-flt-clear"} type={:clear} title="Clear Filter"/>
          </div>
          <input id={@filter_id} type="text" autocomplete="off" phx-target={@myself}
            phx-change={~s([["_",{"to":"#_"}]])
              # NOTE: JS.set_attribute prevents the input from sending a validation event to server
              # We can either use JS.add_class("undefined", to: @filter_id) or a the surrogate
              # command above, which will effectively ignore the event
            }
            class={css(@id, :filter, true)}
            placeholder={@search_placeholder} value={@filter} phx-debounce={@debounce}>
        </div>
        <div id={"#{@id}-opts"} class={css(@id, :options)}>
          <%=
            for opt <- @options,
                id        = "#{@id}[#{opt.id}]",
                (disabled = disabled(@selected_count, @max_selected, opt.selected)) || true,
                rest      = disabled && [disabled: true] || [],
                cursor    = disabled && " cursor-not-allowed" || " cursor-pointer"
            do
          %>
            <div class="pr-0">
              <label for={id} class={css(@id, :option_label)}
              ><input id={id} name={id} type="checkbox" phx-change="checked" phx-target={@myself}
                      checked={opt.selected} value="on" class={css(@id, :option_input) <> cursor}
                      {rest}><%= opt.label %></label>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc false
  def handle_event("validate", %{"_target" => [_target]}, socket) do
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

        "checked" ->  # `[✓]` icon - toggle showing selected
          case assigns.selected_count do
            0  ->
              socket
            _  ->
              socket
              |> assign(:filter_checked, not assigns.filter_checked) # Toggle `[✓]` icon
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
  defp set_selected(%{assigns: assigns} = socket, idx, selected?) do
    index   = String.to_integer(idx)
    sel_inc = selected? && 1 || 0

    {count, sel_count, options} =
      Enum.reduce(assigns.options, {0, 0, []}, fn opt, {n, s, acc} ->
        if opt.id == index do
          {n+1, s + sel_inc,
            [%{opt | selected: selected?} | acc]}
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

    # Notify LiveView of the changes
    chg = socket.assigns.on_change
    chg && chg.(options)
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

  defp disabled(_sel_cnt, _max,      true),                    do: false
  defp disabled(sel_cnt,   max, _selected) when sel_cnt < max, do: false
  defp disabled(_sel_cnt, _max, _selected),                    do: true

  defp filter_checked_options(options) do
    Enum.filter(options, fn opt -> opt.selected == true or opt.selected == "true" end)
  end

  @doc false
  def build_class(str)   when is_binary(str),         do: str
  def build_class([]),                                do: ""
  def build_class([h|t]) when h in [nil, ""],         do: build_class(t)
  def build_class([h|t]) when t in [nil,[nil],[""]],  do: h
  def build_class([h])   when is_binary(h),           do: h
  def build_class([h|t]) do
    tail = for i <- t, i && i != "", do: [32, i]
    IO.iodata_to_binary([h | tail])
  end

  attr :id,       :string,  default: nil
  attr :type,     :atom,    values:  [:close, :clear, :check, :updown]
  attr :size,     :string,  default: "5"
  attr :color,    :string,  default: @css.icon_color
  attr :on_click, :any,     default: nil
  attr :params,   :list,    default: []
  attr :target,   :integer
  attr :title,    :string,  default: nil
  attr :titles,   :string,  default: nil
  attr :class,    :string,  default: nil

  defp svg(assigns) do
    size    = assigns[:size]
    {c1,c2} = color(assigns[:color] || assigns[:colors])
    rest    = assigns_to_attributes(assigns, [:id, :type, :size, :color, :on_click,
                                              :params, :target, :title, :titles, :class])
    rest    = add([{"phx-target",  assigns[:target]},
                   {"data-colors", c2},
                   {"data-titles", assigns[:titles]}] ++
                   rest ++
                   (for {k,v} <- assigns[:params], do: {"phx-value-#{k}", v}))
    assigns =
      assigns
      |> assign(:rest,      rest)
      |> assign(:svg_class, build_class(["w-#{size} h-#{size} cursor-pointer", c1, assigns[:class]]))
      |> assign(:path,
          case assigns.type do
            :close  -> ~S|<path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"/>|
            :clear  -> ~S|<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd"/>|
            :check  -> ~S|<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>|
            :updown -> ~S|<path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/>|
          end)
    ~H"""
    <svg id={@id} class={@svg_class} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"
      phx-click={@on_click} {@rest}>
      <title :if={@titles || @title}><%= @title %></title>
      <%= raw @path %>
    </svg>
    """
  end

  defp color(nil),          do: {nil, nil}
  defp color({c1,c2}),      do: {" " <> c1, "#{c1}|#{c2}"}
  defp color(clr),          do: clr =~ "|" && {:binary.split(clr, "|") |> hd, clr} || {clr, nil}

  defp add([]),             do: []
  defp add([{_, nil} | t]), do: add(t)
  defp add([[] | t]),       do: add(t)
  defp add([kv       | t]), do: [kv | add(t)]
end

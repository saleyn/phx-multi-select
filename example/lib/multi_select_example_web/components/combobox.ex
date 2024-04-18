defmodule Phoenix.LiveView.Components.ComboBox do
  @moduledoc """
  Combobox component for Phoenix LiveView.

  Use in your HEEX templates with:
  ```
  <.combobox
    id="multi"
    options={
      %{id: 1, value: "One"},
      %{id: 2, value: "Two"},
    }
  >
  ```

  See `multi_select/1` for details.
  """
  use    Phoenix.LiveComponent
  import Phoenix.HTML
  alias  Phoenix.LiveView.JS
  alias  Phoenix.LiveView.Components.MultiSelect.Option

  @client_keep_pages 2

  def __using__(_) do
    quote do
      import Phoenix.LiveView.Components.ComboBox, only: [combobox: 1]
    end
  end

  @doc """
  ComboBox LiveView stateful component.

  The component implements a number of configuration options:

    * `:id` - the required unique ID of the HTML element for this component

    * `:debounce` - the integer controlling a `phx-debounce` value for the
      search input

    * `:options` - a required list of `%{id: any(), value: string()}` options to
      select from

    * `:form` - the required form name owning this component

    * `:class` - class added to the main `div` of the component
    * `:title` - component's title to use as the tooltip
    * `:placeholder` - component's placeholder text
  """
  attr :id,                   :string,  required: true
  attr :debounce,             :integer, default:  100
  #attr :options,              :any,     default:  [],    doc: "List of `%{id: String.t, label: String.t}` maps or a lambda that returns a list"
  attr :options_generator,    :any,     default:  [],    doc: "List of `%{id: String.t, label: String.t}` maps or a lambda that returns a list"
  attr :form,                 :any,     required: true
  attr :class,                :string,  default:  nil
  attr :title,                :string,  default:  nil,   doc: "Component tooltip title"
  attr :placeholder,          :string,  default:  "Select...", doc: "Placeholder shown on empty input"
  attr :per_page,             :integer, default: 10
  attr :value,                :string,  default: ""

  def combobox(assigns) do
    gen = Map.get(assigns, :options, nil)
    (is_list(gen) or is_function(gen, 3)) || raise ArgumentError, message:
      ":options must be a list or a lambda: ((String.t, interer(), integer()) -> [%{id: integer(), value: String.t}])"

    rest    = Phoenix.Component.assigns_to_attributes(assigns, [])
    assigns = %{rest: rest}
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

  @doc false
  def mount(socket) do
    {:ok,
      socket
      |> assign(:open,  false)
    }
  end

  @doc false
  def update(%{options: gen} = assigns, socket) when is_function(gen, 3) or is_list(gen) do
    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:filter_id, fn -> "#{assigns.id}-filter" end)
      |> assign_new(:code,      fn -> nil end)
      |> paginate(value, 1)
    }
  end

  @doc false
  def render(assigns) do
    ~H"""
    <div id={@id} style={} class={[@class, "flex flex-col w-full gap-1 relative sm:text-sm"]}
      >
      <div class="flex place-items-center" title={@title}>
        <input id={@filter_id} type="text"
          value={@value}
          autocomplete="off"
          phx-target={@myself}
          phx-keyup="search"
          phx-blur="blur"
          phx-value-code={@code}
          class={[@open && "" || "rounded-b-lg", "pl-2 !pr-14 w-full z-11 border rounded-t-lg bg-white border-gray-300 dark:border-gray-600 disabled:bg-gray-100 disabled:cursor-not-allowed shadow-sm dark:bg-gray-800 dark:text-gray-300 dark:disabled:bg-gray-700"]}
          phx-debounce={@debounce}
        >
        <div class="absolute right-1 z-10 flex cursor-pointer place-items-center fill-zinc-400 hover:fill-zinc-500 ">
          <.svg type={:clear} title="Clear selection" phx-click="clear" target={@myself} class="w-6"/>
          <svg id="cbox-updown-icon" class={[@open && "rotate-180" || "", "w-6 cursor-pointer fill-zinc-400 hover:fill-zinc-500"]} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"
            phx-click="toggle" phx-target={@myself}>
            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"></path>
          </svg>
        </div>
      </div>
      <div id={@id <> "-ddown"} tabindex="0"
        class={[@open && "" || "hidden", "-mt-[4px] w-full p-2 ml-0 z-5 outline-none flex flex-col border-x border-b rounded-b-lg shadow-md bg-white border-gray-300 dark:border-gray-600 disabled:bg-gray-100 disabled:cursor-not-allowed shadow-sm dark:bg-gray-800 dark:text-gray-300 dark:disabled:bg-gray-700"]}
      >
        <div id="items"
          class={["flex flex-col text-sm overflow-auto max-h-48 cursor-pointer scrollbar scrollbar-thumb-zinc-400 scrollbar-track-zinc-200 dark:scrollbar-thumb-gray-700 dark:scrollbar-track-gray-900",
                  "font-medium text-gray-900 dark:text-gray-300 pr-0 px-2"
                  #if(@the_end?,  do: "pb-10", else: "pb-[calc(100vh)]"),
                  #if(@page == 1, do: "pt-10", else: "pt-[calc(100vh)]")
                ]}
          phx-hook="Phoenix.InfiniteScroll"
          phx-update="stream"
          phx-target={@myself}
          phx-viewport-top={@page > 1 && "prev-page"}
          phx-viewport-bottom={not @the_end? && "next-page"}
          phx-page-loading
        >
          <span :for={{dom_id, opt} <- @streams.items} id={dom_id} class="hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white" phx-target={@myself} phx-click="select" phx-value-code={opt.id} phx-value-value={opt.value}><%= opt.value %></span>
        </div>
      </div>
    </div>
    """
  end

  @doc false
  def handle_event("validate", %{"_target" => ["undefined"]}, socket) do
    {:noreply, socket}
  end
  def handle_event("validate", %{"_target" => [target]}, socket) do
    {:noreply, socket}
  end

  ## Event sent when the client typed something in the 'Search' input, and
  ## JS hook notified us of the change.
  def handle_event("search", %{"value" => value, "key" => key}, %{assigns: %{open: was_open, page: page}} = socket) do
    {:noreply,
      socket
      |> assign(:open, key != "Escape" and (was_open or value != ""))
      |> paginate(value, page)
    }
  end

  def handle_event("blur", _, socket) do
    {:noreply,
      socket
      |> assign(:open, false)
    }
  end

  def handle_event("toggle", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, :open, not assigns[:open])}
  end

  def handle_event("select", %{"code" => code, "value" => value}, socket) do
    {:noreply, assign(socket, value: value, code: code, first_match: value, invalid: false, open: false)}
  end

  def handle_event("clear", %{}, socket) do
    {:noreply,
      socket
      |> paginate("", 1)
    }
  end

  def handle_event("next-page", _, %{assigns: %{value: value, page: page}} = socket) do
    {:noreply, paginate(socket, value, page + 1)}
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate(socket, socket.assigns.value, 1)}
  end

  def handle_event("prev-page", _, %{assigns: %{value: value, page: page}} = socket) do
    {:noreply, paginate(socket, value, max(1, page - 1))}
  end

  defp paginate(%{assigns: assigns} = socket, value, new_page) when new_page >= 1 do
    %{per_page: per_page, page: cur_page, value: old_value, options: gen} = assigns

    {reset, new_page} =
      value == old_value && {false, new_page} || {true, 1}

    {the_end, items} = gen.(value, new_page, per_page)

    {items, at} =
      if new_page >= cur_page do
        {items, -1}
      else
        {Enum.reverse(items), 0}
      end

    opts = [at: at, reset: reset]

    cond do
      items == [] or value == "" ->
        assign(socket, page: 1, the_end?: at == -1)

      true ->
        socket
        |> assign(:page, new_page)
        |> assign(the_end?: the_end)
    end
    |> assign(:value, value)
    |> stream(:items, items, opts)
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
  attr :color,    :string,  default: "fill-zinc-400 hover:fill-zinc-500"
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

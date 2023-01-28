# Phoenix LiveView MultiSelect Component

This project implements an Elixir Phoenix LiveView component that has a capability
of selecting multiple checkboxed items from a list.

![Example](https://user-images.githubusercontent.com/272543/214661918-110505f2-e796-40e3-a1ee-47178cb0daba.png)

The component supports the following options:

- Selection of multiple items from the given list of options
- Limit the max number of selected items
- Ability to either wrap the selected tags in the main div of the component or
collapse them in a single tag
- Ability to search in the list of options on the client side or on the server
side

## Author

Serge Aleynikov

## Installation

Include the project in the `mix.exs` as a dependency:
```elixir
defp deps do
  [
    {:multi_select, "~> 0.0"},
    ...
  ]
```

Run `mix deps.get`, and `mix multi_select.install`. This will modify the following
files:

- `assets/tailwind.config.js` - to add the necessary color alias, and search path
- `assets/package.json` - to add the tailwind scrollbar customization
- `assets/js/hooks/multi-select-hook.js` - copied from the multi_select source
- `assets/js/hooks/index.js` - add the MultiSelectHook

## Usage

In your project locate this file `{{your_project}}_web.ex`, and add:

```elixir
  defp html_helpers do
    quote do
      ...
      use Phoenix.LiveView.Components.MultiSelect   ## <--- add this line
      ...
    end
  end
```

Now in the `*.html.heex` templates you can use the `multi_select` LiveView
component like this:
```html
<.multi_select
  id="some-id"
  options={
    {id: 1, label: "Option1"},
    {id: 2, label: "Option2"},
    ...
  }
/>
```

For list of the available component's options see
`Phoenix.LiveView.Components.MultiSelect.multi_select/1`

## Demo

The demo project is located in the `examples/` directory, and can be compiled
and run with:

```
cd examples
make
make run
```
Now you can visit [`localhost:4002`](http://localhost:4000) from your browser.

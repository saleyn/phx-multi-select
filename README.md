# Phoenix LiveView MultiSelect Component

This project implements an Elixir Phoenix LiveView component that has a capability
of selecting multiple checkboxed items from a list.

![Example](https://user-images.githubusercontent.com/272543/214661918-110505f2-e796-40e3-a1ee-47178cb0daba.png)

## Installation

Include the project in the `mix.exs` as a dependency:
```
defp deps do
  [
    {:multi_select, "~> 0.0"},
    ...
  ]
```

Run `mix deps.get`, and `mix multi_select.install`. This will modify the following
files:

- `assets/tailwind.config.js` - to add the necessary color alias
- `assets/package.json` - to add the tailwind scrollbar customization
- `assets/js/hooks/multi-select-hook.js` - copied from the multi_select source
- `assets/js/hooks/index.js` - add the MultiSelectHook

## Demo

The demo project is located in the `examples/` directory, and can be compiled
and run with:

```
cd examples
make
make run
```
Now you can visit [`localhost:4002`](http://localhost:4000) from your browser.

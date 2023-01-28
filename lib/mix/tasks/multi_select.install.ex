defmodule Mix.Tasks.MultiSelect.Install do
  @moduledoc """
  Installs multi_select component in the existing project.

  ```bash
  $ mix multi_select.install
  ```
  """

  @shortdoc "Installs MultiSelect component"
  use Mix.Task

  @impl true
  def run(_args) do
    modify_tailwind_cfg()
    modify_npm_cfg()
    install_js_hook()
    :ok
  end

  defp modify_tailwind_cfg() do
    tailwind_cfg_file = "assets/tailwind.config.js"
    tailwind_cfg =
      case File.exists?(tailwind_cfg_file) do
        true  -> File.read!(tailwind_cfg_file)
        false -> File.write!(tailwind_cfg_file, new_tailwind_cfg())
      end
    if tailwind_cfg =~ ~r/colors:\s*\{[^p]+primary:\s*[^,]+,/ do
      IO.puts("==> File #{tailwind_cfg_file} doesn't require modifications")
    else
      {tailwind_cfg, tailwind_cfg_file}
      |> add_theme()
      |> add_extend()
      |> add_colors()
      |> add_primary()
    end
  end

  defp modify_npm_cfg() do
    file = "assets/package.json"
    if File.exists?(file) and (File.read!(file) =~ "tailwind-scrollbar") do
      IO.puts("==> File #{file} doesn't require modifications")
    else
      {_, 0} = System.cmd("npm", ~w(install -D tailwind-scrollbar), cd: "assets")
      IO.puts("==> Add tailwind-scrollbar NPM dev package")
    end
  end

  defp install_js_hook() do
    file = "multi-select-hook.js"
    path = "assets/js/hooks/#{file}"
    if File.exists?(path) do
      IO.puts("==> File #{path} is already installed")
    else
      File.cp!("deps/multi_select/assets/${file}", path)
    end

    index = "assets/js/hooks/index.js"
    if File.exists?(index) do
      f = File.read!(index)
      str =
        if not (f =~ "import MultiSelectHook") do
          "import MultiSelectHook from \"./multi-select-hook\"\n" <> f
        else
          f
        end
      str =
        case Regex.run(~r/\n\s*export[^{]+{/, str, return: :index) do
          [{n, m}] ->
            {s1, s2} = String.split_at(str, n+m)
            if s2 =~ "MultiSelectHook" do
              str
            else
              s2 = String.trim_leading(s2, "\n")
              s1 <> "\n  MultiSelectHook,\n" <> s2
            end
          _ ->
            str <> "\nexport default {\n  MultiSelectHook\n}\n"
        end

      if f != str do
        File.write!(index, str)
        IO.puts("==> File #{index} modified")
      else
        IO.puts("==> File #{index} doesn't require modifications")
      end
    end
  end

  defp add_theme({str, file}) do
    case Regex.run(~r/\n(\s*)theme:\s*\{/, str, return: :index) do
      [theme_idx, indent_idx] ->
        {str, file, indent_idx, theme_idx}
      _ ->
        raise RuntimeError, message: "Cannot find 'theme:' entry in #{file}"
    end
  end

  defp add_extend({str, file, {_, indent_wid} = indent_idx, {n, m} = _theme_idx}) do
    case Regex.run(~r/\n(\s*)extend:\s*\{/, str, return: :index) do
      [idx, indent_idx] ->
        {str, file, indent_idx, idx}
      _ ->
        {s1, s2} = String.split_at(str, n+m)
        indent   = String.duplicate(" ", indent_wid)
        res1     = s1 <> indent <> "extend: {\n"
        res2     = indent <> "},\n" <> s2
        {res1 <> res2, file, indent_idx, {0, byte_size(res1)}}
    end
  end

  defp add_colors({str, file, {_, indent_wid} = indent_idx, {n, m} = _extend_idx}) do
    case Regex.run(~r/\n(\s*)colors:\s*\{/, str, return: :index) do
      [idx, indent_idx] ->
        {str, file, indent_idx, idx}
      _ ->
        {s1, s2} = String.split_at(str, n+m)
        indent   = String.duplicate(" ", indent_wid)
        res1     = s1 <> String.duplicate(indent, 2) <> "colors: {\n"
        res2     = indent <> "},\n" <> s2
        {res1 <> res2, file, indent_idx, {0, byte_size(res1)}}
    end
  end

  defp add_primary({str, file, {_, indent_wid}, {n, m} = _colors_idx}) do
    case Regex.run(~r/\n(\s*)primary:\s*[^,]+,/, str, return: :index) do
      [_idx, _indent_idx] ->
        str
      _ ->
        {s1, s2} = String.split_at(str, n+m)
        indent   = String.duplicate(" ", indent_wid)
        res      = s1 <> "\n" <> String.duplicate(indent, 3) <> "primary: colors.blue,\n"
                      <> String.trim_leading(s2, "\n")
        res      =
          if (res =~ "require(\"tailwindcss/colors\")") do
            res
          else
            [{offset, _}|_] = Regex.run(~r/module.exports/, res, return: :index)
            {s1, s2} = String.split_at(res, offset)
            res = s1 <> "const colors = require(\"tailwindcss/colors\")\n" <> s2
            res
          end
        File.write!(file, res)
        IO.puts("==> Added definition of primary color to #{file}")
    end
  end

  defp new_tailwind_cfg() do
    """
    const plugin = require("tailwindcss/plugin")
    const colors = require("tailwindcss/colors")

    module.exports = {
      content: [
        "./js/**/*.js",
        "../lib/*_web.ex",
        "../lib/*_web/**/*.*ex"
      ],
      theme: {
        extend: {
          colors: {
            primary: colors.blue,
          }
        }
      },
      darkMode: "class",
      plugins: [
        require("@tailwindcss/forms"),
        require('tailwind-scrollbar'),
      ]
    }
    """
  end
end

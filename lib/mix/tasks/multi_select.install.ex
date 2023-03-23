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
    check_alpinejs()
    :ok
  end

  defp modify_tailwind_cfg() do
    file = "assets/tailwind.config.js"

    if not File.exists?(file) do
      File.write!(file, new_tailwind_cfg())
      IO.puts("==> File #{file} created")
    else
      tailwind_cfg = File.read!(file)
      ## Add the "../deps/phoenix_multi_select/lib/*.ex" string to the `content` section
      str =
        if tailwind_cfg =~ content_mask() do
          tailwind_cfg
        else
          {str, module_exports_offset} =
            case Regex.run(~r/^module\.exports\s*=\s*\{\n*/m, tailwind_cfg, return: :index) do
              [offset] ->
                {tailwind_cfg, offset}
              nil ->
                raise RuntimeError, message: "Cannot find 'module.exports = {...}' in #{file}"
            end
          case Regex.run(~r/\n(\s*)content:\s*\[([^\]]+)/, str, return: :index) do
            [{s1n, s1m}, {_, indent_wid}, {s2n, s2m}] ->
              {s1, _} = String.split_at(str, s1n+s1m-s2m)
              {_, s3} = String.split_at(str, s2n+s2m)
              content =
                str
                |> String.slice(s2n, s2m)
                |> then(& Regex.replace(~r/[ ,\n]+$/, &1, ""))
                |> then(& &1 == "" && &1 || &1 <> ",")
                |> then(& """
                    #{&1}
                    #{String.duplicate(" ", indent_wid*2)}#{content_mask()},
                    """)
              s1 <> content <> String.duplicate(" ", indent_wid) <> s3
            _ ->
              {s1, s2} = String.split_at(str, elem(module_exports_offset, 0)+elem(module_exports_offset, 1))
              s1 <> content_str() <> s2
          end
        end
      ## Add the `primary` custom color
      str =
        if str =~ ~r/colors:\s*\{[^p]+primary:\s*[^,]+,/ do
          str
        else
          {str, file}
          |> add_theme()
          |> add_extend()
          |> add_colors()
          |> add_primary()
        end

      if str == tailwind_cfg do
        out("==> File #{file} doesn't require modifications")
      else
        File.write!(file, str)
        IO.puts("==> Added definition of primary color to #{file}")
      end
    end
  end

  defp content_str() do
    """
      content: [
        "./js/**/*.js",
        "../lib/*_web.ex",
        "../lib/*_web/**/*.*ex",
        #{content_mask()}
      ],
    """
  end

  defp content_mask(), do: "\"../deps/phoenix_multi_select/lib/*.ex\""

  defp modify_npm_cfg() do
    file = "assets/package.json"
    if File.exists?(file) and (File.read!(file) =~ "tailwind-scrollbar") do
      out("==> File #{file} doesn't require modifications")
    else
      pkg_mgr = get_package_mgr(["npm", "yarn"])
      {_, 0} = System.cmd(pkg_mgr, ~w(install -D tailwind-scrollbar), cd: "assets")
      IO.puts("==> Added tailwind-scrollbar NPM dev package")
    end
  end

  defp get_package_mgr([]), do:
    raise RuntimeError, message: "No JS package manager found: npm, yarn."
  defp get_package_mgr([name|tail]) do
    case System.cmd("sh", ["-c", "which " <> name]) do
      {_, 0} -> name
      {_, _} -> get_package_mgr(tail)
    end
  end

  defp install_js_hook() do
    hooks_folder = "assets/js/hooks"
    index_file   = "assets/js/hooks/index.js"

    File.exists?(hooks_folder) || File.mkdir!(hooks_folder)
    File.exists?(index_file)   || File.touch!(index_file)

    file = "multi-select-hook.js"
    path = "assets/js/hooks/#{file}"
    src  = "#{Mix.Project.deps_paths()[:phoenix_multi_select]}/assets/#{file}"
    if File.exists?(path) && File.read!(path) == File.read!(src) do
      out("==> File #{path} is already installed")
    else
      File.cp!(src, path)
      IO.puts("==> Installed #{path} file")
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
        out("==> File #{index} doesn't require modifications")
      end
    end
  end

  defp check_alpinejs() do
    if Application.get_env(:phoenix_multi_select, :use_alpinejs) do
      found =
        case Path.wildcard("lib/**/root.html.heex") do
          [root_html] -> File.read!(root_html) =~ ~r/<[^s]*script.+alpinejs/
          []          -> false
        end
      file  = "assets/js/app.js"
      found = found ||
        case File.exists?(file) do
          true  -> File.read!(file) =~ ~r/import.+alpinejs/
          false -> false
        end
      if not found do
        IO.puts("""
          ==> Configuration option `config :phoenix_multi_select, use_alpinejs: true`
          ==> requires that AlpineJS is available.
          ==>
          ==> However AlpineJS configuration is missing! You either need to include:
          ==>
          ==>   <script src="//unpkg.com/alpinejs" defer></script>
          ==>
          ==> in the root.html.heex template, or add this to the assets/js/app.js:
          ==>
          ==>   import 'alpinejs'
          ==>
          ==>   window.Alpine = Alpine
          ==>   Alpine.start()
          """)
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

  defp add_primary({str, _file, {_, indent_wid}, {n, m} = _colors_idx}) do
    case Regex.run(~r/\n(\s*)primary:\s*[^,]+,/, str, return: :index) do
      [_idx, _indent_idx] ->
        str
      _ ->
        {s1, s2} = String.split_at(str, n+m)
        indent   = String.duplicate(" ", indent_wid)
        res      = s1 <> "\n" <> String.duplicate(indent, 3) <> "primary: colors.blue,\n"
                      <> String.trim_leading(s2, "\n")
        if (res =~ "require(\"tailwindcss/colors\")") do
          res
        else
          [{offset, _}|_] = Regex.run(~r/module.exports/, res, return: :index)
          {s1, s2} = String.split_at(res, offset)
          res = s1 <> "const colors = require(\"tailwindcss/colors\")\n" <> s2
          res
        end
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
        "../lib/*_web/**/*.*ex",
        #{content_mask()},
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

  defp out(str), do:
    (System.get_env("DEBUG", "0") |> String.to_integer() > 0) && IO.puts(str)
end

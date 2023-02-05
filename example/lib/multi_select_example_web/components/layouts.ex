defmodule MultiSelectExampleWeb.Layouts do
  use MultiSelectExampleWeb, :html

  embed_templates "layouts/*"

  @use_alpinejs   Application.compile_env(:phoenix_multi_select, :use_alpinejs) || false

  def script_alpinejs(assigns) do
    if @use_alpinejs do
      ~H"""
      <script src="//unpkg.com/alpinejs" defer></script>
      """
    else
      ~H""
    end
  end
end

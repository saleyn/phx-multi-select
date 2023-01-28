defmodule MultiSelectExampleWeb.Router do
  use MultiSelectExampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MultiSelectExampleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MultiSelectExampleWeb do
    pipe_through :browser

    live_session :default do
      live "/", DemoLive
      live "/result", ResultLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MultiSelectExampleWeb do
  #   pipe_through :api
  # end
end

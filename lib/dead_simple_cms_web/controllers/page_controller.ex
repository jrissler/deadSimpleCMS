defmodule DeadSimpleCmsWeb.PageController do
  use DeadSimpleCmsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

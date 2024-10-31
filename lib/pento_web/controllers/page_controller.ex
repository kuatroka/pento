defmodule PentoWeb.PageController do
  use PentoWeb, :controller

  import PentoWeb.UserAuth, only: [require_authenticated_user: 2]

  def home(conn, _params) do
    require_authenticated_user(conn, [])

    # if conn.assigns.current_user do
    #   redirect(conn, to: "/guess")
    # else
    #   render(conn, :home)
    # end

    render(conn, :home)

  end
end

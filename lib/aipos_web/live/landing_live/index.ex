defmodule AiposWeb.LandingLive.Index do
  use AiposWeb, :live_view
  alias Aipos.Accounts

  def mount(_params, session, socket) do
    current_user =
      if user_token = session["user_token"] do
        Accounts.get_user_by_session_token(user_token)
      end

    {:ok, assign(socket, current_user: current_user)}
  end

  def render(assigns) do
    ~H"""
    <.landing current_user={@current_user} />
    <.footer />
    """
  end
end

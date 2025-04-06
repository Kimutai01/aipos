defmodule AiposWeb.RegisterLive.Show do
  use AiposWeb, :live_view

  alias Aipos.Registers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:registers, Registers.list_registers())
     |> assign(:active_page, "registers")
     |> assign(:current_organization, get_organization(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:register, Registers.get_register!(id))}
  end

  defp get_organization(user) do
    Aipos.Organizations.get_organization!(user.organization_id)
  end

  defp page_title(:show), do: "Show Register"
  defp page_title(:edit), do: "Edit Register"
end

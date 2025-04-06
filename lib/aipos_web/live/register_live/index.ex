defmodule AiposWeb.RegisterLive.Index do
  use AiposWeb, :live_view

  alias Aipos.Registers
  alias Aipos.Registers.Register

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:registers, Registers.list_registers())
     |> assign(:active_page, "registers")
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:current_organization, get_organization(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Register")
    |> assign(:register, Registers.get_register!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Register")
    |> assign(:register, %Register{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Registers")
    |> assign(:register, nil)
  end

  @impl true
  def handle_info({AiposWeb.RegisterLive.FormComponent, {:saved, register}}, socket) do
    {:noreply, stream_insert(socket, :registers, register)}
  end

  defp get_organization(user) do
    Aipos.Organizations.get_organization!(user.organization_id)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    register = Registers.get_register!(id)
    {:ok, _} = Registers.delete_register(register)

    {:noreply, stream_delete(socket, :registers, register)}
  end
end

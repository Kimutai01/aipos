defmodule AiposWeb.SupplierLive.Index do
  use AiposWeb, :live_view

  alias Aipos.Suppliers
  alias Aipos.Suppliers.Supplier
  alias AiposWeb.Sidebar

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(
        :current_organization,
        get_current_organization(socket.assigns.current_user.organization_id)
      )
      |> assign(:active_page, "suppliers")
      |> assign(:search_query, "")
      |> stream(
        :suppliers,
        Suppliers.list_suppliers_by_organization(socket.assigns.current_user.organization_id)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Supplier")
    |> assign(:supplier, Suppliers.get_supplier!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Supplier")
    |> assign(:supplier, %Supplier{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Suppliers")
    |> assign(:supplier, nil)
  end

  @impl true
  def handle_info({AiposWeb.SupplierLive.FormComponent, {:saved, supplier}}, socket) do
    {:noreply, stream_insert(socket, :suppliers, supplier)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    supplier = Suppliers.get_supplier!(id)
    {:ok, _} = Suppliers.delete_supplier(supplier)

    {:noreply, stream_delete(socket, :suppliers, supplier)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    suppliers =
      Suppliers.search_suppliers(
        query,
        socket.assigns.current_user.organization_id
      )

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> stream(:suppliers, suppliers, reset: true)}
  end

  defp get_current_organization(organization_id) do
    Aipos.Organizations.get_organization!(organization_id)
  end
end

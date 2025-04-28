defmodule AiposWeb.CustomerLive.Index do
  use AiposWeb, :live_view

  alias Aipos.Customers
  alias Aipos.Customers.Customer
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
      |> assign(:active_page, "customers")
      |> assign(:search_query, "")
      |> assign(:filter, "all")
      |> stream(:customers, Customers.list_customers())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Customer")
    |> assign(:customer, Customers.get_customer!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Customer")
    |> assign(:customer, %Customer{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Customers")
    |> assign(:customer, nil)
  end

  @impl true
  def handle_info({AiposWeb.CustomerLive.FormComponent, {:saved, customer}}, socket) do
    {:noreply, stream_insert(socket, :customers, customer)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    customer = Customers.get_customer!(id)
    {:ok, _} = Customers.delete_customer(customer)

    {:noreply, stream_delete(socket, :customers, customer)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    customers = Customers.search_customers(query)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> stream(:customers, customers, reset: true)}
  end

  @impl true
  def handle_event("filter_customers", %{"filter" => filter}, socket) do
    customers =
      case filter do
        "all" -> Customers.list_customers()
        "loyal" -> Customers.list_loyal_customers()
        "recent" -> Customers.list_recent_customers()
        "inactive" -> Customers.list_inactive_customers()
        _ -> Customers.list_customers()
      end

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> stream(:customers, customers, reset: true)}
  end

  defp get_current_organization(organization_id) do
    Aipos.Organizations.get_organization!(organization_id)
  end

  defp membership_level_color(level) do
    case level do
      "Bronze" -> "bg-amber-700"
      "Silver" -> "bg-gray-500"
      "Gold" -> "bg-yellow-500"
      "Platinum" -> "bg-blue-700"
      _ -> "bg-gray-700"
    end
  end

  defp format_currency(amount) when is_nil(amount), do: "KSh 0.00"

  defp format_currency(amount) do
    "KSh #{:erlang.float_to_binary(Decimal.to_float(amount), decimals: 2)}"
  end
end

defmodule AiposWeb.DashboardLive.Index do
  use AiposWeb, :live_view
  alias Aipos.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_organization, get_organization(socket.assigns.current_user))
      |> assign(:active_page, "dashboard")
      |> assign(:today_sales, generate_today_sales())
      |> assign(:recent_sales, generate_recent_sales())
      |> assign(:top_products, generate_top_products())
      |> assign(:low_stock_items, generate_low_stock_items())
      |> assign(:sales_stats, generate_sales_stats())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-gray-100">
      <!-- Sidebar -->
      <.live_component
        module={AiposWeb.Sidebar}
        id="sidebar"
        current_user={@current_user}
        current_organization={@current_organization}
        active_page={@active_page}
      />
      
    <!-- Main Content -->
      <div class="flex-1 pl-64">
        <!-- Header -->
        <header class="bg-white shadow">
          <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between">
              <h1 class="text-xl font-bold tracking-tight text-gray-900">Dashboard</h1>
              <div class="flex items-center">
                <div class="relative mr-4">
                  <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                    <Heroicons.icon name="magnifying-glass" type="mini" class="h-5 w-5 text-gray-400" />
                  </span>
                  <input
                    type="text"
                    placeholder="Search..."
                    class="w-64 rounded-lg border border-gray-300 py-2 pl-10 pr-4 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                  />
                </div>
                <button type="button" class="rounded-full bg-gray-200 p-1">
                  <Heroicons.icon name="bell" type="outline" class="h-6 w-6 text-gray-500" />
                </button>
              </div>
            </div>
          </div>
        </header>
        
    <!-- Main Content -->
        <main class="mx-auto max-w-7xl py-6 px-4 sm:px-6 lg:px-8">
          <!-- Quick Stats -->
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
            <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
              <dt class="truncate text-sm font-medium text-gray-500">Today's Sales</dt>
              <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
                KSh {@today_sales.amount}
              </dd>
              <dd class="mt-1 flex items-center text-sm">
                <span class={"#{if @today_sales.trend > 0, do: "text-green-600", else: "text-red-600"} font-semibold"}>
                  {if @today_sales.trend > 0, do: "+", else: ""}{@today_sales.trend}%
                </span>
                <span class="text-gray-500 ml-1">from yesterday</span>
              </dd>
            </div>

            <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
              <dt class="truncate text-sm font-medium text-gray-500">Transactions Today</dt>
              <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
                {@today_sales.transactions}
              </dd>
              <dd class="mt-1 flex items-center text-sm">
                <span class="text-green-600 font-semibold">
                  +{@today_sales.transactions_trend}%
                </span>
                <span class="text-gray-500 ml-1">from yesterday</span>
              </dd>
            </div>

            <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
              <dt class="truncate text-sm font-medium text-gray-500">Average Order Value</dt>
              <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
                KSh {@sales_stats.avg_order}
              </dd>
              <dd class="mt-1 flex items-center text-sm">
                <span class={"#{if @sales_stats.avg_order_trend > 0, do: "text-green-600", else: "text-red-600"} font-semibold"}>
                  {if @sales_stats.avg_order_trend > 0, do: "+", else: ""}{@sales_stats.avg_order_trend}%
                </span>
                <span class="text-gray-500 ml-1">from last week</span>
              </dd>
            </div>

            <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
              <dt class="truncate text-sm font-medium text-gray-500">Low Stock Items</dt>
              <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
                {length(@low_stock_items)}
              </dd>
              <dd class="mt-1 text-sm text-gray-500">
                <a href="/inventory" class="text-blue-600 hover:text-blue-800">View inventory</a>
              </dd>
            </div>
          </div>
          
    <!-- Recent Sales & Top Products -->
          <div class="mt-8 grid grid-cols-1 gap-5 lg:grid-cols-2">
            <!-- Recent Sales -->
            <div class="overflow-hidden rounded-lg bg-white shadow">
              <div class="p-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Recent Sales</h3>
                <div class="mt-5 flow-root">
                  <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                    <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                      <table class="min-w-full divide-y divide-gray-300">
                        <thead>
                          <tr>
                            <th
                              scope="col"
                              class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0"
                            >
                              Order ID
                            </th>
                            <th
                              scope="col"
                              class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                            >
                              Time
                            </th>
                            <th
                              scope="col"
                              class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                            >
                              Items
                            </th>
                            <th
                              scope="col"
                              class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                            >
                              Total
                            </th>
                            <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                              <span class="sr-only">View</span>
                            </th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-200">
                          <%= for sale <- @recent_sales do %>
                            <tr>
                              <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                                #{sale.id}
                              </td>
                              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                {sale.time}
                              </td>
                              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                {sale.items} items
                              </td>
                              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                KSh {sale.total}
                              </td>
                              <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                                <a href="#" class="text-blue-600 hover:text-blue-900">View</a>
                              </td>
                            </tr>
                          <% end %>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
                <div class="mt-5">
                  <a href="/pos/sales" class="text-sm font-medium text-blue-600 hover:text-blue-800">
                    View all sales
                  </a>
                </div>
              </div>
            </div>

            <div class="overflow-hidden rounded-lg bg-white shadow">
              <div class="p-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Top Selling Products</h3>
                <div class="mt-5">
                  <ul role="list" class="divide-y divide-gray-200">
                    <%= for {product, index} <- Enum.with_index(@top_products) do %>
                      <li class="flex items-center py-3">
                        <span class={"flex h-8 w-8 items-center justify-center rounded-full #{top_product_color(index)} text-white"}>
                          {index + 1}
                        </span>
                        <div class="ml-4 flex-1">
                          <p class="text-sm font-medium text-gray-900">{product.name}</p>
                          <p class="text-sm text-gray-500">{product.category}</p>
                        </div>
                        <div class="text-right">
                          <p class="text-sm font-medium text-gray-900">{product.sold} sold</p>
                          <p class="text-sm text-gray-500">KSh {product.revenue}</p>
                        </div>
                      </li>
                    <% end %>
                  </ul>
                </div>
                <div class="mt-5">
                  <p class="text-center text-sm text-gray-500">Sales Graph will be displayed here</p>
                  <div class="mt-3 h-48 rounded-lg bg-gray-100 flex items-center justify-center">
                    <p class="text-gray-400">Sales Trend Graph</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-8">
            <div class="overflow-hidden rounded-lg bg-white shadow">
              <div class="p-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Inventory Alerts</h3>
                <div class="mt-5 flow-root">
                  <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                    <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                      <table class="min-w-full divide-y divide-gray-300">
                        <thead>
                          <tr>
                            <th
                              scope="col"
                              class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0"
                            >
                              Product
                            </th>
                            <th
                              scope="col"
                              class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                            >
                              Category
                            </th>
                            <th
                              scope="col"
                              class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                            >
                              Current Stock
                            </th>
                            <th
                              scope="col"
                              class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                            >
                              Status
                            </th>
                            <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                              <span class="sr-only">Action</span>
                            </th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-200">
                          <%= for item <- @low_stock_items do %>
                            <tr>
                              <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                                {item.name}
                              </td>
                              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                {item.category}
                              </td>
                              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                {item.stock} units
                              </td>
                              <td class="whitespace-nowrap px-3 py-4 text-sm">
                                <span class={"inline-flex rounded-full px-2 text-xs font-semibold leading-5 #{stock_status_color(item.status)}"}>
                                  {item.status}
                                </span>
                              </td>
                              <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                                <a href="#" class="text-blue-600 hover:text-blue-900">Order</a>
                              </td>
                            </tr>
                          <% end %>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
                <div class="mt-5">
                  <a href="/inventory" class="text-sm font-medium text-blue-600 hover:text-blue-800">
                    View all inventory
                  </a>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
    """
  end

  defp top_product_color(0), do: "bg-blue-600"
  defp top_product_color(1), do: "bg-green-600"
  defp top_product_color(2), do: "bg-purple-600"
  defp top_product_color(_), do: "bg-gray-600"

  defp stock_status_color("Low"), do: "bg-yellow-100 text-yellow-800"
  defp stock_status_color("Critical"), do: "bg-red-100 text-red-800"
  defp stock_status_color(_), do: "bg-gray-100 text-gray-800"

  defp get_organization(user) do
    Aipos.Organizations.get_organization!(user.organization_id)
  end

  defp generate_today_sales do
    %{
      amount: "156,890",
      trend: 12.5,
      transactions: 42,
      transactions_trend: 8.3
    }
  end

  defp generate_recent_sales do
    [
      %{id: "10392", time: "Just now", items: 5, total: "7,865"},
      %{id: "10391", time: "5 min ago", items: 2, total: "2,550"},
      %{id: "10390", time: "20 min ago", items: 10, total: "15,230"},
      %{id: "10389", time: "1 hour ago", items: 3, total: "4,580"},
      %{id: "10388", time: "2 hours ago", items: 7, total: "9,825"}
    ]
  end

  defp generate_top_products do
    [
      %{name: "Fresh Milk 1L", category: "Dairy", sold: 32, revenue: "12,800"},
      %{name: "Whole Wheat Bread", category: "Bakery", sold: 28, revenue: "8,400"},
      %{name: "Organic Eggs (12pk)", category: "Produce", sold: 25, revenue: "11,250"},
      %{name: "Sliced Cheese 500g", category: "Dairy", sold: 22, revenue: "11,000"},
      %{name: "Bananas 1kg", category: "Produce", sold: 20, revenue: "4,000"}
    ]
  end

  defp generate_low_stock_items do
    [
      %{name: "Fresh Milk 1L", category: "Dairy", stock: 8, status: "Low"},
      %{name: "Organic Eggs (12pk)", category: "Produce", stock: 3, status: "Critical"},
      %{name: "Sliced Cheese 500g", category: "Dairy", stock: 5, status: "Low"},
      %{name: "Premium Coffee 250g", category: "Beverages", stock: 2, status: "Critical"},
      %{name: "Tomatoes 1kg", category: "Produce", stock: 6, status: "Low"}
    ]
  end

  defp generate_sales_stats do
    %{
      avg_order: "3,650",
      avg_order_trend: 5.2
    }
  end
end

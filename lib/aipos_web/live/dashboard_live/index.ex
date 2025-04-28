defmodule AiposWeb.DashboardLive.Index do
  use AiposWeb, :live_view
  alias Aipos.Accounts
  alias Aipos.Sales
  alias Aipos.Sales.{Sale, SaleItem}
  alias Aipos.ProductSkus
  alias Aipos.ProductSkus.ProductSku
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    organization_id = socket.assigns.current_user.organization_id

    # Get current date in UTC
    today = Date.utc_today()
    yesterday = Date.add(today, -1)
    one_week_ago = Date.add(today, -7)

    # Get sales data for the last 30 days for chart
    sales_data_by_day = get_sales_data_by_day(organization_id)

    # Main data for dashboard
    today_sales = get_today_sales(organization_id, today, yesterday)
    recent_sales = get_recent_sales(organization_id)
    top_products = get_top_products(organization_id)
    IO.inspect(top_products, label: "Top Produsdhjkdsldshjkdsjhcts")
    low_stock_items = get_low_stock_items(organization_id)
    sales_stats = get_sales_stats(organization_id, today, one_week_ago)

    socket =
      socket
      |> assign(:current_organization, get_organization(socket.assigns.current_user))
      |> assign(:active_page, "dashboard")
      |> assign(:today_sales, today_sales)
      |> assign(:recent_sales, recent_sales)
      |> assign(:top_products, top_products)
      |> assign(:low_stock_items, low_stock_items)
      |> assign(:sales_stats, sales_stats)
      |> assign(:sales_data_by_day, sales_data_by_day)
      |> assign(:data_available, %{
        sales: length(recent_sales) > 0,
        products: length(top_products) > 0,
        inventory: length(low_stock_items) > 0
      })

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
                <span class={"#{if @today_sales.transactions_trend > 0, do: "text-green-600", else: "text-red-600"} font-semibold"}>
                  {if @today_sales.transactions_trend > 0, do: "+", else: ""}{@today_sales.transactions_trend}%
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
          
    <!-- Daily Sales Chart -->
          <div class="mt-8">
            <div class="overflow-hidden rounded-lg bg-white shadow">
              <div class="p-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Daily Sales Trend</h3>
                <div
                  id="daily-sales-chart"
                  phx-hook="DailySalesChart"
                  class="mt-5 h-64"
                  data-sales={Jason.encode!(@sales_data_by_day)}
                >
                  <canvas id="dailySalesChart" class="w-full h-full"></canvas>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Recent Sales & Top Products -->
          <div class="mt-8 grid grid-cols-1 gap-5 lg:grid-cols-2">
            <!-- Recent Sales -->
            <div class="overflow-hidden rounded-lg bg-white shadow">
              <div class="p-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Recent Sales</h3>
                <div class="mt-5 flow-root">
                  <%= if Enum.empty?(@recent_sales) do %>
                    <div class="py-10 text-center">
                      <Heroicons.icon
                        name="shopping-cart"
                        type="outline"
                        class="mx-auto h-12 w-12 text-gray-400"
                      />
                      <h3 class="mt-2 text-sm font-semibold text-gray-900">No sales data</h3>
                      <p class="mt-1 text-sm text-gray-500">
                        No recent sales have been recorded yet.
                      </p>
                      <div class="mt-6">
                        <a
                          href="/pos"
                          class="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
                        >
                          <Heroicons.icon name="plus" type="mini" class="mr-1 h-4 w-4" /> New Sale
                        </a>
                      </div>
                    </div>
                  <% else %>
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
                                  #{sale.transaction_id || sale.id}
                                </td>
                                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                  <%= if sale.inserted_at do %>
                                    {format_time(sale.inserted_at)}
                                  <% else %>
                                    {sale.time || "Unknown"}
                                  <% end %>
                                </td>
                                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                                  KSh
                                  <%= if sale.total_amount do %>
                                    {format_decimal(sale.total_amount)}
                                  <% else %>
                                    {sale.total || "0"}
                                  <% end %>
                                </td>
                                <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                                  <a
                                    href={"/pos/sales/#{sale.id}"}
                                    class="text-blue-600 hover:text-blue-900"
                                  >
                                    View
                                  </a>
                                </td>
                              </tr>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    </div>
                    <div class="mt-5">
                      <a
                        href="/pos/sales"
                        class="text-sm font-medium text-blue-600 hover:text-blue-800"
                      >
                        View all sales
                      </a>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="overflow-hidden rounded-lg bg-white shadow">
              <div class="p-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Top Selling Products</h3>
                <div class="mt-5">
                  <%= if Enum.empty?(@top_products) do %>
                    <div class="py-10 text-center">
                      <Heroicons.icon
                        name="chart-bar"
                        type="outline"
                        class="mx-auto h-12 w-12 text-gray-400"
                      />
                      <h3 class="mt-2 text-sm font-semibold text-gray-900">No product data</h3>
                      <p class="mt-1 text-sm text-gray-500">
                        Start selling products to see your top performers.
                      </p>
                      <div class="mt-6">
                        <a
                          href="/inventory/products"
                          class="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
                        >
                          <Heroicons.icon name="plus" type="mini" class="mr-1 h-4 w-4" /> Add Products
                        </a>
                      </div>
                    </div>
                  <% else %>
                    <ul role="list" class="divide-y divide-gray-200">
                      <%= for {product, index} <- Enum.with_index(@top_products) do %>
                        <li class="flex items-center py-3">
                          <span class={"flex h-8 w-8 items-center justify-center rounded-full #{top_product_color(index)} text-white"}>
                            {index + 1}
                          </span>
                          <div class="ml-4 flex-1">
                            <p class="text-sm font-medium text-gray-900">{product.name}</p>
                          </div>
                          <div class="text-right">
                            <p class="text-sm font-medium text-gray-900">{product.sold} sold</p>
                            <p class="text-sm text-gray-500">KSh {product.revenue}</p>
                          </div>
                        </li>
                      <% end %>
                    </ul>
                    <div class="mt-5">
                      <p class="text-center text-sm font-medium text-gray-900">
                        Sales Distribution
                      </p>
                      <div
                        id="products-chart"
                        phx-hook="ProductsChart"
                        class="mt-3 h-48 rounded-lg"
                        data-products={Jason.encode!(@top_products)}
                      >
                        <canvas id="productsChart" class="w-full h-full p-1"></canvas>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-8">
            <div class="overflow-hidden rounded-lg bg-white shadow">
              <div class="p-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Inventory Alerts</h3>
                <div class="mt-5 flow-root">
                  <%= if Enum.empty?(@low_stock_items) do %>
                    <div class="py-10 text-center">
                      <Heroicons.icon
                        name="academic-cap"
                        type="outline"
                        class="mx-auto h-12 w-12 text-gray-400"
                      />
                      <h3 class="mt-2 text-sm font-semibold text-gray-900">No inventory alerts</h3>
                      <p class="mt-1 text-sm text-gray-500">
                        All products have sufficient stock levels.
                      </p>
                      <div class="mt-6">
                        <a
                          href="/inventory"
                          class="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
                        >
                          <Heroicons.icon
                            name="clipboard-document-list"
                            type="mini"
                            class="mr-1 h-4 w-4"
                          /> View Inventory
                        </a>
                      </div>
                    </div>
                  <% else %>
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
                                  {item.stock_quantity || item.stock} units
                                </td>
                                <td class="whitespace-nowrap px-3 py-4 text-sm">
                                  <span class={"inline-flex rounded-full px-2 text-xs font-semibold leading-5 #{stock_status_color(item.status)}"}>
                                    {item.status}
                                  </span>
                                </td>
                                <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                                  <a
                                    href={"/inventory/product_skus/#{item.id || ""}/edit"}
                                    class="text-blue-600 hover:text-blue-900"
                                  >
                                    Order
                                  </a>
                                </td>
                              </tr>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    </div>
                    <div class="mt-5">
                      <a
                        href="/inventory"
                        class="text-sm font-medium text-blue-600 hover:text-blue-800"
                      >
                        View all inventory
                      </a>
                    </div>
                  <% end %>
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

  # Format a Decimal value to a string with commas
  defp format_decimal(nil), do: "0"

  defp format_decimal(decimal) do
    decimal
    |> Decimal.round(0)
    |> Decimal.to_string()
    |> format_number_with_commas()
  end

  # Format a number string to include commas
  defp format_number_with_commas(number_string) do
    number_string
    |> String.replace(~r/(\d)(?=(\d{3})+(?!\d))/, "\\1,")
  end

  # Format datetime to relative time
  defp format_time(nil), do: "Unknown"

  defp format_time(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime)

    cond do
      diff_seconds < 60 ->
        "Just now"

      diff_seconds < 3600 ->
        "#{div(diff_seconds, 60)} min ago"

      diff_seconds < 86400 ->
        "#{div(diff_seconds, 3600)} hour#{if div(diff_seconds, 3600) > 1, do: "s", else: ""} ago"

      true ->
        "#{div(diff_seconds, 86400)} day#{if div(diff_seconds, 86400) > 1, do: "s", else: ""} ago"
    end
  end

  # Get today's sales data from database
  defp get_today_sales(organization_id, today, yesterday) do
    today_start = DateTime.new!(today, ~T[00:00:00.000], "Etc/UTC")
    today_end = DateTime.new!(today, ~T[23:59:59.999], "Etc/UTC")

    yesterday_start = DateTime.new!(yesterday, ~T[00:00:00.000], "Etc/UTC")
    yesterday_end = DateTime.new!(yesterday, ~T[23:59:59.999], "Etc/UTC")

    # Query for today's sales
    today_sales_query =
      from s in Sale,
        where:
          s.organization_id == ^organization_id and
            s.inserted_at >= ^today_start and
            s.inserted_at <= ^today_end,
        select: %{
          total: sum(s.total_amount),
          count: count(s.id)
        }

    # Query for yesterday's sales
    yesterday_sales_query =
      from s in Sale,
        where:
          s.organization_id == ^organization_id and
            s.inserted_at >= ^yesterday_start and
            s.inserted_at <= ^yesterday_end,
        select: %{
          total: sum(s.total_amount),
          count: count(s.id)
        }

    today_results = Aipos.Repo.one(today_sales_query) || %{total: Decimal.new(0), count: 0}

    yesterday_results =
      Aipos.Repo.one(yesterday_sales_query) || %{total: Decimal.new(0), count: 0}

    # Calculate trends
    amount_trend = calculate_trend(today_results.total, yesterday_results.total)
    transaction_trend = calculate_trend(today_results.count, yesterday_results.count)

    %{
      amount: format_decimal(today_results.total),
      trend: amount_trend,
      transactions: today_results.count,
      transactions_trend: transaction_trend
    }
  end

  # Calculate percentage trend between current and previous values
  defp calculate_trend(current, previous) do
    current_val = if is_nil(current), do: Decimal.new(0), else: current
    previous_val = if is_nil(previous), do: Decimal.new(0), else: previous

    # Handle division by zero case
    if Decimal.eq?(previous_val, Decimal.new(0)) do
      if Decimal.gt?(current_val, Decimal.new(0)), do: 100.0, else: 0.0
    else
      current_val
      |> Decimal.sub(previous_val)
      |> Decimal.div(previous_val)
      |> Decimal.mult(Decimal.new(100))
      |> Decimal.round(1)
      |> Decimal.to_float()
    end
  end

  # Get recent sales from database
  defp get_recent_sales(organization_id) do
    # Query sales without the association that doesn't exist
    query =
      from s in Sale,
        where: s.organization_id == ^organization_id,
        order_by: [desc: s.inserted_at],
        limit: 5,
        select: %{
          id: s.id,
          transaction_id: s.transaction_id,
          total_amount: s.total_amount,
          inserted_at: s.inserted_at
        }

    # Execute the query
    sales = Aipos.Repo.all(query)

    # Return empty list if no sales found (no fallback data)
    sales
  end

  # Fixed get_top_products function that ensures correct organization filtering
  # Fixed get_top_products function without category field
  defp get_top_products(organization_id) do
    try do
      # First query: Group by product_sku_id and sum quantities
      query =
        from si in SaleItem,
          where: si.organization_id == ^organization_id,
          group_by: [si.product_sku_id, si.name],
          order_by: [desc: sum(si.quantity)],
          limit: 5,
          select: %{
            id: si.product_sku_id,
            name: si.name,
            sold: sum(si.quantity),
            revenue: sum(si.subtotal)
          }

      Aipos.Repo.all(query)
    rescue
      e ->
        IO.inspect(e, label: "Error in get_top_products")
        []
    end
  end

  defp get_low_stock_items(organization_id) do
    # Safety check for schema structure
    try do
      # Updated query to use only product_skus without joining products
      buffer_query =
        from sku in ProductSku,
          where:
            sku.organization_id == ^organization_id and
              not is_nil(sku.stock_quantity) and
              not is_nil(sku.buffer_level) and
              sku.stock_quantity < sku.buffer_level and
              sku.stock_quantity > 0,
          order_by: [asc: sku.stock_quantity],
          limit: 5,
          select: %{
            id: sku.id,
            name: sku.name,
            stock_quantity: sku.stock_quantity,
            buffer_level: sku.buffer_level
          }

      items = Aipos.Repo.all(buffer_query)

      # Add status based on stock level
      Enum.map(items, fn item ->
        buffer = item.buffer_level || 5
        half_buffer = div(buffer, 2)

        status =
          cond do
            item.stock_quantity <= half_buffer -> "Critical"
            true -> "Low"
          end

        Map.put(item, :status, status)
      end)
    rescue
      e ->
        IO.inspect(e, label: "Error in get_low_stock_items")
        []
    end
  end

  # Get sales statistics
  defp get_sales_stats(organization_id, today, one_week_ago) do
    # Current week range
    current_week_start = Date.beginning_of_week(today)
    current_week_end = Date.end_of_week(today)

    # Previous week range
    previous_week_start = Date.beginning_of_week(one_week_ago)
    previous_week_end = Date.end_of_week(one_week_ago)

    # Convert to DateTime
    current_week_start_dt = DateTime.new!(current_week_start, ~T[00:00:00.000], "Etc/UTC")
    current_week_end_dt = DateTime.new!(current_week_end, ~T[23:59:59.999], "Etc/UTC")
    previous_week_start_dt = DateTime.new!(previous_week_start, ~T[00:00:00.000], "Etc/UTC")
    previous_week_end_dt = DateTime.new!(previous_week_end, ~T[23:59:59.999], "Etc/UTC")

    # Query for current week average order value
    current_week_query =
      from s in Sale,
        where:
          s.organization_id == ^organization_id and
            s.inserted_at >= ^current_week_start_dt and
            s.inserted_at <= ^current_week_end_dt,
        select: %{
          total: sum(s.total_amount),
          count: count(s.id)
        }

    # Query for previous week average order value
    previous_week_query =
      from s in Sale,
        where:
          s.organization_id == ^organization_id and
            s.inserted_at >= ^previous_week_start_dt and
            s.inserted_at <= ^previous_week_end_dt,
        select: %{
          total: sum(s.total_amount),
          count: count(s.id)
        }

    current_week_results =
      Aipos.Repo.one(current_week_query) || %{total: Decimal.new(0), count: 0}

    previous_week_results =
      Aipos.Repo.one(previous_week_query) || %{total: Decimal.new(0), count: 0}

    # Calculate average order values
    current_avg =
      if current_week_results.count > 0 do
        Decimal.div(current_week_results.total, Decimal.new(current_week_results.count))
      else
        Decimal.new(0)
      end

    previous_avg =
      if previous_week_results.count > 0 do
        Decimal.div(previous_week_results.total, Decimal.new(previous_week_results.count))
      else
        Decimal.new(0)
      end

    # Calculate trend
    avg_order_trend = calculate_trend(current_avg, previous_avg)

    %{
      avg_order: format_decimal(current_avg),
      avg_order_trend: avg_order_trend
    }
  end

  # Get sales data by day for the last 30 days
  defp get_sales_data_by_day(organization_id) do
    # Calculate date range for the last 30 days
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -30)

    # Convert to DateTime for database query
    start_datetime = DateTime.new!(start_date, ~T[00:00:00.000], "Etc/UTC")
    end_datetime = DateTime.new!(end_date, ~T[23:59:59.999], "Etc/UTC")

    # Query for getting sales by day
    query =
      from s in Sale,
        where:
          s.organization_id == ^organization_id and
            s.inserted_at >= ^start_datetime and
            s.inserted_at <= ^end_datetime,
        group_by: fragment("date(inserted_at)"),
        order_by: fragment("date(inserted_at)"),
        select: %{
          date: fragment("date(inserted_at)"),
          total: sum(s.total_amount),
          count: count(s.id)
        }

    # Execute query
    results = Aipos.Repo.all(query)

    # Create a map of all dates in the range
    date_range = Date.range(start_date, end_date)

    # Format the results with all dates, filling in zeros for missing dates
    date_map =
      Enum.reduce(date_range, %{}, fn date, acc ->
        Map.put(acc, Date.to_string(date), %{total: Decimal.new(0), count: 0})
      end)

    # Merge the results with the date map
    Enum.reduce(results, date_map, fn result, acc ->
      date_str =
        case result.date do
          %Date{} = d -> Date.to_string(d)
          d when is_binary(d) -> d
          _ -> nil
        end

      if date_str && Map.has_key?(acc, date_str) do
        Map.put(acc, date_str, %{total: result.total, count: result.count})
      else
        acc
      end
    end)
  end
end

defmodule AiposWeb.Sale.Sales do
  use Phoenix.LiveView

  alias AiposWeb.Sidebar

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:page_title, "Sales History")
      |> assign(:active_page, "sales")
      |> assign(:current_user, sample_user())
      |> assign(:current_organization, sample_organization())
      |> assign(:selected_date, Date.utc_today())
      |> assign(:search_query, "")
      |> assign(:filter_payment_method, "all")
      |> assign(:sort_field, "created_at")
      |> assign(:sort_direction, "desc")
      |> assign(:page, 1)
      |> assign(:per_page, 10)
      |> assign_sample_analytics()
      |> assign_sample_sales()

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    # Filter sales based on the query
    filtered_sales = filter_sales_by_query(socket.assigns.all_sales, query)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> assign(:sales, Enum.take(filtered_sales, socket.assigns.per_page))
     |> assign(:total_count, Enum.count(filtered_sales))
     |> assign(:total_pages, ceil(Enum.count(filtered_sales) / socket.assigns.per_page))}
  end

  @impl true
  def handle_event("filter_by_payment", %{"payment_method" => method}, socket) do
    filtered_sales = filter_sales_by_payment(socket.assigns.all_sales, method)

    {:noreply,
     socket
     |> assign(:filter_payment_method, method)
     |> assign(:page, 1)
     |> assign(:sales, Enum.take(filtered_sales, socket.assigns.per_page))
     |> assign(:total_count, Enum.count(filtered_sales))
     |> assign(:total_pages, ceil(Enum.count(filtered_sales) / socket.assigns.per_page))}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    direction =
      if socket.assigns.sort_field == field && socket.assigns.sort_direction == "asc",
        do: "desc",
        else: "asc"

    sorted_sales = sort_sales(socket.assigns.sales, field, direction)

    {:noreply,
     socket
     |> assign(:sort_field, field)
     |> assign(:sort_direction, direction)
     |> assign(:sales, sorted_sales)}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    {page, _} = Integer.parse(page)
    start_idx = (page - 1) * socket.assigns.per_page

    filtered_sales =
      socket.assigns.all_sales
      |> filter_sales_by_query(socket.assigns.search_query)
      |> filter_sales_by_payment(socket.assigns.filter_payment_method)

    paginated_sales =
      filtered_sales
      |> Enum.slice(start_idx, socket.assigns.per_page)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:sales, paginated_sales)}
  end

  @impl true
  def handle_event("export_csv", _, socket) do
    filename = "sales_export_#{Date.to_string(socket.assigns.selected_date)}.csv"

    # Simulate CSV content
    csv_content =
      "receipt_number,date,time,customer,payment_method,total_amount\n" <>
        Enum.map_join(socket.assigns.all_sales, "\n", fn sale ->
          customer_name = if sale.customer, do: sale.customer.name, else: "Walk-in customer"

          "#{sale.receipt_number},#{Date.to_string(socket.assigns.selected_date)},#{format_time(sale.inserted_at)},#{customer_name},#{sale.payment_method},#{sale.total_amount}"
        end)

    {:noreply,
     socket
     |> put_flash(:info, "Export started. You'll receive a download shortly.")
     |> push_event("download-csv", %{filename: filename, content: csv_content})}
  end

  defp assign_sample_analytics(socket) do
    socket
    |> assign(:today_analytics, %{
      total_amount: 157_850.00,
      total_sales: 43,
      average_sale: 3671.00,
      items_sold: 137,
      unique_products: 28,
      top_payment_method: "mpesa",
      top_payment_percentage: 52
    })
    |> assign(:hourly_data, [
      %{hour: 8, amount: 12500.00, percentage: 20},
      %{hour: 9, amount: 18750.00, percentage: 30},
      %{hour: 10, amount: 28125.00, percentage: 45},
      %{hour: 11, amount: 22500.00, percentage: 36},
      %{hour: 12, amount: 37500.00, percentage: 60},
      %{hour: 13, amount: 31250.00, percentage: 50},
      %{hour: 14, amount: 18750.00, percentage: 30},
      %{hour: 15, amount: 25000.00, percentage: 40},
      %{hour: 16, amount: 15625.00, percentage: 25},
      %{hour: 17, amount: 21875.00, percentage: 35}
    ])
    |> assign(:payment_methods, [
      %{method: "mpesa", amount: 82082.00, percentage: 52, count: 22},
      %{method: "card", amount: 47355.00, percentage: 30, count: 13},
      %{method: "cash", amount: 28413.00, percentage: 18, count: 8}
    ])
    |> assign(:top_products, [
      %{name: "Premium Coffee", quantity: 42, total_amount: 12600.00, percentage: 100},
      %{name: "Chicken Sandwich", quantity: 37, total_amount: 11100.00, percentage: 88},
      %{name: "Fresh Juice", quantity: 31, total_amount: 7750.00, percentage: 62},
      %{name: "Breakfast Combo", quantity: 28, total_amount: 16800.00, percentage: 70},
      %{name: "Chocolate Cake", quantity: 25, total_amount: 9375.00, percentage: 60}
    ])
  end

  defp assign_sample_sales(socket) do
    # Generate 50 random sales
    all_sales =
      Enum.map(1..50, fn i ->
        # Random time in the last 12 hours
        random_seconds = :rand.uniform(12 * 60 * 60)
        inserted_at = DateTime.add(DateTime.utc_now(), -random_seconds, :second)

        # Random payment method
        payment_method = Enum.random(["cash", "card", "mpesa"])

        # Random number of items between 1 and 8
        items_count = :rand.uniform(8)

        # Random price between 100 and 5000
        total_amount = (:rand.uniform(49) + 1) * 100

        # Customer (20% chance of being a walk-in customer)
        customer =
          if :rand.uniform(100) <= 80,
            do: %{
              name:
                Enum.random([
                  "John Doe",
                  "Jane Smith",
                  "David Mwangi",
                  "Mary Wanjiku",
                  "Peter Kamau"
                ]),
              phone: "07#{:rand.uniform(99_999_999)}"
            },
            else: nil

        %{
          id: i,
          receipt_number: "S#{10000 + i}",
          inserted_at: inserted_at,
          customer: customer,
          items: Enum.map(1..items_count, fn _ -> %{} end),
          payment_method: payment_method,
          total_amount: total_amount
        }
      end)

    # Sort by most recent first
    sorted_sales = Enum.sort_by(all_sales, & &1.inserted_at, {:desc, DateTime})

    socket
    |> assign(:all_sales, all_sales)
    |> assign(:sales, Enum.take(sorted_sales, socket.assigns.per_page))
    |> assign(:total_count, length(all_sales))
    |> assign(:total_pages, ceil(length(all_sales) / socket.assigns.per_page))
  end

  defp filter_sales_by_query(sales, query) do
    if query == "" do
      sales
    else
      query = String.downcase(query)

      Enum.filter(sales, fn sale ->
        receipt_match = String.contains?(String.downcase(sale.receipt_number), query)

        customer_match =
          if sale.customer do
            String.contains?(String.downcase(sale.customer.name), query) ||
              String.contains?(String.downcase(sale.customer.phone), query)
          else
            false
          end

        receipt_match || customer_match
      end)
    end
  end

  defp filter_sales_by_payment(sales, method) do
    if method == "all" do
      sales
    else
      Enum.filter(sales, fn sale -> sale.payment_method == method end)
    end
  end

  defp sort_sales(sales, field, direction) do
    case field do
      "receipt_number" ->
        Enum.sort_by(sales, & &1.receipt_number, sort_direction_to_atom(direction))

      "created_at" ->
        Enum.sort_by(sales, & &1.inserted_at, sort_direction_to_atom(direction))

      "customer" ->
        Enum.sort_by(
          sales,
          fn sale ->
            if sale.customer, do: String.downcase(sale.customer.name), else: "zzz"
          end,
          sort_direction_to_atom(direction)
        )

      "payment_method" ->
        Enum.sort_by(sales, & &1.payment_method, sort_direction_to_atom(direction))

      "total_amount" ->
        Enum.sort_by(sales, & &1.total_amount, sort_direction_to_atom(direction))

      _ ->
        sales
    end
  end

  defp sort_direction_to_atom("asc"), do: :asc
  defp sort_direction_to_atom("desc"), do: :desc

  defp sample_user do
    %{
      id: 1,
      email: "admin@example.com",
      name: "Sample Admin",
      role: "admin",
      organization_id: 1
    }
  end

  defp sample_organization do
    %{
      id: 1,
      name: "Sample Organization",
      logo: "/images/logo.png"
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-gray-100">
      <Sidebar.render
        active_page={@active_page}
        current_user={@current_user}
        current_organization={@current_organization}
      />

      <div class="flex-1 flex flex-col ml-64 overflow-hidden">
        <header class="bg-white shadow">
          <div class="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8 flex justify-between items-center">
            <h1 class="text-2xl font-bold text-gray-900">Sales History</h1>

            <div class="flex items-center space-x-2">
              <button
                phx-click="export_csv"
                class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
              >
                <.icon name="document-arrow-down" class="h-4 w-4 mr-2" /> Export CSV
              </button>
            </div>
          </div>
        </header>

        <div class="flex-1 overflow-auto p-4">
          <!-- Analytics Dashboard -->
          <div class="bg-white rounded-lg shadow mb-6">
            <div class="p-4 border-b">
              <h2 class="text-lg font-medium">Today's Sales Analytics</h2>
            </div>

            <div class="p-4 grid grid-cols-1 md:grid-cols-4 gap-4">
              <!-- Total Sales Card -->
              <div class="bg-blue-50 p-4 rounded-lg">
                <div class="text-blue-500 text-sm font-medium mb-1">Total Sales</div>
                <div class="text-2xl font-bold">{format_currency(@today_analytics.total_amount)}</div>
                <div class="text-sm text-gray-500 mt-1">
                  {@today_analytics.total_sales} transactions
                </div>
              </div>
              
    <!-- Average Sale Card -->
              <div class="bg-green-50 p-4 rounded-lg">
                <div class="text-green-500 text-sm font-medium mb-1">Average Sale</div>
                <div class="text-2xl font-bold">{format_currency(@today_analytics.average_sale)}</div>
                <div class="text-sm text-gray-500 mt-1">per transaction</div>
              </div>
              
    <!-- Items Sold Card -->
              <div class="bg-purple-50 p-4 rounded-lg">
                <div class="text-purple-500 text-sm font-medium mb-1">Items Sold</div>
                <div class="text-2xl font-bold">{@today_analytics.items_sold}</div>
                <div class="text-sm text-gray-500 mt-1">
                  {@today_analytics.unique_products} unique products
                </div>
              </div>
              
    <!-- Top Payment Method Card -->
              <div class="bg-amber-50 p-4 rounded-lg">
                <div class="text-amber-500 text-sm font-medium mb-1">Top Payment Method</div>
                <div class="text-2xl font-bold capitalize">{@today_analytics.top_payment_method}</div>
                <div class="text-sm text-gray-500 mt-1">
                  {@today_analytics.top_payment_percentage}% of sales
                </div>
              </div>
            </div>

            <div class="p-4 grid grid-cols-1 md:grid-cols-2 gap-6">
              <!-- Hourly Sales Chart -->
              <div class="bg-gray-50 p-4 rounded-lg">
                <h3 class="text-sm font-medium text-gray-700 mb-3">Hourly Sales</h3>
                <div class="h-64">
                  <div class="flex h-full items-end">
                    <%= for hour_data <- @hourly_data do %>
                      <div class="flex-1 mx-1">
                        <div
                          class="bg-blue-500 hover:bg-blue-600 rounded-t"
                          style={"height: #{hour_data.percentage}%"}
                          title={"#{hour_data.hour}:00 - #{format_currency(hour_data.amount)}"}
                        >
                        </div>
                        <div class="text-xs text-center mt-1">{hour_data.hour}h</div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
              
    <!-- Top Products -->
              <div class="bg-gray-50 p-4 rounded-lg">
                <h3 class="text-sm font-medium text-gray-700 mb-3">Top Selling Products</h3>
                <div class="space-y-3">
                  <%= for {product, index} <- Enum.with_index(@top_products) do %>
                    <div class="flex items-center">
                      <div class="w-6 h-6 flex items-center justify-center rounded-full bg-blue-500 text-white text-xs font-medium">
                        {index + 1}
                      </div>
                      <div class="ml-3 flex-1">
                        <div class="text-sm font-medium">{product.name}</div>
                        <div class="flex justify-between text-xs text-gray-500">
                          <span>{product.quantity} sold</span>
                          <span>{format_currency(product.total_amount)}</span>
                        </div>
                        <div class="w-full h-1.5 bg-gray-200 rounded-full mt-1">
                          <div
                            class="bg-blue-500 h-1.5 rounded-full"
                            style={"width: #{product.percentage}%"}
                          >
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Search and Filters -->
          <div class="bg-white rounded-lg shadow mb-4 p-4">
            <div class="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
              <div class="md:w-1/3">
                <form phx-submit="search" class="relative">
                  <input
                    type="text"
                    name="query"
                    placeholder="Search by receipt #, customer name..."
                    value={@search_query}
                    class="w-full pl-10 pr-4 py-2 border rounded-md shadow-sm"
                  />
                  <div class="absolute left-3 top-2.5 text-gray-400">
                    <.icon name="magnifying-glass" class="h-5 w-5" />
                  </div>
                </form>
              </div>

              <div class="flex items-center space-x-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Payment Method</label>
                  <select
                    phx-change="filter_by_payment"
                    name="payment_method"
                    class="border rounded-md shadow-sm py-2 px-3"
                  >
                    <option value="all" selected={@filter_payment_method == "all"}>
                      All Methods
                    </option>
                    <option value="cash" selected={@filter_payment_method == "cash"}>Cash</option>
                    <option value="card" selected={@filter_payment_method == "card"}>Card</option>
                    <option value="mpesa" selected={@filter_payment_method == "mpesa"}>M-Pesa</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Date</label>
                  <div class="inline-flex items-center justify-center px-3 py-2 border rounded-md shadow-sm bg-gray-50">
                    <.icon name="calendar" class="h-5 w-5 text-gray-400 mr-2" />
                    <span>Today</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Sales Table -->
          <div class="bg-white rounded-lg shadow">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      <button
                        phx-click="sort"
                        phx-value-field="receipt_number"
                        class="flex items-center"
                      >
                        Receipt #
                        <%= if @sort_field == "receipt_number" do %>
                          <.icon
                            name={if @sort_direction == "asc", do: "chevron-up", else: "chevron-down"}
                            class="h-4 w-4 ml-1"
                          />
                        <% end %>
                      </button>
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      <button phx-click="sort" phx-value-field="created_at" class="flex items-center">
                        Time
                        <%= if @sort_field == "created_at" do %>
                          <.icon
                            name={if @sort_direction == "asc", do: "chevron-up", else: "chevron-down"}
                            class="h-4 w-4 ml-1"
                          />
                        <% end %>
                      </button>
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      <button phx-click="sort" phx-value-field="customer" class="flex items-center">
                        Customer
                        <%= if @sort_field == "customer" do %>
                          <.icon
                            name={if @sort_direction == "asc", do: "chevron-up", else: "chevron-down"}
                            class="h-4 w-4 ml-1"
                          />
                        <% end %>
                      </button>
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Items
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      <button
                        phx-click="sort"
                        phx-value-field="payment_method"
                        class="flex items-center"
                      >
                        Payment
                        <%= if @sort_field == "payment_method" do %>
                          <.icon
                            name={if @sort_direction == "asc", do: "chevron-up", else: "chevron-down"}
                            class="h-4 w-4 ml-1"
                          />
                        <% end %>
                      </button>
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      <button
                        phx-click="sort"
                        phx-value-field="total_amount"
                        class="flex items-center"
                      >
                        Amount
                        <%= if @sort_field == "total_amount" do %>
                          <.icon
                            name={if @sort_direction == "asc", do: "chevron-up", else: "chevron-down"}
                            class="h-4 w-4 ml-1"
                          />
                        <% end %>
                      </button>
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= if Enum.empty?(@sales) do %>
                    <tr>
                      <td colspan="7" class="px-6 py-8 text-center text-gray-500">
                        No sales found for the selected criteria.
                      </td>
                    </tr>
                  <% else %>
                    <%= for sale <- @sales do %>
                      <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          #{sale.receipt_number}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {format_time(sale.inserted_at)}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <%= if sale.customer do %>
                            <div class="font-medium">{sale.customer.name}</div>
                            <div class="text-xs text-gray-400">{sale.customer.phone}</div>
                          <% else %>
                            <span class="text-gray-400">Walk-in customer</span>
                          <% end %>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            {length(sale.items)} items
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{payment_method_color(sale.payment_method)}"}>
                            {String.capitalize(sale.payment_method)}
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {format_currency(sale.total_amount)}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <a href={"/sales/#{sale.id}"} class="text-indigo-600 hover:text-indigo-900">
                            View
                          </a>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
            
    <!-- Pagination -->
            <%= if @total_pages > 1 do %>
              <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
                <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing <span class="font-medium">{(@page - 1) * @per_page + 1}</span>
                      to <span class="font-medium">{min(@page * @per_page, @total_count)}</span>
                      of <span class="font-medium">{@total_count}</span>
                      results
                    </p>
                  </div>
                  <div>
                    <nav
                      class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                      aria-label="Pagination"
                    >
                      <button
                        phx-click="change_page"
                        phx-value-page={max(@page - 1, 1)}
                        disabled={@page == 1}
                        class={"relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium #{if @page == 1, do: "text-gray-300", else: "text-gray-500 hover:bg-gray-50"}"}
                      >
                        <span class="sr-only">Previous</span>
                        <.icon name="chevron-left" class="h-5 w-5" />
                      </button>

                      <%= for page_num <- max(1, @page - 2)..min(@total_pages, @page + 2) do %>
                        <button
                          phx-click="change_page"
                          phx-value-page={page_num}
                          class={"relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium #{if @page == page_num, do: "bg-blue-50 text-blue-600 border-blue-500", else: "bg-white text-gray-700 hover:bg-gray-50"}"}
                        >
                          {page_num}
                        </button>
                      <% end %>

                      <button
                        phx-click="change_page"
                        phx-value-page={min(@page + 1, @total_pages)}
                        disabled={@page == @total_pages}
                        class={"relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium #{if @page == @total_pages, do: "text-gray-300", else: "text-gray-500 hover:bg-gray-50"}"}
                      >
                        <span class="sr-only">Next</span>
                        <.icon name="chevron-right" class="h-5 w-5" />
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_currency(amount) do
    "KSh #{:erlang.float_to_binary(amount / 1, decimals: 2)}"
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M")
  end

  defp payment_method_color(method) do
    case method do
      "cash" -> "bg-green-100 text-green-800"
      "card" -> "bg-purple-100 text-purple-800"
      "mpesa" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp icon(assigns) do
    ~H"""
    <Heroicons.icon name={@name} class={@class} />
    """
  end
end

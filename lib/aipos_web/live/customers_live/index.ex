defmodule AiposWeb.CustomersLive.Index do
  use AiposWeb, :live_view

  alias AiposWeb.Sidebar

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:page_title, "Customers")
      |> assign(:active_page, "customers")
      |> assign(:current_user, sample_user())
      |> assign(:current_organization, sample_organization())
      |> assign(:search_query, "")
      |> assign(:filter, "all")
      |> assign(:selected_customer, nil)
      |> assign(:show_customer_form, false)
      |> assign(:show_customer_details, false)
      |> assign(:loading, false)
      |> assign(:customers, generate_sample_customers())
      |> assign(:loyalty_tiers, sample_loyalty_tiers())
      |> assign(:changeset, %{})

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_customers =
      socket.assigns.customers
      |> Enum.filter(fn customer ->
        name_match = String.contains?(String.downcase(customer.name), String.downcase(query))
        phone_match = String.contains?(customer.phone, query)

        email_match =
          String.contains?(String.downcase(customer.email || ""), String.downcase(query))

        name_match || phone_match || email_match
      end)

    {:noreply, assign(socket, :customers, filtered_customers)}
  end

  @impl true
  def handle_event("filter_customers", %{"filter" => filter}, socket) do
    all_customers = generate_sample_customers()

    filtered_customers =
      case filter do
        "all" -> all_customers
        "loyal" -> Enum.filter(all_customers, fn c -> c.loyalty_points > 1000 end)
        "recent" -> Enum.filter(all_customers, fn c -> Enum.count(c.recent_purchases) > 0 end)
        "inactive" -> Enum.filter(all_customers, fn c -> c.days_since_last_purchase > 30 end)
        _ -> all_customers
      end

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:customers, filtered_customers)}
  end

  @impl true
  def handle_event("show_customer_form", _, socket) do
    {:noreply, assign(socket, :show_customer_form, true)}
  end

  @impl true
  def handle_event("cancel_customer_form", _, socket) do
    {:noreply, assign(socket, :show_customer_form, false)}
  end

  @impl true
  def handle_event("save_customer", %{"customer" => customer_params}, socket) do
    # Simulate customer creation
    new_customer = %{
      id: :rand.uniform(1000) + 100,
      name: customer_params["name"],
      phone: customer_params["phone"],
      email: customer_params["email"],
      address: customer_params["address"],
      loyalty_points: 0,
      membership_level: "Bronze",
      total_spent: 0,
      total_orders: 0,
      recent_purchases: [],
      days_since_last_purchase: 0
    }

    updated_customers = [new_customer | socket.assigns.customers]

    {:noreply,
     socket
     |> assign(:customers, updated_customers)
     |> assign(:show_customer_form, false)
     |> put_flash(:info, "Customer created successfully!")}
  end

  @impl true
  def handle_event("show_customer_details", %{"id" => id}, socket) do
    id = String.to_integer(id)
    customer = Enum.find(socket.assigns.customers, fn c -> c.id == id end)

    # Generate some random purchase history
    purchase_history = generate_purchase_history()
    loyalty_history = generate_loyalty_history(customer)

    {:noreply,
     socket
     |> assign(:selected_customer, customer)
     |> assign(:purchase_history, purchase_history)
     |> assign(:loyalty_history, loyalty_history)
     |> assign(:show_customer_details, true)}
  end

  @impl true
  def handle_event("close_customer_details", _, socket) do
    {:noreply,
     socket
     |> assign(:show_customer_details, false)
     |> assign(:selected_customer, nil)}
  end

  @impl true
  def handle_event("add_loyalty_points", %{"points" => points_str}, socket) do
    {points, _} = Integer.parse(points_str)
    customer = socket.assigns.selected_customer

    updated_customer = Map.update!(customer, :loyalty_points, fn current -> current + points end)

    # Calculate new membership level based on updated points
    updated_customer =
      Map.put(
        updated_customer,
        :membership_level,
        calculate_membership_level(updated_customer.loyalty_points)
      )

    # Update the customer in the list
    updated_customers =
      Enum.map(socket.assigns.customers, fn c ->
        if c.id == customer.id, do: updated_customer, else: c
      end)

    # Add to loyalty history
    now = DateTime.utc_now()

    new_entry = %{
      id: :rand.uniform(1000),
      date: now,
      points: points,
      reason: "Manual adjustment",
      type: "credit"
    }

    updated_history = [new_entry | socket.assigns.loyalty_history]

    {:noreply,
     socket
     |> assign(:selected_customer, updated_customer)
     |> assign(:customers, updated_customers)
     |> assign(:loyalty_history, updated_history)
     |> put_flash(:info, "Added #{points} loyalty points to #{customer.name}'s account")}
  end

  # Helper functions to generate sample data

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
      name: "Smart Store",
      logo: "/images/logo.png"
    }
  end

  defp generate_sample_customers do
    Enum.map(1..25, fn i ->
      loyalty_points = :rand.uniform(3000)
      total_spent = :rand.uniform(50000) + 1000
      total_orders = :rand.uniform(40) + 1
      days_since_last_purchase = :rand.uniform(60)

      recent_purchases =
        if days_since_last_purchase < 30 do
          Enum.map(1..:rand.uniform(5), fn _ ->
            %{
              id: :rand.uniform(1000),
              date: Date.add(Date.utc_today(), -:rand.uniform(30)),
              amount: :rand.uniform(2000) + 100
            }
          end)
        else
          []
        end

      # First names
      first_names = [
        "John",
        "Mary",
        "James",
        "Patricia",
        "Robert",
        "Jennifer",
        "Michael",
        "Linda",
        "William",
        "Elizabeth",
        "David",
        "Susan",
        "Richard",
        "Jessica",
        "Joseph",
        "Sarah",
        "Thomas",
        "Karen",
        "Charles",
        "Nancy",
        "Daniel",
        "Lisa",
        "Matthew",
        "Betty",
        "Anthony",
        "Margaret",
        "Mark",
        "Sandra",
        "Donald",
        "Ashley",
        "Steven",
        "Kimberly",
        "Paul",
        "Emily",
        "Andrew",
        "Donna",
        "Joshua",
        "Michelle",
        "Kenneth",
        "Carol"
      ]

      # Last names
      last_names = [
        "Smith",
        "Johnson",
        "Williams",
        "Brown",
        "Jones",
        "Miller",
        "Davis",
        "Garcia",
        "Rodriguez",
        "Wilson",
        "Martinez",
        "Anderson",
        "Taylor",
        "Thomas",
        "Hernandez",
        "Moore",
        "Martin",
        "Jackson",
        "Thompson",
        "White",
        "Lopez",
        "Lee",
        "Gonzalez",
        "Harris",
        "Clark",
        "Lewis",
        "Robinson",
        "Walker",
        "Perez",
        "Hall",
        "Young",
        "Allen",
        "Sanchez",
        "Wright",
        "King",
        "Scott",
        "Green",
        "Baker",
        "Adams",
        "Nelson"
      ]

      # Random name generation
      name = "#{Enum.random(first_names)} #{Enum.random(last_names)}"

      %{
        id: i,
        name: name,
        phone: "07#{Enum.random(10..99)}#{Enum.random(100..999)}#{Enum.random(100..999)}",
        email: "#{String.downcase(String.replace(name, " ", "."))}@example.com",
        address: "#{:rand.uniform(999)} Main St, Nairobi",
        loyalty_points: loyalty_points,
        membership_level: calculate_membership_level(loyalty_points),
        total_spent: total_spent,
        total_orders: total_orders,
        recent_purchases: recent_purchases,
        days_since_last_purchase: days_since_last_purchase
      }
    end)
  end

  defp calculate_membership_level(points) do
    cond do
      points >= 2000 -> "Platinum"
      points >= 1000 -> "Gold"
      points >= 500 -> "Silver"
      true -> "Bronze"
    end
  end

  defp sample_loyalty_tiers do
    [
      %{name: "Bronze", min_points: 0, benefits: "Basic loyalty program benefits"},
      %{
        name: "Silver",
        min_points: 500,
        benefits: "5% discount on all purchases + Bronze benefits"
      },
      %{
        name: "Gold",
        min_points: 1000,
        benefits: "10% discount on all purchases + free delivery + Silver benefits"
      },
      %{
        name: "Platinum",
        min_points: 2000,
        benefits: "15% discount on all purchases + priority service + Gold benefits"
      }
    ]
  end

  defp generate_purchase_history do
    Enum.map(1..15, fn i ->
      items =
        Enum.map(1..(:rand.uniform(5) + 1), fn _ ->
          product_names = [
            "Premium Coffee",
            "Chicken Sandwich",
            "Fresh Juice",
            "Breakfast Combo",
            "Chocolate Cake",
            "Vegetable Salad",
            "Cheese Burger",
            "Pizza Slice",
            "Ice Cream",
            "Fruit Platter",
            "Bottled Water",
            "Soda"
          ]

          %{
            name: Enum.random(product_names),
            quantity: :rand.uniform(3),
            price: (:rand.uniform(20) + 5) * 50
          }
        end)

      total = Enum.reduce(items, 0, fn item, acc -> acc + item.quantity * item.price end)

      %{
        id: i,
        receipt_number: "S#{10000 + i}",
        date: Date.add(Date.utc_today(), -:rand.uniform(90)),
        items: items,
        total: total,
        payment_method: Enum.random(["Cash", "Card", "M-Pesa"])
      }
    end)
    |> Enum.sort_by(fn p -> p.date end, {:desc, Date})
  end

  defp generate_loyalty_history(customer) do
    # Create some loyalty point history
    num_entries = :rand.uniform(10) + 5

    Enum.map(1..num_entries, fn i ->
      days_ago = :rand.uniform(180)
      date = DateTime.add(DateTime.utc_now(), -days_ago * 24 * 3600, :second)

      # About 80% should be credits from purchases, 20% redemptions
      is_credit = :rand.uniform(100) <= 80
      points = if is_credit, do: :rand.uniform(300) + 50, else: -(:rand.uniform(200) + 100)

      reason =
        if is_credit do
          "Purchase: Receipt #S#{10000 + :rand.uniform(999)}"
        else
          redemption_reasons = [
            "Discount coupon",
            "Free product",
            "Special offer",
            "Birthday reward"
          ]

          "Redemption: #{Enum.random(redemption_reasons)}"
        end

      %{
        id: i,
        date: date,
        points: points,
        reason: reason,
        type: if(is_credit, do: "credit", else: "debit")
      }
    end)
    |> Enum.sort_by(fn h -> h.date end, {:desc, DateTime})
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

      <div class="flex-1 ml-64 flex flex-col overflow-hidden">
        <header class="bg-white shadow">
          <div class="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8 flex justify-between items-center">
            <h1 class="text-2xl font-bold text-gray-900">Customers</h1>

            <div>
              <button
                phx-click="show_customer_form"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
              >
                <Heroicons.icon name="plus" class="h-5 w-5 mr-2" /> Add Customer
              </button>
            </div>
          </div>
        </header>

        <div class="flex-1 overflow-hidden">
          <!-- Main Content -->
          <div class="p-6 h-full overflow-auto">
            <!-- Search and filters -->
            <div class="bg-white shadow rounded-lg mb-6">
              <div class="p-4">
                <div class="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
                  <div class="md:w-1/2">
                    <form phx-submit="search" class="relative">
                      <input
                        type="text"
                        name="query"
                        placeholder="Search by name, phone, or email..."
                        value={@search_query}
                        class="w-full pl-10 pr-4 py-2 border rounded-md shadow-sm"
                      />
                      <div class="absolute left-3 top-2.5 text-gray-400">
                        <Heroicons.icon name="magnifying-glass" class="h-5 w-5" />
                      </div>
                    </form>
                  </div>

                  <div class="flex items-center space-x-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">Filter</label>
                      <select
                        phx-change="filter_customers"
                        name="filter"
                        class="border rounded-md shadow-sm py-2 px-3"
                      >
                        <option value="all" selected={@filter == "all"}>All Customers</option>
                        <option value="loyal" selected={@filter == "loyal"}>Loyal Members</option>
                        <option value="recent" selected={@filter == "recent"}>
                          Recent Customers
                        </option>
                        <option value="inactive" selected={@filter == "inactive"}>
                          Inactive (30+ days)
                        </option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Customer List -->
            <div class="bg-white shadow rounded-lg overflow-hidden">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Customer
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Loyalty
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Purchases
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Last Purchase
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
                  <%= if Enum.empty?(@customers) do %>
                    <tr>
                      <td colspan="5" class="px-6 py-4 text-center text-gray-500">
                        No customers found with the current filters.
                      </td>
                    </tr>
                  <% else %>
                    <%= for customer <- @customers do %>
                      <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="flex items-center">
                            <div class="h-10 w-10 flex-shrink-0 rounded-full bg-blue-100 flex items-center justify-center">
                              <span class="text-blue-800 font-medium text-lg">
                                {String.first(customer.name)}
                              </span>
                            </div>
                            <div class="ml-4">
                              <div class="text-sm font-medium text-gray-900">
                                {customer.name}
                              </div>
                              <div class="text-sm text-gray-500">
                                {customer.phone}
                              </div>
                              <%= if customer.email do %>
                                <div class="text-xs text-gray-400">
                                  {customer.email}
                                </div>
                              <% end %>
                            </div>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="flex flex-col">
                            <div class={"text-sm px-2 py-0.5 rounded-full text-white w-fit #{membership_level_color(customer.membership_level)}"}>
                              {customer.membership_level}
                            </div>
                            <div class="text-sm text-gray-700 mt-1">
                              {customer.loyalty_points} points
                            </div>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-900">
                            {format_currency(customer.total_spent)}
                          </div>
                          <div class="text-sm text-gray-500">
                            {customer.total_orders} orders
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <%= if customer.days_since_last_purchase <= 30 do %>
                            <span class="text-sm text-green-600 font-medium">
                              {customer.days_since_last_purchase} days ago
                            </span>
                          <% else %>
                            <span class={"text-sm #{if customer.days_since_last_purchase > 60, do: "text-red-600", else: "text-yellow-600"} font-medium"}>
                              {customer.days_since_last_purchase} days ago
                            </span>
                          <% end %>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <button
                            phx-click="show_customer_details"
                            phx-value-id={customer.id}
                            class="text-indigo-600 hover:text-indigo-900"
                          >
                            View
                          </button>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Customer Form Modal -->
      <%= if @show_customer_form do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
            <div class="p-4 border-b border-gray-200">
              <h3 class="text-lg font-medium">Add New Customer</h3>
            </div>

            <form phx-submit="save_customer">
              <div class="p-4 space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Name</label>
                  <input
                    type="text"
                    name="customer[name]"
                    required
                    class="mt-1 block w-full border rounded-md shadow-sm py-2 px-3"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700">Phone</label>
                  <input
                    type="text"
                    name="customer[phone]"
                    required
                    class="mt-1 block w-full border rounded-md shadow-sm py-2 px-3"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700">Email</label>
                  <input
                    type="email"
                    name="customer[email]"
                    class="mt-1 block w-full border rounded-md shadow-sm py-2 px-3"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700">Address</label>
                  <textarea
                    name="customer[address]"
                    rows="2"
                    class="mt-1 block w-full border rounded-md shadow-sm py-2 px-3"
                  ></textarea>
                </div>
              </div>

              <div class="p-4 border-t border-gray-200 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="cancel_customer_form"
                  class="px-4 py-2 border rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                >
                  Save Customer
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
    <!-- Customer Details Slide Over -->
      <%= if @show_customer_details && @selected_customer do %>
        <div class="fixed inset-0 overflow-hidden z-50">
          <div class="absolute inset-0 overflow-hidden">
            <div class="absolute inset-0 bg-gray-500 bg-opacity-75" phx-click="close_customer_details">
            </div>

            <div class="fixed inset-y-0 right-0 max-w-2xl w-full flex">
              <div class="relative w-full bg-white shadow-xl flex flex-col overflow-y-auto">
                <div class="flex-1 overflow-y-auto">
                  <!-- Header -->
                  <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                    <h2 class="text-xl font-medium text-gray-900">Customer Details</h2>
                    <button
                      phx-click="close_customer_details"
                      class="text-gray-400 hover:text-gray-500"
                    >
                      <Heroicons.icon name="x-mark" class="h-6 w-6" />
                    </button>
                  </div>
                  
    <!-- Profile -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <div class="flex items-center">
                      <div class="h-20 w-20 rounded-full bg-blue-100 flex items-center justify-center">
                        <span class="text-blue-800 font-bold text-2xl">
                          {String.first(@selected_customer.name)}
                        </span>
                      </div>
                      <div class="ml-4">
                        <h3 class="text-xl font-medium">{@selected_customer.name}</h3>
                        <div class="mt-1 text-sm text-gray-500">
                          <div class="flex items-center">
                            <Heroicons.icon name="phone" class="h-4 w-4 mr-1 text-gray-400" />
                            <span>{@selected_customer.phone}</span>
                          </div>
                          <%= if @selected_customer.email do %>
                            <div class="flex items-center mt-1">
                              <Heroicons.icon name="envelope" class="h-4 w-4 mr-1 text-gray-400" />
                              <span>{@selected_customer.email}</span>
                            </div>
                          <% end %>
                          <%= if @selected_customer.address do %>
                            <div class="flex items-center mt-1">
                              <Heroicons.icon name="map-pin" class="h-4 w-4 mr-1 text-gray-400" />
                              <span>{@selected_customer.address}</span>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                  
    <!-- Stats -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <h3 class="text-lg font-medium mb-3">Overview</h3>
                    <div class="grid grid-cols-2 gap-4">
                      <div class="bg-gray-50 p-3 rounded-lg">
                        <div class="text-xs text-gray-500">Total Spent</div>
                        <div class="text-xl font-bold">
                          {format_currency(@selected_customer.total_spent)}
                        </div>
                      </div>
                      <div class="bg-gray-50 p-3 rounded-lg">
                        <div class="text-xs text-gray-500">Total Orders</div>
                        <div class="text-xl font-bold">{@selected_customer.total_orders}</div>
                      </div>
                    </div>
                  </div>
                  
    <!-- Loyalty -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="text-lg font-medium">Loyalty Program</h3>

                      <form phx-submit="add_loyalty_points" class="flex items-center">
                        <input
                          type="number"
                          name="points"
                          min="1"
                          placeholder="Points"
                          class="w-20 border rounded-l-md shadow-sm py-1 px-2 text-sm"
                        />
                        <button
                          type="submit"
                          class="inline-flex items-center px-3 py-1 border border-l-0 border-transparent rounded-r-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                        >
                          Add
                        </button>
                      </form>
                    </div>

                    <div class="bg-gray-50 p-4 rounded-lg mb-4">
                      <div class="flex items-center justify-between mb-2">
                        <div>
                          <span class={"px-2 py-0.5 rounded-full text-white text-xs font-medium #{membership_level_color(@selected_customer.membership_level)}"}>
                            {@selected_customer.membership_level}
                          </span>
                          <span class="ml-2 text-sm font-medium">
                            {@selected_customer.loyalty_points} points
                          </span>
                        </div>

                        {next_tier =
                          next_membership_tier(@selected_customer.loyalty_points, @loyalty_tiers)}
                        <%= if next_tier do %>
                          <div class="text-xs text-gray-500">
                            {next_tier.min_points - @selected_customer.loyalty_points} points to {next_tier.name}
                          </div>
                        <% end %>
                      </div>
                      
    <!-- Progress bar -->
                      <div class="w-full bg-gray-200 rounded-full h-2.5">
                        {current_tier =
                          current_membership_tier(@selected_customer.loyalty_points, @loyalty_tiers)}
                        {next_tier =
                          next_membership_tier(@selected_customer.loyalty_points, @loyalty_tiers)}

                        <%= if next_tier do %>
                          <div
                            class="bg-blue-600 h-2.5 rounded-full"
                            style={"width: #{calculate_progress_percentage(@selected_customer.loyalty_points, current_tier.min_points, next_tier.min_points)}%"}
                          >
                          </div>
                        <% else %>
                          <div class="bg-blue-600 h-2.5 rounded-full w-full"></div>
                        <% end %>
                      </div>
                    </div>
                    
    <!-- Loyalty Tiers Info -->
                    <div class="mb-4">
                      <h4 class="text-sm font-medium mb-2">Membership Tiers & Benefits</h4>
                      <div class="space-y-2">
                        <%= for tier <- @loyalty_tiers do %>
                          <div class={"p-2 rounded-md border-l-4 #{tier_border_color(tier.name)} #{if tier.name == @selected_customer.membership_level, do: "bg-blue-50", else: "bg-white"}"}>
                            <div class="flex justify-between">
                              <span class="font-medium">{tier.name}</span>
                              <span class="text-sm text-gray-500">{tier.min_points}+ points</span>
                            </div>
                            <p class="text-xs text-gray-600 mt-1">{tier.benefits}</p>
                          </div>
                        <% end %>
                      </div>
                    </div>

                    <div>
                      <div>
                        <h4 class="text-sm font-medium mb-2">Points History</h4>
                        <div class="max-h-40 overflow-y-auto border rounded-md">
                          <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                              <tr>
                                <th class="px-3 py-2 text-left text-xs font-medium text-gray-500">
                                  Date
                                </th>
                                <th class="px-3 py-2 text-left text-xs font-medium text-gray-500">
                                  Points
                                </th>
                                <th class="px-3 py-2 text-left text-xs font-medium text-gray-500">
                                  Details
                                </th>
                              </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                              <%= if @loyalty_history && length(@loyalty_history) > 0 do %>
                                <%= for entry <- @loyalty_history do %>
                                  <tr>
                                    <td class="px-3 py-2 whitespace-nowrap text-xs">
                                      {Calendar.strftime(entry.date, "%b %d, %Y")}
                                    </td>
                                    <td class="px-3 py-2 whitespace-nowrap text-xs">
                                      <span class={"font-medium #{if entry.type == "credit", do: "text-green-600", else: "text-red-600"}"}>
                                        {if entry.type == "credit", do: "+", else: "-"}{abs(
                                          entry.points
                                        )}
                                      </span>
                                    </td>
                                    <td class="px-3 py-2 whitespace-nowrap text-xs text-gray-500">
                                      {entry.reason}
                                    </td>
                                  </tr>
                                <% end %>
                              <% else %>
                                <tr>
                                  <td colspan="3" class="px-3 py-2 text-center text-xs text-gray-500">
                                    No loyalty history available
                                  </td>
                                </tr>
                              <% end %>
                            </tbody>
                          </table>
                        </div>
                      </div>
                    </div>
                  </div>
                  
    <!-- Purchase History -->
                  <div class="px-6 py-4">
                    <h3 class="text-lg font-medium mb-3">Purchase History</h3>

                    <%= if @purchase_history && length(@purchase_history) > 0 do %>
                      <div class="space-y-4">
                        <%= for purchase <- @purchase_history do %>
                          <div class="border rounded-md overflow-hidden">
                            <div class="bg-gray-50 px-4 py-2 flex justify-between items-center">
                              <div>
                                <span class="font-medium">Receipt #{purchase.receipt_number}</span>
                                <span class="ml-2 text-sm text-gray-500">
                                  {Calendar.strftime(purchase.date, "%b %d, %Y")}
                                </span>
                              </div>
                              <div>
                                <span class="font-medium">{format_currency(purchase.total)}</span>
                                <span class="ml-2 px-2 py-0.5 rounded-full bg-gray-200 text-xs">
                                  {purchase.payment_method}
                                </span>
                              </div>
                            </div>

                            <div class="px-4 py-2">
                              <table class="min-w-full">
                                <thead>
                                  <tr class="text-xs text-gray-500 border-b">
                                    <th class="text-left py-1">Item</th>
                                    <th class="text-right py-1">Qty</th>
                                    <th class="text-right py-1">Price</th>
                                    <th class="text-right py-1">Total</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  <%= for item <- purchase.items do %>
                                    <tr class="text-sm">
                                      <td class="py-1">{item.name}</td>
                                      <td class="py-1 text-right">{item.quantity}</td>
                                      <td class="py-1 text-right">{format_currency(item.price)}</td>
                                      <td class="py-1 text-right font-medium">
                                        {format_currency(item.price * item.quantity)}
                                      </td>
                                    </tr>
                                  <% end %>
                                </tbody>
                              </table>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% else %>
                      <div class="text-center py-8 text-gray-500">
                        <p>No purchase history available for this customer.</p>
                      </div>
                    <% end %>
                  </div>
                </div>
                
    <!-- Footer actions -->
                <div class="border-t border-gray-200 p-4">
                  <div class="flex space-x-3">
                    <button class="flex-1 px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50">
                      <Heroicons.icon name="envelope" class="h-5 w-5 mr-2 inline" /> Send Message
                    </button>
                    <button class="flex-1 px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700">
                      <Heroicons.icon name="pencil-square" class="h-5 w-5 mr-2 inline" />
                      Edit Customer
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions for UI display

  defp format_currency(amount) do
    "KSh #{:erlang.float_to_binary(amount / 1, decimals: 2)}"
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

  defp tier_border_color(level) do
    case level do
      "Bronze" -> "border-amber-300"
      "Silver" -> "border-gray-300"
      "Gold" -> "border-yellow-300"
      "Platinum" -> "border-blue-300"
      _ -> "border-gray-300"
    end
  end

  defp current_membership_tier(points, tiers) do
    Enum.reduce(tiers, List.first(tiers), fn tier, acc ->
      if points >= tier.min_points && tier.min_points >= acc.min_points, do: tier, else: acc
    end)
  end

  defp next_membership_tier(points, tiers) do
    sorted_tiers = Enum.sort_by(tiers, & &1.min_points)

    Enum.find(sorted_tiers, fn tier -> tier.min_points > points end)
  end

  defp calculate_progress_percentage(points, current_min, next_min) do
    range = next_min - current_min
    progress = points - current_min

    percentage = progress / range * 100
    min(max(percentage, 0), 100)
  end
end

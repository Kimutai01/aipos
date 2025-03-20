defmodule AiposWeb.SuppliersLive.Index do
  use AiposWeb, :live_view

  alias AiposWeb.Sidebar

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:page_title, "Suppliers")
      |> assign(:active_page, "suppliers")
      |> assign(:current_user, sample_user())
      |> assign(:current_organization, sample_organization())
      |> assign(:search_query, "")
      |> assign(:filter, "all")
      |> assign(:sort_by, "name")
      |> assign(:sort_direction, "asc")
      |> assign(:suppliers, generate_sample_suppliers())
      |> assign(:show_supplier_form, false)
      |> assign(:selected_supplier, nil)
      |> assign(:show_supplier_details, false)
      |> assign(:form_mode, "create")
      |> assign(:changeset, %{})
      |> assign(:products_by_supplier, %{})
      |> assign(:orders_by_supplier, %{})
      |> assign(:supplier_stats, calculate_supplier_stats())
      |> assign(:supplier_tags, ["Beverages", "Food", "Equipment", "Packaging", "Ingredients"])

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_suppliers =
      socket.assigns.suppliers
      |> Enum.filter(fn supplier ->
        name_match = String.contains?(String.downcase(supplier.name), String.downcase(query))

        contact_match =
          String.contains?(String.downcase(supplier.contact_name || ""), String.downcase(query))

        phone_match = String.contains?(supplier.phone || "", query)

        email_match =
          String.contains?(String.downcase(supplier.email || ""), String.downcase(query))

        name_match || contact_match || phone_match || email_match
      end)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:suppliers, filtered_suppliers)}
  end

  @impl true
  def handle_event("filter_suppliers", %{"filter" => filter}, socket) do
    all_suppliers = generate_sample_suppliers()

    filtered_suppliers =
      case filter do
        "all" -> all_suppliers
        "active" -> Enum.filter(all_suppliers, fn s -> s.status == "active" end)
        "inactive" -> Enum.filter(all_suppliers, fn s -> s.status == "inactive" end)
        tag -> Enum.filter(all_suppliers, fn s -> tag in s.tags end)
      end

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:suppliers, filtered_suppliers)}
  end

  @impl true
  def handle_event("sort_suppliers", %{"sort_by" => sort_by}, socket) do
    sort_direction =
      if socket.assigns.sort_by == sort_by do
        if socket.assigns.sort_direction == "asc", do: "desc", else: "asc"
      else
        "asc"
      end

    sorted_suppliers = sort_suppliers(socket.assigns.suppliers, sort_by, sort_direction)

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:sort_direction, sort_direction)
     |> assign(:suppliers, sorted_suppliers)}
  end

  @impl true
  def handle_event("new_supplier", _, socket) do
    {:noreply,
     socket
     |> assign(:show_supplier_form, true)
     |> assign(:form_mode, "create")
     |> assign(:changeset, %{})}
  end

  @impl true
  def handle_event("edit_supplier", %{"id" => id}, socket) do
    id = String.to_integer(id)
    supplier = Enum.find(socket.assigns.suppliers, fn s -> s.id == id end)

    {:noreply,
     socket
     |> assign(:selected_supplier, supplier)
     |> assign(:show_supplier_form, true)
     |> assign(:form_mode, "edit")}
  end

  @impl true
  def handle_event("cancel_supplier_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_supplier_form, false)
     |> assign(:selected_supplier, nil)}
  end

  @impl true
  def handle_event("save_supplier", %{"supplier" => supplier_params}, socket) do
    if socket.assigns.form_mode == "create" do
      # Simulate supplier creation
      new_supplier = %{
        id: :rand.uniform(1000) + 100,
        name: supplier_params["name"],
        contact_name: supplier_params["contact_name"],
        phone: supplier_params["phone"],
        email: supplier_params["email"],
        address: supplier_params["address"],
        tags: String.split(supplier_params["tags"] || "", ",") |> Enum.map(&String.trim/1),
        status: "active",
        payment_terms: supplier_params["payment_terms"],
        lead_time: String.to_integer(supplier_params["lead_time"] || "3"),
        last_order_date: Date.add(Date.utc_today(), -:rand.uniform(30)),
        notes: supplier_params["notes"],
        created_at: Date.utc_today()
      }

      updated_suppliers = [new_supplier | socket.assigns.suppliers]

      {:noreply,
       socket
       |> assign(:suppliers, updated_suppliers)
       |> assign(:show_supplier_form, false)
       |> put_flash(:info, "Supplier created successfully!")}
    else
      # Simulate supplier update
      updated_suppliers =
        Enum.map(socket.assigns.suppliers, fn s ->
          if s.id == socket.assigns.selected_supplier.id do
            %{
              s
              | name: supplier_params["name"],
                contact_name: supplier_params["contact_name"],
                phone: supplier_params["phone"],
                email: supplier_params["email"],
                address: supplier_params["address"],
                tags:
                  String.split(supplier_params["tags"] || "", ",") |> Enum.map(&String.trim/1),
                payment_terms: supplier_params["payment_terms"],
                lead_time: String.to_integer(supplier_params["lead_time"] || "3"),
                notes: supplier_params["notes"]
            }
          else
            s
          end
        end)

      {:noreply,
       socket
       |> assign(:suppliers, updated_suppliers)
       |> assign(:show_supplier_form, false)
       |> assign(:selected_supplier, nil)
       |> put_flash(:info, "Supplier updated successfully!")}
    end
  end

  @impl true
  def handle_event("view_supplier", %{"id" => id}, socket) do
    id = String.to_integer(id)
    supplier = Enum.find(socket.assigns.suppliers, fn s -> s.id == id end)

    # Generate products and orders for this supplier
    products = generate_supplier_products(supplier)
    orders = generate_supplier_orders(supplier)

    {:noreply,
     socket
     |> assign(:selected_supplier, supplier)
     |> assign(:show_supplier_details, true)
     |> assign(:products_by_supplier, products)
     |> assign(:orders_by_supplier, orders)}
  end

  @impl true
  def handle_event("close_supplier_details", _, socket) do
    {:noreply,
     socket
     |> assign(:show_supplier_details, false)
     |> assign(:selected_supplier, nil)}
  end

  @impl true
  def handle_event("toggle_supplier_status", %{"id" => id}, socket) do
    id = String.to_integer(id)

    updated_suppliers =
      Enum.map(socket.assigns.suppliers, fn s ->
        if s.id == id do
          new_status = if s.status == "active", do: "inactive", else: "active"
          %{s | status: new_status}
        else
          s
        end
      end)

    {:noreply,
     socket
     |> assign(:suppliers, updated_suppliers)
     |> put_flash(:info, "Supplier status updated successfully!")}
  end

  # Helper functions

  defp sort_suppliers(suppliers, sort_by, sort_direction) do
    Enum.sort_by(
      suppliers,
      fn supplier ->
        case sort_by do
          "name" -> supplier.name
          "lead_time" -> supplier.lead_time
          "last_order" -> supplier.last_order_date
          _ -> supplier.name
        end
      end,
      sort_direction_comparator(sort_direction)
    )
  end

  defp sort_direction_comparator("asc"), do: :asc
  defp sort_direction_comparator("desc"), do: :desc

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

  defp generate_sample_suppliers do
    supplier_names = [
      {"Fresh Harvest Supplies", ["Food", "Ingredients"]},
      {"Premium Coffee Distributors", ["Beverages"]},
      {"Quality Packaging Co.", ["Packaging"]},
      {"Global Food Imports", ["Food", "Ingredients"]},
      {"Swift Delivery Services", ["Food", "Beverages"]},
      {"Mountain Spring Water", ["Beverages"]},
      {"Kitchen Equipment Ltd.", ["Equipment"]},
      {"Organic Farms Direct", ["Food", "Ingredients"]},
      {"Eco Packaging Solutions", ["Packaging"]},
      {"Artisan Bakery Suppliers", ["Food", "Ingredients"]},
      {"Elite Dairy Products", ["Food", "Ingredients"]},
      {"Restaurant Essentials Co.", ["Equipment", "Packaging"]},
      {"Coffee Bean Wholesalers", ["Beverages", "Ingredients"]},
      {"Industrial Kitchen Supply", ["Equipment"]},
      {"Gourmet Ingredients Inc.", ["Food", "Ingredients"]},
      {"National Beverage Distributors", ["Beverages"]},
      {"Southern Fresh Produce", ["Food", "Ingredients"]},
      {"Best Value Packaging", ["Packaging"]},
      {"Hospitality Equipment Co.", ["Equipment"]},
      {"Exotic Spice Traders", ["Ingredients"]}
    ]

    payment_terms_options = [
      "Net 30",
      "Net 15",
      "Net 45",
      "Cash on Delivery",
      "15 days EOM",
      "30 days EOM",
      "2/10 Net 30",
      "Advance Payment"
    ]

    today = Date.utc_today()

    Enum.map(Enum.with_index(supplier_names), fn {{name, tags}, index} ->
      id = index + 1

      %{
        id: id,
        name: name,
        contact_name: random_contact_name(),
        phone: random_phone(),
        email: String.downcase(String.replace(name, " ", ".")) <> "@example.com",
        address: random_address(),
        tags: tags,
        status: Enum.random(["active", "active", "active", "inactive"]),
        payment_terms: Enum.random(payment_terms_options),
        lead_time: Enum.random(1..14),
        last_order_date: Date.add(today, -Enum.random(1..90)),
        notes:
          Enum.random([
            "Reliable supplier with quality products",
            "Occasional delays in delivery",
            "Bulk discounts available for large orders",
            "Requires minimum order quantity",
            "Good quality but premium prices",
            "Eco-friendly packaging options available",
            "Flexible payment terms for regular customers",
            "Limited stock during peak seasons",
            "",
            ""
          ]),
        created_at: Date.add(today, -Enum.random(30..365))
      }
    end)
  end

  defp random_contact_name do
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
      "Sarah"
    ]

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
      "Hernandez"
    ]

    "#{Enum.random(first_names)} #{Enum.random(last_names)}"
  end

  defp random_phone do
    "+254 7#{Enum.random(10..99)} #{Enum.random(100..999)} #{Enum.random(100..999)}"
  end

  defp random_address do
    streets = [
      "Main Street",
      "High Street",
      "Park Avenue",
      "Oak Lane",
      "Cedar Road",
      "Maple Drive",
      "Pine Street",
      "Elm Avenue",
      "River Road",
      "Lake Drive"
    ]

    cities = [
      "Nairobi",
      "Mombasa",
      "Kisumu",
      "Nakuru",
      "Eldoret",
      "Thika",
      "Kitale",
      "Malindi",
      "Machakos",
      "Naivasha"
    ]

    "#{Enum.random(100..999)} #{Enum.random(streets)}, #{Enum.random(cities)}"
  end

  defp generate_supplier_products(supplier) do
    product_count = Enum.random(3..10)

    Enum.map(1..product_count, fn i ->
      # Generate product names based on supplier tags
      product_name =
        case Enum.find(supplier.tags, fn tag -> tag in ["Food", "Beverages", "Ingredients"] end) do
          "Food" ->
            Enum.random([
              "Premium Rice",
              "Whole Wheat Flour",
              "Cooking Oil",
              "Sugar",
              "Salt",
              "Frozen Chicken",
              "Beef Cuts",
              "Seafood Mix",
              "Pasta",
              "Instant Noodles"
            ])

          "Beverages" ->
            Enum.random([
              "Coffee Beans",
              "Tea Bags",
              "Fruit Juices",
              "Soda Concentrate",
              "Milk",
              "Drinking Water",
              "Energy Drinks",
              "Syrups",
              "Wine",
              "Beer"
            ])

          "Ingredients" ->
            Enum.random([
              "Spices Mix",
              "Baking Powder",
              "Vanilla Extract",
              "Tomato Paste",
              "Cooking Cream",
              "Food Coloring",
              "Flavor Enhancers",
              "Herbs Mix",
              "Salad Dressing",
              "Marinades"
            ])

          "Packaging" ->
            Enum.random([
              "Paper Bags",
              "Food Containers",
              "Coffee Cups",
              "Plastic Wraps",
              "Aluminum Foil",
              "Take-away Boxes",
              "Straws",
              "Napkins",
              "Branded Bags",
              "Biodegradable Containers"
            ])

          "Equipment" ->
            Enum.random([
              "Coffee Makers",
              "Blenders",
              "Kitchen Knives",
              "Cooking Pots",
              "Serving Trays",
              "Storage Containers",
              "Utensils",
              "Cleaning Supplies",
              "Refrigeration Parts",
              "Food Processors"
            ])

          _ ->
            Enum.random([
              "General Items",
              "Supplies",
              "Consumables",
              "Store Items",
              "Shop Products"
            ])
        end

      %{
        id: supplier.id * 100 + i,
        sku: "#{String.upcase(String.slice(supplier.name, 0, 3))}-#{1000 + i}",
        name: "#{product_name} (#{supplier.name})",
        unit: Enum.random(["kg", "liter", "pack", "box", "piece", "carton"]),
        price: Enum.random(10..1000) / 10 * 10,
        min_order_qty: Enum.random([1, 5, 10, 20, 50]),
        last_order: Date.add(Date.utc_today(), -Enum.random(1..60)),
        in_stock: Enum.random([true, true, true, false])
      }
    end)
  end

  defp generate_supplier_orders(supplier) do
    order_count = Enum.random(5..15)

    Enum.map(1..order_count, fn i ->
      order_date = Date.add(Date.utc_today(), -Enum.random(i..365))
      delivery_date = Date.add(order_date, Enum.random(1..(supplier.lead_time + 2)))

      items_count = Enum.random(1..5)
      total_amount = Enum.random(5..30) * 1000

      status =
        cond do
          Date.compare(delivery_date, Date.utc_today()) == :gt -> "pending"
          Enum.random(1..10) == 1 -> "delayed"
          Enum.random(1..20) == 1 -> "issue"
          true -> "delivered"
        end

      %{
        id: supplier.id * 1000 + i,
        order_number: "PO-#{2023 + div(i, 12)}-#{1000 + i}",
        date: order_date,
        delivery_date: delivery_date,
        status: status,
        items_count: items_count,
        total_amount: total_amount,
        payment_status: if(Enum.random(1..10) <= 8, do: "paid", else: "pending")
      }
    end)
    |> Enum.sort_by(fn order -> order.date end, {:desc, Date})
  end

  defp calculate_supplier_stats do
    %{
      total_suppliers: 20,
      active_suppliers: 16,
      inactive_suppliers: 4,
      total_spend_month: 2_345_000,
      total_spend_year: 28_750_000,
      pending_orders: 12,
      average_lead_time: 5
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

      <div class="flex-1 flex ml-64 flex-col overflow-hidden">
        <header class="bg-white shadow">
          <div class="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8 flex justify-between items-center">
            <h1 class="text-2xl font-bold text-gray-900">Suppliers</h1>

            <div>
              <button
                phx-click="new_supplier"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
              >
                <Heroicons.icon name="plus" class="h-5 w-5 mr-2" /> Add Supplier
              </button>
            </div>
          </div>
        </header>

        <div class="flex-1 overflow-hidden">
          <!-- Main Content -->
          <div class="p-6 h-full overflow-auto">
            <!-- Stats Cards -->
            <div class="bg-white shadow rounded-lg mb-6">
              <div class="p-6">
                <h2 class="text-lg font-medium mb-4">Supplier Overview</h2>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
                  <div class="bg-blue-50 p-4 rounded-lg">
                    <div class="text-blue-500 text-sm font-medium mb-1">Total Suppliers</div>
                    <div class="text-2xl font-bold">{@supplier_stats.total_suppliers}</div>
                    <div class="text-sm text-gray-500 mt-1">
                      <span class="text-green-600">{@supplier_stats.active_suppliers}</span>
                      active, <span class="text-red-600">{@supplier_stats.inactive_suppliers}</span>
                      inactive
                    </div>
                  </div>

                  <div class="bg-green-50 p-4 rounded-lg">
                    <div class="text-green-500 text-sm font-medium mb-1">Monthly Spend</div>
                    <div class="text-2xl font-bold">
                      {format_currency(@supplier_stats.total_spend_month)}
                    </div>
                    <div class="text-sm text-gray-500 mt-1">
                      {format_currency(@supplier_stats.total_spend_year)} annually
                    </div>
                  </div>

                  <div class="bg-amber-50 p-4 rounded-lg">
                    <div class="text-amber-500 text-sm font-medium mb-1">Pending Orders</div>
                    <div class="text-2xl font-bold">{@supplier_stats.pending_orders}</div>
                    <div class="text-sm text-gray-500 mt-1">awaiting delivery</div>
                  </div>

                  <div class="bg-purple-50 p-4 rounded-lg">
                    <div class="text-purple-500 text-sm font-medium mb-1">Avg. Lead Time</div>
                    <div class="text-2xl font-bold">{@supplier_stats.average_lead_time} days</div>
                    <div class="text-sm text-gray-500 mt-1">from order to delivery</div>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Search and filters -->
            <div class="bg-white shadow rounded-lg mb-6">
              <div class="p-4">
                <div class="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
                  <div class="md:w-1/2">
                    <form phx-submit="search" class="relative">
                      <input
                        type="text"
                        name="query"
                        placeholder="Search by name, contact, or email..."
                        value={@search_query}
                        class="w-full pl-10 pr-4 py-2 border rounded-md shadow-sm"
                      />
                      <div class="absolute left-3 top-2.5 text-gray-400">
                        <Heroicons.icon name="magnifying-glass" class="h-5 w-5" />
                      </div>
                    </form>
                  </div>

                  <div class="flex flex-wrap items-center space-x-2">
                    <span class="text-sm font-medium text-gray-700">Filter:</span>
                    <button
                      phx-click="filter_suppliers"
                      phx-value-filter="all"
                      class={"px-3 py-1 rounded-md text-sm #{if @filter == "all", do: "bg-blue-100 text-blue-800 font-medium", else: "bg-gray-100 text-gray-800 hover:bg-gray-200"}"}
                    >
                      All
                    </button>
                    <button
                      phx-click="filter_suppliers"
                      phx-value-filter="active"
                      class={"px-3 py-1 rounded-md text-sm #{if @filter == "active", do: "bg-green-100 text-green-800 font-medium", else: "bg-gray-100 text-gray-800 hover:bg-gray-200"}"}
                    >
                      Active
                    </button>
                    <button
                      phx-click="filter_suppliers"
                      phx-value-filter="inactive"
                      class={"px-3 py-1 rounded-md text-sm #{if @filter == "inactive", do: "bg-red-100 text-red-800 font-medium", else: "bg-gray-100 text-gray-800 hover:bg-gray-200"}"}
                    >
                      Inactive
                    </button>

                    <%= for tag <- @supplier_tags do %>
                      <button
                        phx-click="filter_suppliers"
                        phx-value-filter={tag}
                        class={"px-3 py-1 rounded-md text-sm #{if @filter == tag, do: "bg-purple-100 text-purple-800 font-medium", else: "bg-gray-100 text-gray-800 hover:bg-gray-200"}"}
                      >
                        {tag}
                      </button>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Suppliers List -->
            <div class="bg-white shadow rounded-lg overflow-hidden">
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        <button
                          phx-click="sort_suppliers"
                          phx-value-sort_by="name"
                          class="flex items-center"
                        >
                          Supplier
                          <%= if @sort_by == "name" do %>
                            <Heroicons.icon
                              name={
                                if @sort_direction == "asc", do: "chevron-up", else: "chevron-down"
                              }
                              class="h-4 w-4 ml-1"
                            />
                          <% end %>
                        </button>
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Contact Info
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        <button
                          phx-click="sort_suppliers"
                          phx-value-sort_by="lead_time"
                          class="flex items-center"
                        >
                          Lead Time
                          <%= if @sort_by == "lead_time" do %>
                            <Heroicons.icon
                              name={
                                if @sort_direction == "asc", do: "chevron-up", else: "chevron-down"
                              }
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
                          phx-click="sort_suppliers"
                          phx-value-sort_by="last_order"
                          class="flex items-center"
                        >
                          Last Order
                          <%= if @sort_by == "last_order" do %>
                            <Heroicons.icon
                              name={
                                if @sort_direction == "asc", do: "chevron-up", else: "chevron-down"
                              }
                              class="h-4 w-4 ml-1"
                            />
                          <% end %>
                        </button>
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Status
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
                    <%= if Enum.empty?(@suppliers) do %>
                      <tr>
                        <td colspan="6" class="px-6 py-4 text-center text-gray-500">
                          No suppliers found with the current filters.
                        </td>
                      </tr>
                    <% else %>
                      <%= for supplier <- @suppliers do %>
                        <tr class="hover:bg-gray-50">
                          <td class="px-6 py-4">
                            <div class="flex items-center">
                              <div class="h-10 w-10 flex-shrink-0 rounded-full bg-blue-100 flex items-center justify-center">
                                <span class="text-blue-800 font-medium text-lg">
                                  {String.first(supplier.name)}
                                </span>
                              </div>
                              <div class="ml-4">
                                <div class="text-sm font-medium text-gray-900">
                                  {supplier.name}
                                </div>
                                <div class="flex flex-wrap mt-1">
                                  <%= for tag <- supplier.tags do %>
                                    <span class="mr-1 mb-1 text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-800">
                                      {tag}
                                    </span>
                                  <% end %>
                                </div>
                              </div>
                            </div>
                          </td>
                          <td class="px-6 py-4">
                            <div class="text-sm text-gray-900">{supplier.contact_name}</div>
                            <div class="text-sm text-gray-500">{supplier.phone}</div>
                            <div class="text-sm text-gray-500">{supplier.email}</div>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap">
                            <div class="text-sm text-gray-900">{supplier.lead_time} days</div>
                            <div class="text-sm text-gray-500">{supplier.payment_terms}</div>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap">
                            <div class="text-sm text-gray-900">
                              {format_date(supplier.last_order_date)}
                            </div>
                            <div class="text-sm text-gray-500">
                              {days_ago(supplier.last_order_date)} days ago
                            </div>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap">
                            <span class={"px-2 py-1 inline-flex text-xs leading-5 font-medium rounded-full #{status_color(supplier.status)}"}>
                              {String.capitalize(supplier.status)}
                            </span>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                            <div class="flex justify-end space-x-2">
                              <button
                                phx-click="view_supplier"
                                phx-value-id={supplier.id}
                                class="text-indigo-600 hover:text-indigo-900"
                              >
                                View
                              </button>
                              <button
                                phx-click="edit_supplier"
                                phx-value-id={supplier.id}
                                class="text-blue-600 hover:text-blue-900"
                              >
                                Edit
                              </button>
                              <button
                                phx-click="toggle_supplier_status"
                                phx-value-id={supplier.id}
                                class={
                                  if supplier.status == "active",
                                    do: "text-red-600 hover:text-red-900",
                                    else: "text-green-600 hover:text-green-900"
                                }
                              >
                                {if supplier.status == "active", do: "Deactivate", else: "Activate"}
                              </button>
                            </div>
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
      </div>
      
    <!-- Supplier Form Modal -->
      <%= if @show_supplier_form do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-screen overflow-y-auto">
            <div class="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="text-lg font-medium">
                {if @form_mode == "create", do: "Add New Supplier", else: "Edit Supplier"}
              </h3>
              <button phx-click="cancel_supplier_form" class="text-gray-400 hover:text-gray-500">
                <Heroicons.icon name="x-mark" class="h-6 w-6" />
              </button>
            </div>

            <form phx-submit="save_supplier">
              <div class="p-6 space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Supplier Name</label>
                    <input
                      type="text"
                      name="supplier[name]"
                      required
                      value={if @selected_supplier, do: @selected_supplier.name, else: ""}
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Contact Name</label>
                    <input
                      type="text"
                      name="supplier[contact_name]"
                      value={if @selected_supplier, do: @selected_supplier.contact_name, else: ""}
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                    <input
                      type="text"
                      name="supplier[phone]"
                      value={if @selected_supplier, do: @selected_supplier.phone, else: ""}
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                    <input
                      type="email"
                      name="supplier[email]"
                      value={if @selected_supplier, do: @selected_supplier.email, else: ""}
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Address</label>
                  <textarea
                    name="supplier[address]"
                    rows="2"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  ><%= if @selected_supplier, do: @selected_supplier.address, else: "" %></textarea>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Tags (comma-separated)
                    </label>
                    <input
                      type="text"
                      name="supplier[tags]"
                      value={
                        if @selected_supplier, do: Enum.join(@selected_supplier.tags, ", "), else: ""
                      }
                      placeholder="e.g. Food, Beverages, Packaging"
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Lead Time (days)
                    </label>
                    <input
                      type="number"
                      name="supplier[lead_time]"
                      min="1"
                      value={if @selected_supplier, do: @selected_supplier.lead_time, else: "3"}
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Payment Terms</label>
                  <select
                    name="supplier[payment_terms]"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  >
                    <option
                      value="Net 30"
                      selected={@selected_supplier && @selected_supplier.payment_terms == "Net 30"}
                    >
                      Net 30
                    </option>
                    <option
                      value="Net 15"
                      selected={@selected_supplier && @selected_supplier.payment_terms == "Net 15"}
                    >
                      Net 15
                    </option>
                    <option
                      value="Net 45"
                      selected={@selected_supplier && @selected_supplier.payment_terms == "Net 45"}
                    >
                      Net 45
                    </option>
                    <option
                      value="Cash on Delivery"
                      selected={
                        @selected_supplier && @selected_supplier.payment_terms == "Cash on Delivery"
                      }
                    >
                      Cash on Delivery
                    </option>
                    <option
                      value="15 days EOM"
                      selected={
                        @selected_supplier && @selected_supplier.payment_terms == "15 days EOM"
                      }
                    >
                      15 days End of Month
                    </option>
                    <option
                      value="30 days EOM"
                      selected={
                        @selected_supplier && @selected_supplier.payment_terms == "30 days EOM"
                      }
                    >
                      30 days End of Month
                    </option>
                    <option
                      value="2/10 Net 30"
                      selected={
                        @selected_supplier && @selected_supplier.payment_terms == "2/10 Net 30"
                      }
                    >
                      2% discount if paid within 10 days, otherwise Net 30
                    </option>
                    <option
                      value="Advance Payment"
                      selected={
                        @selected_supplier && @selected_supplier.payment_terms == "Advance Payment"
                      }
                    >
                      Advance Payment
                    </option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
                  <textarea
                    name="supplier[notes]"
                    rows="3"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  ><%= if @selected_supplier, do: @selected_supplier.notes, else: "" %></textarea>
                </div>
              </div>

              <div class="p-4 border-t border-gray-200 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="cancel_supplier_form"
                  class="px-4 py-2 border rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                >
                  {if @form_mode == "create", do: "Add Supplier", else: "Update Supplier"}
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
    <!-- Supplier Details Slide Over -->
      <%= if @show_supplier_details && @selected_supplier do %>
        <div class="fixed inset-0 overflow-hidden z-50">
          <div class="absolute inset-0 overflow-hidden">
            <div class="absolute inset-0 bg-gray-500 bg-opacity-75" phx-click="close_supplier_details">
            </div>

            <div class="fixed inset-y-0 right-0 max-w-2xl w-full flex">
              <div class="relative w-full bg-white shadow-xl flex flex-col overflow-y-auto">
                <div class="flex-1 overflow-y-auto">
                  <!-- Header -->
                  <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                    <h2 class="text-xl font-medium text-gray-900">Supplier Details</h2>
                    <button
                      phx-click="close_supplier_details"
                      class="text-gray-400 hover:text-gray-500"
                    >
                      <Heroicons.icon name="x-mark" class="h-6 w-6" />
                    </button>
                  </div>
                  
    <!-- Overview -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <div class="flex items-center">
                      <div class="h-16 w-16 flex-shrink-0 rounded-full bg-blue-100 flex items-center justify-center">
                        <span class="text-blue-800 font-bold text-2xl">
                          {String.first(@selected_supplier.name)}
                        </span>
                      </div>
                      <div class="ml-4">
                        <div class="flex items-center">
                          <h3 class="text-xl font-medium">{@selected_supplier.name}</h3>
                          <span class={"ml-2 px-2 py-0.5 rounded-full text-xs font-medium #{status_color(@selected_supplier.status)}"}>
                            {String.capitalize(@selected_supplier.status)}
                          </span>
                        </div>

                        <div class="mt-1 text-sm text-gray-500">
                          <div class="flex items-center">
                            <Heroicons.icon name="user" class="h-4 w-4 mr-1 text-gray-400" />
                            <span>{@selected_supplier.contact_name}</span>
                          </div>

                          <div class="flex items-center mt-1">
                            <Heroicons.icon name="phone" class="h-4 w-4 mr-1 text-gray-400" />
                            <span>{@selected_supplier.phone}</span>
                          </div>

                          <div class="flex items-center mt-1">
                            <Heroicons.icon name="envelope" class="h-4 w-4 mr-1 text-gray-400" />
                            <span>{@selected_supplier.email}</span>
                          </div>
                        </div>

                        <div class="mt-2 flex flex-wrap gap-1">
                          <%= for tag <- @selected_supplier.tags do %>
                            <span class="text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-800">
                              {tag}
                            </span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                  
    <!-- Details -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <h4 class="text-sm font-medium text-gray-700 mb-3">Supplier Information</h4>

                    <div class="bg-gray-50 rounded-lg p-4">
                      <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-4 gap-y-3 text-sm">
                        <div>
                          <dt class="text-xs text-gray-500">Address</dt>
                          <dd class="font-medium">{@selected_supplier.address}</dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">Payment Terms</dt>
                          <dd class="font-medium">{@selected_supplier.payment_terms}</dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">Lead Time</dt>
                          <dd class="font-medium">{@selected_supplier.lead_time} days</dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">Last Order</dt>
                          <dd class="font-medium">
                            {format_date(@selected_supplier.last_order_date)} ({days_ago(
                              @selected_supplier.last_order_date
                            )} days ago)
                          </dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">Supplier Since</dt>
                          <dd class="font-medium">
                            {format_date(@selected_supplier.created_at)} ({days_ago(
                              @selected_supplier.created_at
                            )} days)
                          </dd>
                        </div>
                      </dl>

                      <%= if @selected_supplier.notes && @selected_supplier.notes != "" do %>
                        <div class="mt-4 pt-4 border-t border-gray-200">
                          <h5 class="text-xs text-gray-500 mb-1">Notes</h5>
                          <p class="text-sm">{@selected_supplier.notes}</p>
                        </div>
                      <% end %>
                    </div>
                  </div>
                  
    <!-- Products -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <div class="flex justify-between items-center mb-3">
                      <h4 class="text-sm font-medium text-gray-700">Products</h4>
                      <a href="#" class="text-xs text-indigo-600 hover:text-indigo-900">View All</a>
                    </div>

                    <%= if @products_by_supplier && length(@products_by_supplier) > 0 do %>
                      <div class="border rounded-md overflow-hidden">
                        <table class="min-w-full divide-y divide-gray-200">
                          <thead class="bg-gray-50">
                            <tr>
                              <th
                                scope="col"
                                class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Product
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Unit
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Price
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Min. Order
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Status
                              </th>
                            </tr>
                          </thead>
                          <tbody class="bg-white divide-y divide-gray-200">
                            <%= for product <- @products_by_supplier do %>
                              <tr class="hover:bg-gray-50">
                                <td class="px-4 py-2 whitespace-nowrap">
                                  <div class="text-sm font-medium text-gray-900">{product.name}</div>
                                  <div class="text-xs text-gray-500">{product.sku}</div>
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-500">
                                  {product.unit}
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-sm text-right text-gray-900 font-medium">
                                  {format_currency(product.price)}
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-sm text-right text-gray-900">
                                  {product.min_order_qty}
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-center">
                                  <%= if product.in_stock do %>
                                    <span class="px-2 py-0.5 inline-flex text-xs leading-5 font-medium rounded-full bg-green-100 text-green-800">
                                      In Stock
                                    </span>
                                  <% else %>
                                    <span class="px-2 py-0.5 inline-flex text-xs leading-5 font-medium rounded-full bg-red-100 text-red-800">
                                      Out of Stock
                                    </span>
                                  <% end %>
                                </td>
                              </tr>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    <% else %>
                      <div class="text-center py-6 text-gray-500">
                        <p>No products available from this supplier.</p>
                      </div>
                    <% end %>
                  </div>
                  
    <!-- Order History -->
                  <div class="px-6 py-4">
                    <div class="flex justify-between items-center mb-3">
                      <h4 class="text-sm font-medium text-gray-700">Order History</h4>
                      <a href="#" class="text-xs text-indigo-600 hover:text-indigo-900">View All</a>
                    </div>

                    <%= if @orders_by_supplier && length(@orders_by_supplier) > 0 do %>
                      <div class="border rounded-md overflow-hidden">
                        <table class="min-w-full divide-y divide-gray-200">
                          <thead class="bg-gray-50">
                            <tr>
                              <th
                                scope="col"
                                class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Order
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Date
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Amount
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Status
                              </th>
                            </tr>
                          </thead>
                          <tbody class="bg-white divide-y divide-gray-200">
                            <%= for order <- Enum.take(@orders_by_supplier, 10) do %>
                              <tr class="hover:bg-gray-50">
                                <td class="px-4 py-2 whitespace-nowrap">
                                  <div class="text-sm font-medium text-gray-900">
                                    {order.order_number}
                                  </div>
                                  <div class="text-xs text-gray-500">{order.items_count} items</div>
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap">
                                  <div class="text-sm text-gray-900">{format_date(order.date)}</div>
                                  <div class="text-xs text-gray-500">
                                    Delivery: {format_date(order.delivery_date)}
                                  </div>
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-sm text-right">
                                  <div class="font-medium text-gray-900">
                                    {format_currency(order.total_amount)}
                                  </div>
                                  <div class="text-xs text-gray-500">
                                    <%= if order.payment_status == "paid" do %>
                                      <span class="text-green-600">Paid</span>
                                    <% else %>
                                      <span class="text-amber-600">Pending payment</span>
                                    <% end %>
                                  </div>
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-center">
                                  <span class={"px-2 py-0.5 inline-flex text-xs leading-5 font-medium rounded-full #{order_status_color(order.status)}"}>
                                    {String.capitalize(order.status)}
                                  </span>
                                </td>
                              </tr>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    <% else %>
                      <div class="text-center py-6 text-gray-500">
                        <p>No order history available for this supplier.</p>
                      </div>
                    <% end %>
                  </div>
                </div>
                
    <!-- Footer actions -->
                <div class="border-t border-gray-200 p-4">
                  <div class="flex space-x-3">
                    <button
                      phx-click="new_order"
                      phx-value-supplier_id={@selected_supplier.id}
                      class="flex-1 px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                    >
                      <Heroicons.icon name="plus" class="h-5 w-5 mr-2 inline" /> Place New Order
                    </button>

                    <button
                      phx-click="edit_supplier"
                      phx-value-id={@selected_supplier.id}
                      class="flex-1 px-4 py-2 border rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                    >
                      <Heroicons.icon name="pencil-square" class="h-5 w-5 mr-2 inline" />
                      Edit Supplier
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

  # Helper functions for formatting and display

  defp format_currency(amount) do
    "KSh #{:erlang.float_to_binary(amount / 1, decimals: 2)}"
  end

  defp format_date(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  defp days_ago(date) do
    Date.diff(Date.utc_today(), date)
  end

  defp status_color(status) do
    case status do
      "active" -> "bg-green-100 text-green-800"
      "inactive" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp order_status_color(status) do
    case status do
      "delivered" -> "bg-green-100 text-green-800"
      "pending" -> "bg-blue-100 text-blue-800"
      "delayed" -> "bg-amber-100 text-amber-800"
      "issue" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end

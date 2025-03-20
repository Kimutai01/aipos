defmodule AiposWeb.PromotionsLive.Index do
  use AiposWeb, :live_view

  alias AiposWeb.Sidebar

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:page_title, "Promotions & Discounts")
      |> assign(:active_page, "promotions")
      |> assign(:current_user, sample_user())
      |> assign(:current_organization, sample_organization())
      |> assign(:filter, "active")
      |> assign(:promotions, generate_sample_promotions())
      |> assign(:show_promotion_form, false)
      |> assign(:selected_promotion, nil)
      |> assign(:show_promotion_details, false)
      |> assign(:form_mode, "create")
      |> assign(:changeset, %{})
      |> assign(:available_products, generate_sample_products())
      |> assign(:total_redemptions, %{
        today: 8,
        this_week: 42,
        this_month: 156,
        total: 578
      })

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_promotions", %{"filter" => filter}, socket) do
    all_promotions = generate_sample_promotions()

    filtered_promotions =
      case filter do
        "active" -> Enum.filter(all_promotions, fn p -> p.status == "active" end)
        "upcoming" -> Enum.filter(all_promotions, fn p -> p.status == "scheduled" end)
        "expired" -> Enum.filter(all_promotions, fn p -> p.status == "expired" end)
        "all" -> all_promotions
        _ -> all_promotions
      end

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:promotions, filtered_promotions)}
  end

  @impl true
  def handle_event("new_promotion", _, socket) do
    {:noreply,
     socket
     |> assign(:show_promotion_form, true)
     |> assign(:form_mode, "create")
     |> assign(:changeset, %{})}
  end

  @impl true
  def handle_event("edit_promotion", %{"id" => id}, socket) do
    id = String.to_integer(id)
    promotion = Enum.find(socket.assigns.promotions, fn p -> p.id == id end)

    {:noreply,
     socket
     |> assign(:selected_promotion, promotion)
     |> assign(:show_promotion_form, true)
     |> assign(:form_mode, "edit")}
  end

  @impl true
  def handle_event("cancel_promotion_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_promotion_form, false)
     |> assign(:selected_promotion, nil)}
  end

  @impl true
  def handle_event("save_promotion", %{"promotion" => promotion_params}, socket) do
    # Simulate promotion creation
    if socket.assigns.form_mode == "create" do
      new_promotion = %{
        id: :rand.uniform(1000) + 100,
        name: promotion_params["name"],
        description: promotion_params["description"],
        discount_type: promotion_params["discount_type"],
        discount_value: String.to_float(promotion_params["discount_value"]),
        start_date: promotion_params["start_date"],
        end_date: promotion_params["end_date"],
        requirements: promotion_params["requirements"],
        status: "active",
        coupon_code: promotion_params["coupon_code"],
        redemption_limit: String.to_integer(promotion_params["redemption_limit"] || "0"),
        redemptions: 0,
        target_customer_type: promotion_params["target_customer_type"] || "all"
      }

      updated_promotions = [new_promotion | socket.assigns.promotions]

      {:noreply,
       socket
       |> assign(:promotions, updated_promotions)
       |> assign(:show_promotion_form, false)
       |> put_flash(:info, "Promotion created successfully!")}
    else
      # Simulate promotion update
      updated_promotions =
        Enum.map(socket.assigns.promotions, fn p ->
          if p.id == socket.assigns.selected_promotion.id do
            %{
              p
              | name: promotion_params["name"],
                description: promotion_params["description"],
                discount_type: promotion_params["discount_type"],
                discount_value: String.to_float(promotion_params["discount_value"]),
                start_date: promotion_params["start_date"],
                end_date: promotion_params["end_date"],
                requirements: promotion_params["requirements"],
                coupon_code: promotion_params["coupon_code"],
                redemption_limit: String.to_integer(promotion_params["redemption_limit"] || "0"),
                target_customer_type: promotion_params["target_customer_type"] || "all"
            }
          else
            p
          end
        end)

      {:noreply,
       socket
       |> assign(:promotions, updated_promotions)
       |> assign(:show_promotion_form, false)
       |> assign(:selected_promotion, nil)
       |> put_flash(:info, "Promotion updated successfully!")}
    end
  end

  @impl true
  def handle_event("view_promotion", %{"id" => id}, socket) do
    id = String.to_integer(id)
    promotion = Enum.find(socket.assigns.promotions, fn p -> p.id == id end)

    {:noreply,
     socket
     |> assign(:selected_promotion, promotion)
     |> assign(:show_promotion_details, true)
     |> assign(:promotion_redemptions, generate_sample_redemptions(promotion))}
  end

  @impl true
  def handle_event("close_promotion_details", _, socket) do
    {:noreply,
     socket
     |> assign(:show_promotion_details, false)
     |> assign(:selected_promotion, nil)}
  end

  @impl true
  def handle_event("toggle_promotion_status", %{"id" => id}, socket) do
    id = String.to_integer(id)

    updated_promotions =
      Enum.map(socket.assigns.promotions, fn p ->
        if p.id == id do
          new_status =
            case p.status do
              "active" -> "paused"
              "paused" -> "active"
              other -> other
            end

          %{p | status: new_status}
        else
          p
        end
      end)

    {:noreply,
     socket
     |> assign(:promotions, updated_promotions)
     |> put_flash(:info, "Promotion status updated successfully!")}
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

  defp generate_sample_promotions do
    today = Date.utc_today()

    [
      %{
        id: 1,
        name: "Weekend Special",
        description: "Get 15% off on all purchases during weekends",
        discount_type: "percentage",
        discount_value: 15.0,
        start_date: Date.to_string(Date.add(today, -10)),
        end_date: Date.to_string(Date.add(today, 20)),
        requirements: "None, automatically applied during weekends",
        status: "active",
        coupon_code: "",
        redemption_limit: 0,
        redemptions: 156,
        target_customer_type: "all"
      },
      %{
        id: 2,
        name: "First Purchase",
        description: "KSh 500 off on your first purchase",
        discount_type: "fixed",
        discount_value: 500.0,
        start_date: Date.to_string(Date.add(today, -90)),
        end_date: Date.to_string(Date.add(today, 90)),
        requirements: "First time customers only",
        status: "active",
        coupon_code: "WELCOME",
        redemption_limit: 1,
        redemptions: 87,
        target_customer_type: "new"
      },
      %{
        id: 3,
        name: "Loyalty Member Special",
        description: "20% off for Gold & Platinum members",
        discount_type: "percentage",
        discount_value: 20.0,
        start_date: Date.to_string(Date.add(today, -30)),
        end_date: Date.to_string(Date.add(today, 30)),
        requirements: "Must be Gold or Platinum loyalty member",
        status: "active",
        coupon_code: "",
        redemption_limit: 0,
        redemptions: 42,
        target_customer_type: "loyal"
      },
      %{
        id: 4,
        name: "Holiday Sale",
        description: "25% off on selected items",
        discount_type: "percentage",
        discount_value: 25.0,
        start_date: Date.to_string(Date.add(today, 15)),
        end_date: Date.to_string(Date.add(today, 30)),
        requirements: "Applies only to items in the Holiday collection",
        status: "scheduled",
        coupon_code: "HOLIDAY25",
        redemption_limit: 0,
        redemptions: 0,
        target_customer_type: "all"
      },
      %{
        id: 5,
        name: "Buy One Get One Free",
        description: "Buy any coffee and get a second one free",
        discount_type: "bogo",
        discount_value: 100.0,
        start_date: Date.to_string(Date.add(today, -120)),
        end_date: Date.to_string(Date.add(today, -20)),
        requirements: "Must purchase two coffees of equal or lesser value",
        status: "expired",
        coupon_code: "BOGOCOFFEE",
        redemption_limit: 0,
        redemptions: 293,
        target_customer_type: "all"
      },
      %{
        id: 6,
        name: "Reactivation Special",
        description: "30% off your next purchase if you haven't shopped in over 60 days",
        discount_type: "percentage",
        discount_value: 30.0,
        start_date: Date.to_string(Date.add(today, -45)),
        end_date: Date.to_string(Date.add(today, 45)),
        requirements: "Customer must not have made a purchase in the last 60 days",
        status: "active",
        coupon_code: "MISSEDYOU",
        redemption_limit: 1,
        redemptions: 24,
        target_customer_type: "inactive"
      },
      %{
        id: 7,
        name: "Birthday Gift",
        description: "Free dessert on your birthday",
        discount_type: "free_item",
        discount_value: 0.0,
        start_date: Date.to_string(Date.add(today, -365)),
        end_date: Date.to_string(Date.add(today, 365)),
        requirements: "Valid only on customer's birthday with valid ID",
        status: "active",
        coupon_code: "BIRTHDAY",
        redemption_limit: 1,
        redemptions: 176,
        target_customer_type: "all"
      },
      %{
        id: 8,
        name: "Flash Sale",
        description: "50% off all items for 24 hours only",
        discount_type: "percentage",
        discount_value: 50.0,
        start_date: Date.to_string(Date.add(today, 7)),
        end_date: Date.to_string(Date.add(today, 8)),
        requirements: "Limited to first 100 customers",
        status: "scheduled",
        coupon_code: "FLASH50",
        redemption_limit: 100,
        redemptions: 0,
        target_customer_type: "all"
      }
    ]
  end

  defp generate_sample_products do
    [
      %{id: 1, name: "Premium Coffee", price: 300.00},
      %{id: 2, name: "Chicken Sandwich", price: 450.00},
      %{id: 3, name: "Fresh Juice", price: 250.00},
      %{id: 4, name: "Breakfast Combo", price: 600.00},
      %{id: 5, name: "Chocolate Cake", price: 350.00},
      %{id: 6, name: "Vegetable Salad", price: 380.00},
      %{id: 7, name: "Cheese Burger", price: 500.00},
      %{id: 8, name: "Pizza Slice", price: 280.00},
      %{id: 9, name: "Ice Cream", price: 180.00},
      %{id: 10, name: "Fruit Platter", price: 320.00}
    ]
  end

  defp generate_sample_redemptions(promotion) do
    # Generate 20 random redemptions for this promotion
    Enum.map(1..20, fn i ->
      redeemed_date = Date.add(Date.utc_today(), -:rand.uniform(30))
      amount = :rand.uniform(3000) + 500

      discount_amount =
        case promotion.discount_type do
          "percentage" -> amount * (promotion.discount_value / 100)
          "fixed" -> promotion.discount_value
          _ -> promotion.discount_value
        end

      customer_names = [
        "John Doe",
        "Mary Smith",
        "James Johnson",
        "Patricia Williams",
        "Robert Jones",
        "Jennifer Brown",
        "Michael Davis",
        "Linda Miller",
        "William Wilson",
        "Elizabeth Moore"
      ]

      %{
        id: i,
        customer_name: Enum.random(customer_names),
        date: redeemed_date,
        receipt_number: "S#{10000 + i}",
        original_amount: amount,
        discount_amount: discount_amount,
        final_amount: amount - discount_amount
      }
    end)
    |> Enum.sort_by(fn r -> r.date end, {:desc, Date})
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
            <h1 class="text-2xl font-bold text-gray-900">Promotions & Discounts</h1>

            <div>
              <button
                phx-click="new_promotion"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
              >
                <Heroicons.icon name="plus" class="h-5 w-5 mr-2" /> Create Promotion
              </button>
            </div>
          </div>
        </header>

        <div class="flex-1 overflow-hidden p-6">
          <!-- Stats Section -->
          <div class="bg-white shadow rounded-lg mb-6">
            <div class="p-6">
              <h2 class="text-lg font-medium mb-4">Promotion Redemptions</h2>
              <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
                <div class="bg-blue-50 p-4 rounded-lg">
                  <div class="text-blue-500 text-sm font-medium mb-1">Today</div>
                  <div class="text-2xl font-bold">{@total_redemptions.today}</div>
                </div>
                <div class="bg-green-50 p-4 rounded-lg">
                  <div class="text-green-500 text-sm font-medium mb-1">This Week</div>
                  <div class="text-2xl font-bold">{@total_redemptions.this_week}</div>
                </div>
                <div class="bg-purple-50 p-4 rounded-lg">
                  <div class="text-purple-500 text-sm font-medium mb-1">This Month</div>
                  <div class="text-2xl font-bold">{@total_redemptions.this_month}</div>
                </div>
                <div class="bg-amber-50 p-4 rounded-lg">
                  <div class="text-amber-500 text-sm font-medium mb-1">Total</div>
                  <div class="text-2xl font-bold">{@total_redemptions.total}</div>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Filter Controls -->
          <div class="bg-white shadow rounded-lg mb-6">
            <div class="p-4">
              <div class="flex items-center space-x-4">
                <h3 class="text-sm font-medium text-gray-700">Filter:</h3>
                <div class="flex space-x-2">
                  <button
                    phx-click="filter_promotions"
                    phx-value-filter="active"
                    class={"px-3 py-1 rounded-md text-sm #{if @filter == "active", do: "bg-blue-100 text-blue-800 font-medium", else: "bg-gray-100 text-gray-800 hover:bg-gray-200"}"}
                  >
                    Active
                  </button>
                  <button
                    phx-click="filter_promotions"
                    phx-value-filter="upcoming"
                    class={"px-3 py-1 rounded-md text-sm #{if @filter == "upcoming", do: "bg-green-100 text-green-800 font-medium", else: "bg-gray-100 text-gray-800 hover:bg-gray-200"}"}
                  >
                    Upcoming
                  </button>
                  <button
                    phx-click="filter_promotions"
                    phx-value-filter="expired"
                    class={"px-3 py-1 rounded-md text-sm #{if @filter == "expired", do: "bg-red-100 text-red-800 font-medium", else: "bg-gray-100 text-gray-800 hover:bg-gray-200"}"}
                  >
                    Expired
                  </button>
                  <button
                    phx-click="filter_promotions"
                    phx-value-filter="all"
                    class={"px-3 py-1 rounded-md text-sm #{if @filter == "all", do: "bg-purple-100 text-purple-800 font-medium", else: "bg-gray-100 text-gray-800 hover:bg-gray-200"}"}
                  >
                    All
                  </button>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Promotions List -->
          <div class="bg-white shadow rounded-lg overflow-hidden">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Promotion
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Discount
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Period
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Status
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Usage
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
                  <%= if Enum.empty?(@promotions) do %>
                    <tr>
                      <td colspan="6" class="px-6 py-4 text-center text-gray-500">
                        No promotions found with the current filter.
                      </td>
                    </tr>
                  <% else %>
                    <%= for promotion <- @promotions do %>
                      <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="flex items-center">
                            <div class="flex-shrink-0 h-10 w-10 flex items-center justify-center rounded-md bg-indigo-100 text-indigo-600">
                              <Heroicons.icon
                                name={discount_type_icon(promotion.discount_type)}
                                class="h-6 w-6"
                              />
                            </div>
                            <div class="ml-4">
                              <div class="text-sm font-medium text-gray-900">
                                {promotion.name}
                              </div>
                              <div class="text-xs text-gray-500 max-w-xs truncate">
                                {promotion.description}
                              </div>
                              <%= if promotion.coupon_code && promotion.coupon_code != "" do %>
                                <div class="mt-1">
                                  <span class="px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-800">
                                    Code: {promotion.coupon_code}
                                  </span>
                                </div>
                              <% end %>
                            </div>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-900">
                            {format_discount(promotion.discount_type, promotion.discount_value)}
                          </div>
                          <div class="text-xs text-gray-500">
                            {target_customer_label(promotion.target_customer_type)}
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-900">
                            {format_date(promotion.start_date)} to
                          </div>
                          <div class="text-sm text-gray-900">
                            {format_date(promotion.end_date)}
                          </div>
                          <div class="text-xs text-gray-500 mt-1">
                            {format_date_range(promotion.start_date, promotion.end_date)}
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={"px-2 py-1 inline-flex text-xs leading-5 font-medium rounded-full #{status_color(promotion.status)}"}>
                            {String.capitalize(promotion.status)}
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-900">
                            {promotion.redemptions} redemptions
                          </div>
                          <%= if promotion.redemption_limit > 0 do %>
                            <div class="text-xs text-gray-500">
                              Limit: {promotion.redemption_limit}
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-1.5 mt-1">
                              <div
                                class="bg-blue-600 h-1.5 rounded-full"
                                style={"width: #{min(promotion.redemptions / promotion.redemption_limit * 100, 100)}%"}
                              >
                              </div>
                            </div>
                          <% end %>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <div class="flex justify-end space-x-2">
                            <button
                              phx-click="view_promotion"
                              phx-value-id={promotion.id}
                              class="text-indigo-600 hover:text-indigo-900"
                            >
                              View
                            </button>
                            <button
                              phx-click="edit_promotion"
                              phx-value-id={promotion.id}
                              class="text-blue-600 hover:text-blue-900"
                            >
                              Edit
                            </button>
                            <%= if promotion.status in ["active", "paused"] do %>
                              <button
                                phx-click="toggle_promotion_status"
                                phx-value-id={promotion.id}
                                class={
                                  if promotion.status == "active",
                                    do: "text-amber-600 hover:text-amber-900",
                                    else: "text-green-600 hover:text-green-900"
                                }
                              >
                                {if promotion.status == "active", do: "Pause", else: "Activate"}
                              </button>
                            <% end %>
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
      
    <!-- Promotion Form Modal -->
      <%= if @show_promotion_form do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-screen overflow-y-auto">
            <div class="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="text-lg font-medium">
                {if @form_mode == "create", do: "Create New Promotion", else: "Edit Promotion"}
              </h3>
              <button phx-click="cancel_promotion_form" class="text-gray-400 hover:text-gray-500">
                <Heroicons.icon name="x-mark" class="h-6 w-6" />
              </button>
            </div>

            <form phx-submit="save_promotion">
              <div class="p-6 space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Promotion Name</label>
                    <input
                      type="text"
                      name="promotion[name]"
                      required
                      value={if @selected_promotion, do: @selected_promotion.name, else: ""}
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Coupon Code</label>
                  <input
                    type="text"
                    name="promotion[coupon_code]"
                    value={if @selected_promotion, do: @selected_promotion.coupon_code, else: ""}
                    placeholder="Optional"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  />
                  <p class="mt-1 text-xs text-gray-500">Leave blank for automatic discounts</p>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  name="promotion[description]"
                  rows="2"
                  required
                  class="block w-full border rounded-md shadow-sm py-2 px-3"
                ><%= if @selected_promotion, do: @selected_promotion.description, else: "" %></textarea>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Discount Type</label>
                  <select
                    name="promotion[discount_type]"
                    required
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  >
                    <option
                      value="percentage"
                      selected={
                        @selected_promotion && @selected_promotion.discount_type == "percentage"
                      }
                    >
                      Percentage Discount
                    </option>
                    <option
                      value="fixed"
                      selected={@selected_promotion && @selected_promotion.discount_type == "fixed"}
                    >
                      Fixed Amount
                    </option>
                    <option
                      value="bogo"
                      selected={@selected_promotion && @selected_promotion.discount_type == "bogo"}
                    >
                      Buy One Get One
                    </option>
                    <option
                      value="free_item"
                      selected={
                        @selected_promotion && @selected_promotion.discount_type == "free_item"
                      }
                    >
                      Free Item
                    </option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Discount Value</label>
                  <input
                    type="number"
                    name="promotion[discount_value]"
                    min="0"
                    step="0.01"
                    required
                    value={if @selected_promotion, do: @selected_promotion.discount_value, else: ""}
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Redemption Limit</label>
                  <input
                    type="number"
                    name="promotion[redemption_limit]"
                    min="0"
                    step="1"
                    value={
                      if @selected_promotion, do: @selected_promotion.redemption_limit, else: "0"
                    }
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  />
                  <p class="mt-1 text-xs text-gray-500">0 for unlimited</p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
                    <input
                      type="date"
                      name="promotion[start_date]"
                      required
                      value={
                        if @selected_promotion,
                          do: @selected_promotion.start_date,
                          else: Date.to_string(Date.utc_today())
                      }
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">End Date</label>
                    <input
                      type="date"
                      name="promotion[end_date]"
                      required
                      value={
                        if @selected_promotion,
                          do: @selected_promotion.end_date,
                          else: Date.to_string(Date.add(Date.utc_today(), 30))
                      }
                      class="block w-full border rounded-md shadow-sm py-2 px-3"
                    />
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Target Customer Type
                  </label>
                  <select
                    name="promotion[target_customer_type]"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  >
                    <option
                      value="all"
                      selected={
                        @selected_promotion && @selected_promotion.target_customer_type == "all"
                      }
                    >
                      All Customers
                    </option>
                    <option
                      value="new"
                      selected={
                        @selected_promotion && @selected_promotion.target_customer_type == "new"
                      }
                    >
                      New Customers Only
                    </option>
                    <option
                      value="loyal"
                      selected={
                        @selected_promotion && @selected_promotion.target_customer_type == "loyal"
                      }
                    >
                      Loyalty Members Only
                    </option>
                    <option
                      value="inactive"
                      selected={
                        @selected_promotion && @selected_promotion.target_customer_type == "inactive"
                      }
                    >
                      Inactive Customers
                    </option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Requirements & Conditions
                  </label>
                  <textarea
                    name="promotion[requirements]"
                    rows="3"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  ><%= if @selected_promotion, do: @selected_promotion.requirements, else: "" %></textarea>
                  <p class="mt-1 text-xs text-gray-500">
                    Describe any specific requirements or conditions for this promotion
                  </p>
                </div>
              </div>

              <div class="p-4 border-t border-gray-200 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="cancel_promotion_form"
                  class="px-4 py-2 border rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                >
                  {if @form_mode == "create", do: "Create Promotion", else: "Update Promotion"}
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
    <!-- Promotion Details Slide Over -->
      <%= if @show_promotion_details && @selected_promotion do %>
        <div class="fixed inset-0 overflow-hidden z-50">
          <div class="absolute inset-0 overflow-hidden">
            <div
              class="absolute inset-0 bg-gray-500 bg-opacity-75"
              phx-click="close_promotion_details"
            >
            </div>

            <div class="fixed inset-y-0 right-0 max-w-2xl w-full flex">
              <div class="relative w-full bg-white shadow-xl flex flex-col overflow-y-auto">
                <div class="flex-1 overflow-y-auto">
                  <!-- Header -->
                  <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                    <h2 class="text-xl font-medium text-gray-900">Promotion Details</h2>
                    <button
                      phx-click="close_promotion_details"
                      class="text-gray-400 hover:text-gray-500"
                    >
                      <Heroicons.icon name="x-mark" class="h-6 w-6" />
                    </button>
                  </div>
                  
    <!-- Overview -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <div class="flex items-center">
                      <div class="h-16 w-16 flex-shrink-0 flex items-center justify-center rounded-md bg-indigo-100 text-indigo-600">
                        <Heroicons.icon
                          name={discount_type_icon(@selected_promotion.discount_type)}
                          class="h-8 w-8"
                        />
                      </div>
                      <div class="ml-4">
                        <h3 class="text-xl font-medium">{@selected_promotion.name}</h3>
                        <p class="text-sm text-gray-500 mt-1">{@selected_promotion.description}</p>

                        <div class="mt-2 flex flex-wrap gap-2">
                          <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_color(@selected_promotion.status)}"}>
                            {String.capitalize(@selected_promotion.status)}
                          </span>

                          <%= if @selected_promotion.coupon_code && @selected_promotion.coupon_code != "" do %>
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                              Code: {@selected_promotion.coupon_code}
                            </span>
                          <% end %>

                          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            {target_customer_label(@selected_promotion.target_customer_type)}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                  
    <!-- Details -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <h4 class="text-sm font-medium text-gray-700 mb-3">Promotion Details</h4>

                    <div class="bg-gray-50 rounded-md p-4">
                      <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-4 gap-y-3">
                        <div>
                          <dt class="text-xs text-gray-500">Discount Type</dt>
                          <dd class="text-sm font-medium">
                            {String.replace(
                              String.capitalize(@selected_promotion.discount_type),
                              "_",
                              " "
                            )}
                          </dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">Discount Value</dt>
                          <dd class="text-sm font-medium">
                            {format_discount(
                              @selected_promotion.discount_type,
                              @selected_promotion.discount_value
                            )}
                          </dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">Start Date</dt>
                          <dd class="text-sm font-medium">
                            {format_date(@selected_promotion.start_date)}
                          </dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">End Date</dt>
                          <dd class="text-sm font-medium">
                            {format_date(@selected_promotion.end_date)}
                          </dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">Duration</dt>
                          <dd class="text-sm font-medium">
                            {format_date_range(
                              @selected_promotion.start_date,
                              @selected_promotion.end_date
                            )}
                          </dd>
                        </div>

                        <div>
                          <dt class="text-xs text-gray-500">Redemptions</dt>
                          <dd class="text-sm font-medium">
                            {@selected_promotion.redemptions}
                            <%= if @selected_promotion.redemption_limit > 0 do %>
                              / {@selected_promotion.redemption_limit}
                            <% end %>
                          </dd>
                        </div>
                      </dl>

                      <%= if @selected_promotion.requirements && @selected_promotion.requirements != "" do %>
                        <div class="mt-4 pt-4 border-t border-gray-200">
                          <h5 class="text-xs text-gray-500 mb-1">Requirements & Conditions</h5>
                          <p class="text-sm">{@selected_promotion.requirements}</p>
                        </div>
                      <% end %>
                    </div>
                  </div>
                  
    <!-- Redemption History -->
                  <div class="px-6 py-4">
                    <h4 class="text-sm font-medium text-gray-700 mb-3">Recent Redemptions</h4>

                    <%= if @promotion_redemptions && length(@promotion_redemptions) > 0 do %>
                      <div class="border rounded-md overflow-hidden">
                        <table class="min-w-full divide-y divide-gray-200">
                          <thead class="bg-gray-50">
                            <tr>
                              <th
                                scope="col"
                                class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Date
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Customer
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Original
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Discount
                              </th>
                              <th
                                scope="col"
                                class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Final
                              </th>
                            </tr>
                          </thead>
                          <tbody class="bg-white divide-y divide-gray-200">
                            <%= for redemption <- @promotion_redemptions do %>
                              <tr class="hover:bg-gray-50">
                                <td class="px-4 py-2 whitespace-nowrap text-xs text-gray-500">
                                  {format_date(Date.to_string(redemption.date))}
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-xs">
                                  <span class="font-medium text-gray-900">
                                    {redemption.customer_name}
                                  </span>
                                  <span class="ml-1 text-gray-500">#{redemption.receipt_number}</span>
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-xs text-right text-gray-500">
                                  {format_currency(redemption.original_amount)}
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-xs text-right text-red-600 font-medium">
                                  -{format_currency(redemption.discount_amount)}
                                </td>
                                <td class="px-4 py-2 whitespace-nowrap text-xs text-right font-medium">
                                  {format_currency(redemption.final_amount)}
                                </td>
                              </tr>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    <% else %>
                      <div class="text-center py-8 text-gray-500">
                        <p>No redemption history available for this promotion.</p>
                      </div>
                    <% end %>
                  </div>
                </div>
                
    <!-- Footer actions -->
                <div class="border-t border-gray-200 p-4">
                  <div class="flex space-x-3">
                    <button
                      phx-click="edit_promotion"
                      phx-value-id={@selected_promotion.id}
                      class="flex-1 px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                    >
                      <Heroicons.icon name="pencil-square" class="h-5 w-5 mr-2 inline" />
                      Edit Promotion
                    </button>

                    <%= if @selected_promotion.status in ["active", "paused"] do %>
                      <button
                        phx-click="toggle_promotion_status"
                        phx-value-id={@selected_promotion.id}
                        class={"flex-1 px-4 py-2 border rounded-md shadow-sm text-sm font-medium #{if @selected_promotion.status == "active", do: "text-amber-700 border-amber-300 bg-amber-50 hover:bg-amber-100", else: "text-green-700 border-green-300 bg-green-50 hover:bg-green-100"}"}
                      >
                        <%= if @selected_promotion.status == "active" do %>
                          <Heroicons.icon name="pause" class="h-5 w-5 mr-2 inline" /> Pause Promotion
                        <% else %>
                          <Heroicons.icon name="play" class="h-5 w-5 mr-2 inline" />
                          Activate Promotion
                        <% end %>
                      </button>
                    <% end %>
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

  defp format_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Calendar.strftime(date, "%b %d, %Y")
      _ -> date_string
    end
  end

  defp format_date_range(start_date_string, end_date_string) do
    {:ok, start_date} = Date.from_iso8601(start_date_string)
    {:ok, end_date} = Date.from_iso8601(end_date_string)

    today = Date.utc_today()
    days_duration = Date.diff(end_date, start_date) + 1

    cond do
      Date.compare(end_date, today) == :lt ->
        "Expired"

      Date.compare(start_date, today) == :gt ->
        "Starts in #{Date.diff(start_date, today)} days"

      true ->
        "#{days_duration} days#{if days_duration > 30, do: " (#{div(days_duration, 30)} months)", else: ""}"
    end
  end

  defp discount_type_icon(discount_type) do
    case discount_type do
      "percentage" -> "tag"
      "fixed" -> "banknotes"
      "bogo" -> "gift"
      "free_item" -> "star"
      _ -> "tag"
    end
  end

  defp format_discount(discount_type, discount_value) do
    case discount_type do
      "percentage" -> "#{discount_value}% off"
      "fixed" -> "KSh #{discount_value} off"
      "bogo" -> "Buy one get one free"
      "free_item" -> "Free item"
      _ -> "Special discount"
    end
  end

  defp status_color(status) do
    case status do
      "active" -> "bg-green-100 text-green-800"
      "scheduled" -> "bg-blue-100 text-blue-800"
      "expired" -> "bg-gray-100 text-gray-800"
      "paused" -> "bg-amber-100 text-amber-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp target_customer_label(target_type) do
    case target_type do
      "all" -> "All customers"
      "new" -> "New customers only"
      "loyal" -> "Loyalty members only"
      "inactive" -> "Inactive customers"
      _ -> "All customers"
    end
  end
end

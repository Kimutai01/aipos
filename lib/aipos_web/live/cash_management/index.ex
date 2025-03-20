defmodule AiposWeb.CashManagementLive.Index do
  use AiposWeb, :live_view

  alias AiposWeb.Sidebar

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:page_title, "Cash Management")
      |> assign(:active_page, "cash_management")
      |> assign(:current_user, sample_user())
      |> assign(:current_organization, sample_organization())
      |> assign(:date_filter, Date.utc_today())
      |> assign(:register_filter, "all")
      |> assign(:cashiers, generate_sample_cashiers())
      |> assign(:registers, generate_sample_registers())
      |> assign(:drawer_sessions, generate_sample_drawer_sessions())
      |> assign(:current_daily_summary, generate_daily_summary())
      |> assign(:show_drawer_form, false)
      |> assign(:show_drawer_details, false)
      |> assign(:show_adjustment_form, false)
      |> assign(:selected_drawer, nil)
      |> assign(:drawer_types, ["open", "close", "count", "adjustment"])
      |> assign(:adjustment_types, ["add", "remove"])
      |> assign(:payment_methods, ["cash", "card", "mpesa", "bank_transfer", "other"])
      |> assign(:form_mode, "create")
      |> assign(:drawer_transactions, [])
      |> assign(:drawer_stats, %{})
      |> assign(:denominations, [
        %{name: "1000 Note", value: 1000},
        %{name: "500 Note", value: 500},
        %{name: "200 Note", value: 200},
        %{name: "100 Note", value: 100},
        %{name: "50 Note", value: 50},
        %{name: "20 Coin", value: 20},
        %{name: "10 Coin", value: 10},
        %{name: "5 Coin", value: 5},
        %{name: "1 Coin", value: 1}
      ])

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_date", %{"date" => date_str}, socket) do
    {:ok, date} = Date.from_iso8601(date_str)

    # Regenerate sample data for the selected date
    drawer_sessions = generate_sample_drawer_sessions(date)
    daily_summary = generate_daily_summary(date)

    {:noreply,
     socket
     |> assign(:date_filter, date)
     |> assign(:drawer_sessions, drawer_sessions)
     |> assign(:current_daily_summary, daily_summary)}
  end

  @impl true
  def handle_event("filter_register", %{"register" => register_id}, socket) do
    filtered_sessions =
      if register_id == "all" do
        generate_sample_drawer_sessions(socket.assigns.date_filter)
      else
        generate_sample_drawer_sessions(socket.assigns.date_filter)
        |> Enum.filter(fn session -> session.register.id == String.to_integer(register_id) end)
      end

    {:noreply,
     socket
     |> assign(:register_filter, register_id)
     |> assign(:drawer_sessions, filtered_sessions)}
  end

  @impl true
  def handle_event("show_drawer_form", %{"type" => type}, socket) do
    cashier = List.first(socket.assigns.cashiers)
    register = List.first(socket.assigns.registers)

    {:noreply,
     socket
     |> assign(:show_drawer_form, true)
     |> assign(:drawer_type, type)
     |> assign(:form_mode, "create")
     |> assign(:selected_drawer, %{
       cashier: cashier,
       register: register,
       expected_amount: 10000.0,
       actual_amount: 0.0,
       note: "",
       denomination_counts: %{}
     })}
  end

  @impl true
  def handle_event("close_drawer_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_drawer_form, false)
     |> assign(:selected_drawer, nil)}
  end

  @impl true
  def handle_event("change_count", %{"denom" => denom, "count" => count_str}, socket) do
    {count, _} = Integer.parse(count_str)
    denom_value = String.to_integer(denom)

    # Update denomination counts
    denomination_counts =
      Map.put(
        socket.assigns.selected_drawer.denomination_counts,
        denom_value,
        count
      )

    # Calculate total based on denominations
    total_amount =
      Enum.reduce(denomination_counts, 0, fn {denom, count}, acc ->
        acc + denom * count
      end)

    updated_drawer = %{
      socket.assigns.selected_drawer
      | denomination_counts: denomination_counts,
        actual_amount: total_amount
    }

    {:noreply,
     socket
     |> assign(:selected_drawer, updated_drawer)}
  end

  @impl true
  def handle_event("save_drawer_operation", %{"drawer" => drawer_params}, socket) do
    # Simulate saving drawer operation
    new_session = %{
      id: :rand.uniform(1000) + 100,
      type: socket.assigns.drawer_type,
      cashier: socket.assigns.selected_drawer.cashier,
      register: socket.assigns.selected_drawer.register,
      expected_amount: socket.assigns.selected_drawer.expected_amount,
      actual_amount: socket.assigns.selected_drawer.actual_amount,
      variance:
        socket.assigns.selected_drawer.actual_amount -
          socket.assigns.selected_drawer.expected_amount,
      note: drawer_params["note"],
      timestamp: DateTime.utc_now(),
      status: "active"
    }

    # Add new session to the list
    updated_sessions = [new_session | socket.assigns.drawer_sessions]

    {:noreply,
     socket
     |> assign(:drawer_sessions, updated_sessions)
     |> assign(:show_drawer_form, false)
     |> assign(:selected_drawer, nil)
     |> put_flash(
       :info,
       "Drawer #{String.capitalize(socket.assigns.drawer_type)} operation recorded successfully!"
     )}
  end

  @impl true
  def handle_event("show_adjustment_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_adjustment_form, true)}
  end

  @impl true
  def handle_event("close_adjustment_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_adjustment_form, false)}
  end

  @impl true
  def handle_event("save_adjustment", %{"adjustment" => adjustment_params}, socket) do
    # Simulate saving adjustment
    amount = String.to_float(adjustment_params["amount"])
    type = adjustment_params["type"]
    reason = adjustment_params["reason"]

    new_adjustment = %{
      id: :rand.uniform(1000) + 100,
      type: "adjustment",
      adjustment_type: type,
      amount: amount,
      reason: reason,
      cashier: List.first(socket.assigns.cashiers),
      register: List.first(socket.assigns.registers),
      timestamp: DateTime.utc_now(),
      status: "completed"
    }

    # Add new adjustment to the list
    updated_sessions = [new_adjustment | socket.assigns.drawer_sessions]

    {:noreply,
     socket
     |> assign(:drawer_sessions, updated_sessions)
     |> assign(:show_adjustment_form, false)
     |> put_flash(:info, "Cash adjustment recorded successfully!")}
  end

  @impl true
  def handle_event("view_drawer_details", %{"id" => id}, socket) do
    id = String.to_integer(id)
    drawer = Enum.find(socket.assigns.drawer_sessions, fn s -> s.id == id end)

    # Generate drawer transactions and stats
    transactions = generate_drawer_transactions(drawer)
    drawer_stats = calculate_drawer_stats(transactions)

    {:noreply,
     socket
     |> assign(:selected_drawer, drawer)
     |> assign(:show_drawer_details, true)
     |> assign(:drawer_transactions, transactions)
     |> assign(:drawer_stats, drawer_stats)}
  end

  @impl true
  def handle_event("close_drawer_details", _, socket) do
    {:noreply,
     socket
     |> assign(:show_drawer_details, false)
     |> assign(:selected_drawer, nil)}
  end

  # Helper functions

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

  defp generate_sample_cashiers do
    [
      %{id: 1, name: "John Doe", role: "Manager"},
      %{id: 2, name: "Jane Smith", role: "Senior Cashier"},
      %{id: 3, name: "Michael Johnson", role: "Cashier"},
      %{id: 4, name: "Sarah Williams", role: "Cashier"},
      %{id: 5, name: "David Brown", role: "Cashier"}
    ]
  end

  defp generate_sample_registers do
    [
      %{id: 1, name: "Register 1", location: "Main Counter"},
      %{id: 2, name: "Register 2", location: "Main Counter"},
      %{id: 3, name: "Register 3", location: "Express Lane"},
      %{id: 4, name: "Register 4", location: "Customer Service"}
    ]
  end

  defp generate_sample_drawer_sessions(date \\ Date.utc_today()) do
    cashiers = generate_sample_cashiers()
    registers = generate_sample_registers()

    # Generate different drawer events throughout the day
    base_datetime = DateTime.new!(date, ~T[08:00:00], "Etc/UTC") |> DateTime.to_unix()

    drawer_events = []

    # Generate drawer opens
    drawer_events =
      drawer_events ++
        Enum.map(registers, fn register ->
          cashier = Enum.random(cashiers)
          # Random start within first hour
          start_time = base_datetime + :rand.uniform(3600)

          %{
            id: register.id * 100 + 1,
            type: "open",
            cashier: cashier,
            register: register,
            expected_amount: 10000.0,
            actual_amount: 10000.0,
            variance: 0.0,
            note: "Morning drawer open",
            timestamp: DateTime.from_unix!(start_time),
            status: "active"
          }
        end)

    # Generate mid-day counts for some registers
    drawer_events =
      drawer_events ++
        Enum.map(Enum.take_random(registers, 2), fn register ->
          cashier = Enum.random(cashiers)
          # Around noon
          mid_time = base_datetime + 14400 + :rand.uniform(3600)
          actual = 10000.0 + :rand.uniform(20000) + :rand.uniform(100)
          expected = 10000.0 + :rand.uniform(20000)

          %{
            id: register.id * 100 + 2,
            type: "count",
            cashier: cashier,
            register: register,
            expected_amount: expected,
            actual_amount: actual,
            variance: actual - expected,
            note: "Mid-day count",
            timestamp: DateTime.from_unix!(mid_time),
            status: "completed"
          }
        end)

    # Generate adjustments
    drawer_events =
      drawer_events ++
        Enum.map(1..2, fn i ->
          register = Enum.random(registers)
          cashier = Enum.random(cashiers)
          # Afternoon
          adj_time = base_datetime + 18000 + :rand.uniform(7200)

          %{
            id: 500 + i,
            type: "adjustment",
            adjustment_type: Enum.random(["add", "remove"]),
            cashier: cashier,
            register: register,
            amount: :rand.uniform(2000) + 0.0,
            reason:
              Enum.random([
                "Cash pickup for bank deposit",
                "Float addition",
                "Change requested",
                "Correcting counting error"
              ]),
            timestamp: DateTime.from_unix!(adj_time),
            status: "completed"
          }
        end)

    # Generate drawer closes
    drawer_events =
      drawer_events ++
        Enum.map(registers, fn register ->
          cashier = Enum.random(cashiers)
          # End of day
          end_time = base_datetime + 28800 + :rand.uniform(3600)
          expected = 35000.0 + :rand.uniform(15000)
          variance = (:rand.uniform(60) - 30) / 10
          actual = expected + variance

          %{
            id: register.id * 100 + 3,
            type: "close",
            cashier: cashier,
            register: register,
            expected_amount: expected,
            actual_amount: actual,
            variance: actual - expected,
            note: "balanced",
            timestamp: DateTime.from_unix!(end_time),
            status: "closed"
          }
        end)

    # Sort by timestamp
    Enum.sort_by(drawer_events, fn event -> event.timestamp end, {:desc, DateTime})
  end

  defp generate_daily_summary(date \\ Date.utc_today()) do
    %{
      date: date,
      total_cash_sales: 245_780.00,
      total_card_sales: 316_450.00,
      total_mpesa_sales: 198_320.00,
      total_sales: 760_550.00,
      opening_cash: 40_000.00,
      closing_cash: 285_780.00,
      cash_variance: -150.00,
      cash_pickups: 100_000.00,
      transaction_count: 187,
      refunds: 12_500.00,
      discounts: 28_750.00
    }
  end

  defp generate_drawer_transactions(drawer) do
    # Generate transactions for this drawer
    transaction_count = if drawer.type == "open", do: :rand.uniform(30) + 20, else: 0

    payment_methods = ["cash", "card", "mpesa"]
    # Cash most common, then card, then mpesa
    payment_weights = [60, 30, 10]

    Enum.map(1..transaction_count, fn i ->
      payment_method = weighted_random(payment_methods, payment_weights)
      amount = (:rand.uniform(50) + 1) * 100 + :rand.uniform(99)

      timestamp = DateTime.add(drawer.timestamp, i * :rand.uniform(300), :second)

      %{
        id: drawer.id * 1000 + i,
        receipt_number: "S#{10000 + i}",
        amount: amount,
        payment_method: payment_method,
        cashier: drawer.cashier,
        timestamp: timestamp,
        type: "sale"
      }
    end) ++
      if :rand.uniform(10) > 7 do
        # Add a refund transaction occasionally
        [
          %{
            id: drawer.id * 1000 + 99,
            receipt_number: "R#{10000 + :rand.uniform(100)}",
            amount: (:rand.uniform(20) + 1) * 100 + :rand.uniform(99),
            payment_method: "cash",
            cashier: drawer.cashier,
            timestamp: DateTime.add(drawer.timestamp, :rand.uniform(3600), :second),
            type: "refund"
          }
        ]
      else
        []
      end
  end

  defp calculate_drawer_stats(transactions) do
    cash_transactions = Enum.filter(transactions, fn t -> t.payment_method == "cash" end)

    cash_sales =
      Enum.filter(cash_transactions, fn t -> t.type == "sale" end)
      |> Enum.reduce(0, fn t, acc -> acc + t.amount end)

    cash_refunds =
      Enum.filter(cash_transactions, fn t -> t.type == "refund" end)
      |> Enum.reduce(0, fn t, acc -> acc + t.amount end)

    %{
      total_transactions: length(transactions),
      cash_transactions: length(cash_transactions),
      card_transactions:
        length(Enum.filter(transactions, fn t -> t.payment_method == "card" end)),
      mpesa_transactions:
        length(Enum.filter(transactions, fn t -> t.payment_method == "mpesa" end)),
      cash_sales: cash_sales,
      cash_refunds: cash_refunds,
      net_cash_change: cash_sales - cash_refunds
    }
  end

  defp weighted_random(items, weights) do
    # Select random item based on weights
    total_weight = Enum.sum(weights)
    target = :rand.uniform() * total_weight

    {item, _} =
      Enum.zip(items, weights)
      |> Enum.reduce_while({nil, 0}, fn {item, weight}, {_, acc} ->
        if acc + weight >= target do
          {:halt, {item, acc + weight}}
        else
          {:cont, {item, acc + weight}}
        end
      end)

    item
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
            <h1 class="text-2xl font-bold text-gray-900">Cash Management</h1>

            <div class="flex space-x-2">
              <button
                phx-click="show_drawer_form"
                phx-value-type="open"
                class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700"
              >
                <Heroicons.icon name="lock-open" class="h-5 w-5 mr-2" /> Open Drawer
              </button>

              <button
                phx-click="show_drawer_form"
                phx-value-type="count"
                class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
              >
                <Heroicons.icon name="calculator" class="h-5 w-5 mr-2" /> Count Drawer
              </button>

              <button
                phx-click="show_drawer_form"
                phx-value-type="close"
                class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700"
              >
                <Heroicons.icon name="lock-closed" class="h-5 w-5 mr-2" /> Close Drawer
              </button>

              <button
                phx-click="show_adjustment_form"
                class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-amber-600 hover:bg-amber-700"
              >
                <Heroicons.icon name="banknotes" class="h-5 w-5 mr-2" /> Cash Adjustment
              </button>
            </div>
          </div>
        </header>

        <div class="flex-1 overflow-hidden">
          <!-- Main Content -->
          <div class="p-6 h-full overflow-auto">
            <!-- Daily Summary -->
            <div class="bg-white shadow rounded-lg mb-6">
              <div class="p-6">
                <div class="flex items-center justify-between mb-4">
                  <h2 class="text-lg font-medium">
                    Daily Summary - {format_date(@current_daily_summary.date)}
                  </h2>

                  <form phx-change="filter_date" class="flex items-center">
                    <label class="text-sm font-medium text-gray-700 mr-2">Date:</label>
                    <input
                      type="date"
                      name="date"
                      value={Date.to_string(@date_filter)}
                      class="border rounded-md shadow-sm py-1 px-2"
                    />
                  </form>
                </div>

                <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
                  <!-- Total Sales -->
                  <div class="bg-blue-50 p-4 rounded-lg">
                    <div class="text-blue-500 text-sm font-medium mb-1">Total Sales</div>
                    <div class="text-2xl font-bold">
                      {format_currency(@current_daily_summary.total_sales)}
                    </div>
                    <div class="text-sm text-gray-500 mt-1">
                      {@current_daily_summary.transaction_count} transactions
                    </div>
                  </div>
                  
    <!-- Cash Sales -->
                  <div class="bg-green-50 p-4 rounded-lg">
                    <div class="text-green-500 text-sm font-medium mb-1">Cash Sales</div>
                    <div class="text-2xl font-bold">
                      {format_currency(@current_daily_summary.total_cash_sales)}
                    </div>
                    <div class="text-sm text-gray-500 mt-1">
                      {round(
                        @current_daily_summary.total_cash_sales / @current_daily_summary.total_sales *
                          100
                      )}% of total
                    </div>
                  </div>
                  
    <!-- Cash Balance -->
                  <div class="bg-amber-50 p-4 rounded-lg">
                    <div class="text-amber-500 text-sm font-medium mb-1">Cash Balance</div>
                    <div class="text-2xl font-bold">
                      {format_currency(@current_daily_summary.closing_cash)}
                    </div>
                    <div class="text-sm text-gray-500 mt-1">
                      <span class={
                        if @current_daily_summary.cash_variance < 0,
                          do: "text-red-600",
                          else: "text-green-600"
                      }>
                        {if @current_daily_summary.cash_variance < 0, do: "-", else: "+"}{format_currency(
                          abs(@current_daily_summary.cash_variance)
                        )} variance
                      </span>
                    </div>
                  </div>
                  
    <!-- Cash Pickups -->
                  <div class="bg-purple-50 p-4 rounded-lg">
                    <div class="text-purple-500 text-sm font-medium mb-1">Cash Pickups</div>
                    <div class="text-2xl font-bold">
                      {format_currency(@current_daily_summary.cash_pickups)}
                    </div>
                    <div class="text-sm text-gray-500 mt-1">Bank deposits</div>
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-4">
                  <div class="flex items-center p-4 bg-gray-50 rounded-lg">
                    <div class="h-10 w-10 flex items-center justify-center rounded-full bg-blue-100 text-blue-600 mr-3">
                      <Heroicons.icon name="credit-card" class="h-6 w-6" />
                    </div>
                    <div>
                      <div class="text-xs text-gray-500">Card Sales</div>
                      <div class="text-lg font-bold">
                        {format_currency(@current_daily_summary.total_card_sales)}
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center p-4 bg-gray-50 rounded-lg">
                    <div class="h-10 w-10 flex items-center justify-center rounded-full bg-blue-100 text-blue-600 mr-3">
                      <Heroicons.icon name="device-phone-mobile" class="h-6 w-6" />
                    </div>
                    <div>
                      <div class="text-xs text-gray-500">M-Pesa Sales</div>
                      <div class="text-lg font-bold">
                        {format_currency(@current_daily_summary.total_mpesa_sales)}
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center p-4 bg-gray-50 rounded-lg">
                    <div class="h-10 w-10 flex items-center justify-center rounded-full bg-red-100 text-red-600 mr-3">
                      <Heroicons.icon name="arrow-path" class="h-6 w-6" />
                    </div>
                    <div>
                      <div class="text-xs text-gray-500">Refunds</div>
                      <div class="text-lg font-bold">
                        {format_currency(@current_daily_summary.refunds)}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Drawer Activity -->
            <div class="bg-white shadow rounded-lg mb-6">
              <div class="p-4 border-b border-gray-200 flex items-center justify-between">
                <h3 class="text-lg font-medium">Drawer Activity</h3>

                <div class="flex items-center">
                  <span class="text-sm text-gray-700 mr-2">Register:</span>
                  <select
                    phx-change="filter_register"
                    name="register"
                    class="border rounded-md shadow-sm py-1 px-2"
                  >
                    <option value="all" selected={@register_filter == "all"}>All Registers</option>
                    <%= for register <- @registers do %>
                      <option value={register.id} selected={@register_filter == "#{register.id}"}>
                        {register.name}
                      </option>
                    <% end %>
                  </select>
                </div>
              </div>

              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Date/Time
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Register
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Cashier
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Type
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Amount
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Variance
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
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
                    <%= if Enum.empty?(@drawer_sessions) do %>
                      <tr>
                        <td colspan="8" class="px-6 py-4 text-center text-gray-500">
                          No drawer activity found for the selected date and register.
                        </td>
                      </tr>
                    <% else %>
                      <%= for session <- @drawer_sessions do %>
                        <tr class="hover:bg-gray-50">
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {format_datetime(session.timestamp)}
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {session.register.name}
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap">
                            <div class="text-sm font-medium text-gray-900">
                              {session.cashier.name}
                            </div>
                            <div class="text-xs text-gray-500">{session.cashier.role}</div>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap">
                            <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{drawer_type_color(session)}"}>
                              {drawer_type_label(session)}
                            </span>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-right">
                            <%= if session.type != "adjustment" && session.variance do %>
                              <span class={
                                if session.variance < 0,
                                  do: "text-red-600 font-medium",
                                  else:
                                    if(session.variance > 0,
                                      do: "text-green-600 font-medium",
                                      else: "text-gray-500"
                                    )
                              }>
                                {if session.variance > 0, do: "+", else: ""}{format_currency(
                                  session.variance
                                )}
                              </span>
                            <% else %>
                              <span class="text-gray-400">-</span>
                            <% end %>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap text-center">
                            <span class={"px-2 py-1 inline-flex text-xs leading-5 font-medium rounded-full #{drawer_status_color(session.status)}"}>
                              {String.capitalize(session.status)}
                            </span>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                            <button
                              phx-click="view_drawer_details"
                              phx-value-id={session.id}
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
      </div>
      
    <!-- Drawer Count Form Modal -->
      <%= if @show_drawer_form do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-screen overflow-y-auto">
            <div class="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="text-lg font-medium">
                {drawer_form_title(@drawer_type)}
              </h3>
              <button phx-click="close_drawer_form" class="text-gray-400 hover:text-gray-500">
                <Heroicons.icon name="x-mark" class="h-6 w-6" />
              </button>
            </div>

            <form phx-submit="save_drawer_operation">
              <div class="p-6">
                <!-- Registers and Cashier Info -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Register</label>
                    <div class="relative">
                      <select
                        name="drawer[register_id]"
                        class="block w-full border rounded-md shadow-sm py-2 px-3 appearance-none"
                      >
                        <%= for register <- @registers do %>
                          <option
                            value={register.id}
                            selected={@selected_drawer.register.id == register.id}
                          >
                            {register.name} ({register.location})
                          </option>
                        <% end %>
                      </select>
                      <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                        <Heroicons.icon name="chevron-down" class="h-5 w-5 text-gray-400" />
                      </div>
                    </div>
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Cashier</label>
                    <div class="relative">
                      <select
                        name="drawer[cashier_id]"
                        class="block w-full border rounded-md shadow-sm py-2 px-3 appearance-none"
                      >
                        <%= for cashier <- @cashiers do %>
                          <option
                            value={cashier.id}
                            selected={@selected_drawer.cashier.id == cashier.id}
                          >
                            {cashier.name} ({cashier.role})
                          </option>
                        <% end %>
                      </select>
                      <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                        <Heroicons.icon name="chevron-down" class="h-5 w-5 text-gray-400" />
                      </div>
                    </div>
                  </div>
                </div>
                
    <!-- Denomination Counting Form -->
                <div class="bg-gray-50 p-4 rounded-lg mb-6">
                  <h4 class="text-sm font-medium text-gray-700 mb-3">Cash Count</h4>

                  <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
                    <%= for denom <- @denominations do %>
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">
                          {denom.name}
                        </label>
                        <div class="flex items-center">
                          <input
                            type="number"
                            min="0"
                            name={"drawer[denomination][#{denom.value}]"}
                            phx-change="change_count"
                            phx-value-denom={denom.value}
                            value={Map.get(@selected_drawer.denomination_counts, denom.value, 0)}
                            class="block w-full border rounded-md shadow-sm py-2 px-3"
                          />

                          <div class="ml-2 text-sm text-gray-500">
                            {format_currency(
                              denom.value *
                                Map.get(@selected_drawer.denomination_counts, denom.value, 0)
                            )}
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>

                  <div class="mt-4 pt-4 border-t border-gray-200 flex justify-between items-center">
                    <div>
                      <div class="text-sm text-gray-500">Total Counted</div>
                      <div class="text-xl font-bold">
                        {format_currency(@selected_drawer.actual_amount)}
                      </div>
                    </div>

                    <div>
                      <div class="text-sm text-gray-500">Expected Amount</div>
                      <div class="text-xl font-bold">
                        {format_currency(@selected_drawer.expected_amount)}
                      </div>
                    </div>

                    <div>
                      <div class="text-sm text-gray-500">Variance</div>
                      <div class={"text-xl font-bold #{if @selected_drawer.actual_amount - @selected_drawer.expected_amount < 0, do: "text-red-600", else: "text-green-600"}"}>
                        {if @selected_drawer.actual_amount - @selected_drawer.expected_amount >= 0,
                          do: "+",
                          else: ""}
                        {format_currency(
                          @selected_drawer.actual_amount - @selected_drawer.expected_amount
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                <div class="mb-6">
                  <label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
                  <textarea
                    name="drawer[note]"
                    rows="3"
                    placeholder="Any additional notes about this drawer operation"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  ></textarea>
                </div>
              </div>

              <div class="p-4 border-t border-gray-200 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="close_drawer_form"
                  class="px-4 py-2 border rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class={"px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white #{drawer_button_color(@drawer_type)}"}
                >
                  {drawer_button_text(@drawer_type)}
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
    <!-- Cash Adjustment Form Modal -->
      <%= if @show_adjustment_form do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg shadow-xl max-w-lg w-full mx-4">
            <div class="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="text-lg font-medium">Cash Adjustment</h3>
              <button phx-click="close_adjustment_form" class="text-gray-400 hover:text-gray-500">
                <Heroicons.icon name="x-mark" class="h-6 w-6" />
              </button>
            </div>

            <form phx-submit="save_adjustment">
              <div class="p-6 space-y-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Adjustment Type</label>
                  <div class="flex space-x-4">
                    <label class="flex items-center">
                      <input
                        type="radio"
                        name="adjustment[type]"
                        value="add"
                        checked
                        class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
                      />
                      <span class="ml-2 text-sm text-gray-700">Add Cash</span>
                    </label>
                    <label class="flex items-center">
                      <input
                        type="radio"
                        name="adjustment[type]"
                        value="remove"
                        class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
                      />
                      <span class="ml-2 text-sm text-gray-700">Remove Cash</span>
                    </label>
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Register</label>
                    <div class="relative">
                      <select
                        name="adjustment[register_id]"
                        class="block w-full border rounded-md shadow-sm py-2 px-3 appearance-none"
                      >
                        <%= for register <- @registers do %>
                          <option value={register.id}>
                            {register.name}
                          </option>
                        <% end %>
                      </select>
                      <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                        <Heroicons.icon name="chevron-down" class="h-5 w-5 text-gray-400" />
                      </div>
                    </div>
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Amount</label>
                    <div class="relative">
                      <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                        <span class="text-gray-500">KSh</span>
                      </div>
                      <input
                        type="number"
                        name="adjustment[amount]"
                        min="0"
                        step="0.01"
                        required
                        class="block w-full pl-12 border rounded-md shadow-sm py-2 px-3"
                      />
                    </div>
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Reason</label>
                  <select
                    name="adjustment[reason]"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  >
                    <option value="Cash pickup for bank deposit">Cash pickup for bank deposit</option>
                    <option value="Float addition">Float addition</option>
                    <option value="Change requested">Change requested</option>
                    <option value="Correcting counting error">Correcting counting error</option>
                    <option value="Other (see notes)">Other (see notes)</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
                  <textarea
                    name="adjustment[notes]"
                    rows="2"
                    placeholder="Additional details about this adjustment"
                    class="block w-full border rounded-md shadow-sm py-2 px-3"
                  ></textarea>
                </div>
              </div>

              <div class="p-4 border-t border-gray-200 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="close_adjustment_form"
                  class="px-4 py-2 border rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-amber-600 hover:bg-amber-700"
                >
                  Record Adjustment
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
    <!-- Drawer Details Slide Over -->
      <%= if @show_drawer_details && @selected_drawer do %>
        <div class="fixed inset-0 overflow-hidden z-50">
          <div class="absolute inset-0 overflow-hidden">
            <div class="absolute inset-0 bg-gray-500 bg-opacity-75" phx-click="close_drawer_details">
            </div>

            <div class="fixed inset-y-0 right-0 max-w-2xl w-full flex">
              <div class="relative w-full bg-white shadow-xl flex flex-col overflow-y-auto">
                <div class="flex-1 overflow-y-auto">
                  <!-- Header -->
                  <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                    <h2 class="text-xl font-medium text-gray-900">
                      {drawer_details_title(@selected_drawer)}
                    </h2>
                    <button phx-click="close_drawer_details" class="text-gray-400 hover:text-gray-500">
                      <Heroicons.icon name="x-mark" class="h-6 w-6" />
                    </button>
                  </div>
                  
    <!-- Overview -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <div class="flex items-start">
                      <div class={"h-12 w-12 rounded-md flex items-center justify-center #{drawer_icon_background(@selected_drawer.type)}"}>
                        <Heroicons.icon
                          name={drawer_icon(@selected_drawer.type)}
                          class="h-6 w-6 text-white"
                        />
                      </div>
                      <div class="ml-4">
                        <div class="flex items-center">
                          <span class={"px-2 py-0.5 rounded-full text-xs font-medium #{drawer_type_color(@selected_drawer)}"}>
                            {drawer_type_label(@selected_drawer)}
                          </span>
                          <span class={"ml-2 px-2 py-0.5 rounded-full text-xs font-medium #{drawer_status_color(@selected_drawer.status)}"}>
                            {String.capitalize(@selected_drawer.status)}
                          </span>
                        </div>

                        <div class="mt-1 text-sm text-gray-500">
                          <div class="flex items-center">
                            <Heroicons.icon name="clock" class="h-4 w-4 mr-1 text-gray-400" />
                            <span>{format_datetime(@selected_drawer.timestamp)}</span>
                          </div>

                          <div class="flex items-center mt-1">
                            <Heroicons.icon name="user" class="h-4 w-4 mr-1 text-gray-400" />
                            <span>
                              {@selected_drawer.cashier.name} ({@selected_drawer.cashier.role})
                            </span>
                          </div>

                          <div class="flex items-center mt-1">
                            <Heroicons.icon name="shopping-cart" class="h-4 w-4 mr-1 text-gray-400" />
                            <span>
                              {@selected_drawer.register.name} ({@selected_drawer.register.location})
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  
    <!-- Details -->
                  <%= if @selected_drawer.type != "adjustment" do %>
                    <div class="px-6 py-4 border-b border-gray-200">
                      <h4 class="text-sm font-medium text-gray-700 mb-3">Drawer Summary</h4>

                      <div class="bg-gray-50 rounded-lg p-4">
                        <div class="grid grid-cols-2 gap-4">
                          <div>
                            <div class="text-xs text-gray-500">Expected Amount</div>
                            <div class="text-lg font-medium">
                              {format_currency(@selected_drawer.expected_amount)}
                            </div>
                          </div>

                          <div>
                            <div class="text-xs text-gray-500">Actual Amount</div>
                            <div class="text-lg font-medium">
                              {format_currency(@selected_drawer.actual_amount)}
                            </div>
                          </div>

                          <div>
                            <div class="text-xs text-gray-500">Variance</div>
                            <div class={"text-lg font-medium #{if @selected_drawer.variance < 0, do: "text-red-600", else: "text-green-600"}"}>
                              {if @selected_drawer.variance >= 0, do: "+", else: ""}{format_currency(
                                @selected_drawer.variance
                              )}
                            </div>
                          </div>
                        </div>

                        <%= if @selected_drawer.note && @selected_drawer.note != "" do %>
                          <div class="mt-4 pt-4 border-t border-gray-200">
                            <h5 class="text-xs text-gray-500 mb-1">Notes</h5>
                            <p class="text-sm">{@selected_drawer.note}</p>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% else %>
                    <div class="px-6 py-4 border-b border-gray-200">
                      <h4 class="text-sm font-medium text-gray-700 mb-3">Adjustment Details</h4>

                      <div class="bg-gray-50 rounded-lg p-4">
                        <div class="grid grid-cols-2 gap-4">
                          <div>
                            <div class="text-xs text-gray-500">Adjustment Type</div>
                            <div class="text-lg font-medium">
                              {String.capitalize(@selected_drawer.adjustment_type)}
                            </div>
                          </div>

                          <div>
                            <div class="text-xs text-gray-500">Amount</div>
                            <div class={"text-lg font-medium #{if @selected_drawer.adjustment_type == "add", do: "text-green-600", else: "text-red-600"}"}>
                              {if @selected_drawer.adjustment_type == "add", do: "+", else: "-"}{format_currency(
                                @selected_drawer.amount
                              )}
                            </div>
                          </div>

                          <div class="col-span-2">
                            <div class="text-xs text-gray-500">Reason</div>
                            <div class="text-lg font-medium">{@selected_drawer.reason}</div>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                  
    <!-- Transaction Details (for drawer open/close) -->
                  <%= if @selected_drawer.type == "open" && length(@drawer_transactions) > 0 do %>
                    <div class="px-6 py-4">
                      <div class="flex justify-between items-center mb-3">
                        <h4 class="text-sm font-medium text-gray-700">Transactions</h4>

                        <div class="text-sm text-gray-500">
                          Total: {@drawer_stats.total_transactions} transactions
                        </div>
                      </div>

                      <div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">
                        <div class="bg-blue-50 p-3 rounded-lg">
                          <div class="text-blue-500 text-xs font-medium mb-1">Cash</div>
                          <div class="text-lg font-medium">
                            {format_currency(@drawer_stats.cash_sales)}
                          </div>
                          <div class="text-xs text-gray-500">
                            {@drawer_stats.cash_transactions} transactions
                          </div>
                        </div>

                        <div class="bg-blue-50 p-3 rounded-lg">
                          <div class="text-blue-500 text-xs font-medium mb-1">Card</div>
                          <div class="text-lg font-medium">-</div>
                          <div class="text-xs text-gray-500">
                            {@drawer_stats.card_transactions} transactions
                          </div>
                        </div>

                        <div class="bg-blue-50 p-3 rounded-lg">
                          <div class="text-blue-500 text-xs font-medium mb-1">M-Pesa</div>
                          <div class="text-lg font-medium">-</div>
                          <div class="text-xs text-gray-500">
                            {@drawer_stats.mpesa_transactions} transactions
                          </div>
                        </div>
                      </div>

                      <div class="border rounded-md overflow-hidden">
                        <table class="min-w-full divide-y divide-gray-200">
                          <thead class="bg-gray-50">
                            <tr>
                              <th
                                scope="col"
                                class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Receipt
                              </th>
                              <th
                                scope="col"
                                class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Time
                              </th>
                              <th
                                scope="col"
                                class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Payment
                              </th>
                              <th
                                scope="col"
                                class="px-3 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                              >
                                Amount
                              </th>
                            </tr>
                          </thead>
                          <tbody class="bg-white divide-y divide-gray-200">
                            <%= for transaction <- Enum.take(@drawer_transactions, 10) do %>
                              <tr class={"hover:bg-gray-50 #{if transaction.type == "refund", do: "bg-red-50", else: ""}"}>
                                <td class="px-3 py-2 whitespace-nowrap text-sm">
                                  <div class="font-medium text-gray-900">
                                    {transaction.receipt_number}
                                  </div>
                                  <div class="text-xs text-gray-500">
                                    {String.capitalize(transaction.type)}
                                  </div>
                                </td>
                                <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                                  {format_time(transaction.timestamp)}
                                </td>
                                <td class="px-3 py-2 whitespace-nowrap">
                                  <span class={"px-2 py-0.5 text-xs rounded-full #{payment_method_color(transaction.payment_method)}"}>
                                    {String.capitalize(transaction.payment_method)}
                                  </span>
                                </td>
                                <td class="px-3 py-2 whitespace-nowrap text-sm text-right">
                                  <span class={
                                    if transaction.type == "refund",
                                      do: "text-red-600 font-medium",
                                      else: "font-medium"
                                  }>
                                    {if transaction.type == "refund", do: "-"}{format_currency(
                                      transaction.amount
                                    )}
                                  </span>
                                </td>
                              </tr>
                            <% end %>

                            <%= if length(@drawer_transactions) > 10 do %>
                              <tr>
                                <td colspan="4" class="px-3 py-2 text-center text-sm text-gray-500">
                                  Showing 10 of {length(@drawer_transactions)} transactions
                                </td>
                              </tr>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    </div>
                  <% end %>
                </div>
                
    <!-- Footer actions -->
                <div class="border-t border-gray-200 p-4">
                  <div class="flex space-x-3">
                    <%= if @selected_drawer.type == "open" do %>
                      <button
                        phx-click="show_drawer_form"
                        phx-value-type="count"
                        class="flex-1 px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                      >
                        <Heroicons.icon name="calculator" class="h-5 w-5 mr-2 inline" /> Count Drawer
                      </button>

                      <button
                        phx-click="show_drawer_form"
                        phx-value-type="close"
                        class="flex-1 px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700"
                      >
                        <Heroicons.icon name="lock-closed" class="h-5 w-5 mr-2 inline" /> Close Drawer
                      </button>
                    <% end %>

                    <button
                      phx-click="print_drawer_details"
                      phx-value-id={@selected_drawer.id}
                      class="flex-1 px-4 py-2 border rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                    >
                      <Heroicons.icon name="printer" class="h-5 w-5 mr-2 inline" /> Print Report
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

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y %I:%M %p")
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%I:%M %p")
  end

  defp drawer_type_color(session) do
    case session.type do
      "open" ->
        "bg-green-100 text-green-800"

      "close" ->
        "bg-red-100 text-red-800"

      "count" ->
        "bg-blue-100 text-blue-800"

      "adjustment" ->
        if Map.get(session, :adjustment_type) == "add",
          do: "bg-emerald-100 text-emerald-800",
          else: "bg-amber-100 text-amber-800"

      _ ->
        "bg-gray-100 text-gray-800"
    end
  end

  defp drawer_type_label(session) do
    case session.type do
      "open" ->
        "Drawer Open"

      "close" ->
        "Drawer Close"

      "count" ->
        "Cash Count"

      "adjustment" ->
        if Map.get(session, :adjustment_type) == "add", do: "Cash Added", else: "Cash Removed"

      _ ->
        String.capitalize(session.type)
    end
  end

  defp drawer_status_color(status) do
    case status do
      "active" -> "bg-green-100 text-green-800"
      "closed" -> "bg-red-100 text-red-800"
      "completed" -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp payment_method_color(method) do
    case method do
      "cash" -> "bg-green-100 text-green-800"
      "card" -> "bg-blue-100 text-blue-800"
      "mpesa" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp drawer_form_title(type) do
    case type do
      "open" -> "Open Cash Drawer"
      "close" -> "Close Cash Drawer"
      "count" -> "Count Cash Drawer"
      _ -> "Cash Drawer Operation"
    end
  end

  defp drawer_button_text(type) do
    case type do
      "open" -> "Open Drawer"
      "close" -> "Close Drawer"
      "count" -> "Save Count"
      _ -> "Save"
    end
  end

  defp drawer_button_color(type) do
    case type do
      "open" -> "bg-green-600 hover:bg-green-700"
      "close" -> "bg-red-600 hover:bg-red-700"
      "count" -> "bg-blue-600 hover:bg-blue-700"
      _ -> "bg-blue-600 hover:bg-blue-700"
    end
  end

  defp drawer_details_title(drawer) do
    case drawer.type do
      "open" -> "Drawer Open Details"
      "close" -> "Drawer Close Details"
      "count" -> "Cash Count Details"
      "adjustment" -> "Cash Adjustment Details"
      _ -> "Drawer Operation Details"
    end
  end

  defp drawer_icon(type) do
    case type do
      "open" -> "lock-open"
      "close" -> "lock-closed"
      "count" -> "calculator"
      "adjustment" -> "banknotes"
      _ -> "document"
    end
  end

  # Helper function to get the appropriate icon background color for a drawer type
  defp drawer_icon_background(type) do
    case type do
      "open" -> "bg-green-500"
      "close" -> "bg-red-500"
      "count" -> "bg-blue-500"
      "adjustment" -> "bg-amber-500"
      _ -> "bg-gray-500"
    end
  end
end

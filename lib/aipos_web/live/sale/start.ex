defmodule AiposWeb.Live.Sale.Start do
  use AiposWeb, :live_view
  alias Aipos.Sales
  alias Aipos.Products
  alias Aipos.ProductSkus
  alias Aipos.Accounts
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_page, "new_session")
      |> assign(:current_organization, get_organization(socket.assigns.current_user))
      |> assign(:cart_items, [])
      |> assign(:total_amount, Decimal.new(0))
      |> assign(:barcode, "")
      |> assign(
        :registers,
        Aipos.Registers.list_registers(socket.assigns.current_user.id)
      )
      |> assign(:selected_register, nil)
      |> assign(:drawer_opened, false)
      |> assign(:scanner_connected, false)
      # :manual or :external
      |> assign(:scanning_mode, :manual)
      |> assign(:payment_method, "cash")
      |> assign(:amount_tendered, 0)
      |> assign(:change_due, 0)
      |> assign(:search_query, "")
      |> assign(:search_results, [])
      |> assign(:customer, nil)
      |> assign(:customer_phone, "")
      |> assign(:show_customer_search, false)
      |> assign(:session_started, false)
      |> assign(:show_payment_modal, false)

    if connected?(socket), do: Process.send_after(self(), :check_scanner, 1000)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Start New Sale")
  end

  defp apply_action(socket, nil, _params) do
    socket
    |> assign(:page_title, "Start New Sale")
  end

  @impl true
  def handle_event("select_register", %{"id" => id}, socket) do
    register_id = String.to_integer(id)
    register = Aipos.Registers.get_register!(register_id)

    if register.status != "available" do
      {:noreply,
       socket
       |> put_flash(:error, "This register is not available.")}
    else
      # Update the register status to "in_use"
      case Aipos.Registers.update_register(register, %{status: "available"}) do
        {:ok, updated_register} ->
          registers = Aipos.Registers.list_registers(socket.assigns.current_user.id)

          {:noreply,
           socket
           |> assign(:registers, registers)
           |> assign(:selected_register, updated_register)
           |> assign(:session_started, true)}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to select register. Please try again.")}
      end
    end
  end

  def handle_event("add_item", %{"barcode" => barcode}, socket) do
    case find_product_by_barcode(barcode) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Product not found for barcode: #{barcode}")
         |> assign(:barcode, "")}

      product_sku ->
        cart_items = add_to_cart(socket.assigns.cart_items, product_sku)
        total = calculate_total(cart_items)

        {:noreply,
         socket
         |> assign(:cart_items, cart_items)
         |> assign(:total_amount, total)
         |> assign(:barcode, "")}
    end
  end

  def handle_event("validate_barcode", %{"barcode" => barcode}, socket) do
    {:noreply, assign(socket, :barcode, barcode)}
  end

  def handle_event("search_products", %{"query" => query}, socket) do
    results =
      if String.length(query) >= 2 do
        search_products(query, socket.assigns.current_user.organization_id)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, results)}
  end

  def handle_event("add_from_search", %{"id" => id}, socket) do
    product_sku = ProductSkus.get_product_sku!(id)
    cart_items = add_to_cart(socket.assigns.cart_items, product_sku)
    total = calculate_total(cart_items)

    {:noreply,
     socket
     |> assign(:cart_items, cart_items)
     |> assign(:total_amount, total)
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  def handle_event("remove_item", %{"index" => index}, socket) do
    index = String.to_integer(index)
    cart_items = List.delete_at(socket.assigns.cart_items, index)
    total = calculate_total(cart_items)

    {:noreply,
     socket
     |> assign(:cart_items, cart_items)
     |> assign(:total_amount, total)}
  end

  def handle_event("update_quantity", %{"index" => index, "quantity" => quantity}, socket) do
    index = String.to_integer(index)
    quantity = String.to_integer(quantity)

    cart_items =
      List.update_at(socket.assigns.cart_items, index, fn item ->
        subtotal = Decimal.mult(item.price, Decimal.new(quantity))
        %{item | quantity: quantity, subtotal: subtotal}
      end)

    total = calculate_total(cart_items)

    {:noreply,
     socket
     |> assign(:cart_items, cart_items)
     |> assign(:total_amount, total)}
  end

  def handle_event("toggle_scanner_mode", _, socket) do
    new_mode = if socket.assigns.scanning_mode == :manual, do: :external, else: :manual

    socket =
      socket
      |> assign(:scanning_mode, new_mode)

    if new_mode == :external do
      # Attempt to connect to scanner in JS hook
      {:noreply, push_event(socket, "connect_scanner", %{})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("connect_scanner", _, socket) do
    # This would be called from the JS hook
    {:noreply, push_event(socket, "connect_scanner", %{})}
  end

  def handle_event("scanner_connected", _, socket) do
    {:noreply,
     socket
     |> assign(:scanner_connected, true)
     |> put_flash(:info, "Barcode scanner connected successfully")}
  end

  def handle_event("scanner_error", %{"message" => message}, socket) do
    {:noreply,
     socket
     |> assign(:scanner_connected, false)
     |> put_flash(:error, "Scanner error: #{message}")}
  end

  def handle_event("barcode_scanned", %{"barcode" => barcode}, socket) do
    # This would be called from the JS hook when a barcode is scanned
    handle_event("add_item", %{"barcode" => barcode}, socket)
  end

  def handle_event("show_payment_modal", _, socket) do
    if Enum.empty?(socket.assigns.cart_items) do
      {:noreply, put_flash(socket, :error, "Cannot complete payment with empty cart")}
    else
      {:noreply, assign(socket, :show_payment_modal, true)}
    end
  end

  def handle_event("hide_payment_modal", _, socket) do
    {:noreply, assign(socket, :show_payment_modal, false)}
  end

  def handle_event("update_payment_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, :payment_method, method)}
  end

  def handle_event("update_amount_tendered", %{"amount" => amount}, socket) do
    {amount, _} = Float.parse(amount)
    change = amount - Decimal.to_float(socket.assigns.total_amount)

    {:noreply,
     socket
     |> assign(:amount_tendered, amount)
     |> assign(:change_due, max(0, change))}
  end

  def handle_event("complete_sale", _, socket) do
    if socket.assigns.amount_tendered < Decimal.to_float(socket.assigns.total_amount) do
      {:noreply, put_flash(socket, :error, "Amount tendered is less than total amount")}
    else
      # Create sale in database
      sale_params = %{
        register_id: socket.assigns.selected_register.id,
        cashier_id: socket.assigns.current_user.id,
        total_amount: socket.assigns.total_amount,
        payment_method: socket.assigns.payment_method,
        amount_tendered: Decimal.new("#{socket.assigns.amount_tendered}"),
        change_due: Decimal.new("#{socket.assigns.change_due}"),
        status: "completed",
        organization_id: socket.assigns.current_user.organization_id,
        customer_id: socket.assigns.customer && socket.assigns.customer.id
      }

      case Aipos.Sales.create_sale(sale_params) do
        {:ok, sale} ->
          # Create sale items
          Enum.each(socket.assigns.cart_items, fn item ->
            item_params = %{
              sale_id: sale.id,
              product_sku_id: item.sku_id,
              name: item.name,
              quantity: item.quantity,
              price: item.price,
              subtotal: item.subtotal,
              organization_id: socket.assigns.current_user.organization_id
            }

            {:ok, _sale_item} = Aipos.Sales.create_sale_item(item_params)

            update_stock_quantity(item.sku_id, item.quantity)
          end)

          register = socket.assigns.selected_register
          {:ok, _register} = Aipos.Registers.update_register(register, %{status: "available"})

          # Print receipt here
          socket =
            if socket.assigns.payment_method == "cash" do
              # Signal JS to open cash drawer
              push_event(socket, "open_cash_drawer", %{})
            else
              socket
            end

          registers = Aipos.Registers.list_registers(socket.assigns.current_user.id)

          {:noreply,
           socket
           |> assign(:registers, registers)
           |> assign(:drawer_opened, socket.assigns.payment_method == "cash")
           |> assign(:cart_items, [])
           |> assign(:total_amount, Decimal.new(0))
           |> assign(:show_payment_modal, false)
           |> assign(:amount_tendered, 0)
           |> assign(:change_due, 0)
           |> assign(:session_started, false)
           |> assign(:selected_register, nil)
           |> put_flash(:info, "Sale ##{sale.id} completed successfully!")}

        {:error, changeset} ->
          errors = Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
          error_message = "Error completing sale: #{inspect(errors)}"

          {:noreply,
           socket
           |> put_flash(:error, error_message)}
      end
    end
  end

  def handle_event("search_customer", %{"phone" => phone}, socket) do
    # In a real app, you'd search for customer in the database
    customer =
      if phone == "123456789" do
        %{id: 1, name: "John Doe", phone: "123456789", email: "john@example.com"}
      else
        nil
      end

    {:noreply,
     socket
     |> assign(:customer, customer)
     |> assign(:customer_phone, phone)
     |> assign(:show_customer_search, false)}
  end

  def handle_event("show_customer_search", _, socket) do
    {:noreply, assign(socket, :show_customer_search, true)}
  end

  def handle_event("hide_customer_search", _, socket) do
    {:noreply, assign(socket, :show_customer_search, false)}
  end

  def handle_event("reset_sale", _, socket) do
    {:noreply,
     socket
     |> assign(:cart_items, [])
     |> assign(:total_amount, Decimal.new(0))
     |> assign(:customer, nil)
     |> assign(:customer_phone, "")}
  end

  @impl true
  def handle_info(:check_scanner, socket) do
    # In a real app, you might check for connected scanners
    # For now, we'll just trigger the JS hook
    {:noreply, push_event(socket, "check_scanner", %{})}
  end

  # Helper functions

  defp get_organization(user) do
    Aipos.Organizations.get_organization!(user.organization_id)
  end

  defp find_product_by_barcode(barcode) do
    # Look up the product SKU by barcode
    from(s in Aipos.ProductSkus.ProductSku,
      where: s.barcode == ^barcode,
      preload: [:product]
    )
    |> Aipos.Repo.one()
  end

  defp add_to_cart(cart_items, product_sku) do
    # Check if item already exists in cart
    case Enum.find_index(cart_items, &(&1.id == product_sku.id)) do
      nil ->
        # Add new item to cart
        cart_item = %{
          id: product_sku.id,
          sku_id: product_sku.id,
          name: product_sku.name,
          product_name: (product_sku.product && product_sku.product.name) || product_sku.name,
          barcode: product_sku.barcode,
          price: product_sku.price,
          quantity: 1,
          subtotal: product_sku.price,
          image: product_sku.image
        }

        cart_items ++ [cart_item]

      index ->
        # Increment quantity of existing item
        List.update_at(cart_items, index, fn item ->
          new_quantity = item.quantity + 1
          subtotal = Decimal.mult(item.price, Decimal.new(new_quantity))
          %{item | quantity: new_quantity, subtotal: subtotal}
        end)
    end
  end

  defp calculate_total(cart_items) do
    Enum.reduce(cart_items, Decimal.new(0), fn item, acc ->
      Decimal.add(acc, item.subtotal)
    end)
  end

  defp search_products(query, organization_id) do
    # Search for products that match the query
    from(s in Aipos.ProductSkus.ProductSku,
      join: p in assoc(s, :product),
      where:
        (ilike(s.name, ^"%#{query}%") or ilike(p.name, ^"%#{query}%") or
           ilike(s.barcode, ^"%#{query}%")) and s.organization_id == ^organization_id,
      preload: [:product],
      limit: 10
    )
    |> Aipos.Repo.all()
  end

  # Function to update stock quantity after a sale
  defp update_stock_quantity(sku_id, quantity) do
    sku = ProductSkus.get_product_sku!(sku_id)
    new_quantity = sku.stock_quantity - quantity

    new_quantity = if new_quantity < 0, do: 0, else: new_quantity

    ProductSkus.update_product_sku(sku, %{stock_quantity: new_quantity})
  end

  defp format_money(amount) when is_number(amount) do
    :erlang.float_to_binary(amount, decimals: 2)
  end

  defp format_money(%Decimal{} = amount) do
    Decimal.to_string(amount, :normal)
  end

  defp format_money(_), do: "0.00"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-gray-100" id="sale-container" phx-hook="BarcodeScanner">
      <.live_component
        module={AiposWeb.Sidebar}
        id="sidebar"
        current_user={@current_user}
        current_organization={@current_organization}
        active_page={@active_page}
      />

      <%= if !@session_started do %>
        <div class="flex-1 pl-64 flex items-center justify-center">
          <div class="max-w-md w-full px-6">
            <div class="text-center mb-10">
              <h2 class="text-2xl font-bold text-gray-900">Start a Sale Session</h2>
              <p class="mt-2 text-gray-600">Select a register to begin</p>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <%= for register <- @registers do %>
                <button
                  type="button"
                  phx-click="select_register"
                  phx-value-id={register.id}
                  disabled={register.status != "available"}
                  class={"p-6 text-center rounded-lg shadow #{if register.status == "available", do: "bg-white hover:bg-gray-50", else: "bg-gray-100 opacity-60 cursor-not-allowed"}"}
                >
                  <div class="font-semibold text-lg">{register.name}</div>
                  <div class={"text-sm mt-2 rounded-full px-2 py-1 inline-block #{if register.status == "available", do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800"}"}>
                    {String.capitalize(register.status)}
                  </div>
                </button>
              <% end %>
            </div>
          </div>
        </div>
      <% else %>
        <div class="flex-1 pl-64 flex flex-col">
          <header class="bg-white shadow">
            <div class="px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
              <div>
                <h1 class="text-xl font-bold tracking-tight text-gray-900">
                  Sale - {@selected_register.name}
                </h1>
                <p class="text-sm text-gray-500">
                  Cashier: {@current_user.email}
                </p>
              </div>

              <div class="flex items-center space-x-4">
                <div class="flex items-center">
                  <div class={"w-3 h-3 rounded-full mr-2 #{if @scanner_connected, do: "bg-green-500", else: "bg-red-500"}"}>
                  </div>
                  <span class="text-sm text-gray-600">
                    Scanner: {if @scanner_connected, do: "Connected", else: "Disconnected"}
                  </span>
                </div>

                <button
                  type="button"
                  phx-click="toggle_scanner_mode"
                  class={"px-3 py-1 text-xs rounded-full #{if @scanning_mode == :external, do: "bg-blue-100 text-blue-800", else: "bg-gray-100 text-gray-800"}"}
                >
                  <%= if @scanning_mode == :external do %>
                    <Heroicons.icon name="computer-desktop" class="h-3 w-3 inline" /> External Scanner
                  <% else %>
                    <Heroicons.icon name="command-line" class="h-3 w-3 inline" /> Manual Entry
                  <% end %>
                </button>

                <%= if @drawer_opened do %>
                  <span class="text-xs bg-yellow-100 text-yellow-800 rounded-full px-3 py-1">
                    <Heroicons.icon name="exclamation-triangle" class="h-3 w-3 inline" /> Drawer Open
                  </span>
                <% end %>
              </div>
            </div>
          </header>

          <div class="flex-1 flex">
            <!-- Left side - Cart -->
            <div class="w-2/3 p-4 flex flex-col">
              <div class="bg-white rounded-lg shadow flex-1 flex flex-col overflow-hidden">
                <!-- Customer info -->
                <div class="p-4 border-b border-gray-200 flex justify-between items-center">
                  <div>
                    <%= if @customer do %>
                      <div class="flex items-center">
                        <div class="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                          <Heroicons.icon name="user" class="h-6 w-6 text-blue-600" />
                        </div>
                        <div class="ml-3">
                          <div class="font-medium">{@customer.name}</div>
                          <div class="text-sm text-gray-500">{@customer.phone}</div>
                        </div>
                      </div>
                    <% else %>
                      <div class="flex items-center text-gray-500">
                        <Heroicons.icon name="user" class="h-5 w-5 mr-2" />
                        <span>No customer selected</span>
                      </div>
                    <% end %>
                  </div>

                  <button
                    type="button"
                    phx-click="show_customer_search"
                    class="text-sm text-blue-600 hover:text-blue-800"
                  >
                    {if @customer, do: "Change", else: "Add Customer"}
                  </button>
                </div>
                
    <!-- Cart items -->
                <div class="flex-1 overflow-y-auto p-4">
                  <%= if Enum.empty?(@cart_items) do %>
                    <div class="h-full flex flex-col items-center justify-center text-gray-400">
                      <Heroicons.icon name="shopping-cart" class="h-16 w-16 mb-4" />
                      <p class="text-lg">Cart is empty</p>
                      <p class="text-sm mt-2">Add items by scanning a barcode or searching</p>
                    </div>
                  <% else %>
                    <table class="min-w-full divide-y divide-gray-200">
                      <thead>
                        <tr>
                          <th
                            scope="col"
                            class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                          >
                            Item
                          </th>
                          <th
                            scope="col"
                            class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
                          >
                            Price
                          </th>
                          <th
                            scope="col"
                            class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
                          >
                            Quantity
                          </th>
                          <th
                            scope="col"
                            class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                          >
                            Subtotal
                          </th>
                          <th
                            scope="col"
                            class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                          >
                          </th>
                        </tr>
                      </thead>
                      <tbody class="bg-white divide-y divide-gray-200">
                        <%= for {item, index} <- Enum.with_index(@cart_items) do %>
                          <tr>
                            <td class="px-4 py-4 whitespace-nowrap">
                              <div class="flex items-center">
                                <%= if item.image do %>
                                  <div class="flex-shrink-0 h-10 w-10 mr-3">
                                    <img
                                      class="h-10 w-10 rounded-full object-cover"
                                      src={item.image}
                                      alt={item.name}
                                    />
                                  </div>
                                <% end %>
                                <div>
                                  <div class="text-sm font-medium text-gray-900">{item.name}</div>
                                  <div class="text-xs text-gray-500">{item.product_name}</div>
                                  <div class="text-xs text-gray-500">{item.barcode}</div>
                                </div>
                              </div>
                            </td>
                            <td class="px-4 py-4 whitespace-nowrap text-center text-sm text-gray-500">
                              KSh {format_money(item.price)}
                            </td>
                            <td class="px-4 py-4 whitespace-nowrap">
                              <div class="flex items-center justify-center">
                                <button
                                  type="button"
                                  phx-click="update_quantity"
                                  phx-value-index={index}
                                  phx-value-quantity={max(1, item.quantity - 1)}
                                  class="p-1 rounded-full text-gray-400 hover:text-gray-500"
                                >
                                  <Heroicons.icon name="minus" class="h-4 w-4" />
                                </button>
                                <span class="mx-2 text-sm text-gray-900 w-8 text-center">
                                  {item.quantity}
                                </span>
                                <button
                                  type="button"
                                  phx-click="update_quantity"
                                  phx-value-index={index}
                                  phx-value-quantity={item.quantity + 1}
                                  class="p-1 rounded-full text-gray-400 hover:text-gray-500"
                                >
                                  <Heroicons.icon name="plus" class="h-4 w-4" />
                                </button>
                              </div>
                            </td>
                            <td class="px-4 py-4 whitespace-nowrap text-right text-sm text-gray-900">
                              KSh {format_money(item.subtotal)}
                            </td>
                            <td class="px-4 py-4 whitespace-nowrap text-right text-sm font-medium">
                              <button
                                type="button"
                                phx-click="remove_item"
                                phx-value-index={index}
                                class="text-red-600 hover:text-red-900"
                              >
                                <Heroicons.icon name="trash" class="h-4 w-4" />
                              </button>
                            </td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  <% end %>
                </div>
                
    <!-- Cart totals -->
                <div class="p-4 border-t border-gray-200 bg-gray-50">
                  <div class="flex justify-between items-center mb-4">
                    <div class="text-lg font-medium">Total</div>
                    <div class="text-xl font-bold">KSh {format_money(@total_amount)}</div>
                  </div>

                  <div class="flex space-x-2">
                    <button
                      type="button"
                      phx-click="reset_sale"
                      class="flex-1 py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                    >
                      <Heroicons.icon name="trash" class="h-4 w-4 inline mr-1" /> Clear Cart
                    </button>
                    <button
                      type="button"
                      phx-click="show_payment_modal"
                      disabled={Enum.empty?(@cart_items)}
                      class={"flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 #{if Enum.empty?(@cart_items), do: "opacity-50 cursor-not-allowed", else: ""}"}
                    >
                      <Heroicons.icon name="credit-card" class="h-4 w-4 inline mr-1" /> Pay Now
                    </button>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Right side - Barcode entry and product search -->
            <div class="w-1/3 p-4 space-y-4">
              <!-- Barcode entry -->
              <div class="bg-white rounded-lg shadow p-4">
                <h2 class="text-lg font-medium mb-4">Scan Barcode</h2>

                <form phx-submit="add_item" class="flex space-x-2 mb-4">
                  <input
                    type="text"
                    name="barcode"
                    value={@barcode}
                    placeholder="Enter barcode..."
                    phx-keyup="validate_barcode"
                    phx-key="keyup"
                    class="flex-1 shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    autofocus={@scanning_mode == :manual}
                  />
                  <button
                    type="submit"
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
                  >
                    Add
                  </button>
                </form>

                <%= if @scanning_mode == :external do %>
                  <div class="text-xs text-gray-500 italic">
                    <Heroicons.icon name="information-circle" class="h-4 w-4 inline mr-1" />
                    Using external scanner mode. Make sure your scanner is connected.
                  </div>
                <% else %>
                  <div class="text-xs text-gray-500 italic">
                    <Heroicons.icon name="information-circle" class="h-4 w-4 inline mr-1" />
                    Enter the barcode manually and press Enter or click Add.
                  </div>
                <% end %>
              </div>
              
    <!-- Product search -->
              <div class="bg-white rounded-lg shadow p-4">
                <h2 class="text-lg font-medium mb-4">Search Products</h2>

                <div class="mb-4">
                  <input
                    type="text"
                    placeholder="Search by name or barcode..."
                    value={@search_query}
                    phx-keyup="search_products"
                    phx-key="keyup"
                    phx-debounce="300"
                    class="shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>

                <%= if !Enum.empty?(@search_results) do %>
                  <div class="space-y-2 max-h-72 overflow-y-auto">
                    <%= for product_sku <- @search_results do %>
                      <div class="border border-gray-200 rounded-md p-2 flex justify-between items-center">
                        <div class="flex items-center">
                          <%= if product_sku.image do %>
                            <div class="flex-shrink-0 h-10 w-10 mr-3">
                              <img
                                class="h-10 w-10 rounded-full object-cover"
                                src={product_sku.image}
                                alt={product_sku.name}
                              />
                            </div>
                          <% end %>
                          <div>
                            <div class="text-sm font-medium">{product_sku.name}</div>
                            <div class="text-xs text-gray-500">
                              <%= if product_sku.product do %>
                                {product_sku.product.name}
                              <% end %>
                            </div>
                            <div class="text-xs text-gray-500">
                              KSh {format_money(product_sku.price)}
                            </div>
                          </div>
                        </div>
                        <button
                          type="button"
                          phx-click="add_from_search"
                          phx-value-id={product_sku.id}
                          class="px-3 py-1 text-xs font-medium text-blue-600 hover:text-blue-800"
                        >
                          Add to Cart
                        </button>
                      </div>
                    <% end %>
                  </div>
                <% else %>
                  <%= if String.length(@search_query) >= 2 do %>
                    <div class="text-center py-4 text-gray-500">
                      No products found matching "{@search_query}"
                    </div>
                  <% end %>
                <% end %>
              </div>
              
    <!-- Quick actions -->
              <div class="bg-white rounded-lg shadow p-4">
                <h2 class="text-lg font-medium mb-4">Quick Actions</h2>

                <div class="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    phx-click="reset_sale"
                    class="py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                  >
                    <Heroicons.icon name="trash" class="h-4 w-4 inline mr-1" /> Clear
                  </button>
                  <button
                    type="button"
                    phx-click="show_customer_search"
                    class="py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                  >
                    <Heroicons.icon name="user" class="h-4 w-4 inline mr-1" /> Customer
                  </button>
                  <button
                    type="button"
                    disabled
                    class="py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-400 bg-gray-100 cursor-not-allowed"
                  >
                    <Heroicons.icon name="calculator" class="h-4 w-4 inline mr-1" /> Discount
                  </button>
                  <button
                    type="button"
                    phx-click="show_payment_modal"
                    disabled={Enum.empty?(@cart_items)}
                    class={"py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 #{if Enum.empty?(@cart_items), do: "opacity-50 cursor-not-allowed", else: ""}"}
                  >
                    <Heroicons.icon name="banknotes" class="h-4 w-4 inline mr-1" /> Pay
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Customer search modal -->
      <%= if @show_customer_search do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 z-50 flex items-center justify-center">
          <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-semibold">Find Customer</h2>
              <button
                type="button"
                phx-click="hide_customer_search"
                class="text-gray-400 hover:text-gray-500"
              >
                <Heroicons.icon name="x-mark" class="h-6 w-6" />
              </button>
            </div>

            <form phx-submit="search_customer" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700">Phone Number</label>
                <div class="mt-1">
                  <input
                    type="text"
                    name="phone"
                    value={@customer_phone}
                    placeholder="Enter customer phone..."
                    class="shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    required
                  />
                </div>
                <p class="mt-1 text-xs text-gray-500">
                  For demo, use 123456789 to find a sample customer
                </p>
              </div>

              <div class="flex justify-end">
                <button
                  type="button"
                  phx-click="hide_customer_search"
                  class="mr-2 inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="inline-flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
                >
                  Search
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
    <!-- Payment modal -->
      <%= if @show_payment_modal do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 z-50 flex items-center justify-center">
          <div class="bg-white rounded-lg shadow-xl max-w-lg w-full p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-semibold">Complete Payment</h2>
              <button
                type="button"
                phx-click="hide_payment_modal"
                class="text-gray-400 hover:text-gray-500"
              >
                <Heroicons.icon name="x-mark" class="h-6 w-6" />
              </button>
            </div>

            <div class="mb-6">
              <div class="flex justify-between mb-2">
                <span class="text-gray-500">Total Items:</span>
                <span>{Enum.count(@cart_items)}</span>
              </div>
              <div class="flex justify-between mb-2">
                <span class="text-gray-500">Total Amount:</span>
                <span class="font-semibold">KSh {format_money(@total_amount)}</span>
              </div>
            </div>

            <div class="mb-6">
              <label class="block text-sm font-medium text-gray-700 mb-1">Payment Method</label>
              <div class="grid grid-cols-3 gap-2">
                <button
                  type="button"
                  phx-click="update_payment_method"
                  phx-value-method="cash"
                  class={"py-2 px-4 border rounded-md text-sm font-medium #{if @payment_method == "cash", do: "border-blue-500 bg-blue-50 text-blue-700", else: "border-gray-300 text-gray-700 hover:bg-gray-50"}"}
                >
                  <Heroicons.icon name="banknotes" class="h-4 w-4 inline mr-1" /> Cash
                </button>
                <button
                  type="button"
                  phx-click="update_payment_method"
                  phx-value-method="card"
                  class={"py-2 px-4 border rounded-md text-sm font-medium #{if @payment_method == "card", do: "border-blue-500 bg-blue-50 text-blue-700", else: "border-gray-300 text-gray-700 hover:bg-gray-50"}"}
                >
                  <Heroicons.icon name="credit-card" class="h-4 w-4 inline mr-1" /> Card
                </button>
                <button
                  type="button"
                  phx-click="update_payment_method"
                  phx-value-method="mpesa"
                  class={"py-2 px-4 border rounded-md text-sm font-medium #{if @payment_method == "mpesa", do: "border-blue-500 bg-blue-50 text-blue-700", else: "border-gray-300 text-gray-700 hover:bg-gray-50"}"}
                >
                  <Heroicons.icon name="device-phone-mobile" class="h-4 w-4 inline mr-1" /> M-Pesa
                </button>
              </div>
            </div>

            <%= if @payment_method == "cash" do %>
              <div class="mb-6">
                <label class="block text-sm font-medium text-gray-700 mb-1">Amount Tendered</label>
                <div class="mt-1 relative rounded-md shadow-sm">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <span class="text-gray-500 sm:text-sm">KSh</span>
                  </div>
                  <input
                    type="number"
                    min={Decimal.to_float(@total_amount)}
                    step="0.01"
                    phx-change="update_amount_tendered"
                    phx-debounce="300"
                    value={@amount_tendered}
                    name="amount"
                    class="focus:ring-blue-500 focus:border-blue-500 block w-full pl-12 pr-12 sm:text-sm border-gray-300 rounded-md"
                  />
                </div>

                <%= if @amount_tendered > 0 && @amount_tendered >= Decimal.to_float(@total_amount) do %>
                  <div class="mt-2 flex justify-between text-sm">
                    <span class="text-gray-500">Change Due:</span>
                    <span class="font-semibold text-green-600">KSh {format_money(@change_due)}</span>
                  </div>
                <% end %>
                
    <!-- Quick amount buttons -->
                <div class="mt-3 grid grid-cols-4 gap-2">
                  <%= for amount <- [50, 100, 200, 500, 1000, 2000, 5000, "Exact"] do %>
                    <button
                      type="button"
                      phx-click="update_amount_tendered"
                      phx-value-amount={
                        if amount == "Exact", do: Decimal.to_float(@total_amount), else: amount
                      }
                      class="py-1 px-2 border border-gray-300 rounded-md text-xs font-medium text-gray-700 hover:bg-gray-50"
                    >
                      {if amount == "Exact", do: "Exact", else: "KSh #{amount}"}
                    </button>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= if @payment_method == "mpesa" do %>
              <div class="mb-6 bg-yellow-50 border border-yellow-200 rounded-md p-4 text-sm text-yellow-700">
                <p class="flex items-center">
                  <Heroicons.icon name="information-circle" class="h-5 w-5 mr-2 text-yellow-500" />
                  <span>
                    M-Pesa integration would be implemented here. For demo purposes, we'll simulate a successful payment.
                  </span>
                </p>
              </div>
            <% end %>

            <%= if @payment_method == "card" do %>
              <div class="mb-6 bg-yellow-50 border border-yellow-200 rounded-md p-4 text-sm text-yellow-700">
                <p class="flex items-center">
                  <Heroicons.icon name="information-circle" class="h-5 w-5 mr-2 text-yellow-500" />
                  <span>
                    Card payment integration would be implemented here. For demo purposes, we'll simulate a successful payment.
                  </span>
                </p>
              </div>
            <% end %>

            <div class="flex justify-end">
              <button
                type="button"
                phx-click="hide_payment_modal"
                class="mr-2 inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="button"
                phx-click="complete_sale"
                disabled={
                  @payment_method == "cash" && @amount_tendered < Decimal.to_float(@total_amount)
                }
                class={"inline-flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700 #{if @payment_method == "cash" && @amount_tendered < Decimal.to_float(@total_amount), do: "opacity-50 cursor-not-allowed", else: ""}"}
              >
                Complete Sale
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end

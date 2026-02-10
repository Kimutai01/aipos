defmodule AiposWeb.Live.SelfCheckout do
  use AiposWeb, :live_view
  alias Aipos.Products
  alias Aipos.Sales
  alias Aipos.Paystack

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:cart_items, [])
      |> assign(:total_amount, 0)
      |> assign(:barcode, "")
      |> assign(:scanner_connected, false)
      |> assign(:search_query, "")
      |> assign(:search_results, [])
      |> assign(:show_payment_modal, false)
      |> assign(:payment_method, "mpesa")
      |> assign(:payment_phone, "")
      |> assign(:payment_status, nil)
      |> assign(:payment_processing, false)
      |> assign(:receipt_number, nil)
      |> assign(:transaction_id, nil)
      |> assign(:payment_error, nil)
      |> allow_upload(:product_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)

    if connected?(socket), do: Process.send_after(self(), :check_scanner, 1000)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, handle_payment_callback(socket, params)}
  end

  defp handle_payment_callback(socket, %{"payment_status" => "success", "transaction_id" => transaction_id}) do
    # Verify transaction with Paystack
    case Paystack.verify_transaction(transaction_id) do
      {:ok, %{"status" => "success"}} ->
        case Sales.get_sale_by_transaction_id(transaction_id) do
          nil ->
            socket
            |> put_flash(:error, "Sale not found")

          sale ->
            # Update sale status
            {:ok, _updated_sale} = Sales.update_sale(sale, %{status: "completed"})

            socket
            |> assign(:payment_status, "success")
            |> assign(:receipt_number, transaction_id)
            |> assign(:show_payment_modal, true)
            |> assign(:payment_processing, false)
            |> put_flash(:info, "Payment successful! Your receipt number is #{transaction_id}")
        end

      {:ok, %{"status" => status}} ->
        socket
        |> assign(:payment_status, "failed")
        |> assign(:payment_processing, false)
        |> put_flash(:error, "Payment verification failed. Status: #{status}")

      {:error, reason} ->
        socket
        |> assign(:payment_status, "failed")
        |> assign(:payment_processing, false)
        |> put_flash(:error, "Payment verification error: #{reason}")
    end
  end

  defp handle_payment_callback(socket, _params), do: socket

  @impl true
  def handle_event("add_item", %{"barcode" => barcode}, socket) do
    case find_product_by_barcode(barcode) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Product not found for barcode: #{barcode}")
         |> assign(:barcode, "")}

      product ->
        cart_items = add_to_cart(socket.assigns.cart_items, product)
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
        search_products(query)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, results)}
  end

  def handle_event("add_from_search", %{"id" => id}, socket) do
    product = Products.get_product_sku!(id)
    cart_items = add_to_cart(socket.assigns.cart_items, product)
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
        %{item | quantity: quantity, subtotal: item.price * quantity}
      end)

    total = calculate_total(cart_items)

    {:noreply,
     socket
     |> assign(:cart_items, cart_items)
     |> assign(:total_amount, total)}
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

  def handle_event("update_payment_phone", %{"phone" => phone}, socket) do
    {:noreply, assign(socket, :payment_phone, phone)}
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

  def handle_event("process_payment", _, socket) do
    transaction_id = "SCO-#{:os.system_time(:millisecond)}"
    
    # Create pending sale first
    sale_params = %{
      total_amount: Decimal.new("#{socket.assigns.total_amount}"),
      payment_method: socket.assigns.payment_method,
      amount_tendered: Decimal.new("#{socket.assigns.total_amount}"),
      change_due: Decimal.new(0),
      status: "pending_payment",
      transaction_id: transaction_id,
      organization_id: 1  # Self-checkout - use default organization or get from config
    }

    case Aipos.Sales.create_sale(sale_params) do
      {:ok, sale} ->
        # Create sale items
        Enum.each(socket.assigns.cart_items, fn item ->
          item_params = %{
            sale_id: sale.id,
            product_sku_id: item.id,
            name: item.name,
            quantity: item.quantity,
            price: Decimal.new("#{item.price}"),
            subtotal: Decimal.new("#{item.subtotal}"),
            organization_id: 1
          }

          {:ok, _sale_item} = Aipos.Sales.create_sale_item(item_params)
        end)

        # Initialize Paystack payment
        email = if socket.assigns.payment_phone != "" do
          socket.assigns.payment_phone <> "@aipos.local"
        else
          "customer@aipos.local"
        end
        
        callback_url = "#{AiposWeb.Endpoint.url()}/self_checkout?payment_status=success&transaction_id=#{transaction_id}"

        case Paystack.initialize(email, Decimal.new("#{socket.assigns.total_amount}"), transaction_id, callback_url) do
          {:ok, %{"authorization_url" => authorization_url}} ->
            {:noreply,
             socket
             |> assign(:payment_processing, true)
             |> assign(:transaction_id, transaction_id)
             |> redirect(external: authorization_url)}

          {:error, error} ->
            # Delete the pending sale if payment initialization fails
            Sales.delete_sale(sale)

            {:noreply,
             socket
             |> assign(:payment_processing, false)
             |> assign(:payment_error, "Failed to initialize payment: #{error}")
             |> put_flash(:error, "Failed to initialize payment: #{error}")}
        end

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
        error_message = "Error creating sale: #{inspect(errors)}"

        {:noreply,
         socket
         |> assign(:payment_processing, false)
         |> put_flash(:error, error_message)}
    end
  end

  def handle_event("reset_sale", _, socket) do
    {:noreply,
     socket
     |> assign(:cart_items, [])
     |> assign(:total_amount, 0)
     |> assign(:payment_status, nil)
     |> assign(:receipt_number, nil)
     |> assign(:payment_processing, false)
     |> assign(:show_payment_modal, false)}
  end

  def handle_event("upload_receipt_image", _, socket) do
    # Process the receipt image upload
    uploaded_files =
      consume_uploaded_entries(socket, :product_image, fn %{path: path}, entry ->
        dest = Path.join(["priv", "static", "uploads", Path.basename(path)])
        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    # In a real app, you would save this image path with the receipt
    {:noreply, socket}
  end

  @impl true
  def handle_info(:check_scanner, socket) do
    # In a real app, you might check for connected scanners
    # For now, we'll just trigger the JS hook
    {:noreply, push_event(socket, "check_scanner", %{})}
  end

  @impl true
  def handle_info({:payment_processed, success, receipt_number}, socket) do
    socket =
      socket
      |> assign(:payment_processing, false)

    socket =
      if success do
        socket
        |> assign(:payment_status, "success")
        |> assign(:receipt_number, receipt_number)
      else
        socket
        |> assign(:payment_status, "failed")
      end

    {:noreply, socket}
  end

  defp find_product_by_barcode(barcode) do
    # Placeholder - replace with actual implementation
    case barcode do
      "1234567890" ->
        %{id: 1, name: "Sunlight Soap 500g", barcode: "1234567890", price: 120, image: nil}

      "2345678901" ->
        %{id: 2, name: "Bread", barcode: "2345678901", price: 50, image: nil}

      "3456789012" ->
        %{id: 3, name: "Milk 500ml", barcode: "3456789012", price: 70, image: nil}

      _ ->
        nil
    end
  end

  defp add_to_cart(cart_items, product) do
    # Check if item already exists in cart
    case Enum.find_index(cart_items, &(&1.id == product.id)) do
      nil ->
        # Add new item to cart
        cart_item = %{
          id: product.id,
          name: product.name,
          barcode: product.barcode,
          price: product.price,
          quantity: 1,
          subtotal: product.price
        }

        cart_items ++ [cart_item]

      index ->
        # Increment quantity of existing item
        List.update_at(cart_items, index, fn item ->
          new_quantity = item.quantity + 1
          %{item | quantity: new_quantity, subtotal: item.price * new_quantity}
        end)
    end
  end

  defp calculate_total(cart_items) do
    Enum.reduce(cart_items, 0, fn item, acc -> acc + item.subtotal end)
  end

  defp search_products(query) do
    # Placeholder - replace with actual implementation
    [
      %{id: 1, name: "Sunlight Soap 500g", barcode: "1234567890", price: 120, image: nil},
      %{id: 2, name: "Bread", barcode: "2345678901", price: 50, image: nil},
      %{id: 3, name: "Milk 500ml", barcode: "3456789012", price: 70, image: nil}
    ]
    |> Enum.filter(&String.contains?(String.downcase(&1.name), String.downcase(query)))
  end

  defp format_money(amount) do
    :erlang.float_to_binary(amount / 1, decimals: 2)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100" id="self-checkout-container" phx-hook="BarcodeScanner">
      <!-- Header -->
      <header class="bg-white shadow">
        <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <!-- Replace with your actual logo -->
              <div class="h-10 w-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold text-xl">
                S
              </div>
              <h1 class="ml-3 text-xl font-bold tracking-tight text-gray-900">Self-Checkout</h1>
            </div>

            <div class="flex items-center space-x-4">
              <div class="flex items-center">
                <div class={"w-3 h-3 rounded-full mr-2 #{if @scanner_connected, do: "bg-green-500", else: "bg-red-500"}"}>
                </div>
                <span class="text-sm text-gray-600">
                  Scanner:
                  <%= if @scanner_connected  do %>
                    Connected
                  <% else %>
                    Disconnected
                  <% end %>
                </span>
              </div>

              <a href="/" class="text-sm text-blue-600 hover:text-blue-800">
                <Heroicons.icon name="arrow-left" class="h-4 w-4 inline mr-1" /> Back to Home
              </a>
            </div>
          </div>
        </div>
      </header>
      
    <!-- Main Content -->
      <main class="mx-auto max-w-7xl py-6 px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col md:flex-row gap-6">
          <!-- Left Side - Cart -->
          <div class="w-full md:w-2/3 space-y-6">
            <!-- Cart Panel -->
            <div class="bg-white rounded-lg shadow overflow-hidden">
              <div class="p-4 bg-blue-50 border-b border-blue-100">
                <h2 class="text-lg font-medium text-blue-800">Your Shopping Cart</h2>
              </div>
              
    <!-- Cart Items -->
              <div class="p-4">
                <%= if Enum.empty?(@cart_items) do %>
                  <div class="h-40 flex flex-col items-center justify-center text-gray-400">
                    <Heroicons.icon name="shopping-cart" class="h-16 w-16 mb-4" />
                    <p class="text-lg">Your cart is empty</p>
                    <p class="text-sm mt-2">Scan items or search to add products</p>
                  </div>
                <% else %>
                  <div class="overflow-x-auto">
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
                              <div class="text-sm font-medium text-gray-900">{item.name}</div>
                              <div class="text-xs text-gray-500">{item.barcode}</div>
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
                  </div>
                  
    <!-- Total and Checkout Button -->
                  <div class="mt-6 border-t border-gray-200 pt-4">
                    <div class="flex justify-between items-center mb-4">
                      <div class="text-lg font-medium">Total</div>
                      <div class="text-2xl font-bold">KSh {format_money(@total_amount)}</div>
                    </div>

                    <div class="flex justify-end space-x-4">
                      <button
                        type="button"
                        phx-click="reset_sale"
                        class="py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                      >
                        Clear Cart
                      </button>
                      <button
                        type="button"
                        phx-click="show_payment_modal"
                        class="py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                      >
                        Proceed to Checkout
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          
    <!-- Right Side - Product Search & Barcode Scanning -->
          <div class="w-full md:w-1/3 space-y-6">
            <!-- Barcode Scanning -->
            <div class="bg-white rounded-lg shadow p-4">
              <h2 class="text-lg font-medium mb-4">Scan Barcode</h2>

              <form phx-submit="add_item" class="mb-4">
                <div class="flex space-x-2">
                  <input
                    type="text"
                    name="barcode"
                    value={@barcode}
                    placeholder="Enter barcode..."
                    phx-keyup="validate_barcode"
                    phx-key="keyup"
                    class="flex-1 shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    autofocus
                  />
                  <button
                    type="submit"
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
                  >
                    Add
                  </button>
                </div>
              </form>

              <div class="text-xs text-gray-500 italic">
                <Heroicons.icon name="information-circle" class="h-4 w-4 inline mr-1" />
                Enter the barcode manually or use a scanner.
              </div>
            </div>
            
    <!-- Product Search -->
            <div class="bg-white rounded-lg shadow p-4">
              <h2 class="text-lg font-medium mb-4">Search Products</h2>

              <div class="mb-4">
                <input
                  type="text"
                  name="query"
                  placeholder="Search by name..."
                  value={@search_query}
                  phx-keyup="search_products"
                  phx-key="keyup"
                  phx-debounce="300"
                  class="shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border-gray-300 rounded-md"
                />
              </div>

              <%= if !Enum.empty?(@search_results) do %>
                <div class="space-y-2 max-h-72 overflow-y-auto">
                  <%= for product <- @search_results do %>
                    <div class="border border-gray-200 rounded-md p-2 flex justify-between items-center">
                      <div>
                        <div class="text-sm font-medium">{product.name}</div>
                        <div class="text-xs text-gray-500">KSh {format_money(product.price)}</div>
                      </div>
                      <button
                        type="button"
                        phx-click="add_from_search"
                        phx-value-id={product.id}
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
            
    <!-- Help Section -->
            <div class="bg-white rounded-lg shadow p-4">
              <h2 class="text-lg font-medium mb-2">Need Help?</h2>
              <p class="text-sm text-gray-600 mb-4">
                If you're having trouble finding items or using the self-checkout,
                please call a store associate for assistance.
              </p>
              <button
                type="button"
                class="py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 w-full"
              >
                <Heroicons.icon name="phone" class="h-4 w-4 inline mr-1" /> Call for Assistance
              </button>
            </div>
          </div>
        </div>
      </main>
      
    <!-- Payment Modal -->
      <%= if @show_payment_modal do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 z-50 flex items-center justify-center">
          <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-semibold">Complete Payment</h2>
              <%= if !@payment_processing && @payment_status != "success" do %>
                <button
                  type="button"
                  phx-click="hide_payment_modal"
                  class="text-gray-400 hover:text-gray-500"
                >
                  <Heroicons.icon name="x-mark" class="h-6 w-6" />
                </button>
              <% end %>
            </div>

            <%= if @payment_status == "success" do %>
              <!-- Payment Success -->
              <div class="text-center py-6">
                <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100">
                  <Heroicons.icon name="check" class="h-6 w-6 text-green-600" />
                </div>
                <h3 class="mt-3 text-lg font-medium text-gray-900">Payment Successful</h3>
                <p class="mt-2 text-sm text-gray-500">
                  Thank you for your purchase. Your receipt number is:
                </p>
                <p class="mt-1 text-lg font-bold text-gray-800">{@receipt_number}</p>

                <div class="mt-6">
                  <button
                    type="button"
                    phx-click="reset_sale"
                    class="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700"
                  >
                    Done
                  </button>
                </div>
              </div>
            <% else %>
              <%= if @payment_processing do %>
                <!-- Payment Processing -->
                <div class="text-center py-10">
                  <div class="flex justify-center">
                    <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600"></div>
                  </div>
                  <p class="mt-4 text-sm text-gray-500">
                    Processing payment, please wait...
                  </p>
                </div>
              <% else %>
                <!-- Payment Form -->
                <div class="mb-6">
                  <div class="flex justify-between mb-2">
                    <span class="text-gray-500">Total Items:</span>
                    <span>{Enum.count(@cart_items)}</span>
                  </div>
                  <div class="flex justify-between mb-6">
                    <span class="text-gray-500">Total Amount:</span>
                    <span class="font-semibold">KSh {format_money(@total_amount)}</span>
                  </div>

                  <div class="mb-6">
                    <label class="block text-sm font-medium text-gray-700 mb-1">Payment Method</label>
                    <div class="grid grid-cols-2 gap-2">
                      <button
                        type="button"
                        phx-click="update_payment_method"
                        phx-value-method="mpesa"
                        class={"py-2 px-4 border rounded-md text-sm font-medium #{if @payment_method == "mpesa", do: "border-blue-500 bg-blue-50 text-blue-700", else: "border-gray-300 text-gray-700 hover:bg-gray-50"}"}
                      >
                        <Heroicons.icon name="device-phone-mobile" class="h-4 w-4 inline mr-1" />
                        M-Pesa
                      </button>
                      <button
                        type="button"
                        phx-click="update_payment_method"
                        phx-value-method="card"
                        class={"py-2 px-4 border rounded-md text-sm font-medium #{if @payment_method == "card", do: "border-blue-500 bg-blue-50 text-blue-700" , else: "border-gray-300 text-gray-700 hover:bg-gray-50"}"}
                      >
                        <Heroicons.icon name="credit-card" class="h-4 w-4 inline mr-1" /> Card
                      </button>
                    </div>
                  </div>

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
                      phx-click="process_payment"
                      class="inline-flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
                    >
                      Pay Now
                    </button>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end

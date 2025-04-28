defmodule AiposWeb.UssdMarketplaceController do
  use AiposWeb, :controller
  alias Aipos.AfricasTalking
  alias Aipos.Organizations
  alias Aipos.Products
  alias Aipos.ProductSkus
  alias Aipos.Sales
  alias Aipos.Repo

  # Define a module attribute for shipping cost
  @shipping_cost Decimal.new("250.00")

  # Define the cache name
  @cache_name :ussd_session_cache

  def handle_ussd(conn, params) do
    %{
      "sessionId" => session_id,
      "serviceCode" => _service_code,
      "phoneNumber" => phone_number,
      "text" => text
    } = params

    IO.inspect(params, label: "USSD Request Params")

    # Get or initialize session data for the current USSD session
    session_data = get_session_data(session_id, phone_number)

    # Process the USSD input based on current text and session data
    {response, updated_session} = process_ussd_input(text, session_data)

    # Save the updated session data
    save_session_data(session_id, updated_session)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, response)
  end

  # Initialize or retrieve session data for the USSD session using Cachex
  defp get_session_data(session_id, phone_number) do
    # Create a cache key using the session_id
    cache_key = "ussd:#{session_id}"

    # Try to get the session data from Cachex
    case Cachex.get(@cache_name, cache_key) do
      {:ok, nil} ->
        # No data in cache, initialize new session
        %{
          phone_number: phone_number,
          selected_organization: nil,
          cart_items: [],
          total_amount: Decimal.new(0),
          customer: %{
            name: "",
            phone: phone_number
          },
          payment_method: nil
        }

      {:ok, session_data} ->
        # Session data found in cache
        session_data

      {:error, error} ->
        # Log error but still provide a new session
        IO.puts("Error retrieving from cache: #{inspect(error)}")

        %{
          phone_number: phone_number,
          selected_organization: nil,
          cart_items: [],
          total_amount: Decimal.new(0),
          customer: %{
            name: "",
            phone: phone_number
          },
          payment_method: nil
        }
    end
  end

  # Save session data to Cachex
  defp save_session_data(session_id, session_data) do
    cache_key = "ussd:#{session_id}"

    # Save to Cachex with a TTL of 5 minutes (300 seconds)
    # This ensures abandoned sessions will eventually be cleaned up
    Cachex.put(@cache_name, cache_key, session_data, ttl: :timer.seconds(300))
  end

  # Process USSD input based on the input text and current session state
  defp process_ussd_input(text, session_data) do
    IO.puts("Processing USSD input: '#{text}'")

    cond do
      # Main menu
      text == "" ->
        {main_menu(), session_data}

      # Organization selection
      text == "1" ->
        organizations = list_organizations()
        {org_selection_menu(organizations), session_data}

      # Organization was selected - matches pattern 1*X where X is a digit
      Regex.match?(~r/^1\*\d+$/, text) ->
        org_id = String.split(text, "*") |> List.last() |> String.to_integer()

        try do
          organization = Organizations.get_organization!(org_id)
          products = list_organization_products(organization.id)

          updated_session = Map.put(session_data, :selected_organization, organization)
          {product_selection_menu(products, organization.name), updated_session}
        rescue
          Ecto.NoResultsError ->
            {"END Invalid store selection. Please try again.", session_data}
        end

      # Product was selected - matches pattern 1*X*Y where X and Y are digits
      Regex.match?(~r/^1\*\d+\*\d+$/, text) ->
        [_, _org_id_str, product_id_str] = String.split(text, "*")
        product_id = String.to_integer(product_id_str)

        try do
          product_sku = ProductSkus.get_product_sku!(product_id) |> Repo.preload(:product)

          if product_sku.stock_quantity <= 0 do
            {"END Sorry, this product is out of stock. Please try again.", session_data}
          else
            updated_cart = add_to_cart(session_data.cart_items, product_sku)
            total = calculate_total(updated_cart)

            updated_session =
              session_data
              |> Map.put(:cart_items, updated_cart)
              |> Map.put(:total_amount, total)

            {quantity_menu(product_sku), updated_session}
          end
        rescue
          Ecto.NoResultsError ->
            {"END Invalid product selection. Please try again.", session_data}
        end

      # Quantity was selected - matches pattern 1*X*Y*Z where X, Y, and Z are digits
      Regex.match?(~r/^1\*\d+\*\d+\*\d+$/, text) ->
        [_, _, _, quantity_str] = String.split(text, "*")
        quantity = String.to_integer(quantity_str)

        # Get the last item in cart and update its quantity
        {last_item, other_items} = List.pop_at(session_data.cart_items, -1)

        if last_item do
          updated_item = %{
            last_item
            | quantity: quantity,
              subtotal: Decimal.mult(last_item.price, Decimal.new(quantity))
          }

          updated_cart = other_items ++ [updated_item]
          total = calculate_total(updated_cart)

          updated_session =
            session_data
            |> Map.put(:cart_items, updated_cart)
            |> Map.put(:total_amount, total)

          {cart_menu(updated_cart, total), updated_session}
        else
          {"END An error occurred. Please try again.", session_data}
        end

      # Checkout option selected after quantity was selected (direct cart option 1)
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1$/, text) ->
        if Enum.empty?(session_data.cart_items) do
          {"END Your cart is empty. Please add products before checkout.", session_data}
        else
          {checkout_menu(), session_data}
        end

      # Continue shopping option selected after quantity was selected (direct cart option 2)
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*2$/, text) ->
        if is_nil(session_data.selected_organization) do
          {"CON Please select a store first:\n" <> org_selection_menu(list_organizations()),
           session_data}
        else
          organization = session_data.selected_organization
          products = list_organization_products(organization.id)
          {product_selection_menu(products, organization.name), session_data}
        end

      # Clear cart option selected after quantity was selected (direct cart option 3)
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*3$/, text) ->
        updated_session =
          session_data
          |> Map.put(:cart_items, [])
          |> Map.put(:total_amount, Decimal.new(0))

        {"CON Cart cleared.\n\n" <> main_menu(), updated_session}

      # Further checkout flow after direct checkout (1*X*Y*Z*1*1)
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1\*1$/, text) ->
        {payment_method_menu(), session_data}

      # View cart via the dedicated cart menu option
      text == "1*0" ->
        {cart_menu(session_data.cart_items, session_data.total_amount), session_data}

      # Checkout from dedicated cart menu
      text == "1*0*1" ->
        if Enum.empty?(session_data.cart_items) do
          {"END Your cart is empty. Please add products before checkout.", session_data}
        else
          {checkout_menu(), session_data}
        end

      # Continue shopping from dedicated cart menu
      text == "1*0*2" ->
        if is_nil(session_data.selected_organization) do
          {"CON Please select a store first:\n" <> org_selection_menu(list_organizations()),
           session_data}
        else
          organization = session_data.selected_organization
          products = list_organization_products(organization.id)
          {product_selection_menu(products, organization.name), session_data}
        end

      # Clear cart from dedicated cart menu
      text == "1*0*3" ->
        updated_session =
          session_data
          |> Map.put(:cart_items, [])
          |> Map.put(:total_amount, Decimal.new(0))

        {"CON Cart cleared.\n\n" <> main_menu(), updated_session}

      # Payment method selection from dedicated cart menu checkout path
      text == "1*0*1*1" ->
        {payment_method_menu(), session_data}

      # Payment method selection from direct checkout path
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1\*1$/, text) ->
        {payment_method_menu(), session_data}

      # Pay now selected from dedicated cart menu path
      text == "1*0*1*1*1" ->
        updated_session = Map.put(session_data, :payment_method, "pay_now")
        {confirm_order_menu(updated_session), updated_session}

      # Pay on delivery selected from dedicated cart menu path
      text == "1*0*1*1*2" ->
        updated_session = Map.put(session_data, :payment_method, "pay_on_delivery")
        {confirm_order_menu(updated_session), updated_session}

      # Pay now selected from direct checkout path
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1\*1\*1$/, text) ->
        updated_session = Map.put(session_data, :payment_method, "pay_now")
        {confirm_order_menu(updated_session), updated_session}

      # Pay on delivery selected from direct checkout path
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1\*1\*2$/, text) ->
        updated_session = Map.put(session_data, :payment_method, "pay_on_delivery")
        {confirm_order_menu(updated_session), updated_session}

      # Cancel at confirmation screen
      text == "1*0*1*1*1*2" || text == "1*0*1*1*2*2" ||
        Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1\*1\*1\*2$/, text) ||
          Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1\*1\*2\*2$/, text) ->
        {cart_menu(session_data.cart_items, session_data.total_amount), session_data}

      # Order confirmation - Pay Now from dedicated cart path
      text == "1*0*1*1*1*1" ->
        process_order(session_data, "pay_now")

      text == "1*0*1*1*2*1" ->
        process_order(session_data, "pay_on_delivery")

      # Order confirmation - Pay Now from direct checkout path
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1\*1\*1\*1$/, text) ->
        process_order(session_data, "pay_now")

      # Order confirmation - Pay on Delivery from direct checkout path
      Regex.match?(~r/^1\*\d+\*\d+\*\d+\*1\*1\*2\*1$/, text) ->
        process_order(session_data, "pay_on_delivery")

      # Default fallback - debug the received text pattern
      true ->
        {"END Invalid option: '#{text}'. Please try again.", session_data}
    end
  end

  # List organizations from database
  defp list_organizations do
    Organizations.list_organizations()
  end

  # List all products for an organization
  defp list_organization_products(organization_id) do
    # Get products for the organization
    products =
      Products.list_products()
      |> Enum.filter(fn p -> p.organization_id == organization_id end)
      # Limit to 8 for USSD display
      |> Enum.take(8)

    # Get available SKUs for each product
    products
    |> Enum.map(fn product ->
      skus =
        Products.list_product_skus(product.id)
        |> Enum.filter(fn sku -> sku.stock_quantity > 0 end)
        # Just take the first SKU for simplicity
        |> Enum.take(1)
        |> Enum.map(&Repo.preload(&1, :product))

      if Enum.empty?(skus) do
        nil
      else
        %{product: product, sku: List.first(skus)}
      end
    end)
    # Remove nil entries (products with no SKUs)
    |> Enum.filter(&(&1 != nil))
  end

  # Add item to cart
  defp add_to_cart(cart_items, product_sku) do
    product_name =
      if is_map(product_sku.product) &&
           !match?(%Ecto.Association.NotLoaded{}, product_sku.product) do
        product_sku.product.name
      else
        product_sku.name
      end

    cart_item = %{
      id: product_sku.id,
      sku_id: product_sku.id,
      name: product_sku.name,
      product_name: product_name,
      barcode: product_sku.barcode,
      price: product_sku.price,
      quantity: 1,
      subtotal: product_sku.price
    }

    cart_items ++ [cart_item]
  end

  # Calculate total for cart items
  defp calculate_total(cart_items) do
    Enum.reduce(cart_items, Decimal.new(0), fn item, acc ->
      Decimal.add(acc, item.subtotal)
    end)
  end

  # Process the completed order
  defp process_order(session_data, payment_method) do
    if Enum.empty?(session_data.cart_items) do
      {"END Your cart is empty. Please add products before checkout.", session_data}
    else
      now = Aipos.TicketIdEncypter.now()
      total_price = Decimal.add(session_data.total_amount, @shipping_cost)

      status = if payment_method == "pay_now", do: "pending", else: "awaiting_delivery"

      sale_params = %{
        organization_id: session_data.selected_organization.id,
        items: session_data.cart_items,
        subtotal: session_data.total_amount,
        shipping: @shipping_cost,
        total_amount: total_price,
        customer: session_data.customer,
        status: status,
        payment_method: payment_method,
        transaction_id: now,
        order_source: "ussd"
      }

      case Aipos.Sales.create_sale(sale_params) do
        {:ok, sale} ->
          # Create sale items
          Enum.each(session_data.cart_items, fn item ->
            item_params = %{
              sale_id: sale.id,
              product_sku_id: item.sku_id,
              name: item.name,
              quantity: item.quantity,
              price: item.price,
              subtotal: item.subtotal,
              organization_id: session_data.selected_organization.id
            }

            {:ok, _sale_item} = Aipos.Sales.create_sale_item(item_params)

            # Update stock quantity
            update_stock_quantity(item.sku_id, item.quantity)
          end)

          # Determine response based on payment method
          if payment_method == "pay_now" do
            send_payment_instructions(session_data.phone_number, sale.id, total_price)

            {"END Thank you for your order! Check your SMS for payment instructions.",
             %{session_data | cart_items: [], total_amount: Decimal.new(0)}}
          else
            send_order_confirmation(session_data.phone_number, sale.id, total_price)

            {"END Thank you for your order! Your items will be delivered soon.",
             %{session_data | cart_items: [], total_amount: Decimal.new(0)}}
          end

        {:error, reason} ->
          IO.puts("Error creating sale: #{inspect(reason)}")
          {"END Order creation failed. Please try again later.", session_data}
      end
    end
  end

  # Update stock quantity after purchase
  defp update_stock_quantity(sku_id, quantity) do
    sku = ProductSkus.get_product_sku!(sku_id)
    new_quantity = sku.stock_quantity - quantity

    new_quantity = if new_quantity < 0, do: 0, else: new_quantity

    ProductSkus.update_product_sku(sku, %{stock_quantity: new_quantity, status: "sold"})
  end

  # Send payment instructions via SMS
  defp send_payment_instructions(phone_number, order_id, amount) do
    message =
      "Thank you for your order ##{order_id}. Please pay #{format_money(amount)} " <>
        "via M-PESA to Till Number 123456. Use your phone number as reference."

    Task.start(fn ->
      case AfricasTalking.send_sms(phone_number, message) do
        {:ok, _response} ->
          IO.puts("Payment instructions SMS sent successfully to #{phone_number}")

        {:error, reason} ->
          IO.puts(
            "Failed to send payment instructions SMS to #{phone_number}: #{inspect(reason)}"
          )
      end
    end)
  end

  # Send order confirmation via SMS
  defp send_order_confirmation(phone_number, order_id, amount) do
    message =
      "Thank you for your order ##{order_id}. Your total is #{format_money(amount)}. " <>
        "Your items will be delivered within 24-48 hours. Pay on delivery."

    Task.start(fn ->
      case AfricasTalking.send_sms(phone_number, message) do
        {:ok, _response} ->
          IO.puts("Order confirmation SMS sent successfully to #{phone_number}")

        {:error, reason} ->
          IO.puts("Failed to send order confirmation SMS to #{phone_number}: #{inspect(reason)}")
      end
    end)
  end

  # Menu builders

  # Main menu
  defp main_menu do
    "CON Welcome to AIPOs Marketplace.\n" <>
      "1. Shop Now"
  end

  # Organization selection menu
  defp org_selection_menu(organizations) do
    header = "CON Select a store:\n"

    orgs_menu =
      organizations
      |> Enum.with_index(1)
      # Limit to 7 items for USSD display
      |> Enum.take(7)
      |> Enum.map(fn {org, index} -> "#{index}. #{org.name}" end)
      |> Enum.join("\n")

    header <> orgs_menu
  end

  # Product selection menu
  defp product_selection_menu(products, store_name) do
    if Enum.empty?(products) do
      "END No products available from #{store_name}."
    else
      header = "CON #{store_name} - Select a product:\n"

      products_menu =
        products
        |> Enum.with_index(1)
        |> Enum.map(fn {%{product: product, sku: sku}, index} ->
          "#{index}. #{product.name} - #{format_money(sku.price)}"
        end)
        |> Enum.join("\n")

      header <> products_menu <> "\n0. View Cart"
    end
  end

  # Quantity selection menu
  defp quantity_menu(product_sku) do
    "CON #{product_sku.name}\nPrice: #{format_money(product_sku.price)}\n" <>
      "Select quantity:\n" <>
      "1. 1\n" <>
      "2. 2\n" <>
      "3. 3\n" <>
      "4. 4\n" <>
      "5. 5"
  end

  # Cart view menu
  defp cart_menu(cart_items, total) do
    if Enum.empty?(cart_items) do
      "CON Your cart is empty.\n\n" <>
        "2. Continue Shopping"
    else
      header = "CON Your Cart:\n"

      items =
        cart_items
        # Limit for USSD display
        |> Enum.take(3)
        |> Enum.with_index(1)
        |> Enum.map(fn {item, index} ->
          "#{index}. #{item.name} x#{item.quantity} = #{format_money(item.subtotal)}"
        end)
        |> Enum.join("\n")

      more_text =
        if Enum.count(cart_items) > 3,
          do: "\n(+ #{Enum.count(cart_items) - 3} more items)",
          else: ""

      summary =
        "\nSubtotal: #{format_money(total)}" <>
          "\nShipping: #{format_money(@shipping_cost)}" <>
          "\nTotal: #{format_money(Decimal.add(total, @shipping_cost))}"

      options =
        "\n\n1. Checkout" <>
          "\n2. Continue Shopping" <>
          "\n3. Clear Cart"

      header <> items <> more_text <> summary <> options
    end
  end

  # Checkout menu
  defp checkout_menu do
    "CON Customer Information:\n" <>
      "Your order will be delivered to your registered address.\n\n" <>
      "1. Continue to Payment"
  end

  # Payment method menu
  defp payment_method_menu do
    "CON Select payment method:\n" <>
      "1. Pay Now (M-PESA)\n" <>
      "2. Pay on Delivery"
  end

  defp confirm_order_menu(session_data) do
    total = Decimal.add(session_data.total_amount, @shipping_cost)

    payment_method_text =
      case session_data.payment_method do
        "pay_now" -> "M-PESA Payment"
        "pay_on_delivery" -> "Pay on Delivery"
        _ -> "Unknown Payment Method"
      end

    "CON Order Summary:\n" <>
      "Items: #{Enum.count(session_data.cart_items)}\n" <>
      "Total: #{format_money(total)}\n" <>
      "Payment: #{payment_method_text}\n\n" <>
      "1. Confirm Order\n" <>
      "2. Cancel"
  end

  # Helper for formatting money values
  defp format_money(%Decimal{} = amount) do
    Decimal.to_string(amount, :normal)
  end

  defp format_money(amount) when is_number(amount) do
    :erlang.float_to_binary(amount / 1, decimals: 2)
  end

  defp format_money(_), do: "0.00"
end

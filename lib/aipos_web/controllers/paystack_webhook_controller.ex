defmodule AiposWeb.PaystackWebhookController do
  use AiposWeb, :controller
  alias Aipos.Sales
  require Logger

  def create(conn, params) do
    Logger.info("Received Paystack webhook: #{inspect(params)}")

    if params["event"] == "charge.success" do
      spawn(fn ->
        handle_successful_payment(params["data"])
      end)
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{message: "Success"}))
  end

  defp handle_successful_payment(data) do
    reference = data["reference"]
    payment_channel = data["authorization"]["bank"] || data["channel"]

    Logger.info("Processing successful payment for reference: #{reference}")

    case Sales.get_sale_by_transaction_id(reference) do
      nil ->
        Logger.error("Sale not found for transaction: #{reference}")

      sale ->
        # Update sale status to completed
        case Sales.update_sale(sale, %{
               status: "completed",
               payment_channel: payment_channel
             }) do
          {:ok, updated_sale} ->
            Logger.info("Sale ##{updated_sale.id} marked as completed")

          {:error, changeset} ->
            Logger.error("Failed to update sale: #{inspect(changeset)}")
        end
    end
  end
end

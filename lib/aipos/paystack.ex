defmodule Aipos.Paystack do
  @moduledoc """
  The Paystack module is responsible for all interactions with the Paystack API
  """
  
  defp api_url, do: "https://api.paystack.co/transaction/initialize"

  defp paystack_headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{api_key()}"}
    ]
  end

  @doc """
  Initializes a transaction with Paystack and returns the transaction reference and a url to redirect to

  ## Parameters
    - email: Customer email address
    - amount: Amount in KES (will be converted to kobo/cents)
    - transaction_id: Unique transaction reference
    - callback_url: URL to redirect to after payment

  ## Returns
    - {:ok, %{"authorization_url" => url, "access_code" => code, "reference" => ref}} on success
    - {:error, reason} on failure
  """
  def initialize(email, amount, transaction_id, callback_url) do
    # Convert amount to kobo (Paystack expects amount in smallest currency unit)
    amount_in_kobo = Decimal.to_float(amount) * 100 |> trunc()

    paystack_body =
      %{
        "reference" => transaction_id,
        "email" => email,
        "amount" => amount_in_kobo,
        "callback_url" => callback_url,
        "currency" => "KES"
      }
      |> Jason.encode!()

    case HTTPoison.post(api_url(), paystack_body, paystack_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        data =
          body
          |> Jason.decode!()
          |> Map.get("data")

        {:ok, data}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        reason =
          body
          |> Jason.decode!()
          |> Map.get("message")

        {:error, reason}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Verifies a transaction with Paystack

  ## Parameters
    - reference: The transaction reference to verify

  ## Returns
    - {:ok, transaction_data} on success
    - {:error, reason} on failure
  """
  def verify_transaction(reference) do
    url = "https://api.paystack.co/transaction/verify/#{reference}"

    case HTTPoison.get(url, paystack_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        data =
          body
          |> Jason.decode!()
          |> Map.get("data")

        {:ok, data}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Transaction not found"}

      {:ok, %HTTPoison.Response{body: body}} ->
        reason =
          body
          |> Jason.decode!()
          |> Map.get("message")

        {:error, reason}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Creates a sub-account for split payments
  """
  def create_sub_accounts(account_name, bank_code, account_number, percentage_charge) do
    url = "https://api.paystack.co/subaccount"

    sub_account_body =
      %{
        "business_name" => account_name,
        "bank_code" => bank_code,
        "account_number" => account_number,
        "percentage_charge" => percentage_charge
      }
      |> Jason.encode!()

    case HTTPoison.post(url, sub_account_body, paystack_headers()) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}}
      when status_code in [200, 201] ->
        {:created,
         body
         |> Jason.decode!()
         |> Map.get("data")}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:bank_error,
         body
         |> Jason.decode!()
         |> Map.get("message")}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:not_created, reason}
    end
  end

  defp api_key do
    Application.get_env(:aipos, :paystack_secret_key, "sk_test_4a6708cf3369c72531f853185839a83b98ed025b")
  end
end

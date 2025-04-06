defmodule Aipos.Paystack do
  @moduledoc """
  The Paystack module is responsible for all the interactions with the Paystack API
  """
  defp api_url, do: "https://api.paystack.co/transaction/initialize"

  defp paystack_headers,
    do: [
      {
        "Content-Type",
        "application/json"
      },
      {
        "Authorization",
        "Bearer #{api_key()}"
      }
    ]

  @doc """
  Initializes a transaction with Paystack and returns the transaction reference and a url to redirect to

  """

  def initialize(email, amount, transaction_id) do
    api_url = api_url()

    amount = Decimal.mult(amount, Decimal.new("100")) |> Decimal.to_integer()

    paystack_body =
      %{
        "reference" => transaction_id,
        "email" => email,
        "amount" => amount,
        "callback_url" => "https://pos.socoafrica.com/success"
      }
      |> Jason.encode!()

    case HTTPoison.post(api_url, paystack_body, paystack_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> Map.get("data")

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        reason =
          body
          |> Jason.decode!()
          |> Map.get("message")

        %{"error" => reason}

      {:error, %HTTPoison.Error{reason: reason}} ->
        %{"error" => reason}
    end
  end

  def test_verification(transaction_reference) do
    paystack_headers = paystack_headers()

    url = "https://api.paystack.co/transaction/verify/#{transaction_reference}"

    case HTTPoison.get(url, paystack_headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> Map.get("data")

      {:error, %HTTPoison.Error{reason: reason}} ->
        reason
    end
  end

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
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:created,
         body
         |> Jason.decode!()
         |> Map.get("data")}

      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
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

  def list_banks do
    [
      {~c"Absa Bank Kenya Plc", 3},
      {~c"Access Bank Kenya", 26},
      {~c"African BankingCorporation Ltd", 35},
      {~c"Bank of Africa Kenya Ltd", 19},
      {~c"Bank of Baroda Kenya Limited", 6},
      {~c"Bank of India", 5},
      {~c"Caritas Microfinance Bank", 48},
      {~c"Central Bank of Kenya", 9},
      {~c"Choice Microfinance Bank", 36},
      {~c"Citibank NA ", 16},
      {~c"Co-operative Bank of Kenya Ltd", 11},
      {~c"Consolidated Bank of Kenya Ltd", 23},
      {~c"Credit Bank Limited", 25},
      {~c"Development Bank of Kenya Ltd", 59},
      {~c"Diamond Trust Bank Ltd", 63},
      {~c"Dubai Islamic Bank Ltd", 75},
      {~c"Ecobank Kenya Limited", 43},
      {~c"Equity Bank ltd", 68},
      {~c"Family Bank Ltd", 70},
      {~c"Faulu Microfinance Bank", 79},
      {~c"Guaranty Trust Bank Kenya", 53},
      {~c"Guardian Bank Ltd", 55},
      {~c"Gulf African Bank Ltd", 72},
      {~c"Habib Bank Limited", 8},
      {~c"Housing Finance Corporation (HFC Bank)", 61},
      {~c"I & M Bank Ltd", 57},
      {~c"Jamii Bora Bank Ltd", 51},
      {~c"Kenya Commercial Bank Limited", 1},
      {~c"Kenya Women Microfinance Bank", 78},
      {~c"Kingdom Bank", 51},
      {~c"M-Oriental Bank Ltd", 14},
      {~c"Mayfair Bank", 65},
      {~c"Middle East Bank Kenya Ltd", 18},
      {~c"National Bank of Kenya Ltd", 12},
      {~c"NCBA Bank Kenya", 7},
      {~c"Paramount Universal Bank Ltd", 50},
      {~c"PostBank Kenya", 62},
      {~c"Premier Bank Kenya", 74},
      {~c"Prime Bank Limited", 10},
      {~c"SBM Bank Kenya", 30},
      {~c"Sidian Bank Kenya", 66},
      {~c"Spire Bank Kenya", 49},
      {~c"Stanbic Bank Kenya Limited", 31},
      {~c"Standard Chartered Bank Kenya", 2},
      {~c"Stima Sacco", 89},
      {~c"UBA Kenya Bank Ltd", 76},
      {~c"Victoria Commercial Bank Ltd", 54}
    ]
  end

  defp api_key do
    "sk_test_49f8fe7a2e5cd436c2eb6b8305e7caa8aa3625d6"
  end
end

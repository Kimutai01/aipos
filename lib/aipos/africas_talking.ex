
defmodule Aipos.AfricasTalking do
  @api_key "atsk_6eed5bd953f7610b6ec02b93f9c473279df2449dc8161111fb33ae2be57e7ffb2f5a4272"
  @username "mche1"
  @base_url "https://api.africastalking.com/version1"

  require Logger

  def send_sms(phone_numbers, message) when is_list(phone_numbers) do
    body = %{
      username: @username,
      to: Enum.join(phone_numbers, ","),
      message: message
    }

    headers = [
      {"Accept", "application/json"},
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"apiKey", @api_key}
    ]

    url = "#{@base_url}/messaging"

    case HTTPoison.post(url, URI.encode_query(body), headers) do
      {:ok, %{status_code: 201, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def send_sms(phone_number, message) when is_binary(phone_number) do
    send_sms([phone_number], message)
  end
end

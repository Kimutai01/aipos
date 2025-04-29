defmodule Aipos.Tiara do
  defp headers,
    do: [
      {
        "Content-Type",
        "application/json"
      },
      {
        "Authorization",
        "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIyOTAiLCJvaWQiOjI5MCwidWlkIjoiYWUzMGRjZTItMjIzYi00ODUzLWJmMDItNDE5ZWI2MzMzY2Y5IiwiYXBpZCI6MTgzLCJpYXQiOjE2OTM1OTAzNDksImV4cCI6MjAzMzU5MDM0OX0.mG9d0tTkmx49OQKMKQFYKnIQMHFQEIckHBnGe5jTjg3fU95aHLxrtouqsPGr7Yi3GKFt674_ImiLtJavAa4OIw"
      }
    ]

  def send_message(phone_number, message) do
    url = "https://api.tiaraconnect.io/api/messaging/sendsms"

    body =
      %{
        "from" => "TIARACONECT",
        "to" => phone_number,
        "message" => message,
        "refId" => "09wiwu088e"
      }

    req_options = [
      headers: headers(),
      json: body,
      retry: :transient,
      max_retries: 5,
      receive_timeout: 60_000
    ]

    Req.post(url, req_options)
  end
end

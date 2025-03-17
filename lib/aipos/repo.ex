defmodule Aipos.Repo do
  use Ecto.Repo,
    otp_app: :aipos,
    adapter: Ecto.Adapters.Postgres
end

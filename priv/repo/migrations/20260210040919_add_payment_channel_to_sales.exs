defmodule Aipos.Repo.Migrations.AddPaymentChannelToSales do
  use Ecto.Migration

  def change do
    alter table(:sales) do
      add :payment_channel, :string
    end
  end
end

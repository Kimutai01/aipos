defmodule Aipos.Repo.Migrations.AddPaidAtToSale do
  use Ecto.Migration

  def change do
    alter table(:sales) do
      add :paid_at, :utc_datetime
      add :transaction_id, :string
    end

    create index(:sales, [:paid_at])
  end
end

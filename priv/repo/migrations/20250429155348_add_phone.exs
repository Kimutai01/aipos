defmodule Aipos.Repo.Migrations.AddPhone do
  use Ecto.Migration

  def change do
    alter table(:sales) do
      add :phone_number, :string
    end
  end
end

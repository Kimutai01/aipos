defmodule Aipos.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string, null: false
      add :description, :string
      add :category, :string
      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:name])
  end
end

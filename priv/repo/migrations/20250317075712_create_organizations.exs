defmodule Aipos.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string
      add :address, :string
      add :phone, :string
      add :email, :string
      add :logo, :string

      timestamps(type: :utc_datetime)
    end
  end
end

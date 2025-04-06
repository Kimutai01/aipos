defmodule Aipos.Repo.Migrations.AddStaffFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :staff_id, :string
      add :name, :string
      add :active, :boolean, default: true
      add :last_login, :utc_datetime
    end

    create unique_index(:users, [:staff_id])
  end
end

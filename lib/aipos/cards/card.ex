defmodule Aipos.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :card, :device, :inserted_at, :updated_at]}

  schema "cards" do
    field :card, :string
    field :device, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:card, :device])
    |> validate_required([:card, :device])
    |> unique_constraint(:card, name: :unique_card_index)
  end
end

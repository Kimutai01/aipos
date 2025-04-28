defmodule Aipos.CardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aipos.Cards` context.
  """

  @doc """
  Generate a card.
  """
  def card_fixture(attrs \\ %{}) do
    {:ok, card} =
      attrs
      |> Enum.into(%{
        card: "some card",
        device: "some device"
      })
      |> Aipos.Cards.create_card()

    card
  end
end

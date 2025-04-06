defmodule Aipos.TicketIdEncypter do
  def create_ticketid(id) do
    now() <> "X" <> Integer.to_string(id)
  end

  def now do
    Timex.local()
    |> Timex.format!("{YYYY}{0M}{0D}{h24}{m}{s}")
  end

  def decode_ticket_id(ticketid) do
    parts = String.split(ticketid, "X")
    [_timestamp, id] = parts
    id
  end
end

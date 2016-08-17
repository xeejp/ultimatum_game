defmodule Ultimatum.Actions do
  alias Ultimatum.Participant
  alias Ultimatum.Host

  def change_page(data, page) do
    action = get_action("change page", page)
    format(data, action, dispatch_to_all(data, action))
  end

  def change_game_round(data, game_round) do
    action = get_action("change game_round", game_round)
    format(data, action, dispatch_to_all(data, action))
  end

  def change_game_mode(data, game_mode) do
    action = get_action("change game_mode", game_mode)
    format(data, action, dispatch_to_all(data, action))
  end

  def join(data, id, participant) do
    action = get_action("join", %{id: id, participant: participant})
    format(data, action)
  end

  def matched(%{participants: participants, pairs: pairs} = data) do
    host = get_action("matched", %{participants: participants, pairs: pairs})
    participant = Enum.map(participants, fn {id, p} ->
      payload = Map.merge(Participant.format_participant(p), Participant.format_pair(Map.get(pairs, p.pair)))
      {id, %{action: get_action("matched", payload)}}
    end) |> Enum.into(%{})
    format(data, host, participant)
  end

  def update_host_contents(data) do
    host = get_action("update contents", Host.format_contents(data))
    format(data, host)
  end

  def update_participant_contents(data, id) do
    participant = dispatch_to(id, get_action("update contents", Participant.format_contents(data, id)))
    format(data, nil, participant)
  end

  # Utilities

  defp get_action(type, params) do
    %{
      type: type,
      payload: params
    }
  end

  defp dispatch_to(map \\ %{}, id, action) do
    Map.put(map, id, %{action: action})
  end

  defp dispatch_to_all(%{participants: participants}, action) do
    Enum.reduce(participants, %{}, fn {id, _}, acc -> dispatch_to(acc, id, action) end)
  end

  defp format(data, host, participants \\ nil) do
    result = %{"data" => data}
    unless is_nil(host) do
      result = Map.put(result, "host", %{action: host})
    end
    unless is_nil(participants) do
      result = Map.put(result, "participant", participants)
    end
    {:ok, result}
  end
end
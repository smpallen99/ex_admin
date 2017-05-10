defimpl ExAdmin.Authorization, for: TestExAdmin.Simple do
  def authorize_query(_, _, query, _, _), do: query

  def authorize_action(_, %{action: :public_change}, :show), do: true
  def authorize_action(_, %{action: :private_change}, :show), do: false
  def authorize_action(_, %{action: :public_bulk}, :index), do: true
  def authorize_action(_, %{action: :private_bulk}, :index), do: false
  def authorize_action(_, _, _), do: true
end

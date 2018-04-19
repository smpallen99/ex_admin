defmodule ExAdmin.Changeset do
  @moduledoc false
  alias __MODULE__, as: Cs
  defstruct valid?: true, changeset: nil, errors: nil, dependents: [], required: []

  def update(%Cs{} = r, items) when is_list(items) do
    Enum.reduce(items, r, fn {k, v}, acc -> update(acc, k, v) end)
  end

  def update(%Cs{} = r, :changeset, nil) do
    %Cs{r | changeset: nil, required: []}
  end

  def update(%Cs{} = r, :changeset, changeset) do
    %Cs{r | changeset: changeset, required: changeset.required}
  end

  def update(%Cs{valid?: valid?} = r, :valid?, value) do
    %Cs{r | valid?: valid? and value}
  end

  def update(%Cs{dependents: dependents} = r, :dependents, dependent) do
    %Cs{r | dependents: dependents ++ [dependent]}
  end

  def update(%Cs{} = r, :errors, nil), do: r

  def update(%Cs{errors: nil} = r, :errors, error) do
    %Cs{r | errors: error}
  end

  def update(%Cs{errors: errors} = r, :errors, error) do
    %Cs{r | errors: errors ++ error}
  end

  def set_data(%{data: data} = cs, params) do
    struct(cs, data: struct(data, params))
  end

  def set_data(%{model: data} = cs, params) do
    struct(cs, model: struct(data, params))
  end

  def get_data(%{data: data}), do: data
  def get_data(%{model: data}), do: data
end

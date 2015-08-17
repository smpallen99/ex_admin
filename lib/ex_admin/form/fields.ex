defmodule ExAdmin.Form.Fields do
  require Logger
  import ExAdmin.Utils
  import ExAdmin.Helpers
  import ExAdmin.DslUtils
  import Xain, except: [input: 1]

  def ext_name(model_name, field_name), do: "#{model_name}_#{field_name}"

  def input_collection(resource, collection, model_name, field_name, id, nested_name, item) do
    Logger.warn "input_collection: resource: #{inspect resource}"
    Logger.warn "----> item[:opts]: #{inspect item[:opts]}"
    ext_name = ext_name model_name, field_name
    _input_collection(resource, collection, model_name, field_name, item, 
        resource.__struct__.__schema__(:association, field_name))

  end
  defp _input_collection(resource, collection, model_name, field_name, item, %{cardinality: :one} = assoc) do
    ext_name = ext_name model_name, field_name
    assoc_fields = get_association_fields(item[:opts])
    select(id: "#{ext_name}_id", name: "#{model_name}[#{assoc.owner_key}]") do
      handle_prompt(field_name, item)
      for item <- collection do
        selected = if Map.get(resource, assoc.owner_key) == item.id, 
          do: [selected: :selected], else: []

        map_relationship_fields(item, assoc_fields)
        |> option([value: "#{item.id}"] ++ selected) 
      end
    end
  end
  defp _input_collection(resource, collection, model_name, field_name, 
      %{opts: %{as: :check_boxes}} = item, %{cardinality: :many} = assoc) do
    ext_name = ext_name model_name, field_name
    Logger.warn "collection many owner_key: #{inspect assoc.owner_key}"
    name = "license[option_ids][]"
    #input "#license_options_none", name: name, type: :hidden
    ol ".choices-group" do
      for o <- collection do
        li ".choice" do
          label for: "license_option_ids_#{o.id}"  do
            input "#license_option_ids_#{o.id}", value: o.id, name: name, type: :checkbox
            text o.name
          end
        end
      end
    end
  end
  defp _input_collection(resource, collection, model_name, field_name, item, assoc) do
    Logger.error "_input_collection: unknown type for field_name: #{inspect field_name}, item[:opts]: #{inspect item[:opts]}, assoc: #{inspect assoc}"
  end

  def handle_prompt(field_name, item) do
    case get_prompt(field_name, item) do
      false -> nil
      prompt -> option(prompt, value: "")
    end
  end

  def get_prompt(field_name, item) do
    case Map.get item[:opts], :prompt, nil do
      nil -> 
        nm = humanize("#{field_name}")
        |> articlize
        "Select #{nm}"
      other -> other
    end
  end

end

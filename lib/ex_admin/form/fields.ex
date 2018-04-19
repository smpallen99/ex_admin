defmodule ExAdmin.Form.Fields do
  @moduledoc false
  use ExAdmin.Adminlog
  import ExAdmin.Utils
  import ExAdmin.Helpers
  import ExAdmin.Theme.Helpers
  import ExAdmin.Gettext
  import Xain, except: [input: 1]

  def ext_name(model_name, field_name), do: "#{model_name}_#{field_name}"

  def input_collection(
        resource,
        collection,
        model_name,
        field_name,
        _id,
        _nested_name,
        item,
        params,
        errors
      ) do
    # ext_name = ext_name model_name, field_name
    do_input_collection(
      resource,
      collection,
      model_name,
      field_name,
      item,
      resource.__struct__.__schema__(:association, field_name),
      params,
      errors
    )
  end

  def ajax_input_collection(
        resource,
        collection,
        model_name,
        field_name,
        _id,
        _nested_name,
        item,
        params
      ) do
    theme_module(Fields).theme_ajax_input_collection(
      resource,
      collection,
      model_name,
      field_name,
      item,
      params
    )
  end

  def do_input_collection(
        resource,
        collection,
        model_name,
        field_name,
        item,
        %{cardinality: :one} = assoc,
        _params,
        _errors
      ) do
    Adminlog.debug("1st _input_collection... #{field_name}")

    ext_name = ext_name(model_name, field_name)
    assoc_fields = get_association_fields(item[:opts])

    # err = if errors == [], do: false, else: true
    select class: "form-control",
           id: "#{ext_name}_id",
           name: "#{model_name}[#{assoc.owner_key}]" do
      handle_prompt(field_name, item)

      for item <- collection do
        selected =
          cond do
            Map.get(resource, assoc.owner_key) == item.id ->
              [selected: :selected]

            # not(params[model_name][Atom.to_string(assoc.owner_key)] in [nil, ""]) ->
            #   Logger.warn "foo"
            #   [selected: :selected]
            true ->
              []
          end

        map_relationship_fields(item, assoc_fields)
        |> option([value: "#{item.id}"] ++ selected)
      end
    end
  end

  # defp _input_collection(resource, collection, model_name, field_name,
  #     %{opts: %{as: :check_boxes}}, list, params, _errors) when is_list(list) do
  #   Adminlog.debug "2nd _input_collection... #{field_name}"

  #   name_ids = "#{Atom.to_string(field_name) |> Inflex.singularize}_ids"
  #   name = "#{model_name}[#{name_ids}][]"
  #   input "#license_options_none", name: name, type: :hidden

  #   case Map.get(resource, field_name, []) do
  #     list when is_list(list) -> Enum.map(list, &(&1.id))
  #     _ -> []
  #   end
  # end
  # defp _input_collection(resource, collection, model_name, field_name,
  #     %{opts: %{as: :check_boxes}}, %{cardinality: :many, through: [_join_name | _]} = assoc, params) do
  #   # assoc_key = resource.__struct__.__schema__(:association, join_name).assoc_key
  #   # ext_name = ext_name model_name, field_name
  #   name_ids = "#{Atom.to_string(field_name) |> Inflex.singularize}_ids"
  #   name = "#{model_name}[#{name_ids}][]"
  #   id_base = "#{model_name}_#{name_ids}_"
  #   input "#license_options_none", name: name, type: :hidden
  #   params_ids = params[model_name][name_ids] || []

  #   ids = case Map.get(resource, field_name, []) do
  #     list when is_list(list) -> Enum.map(list, &(&1.id))
  #     _ -> []
  #   end

  #   ol ".choices-group" do
  #     for o <- collection do
  #       assoc_id = Map.get(o, assoc.owner_key)
  #       checked = cond do
  #          assoc_id in ids ->
  #           [checked: :checked]
  #          Integer.to_string(assoc_id) in params_ids ->
  #           [checked: :checked]
  #          true ->
  #           []
  #       end
  #       li ".choice" do
  #         id = id_base <> Integer.to_string(o.id)
  #         label for: id  do
  #           input "#" <> id, [value: o.id, name: name, type: :checkbox] ++ checked
  #           text o.name
  #         end
  #       end
  #     end
  #   end
  # end
  def do_input_collection(
        resource,
        collection,
        model_name,
        field_name,
        %{opts: %{as: :check_boxes} = opts},
        %{cardinality: :many, through: [_join_name | _]} = assoc,
        params,
        errors
      ) do
    Adminlog.debug("3rd _input_collection... #{field_name}")

    name_ids = "#{Atom.to_string(field_name) |> Inflex.singularize()}_ids"
    name = "#{model_name}[#{name_ids}][]"
    id_base = "#{model_name}_#{name_ids}_"
    input("#license_options_none", name: name, type: :hidden)
    params_ids = params[model_name][name_ids] || []

    ids =
      case Map.get(resource, field_name, []) do
        list when is_list(list) -> Enum.map(list, & &1.id)
        _ -> []
      end

    for o <- collection do
      assoc_id = Map.get(o, assoc.owner_key)

      checked =
        cond do
          assoc_id in ids ->
            [checked: :checked]

          Integer.to_string(assoc_id) in params_ids ->
            [checked: :checked]

          true ->
            []
        end

      html =
        theme_module(Fields).input_checkbox(fn ->
          id = id_base <> Integer.to_string(o.id)

          label for: id do
            input("#" <> id, [value: o.id, name: name, type: :checkbox] ++ checked)
            text(o.name)
          end
        end)

      if opts[:content] do
        opts[:content].(resource, o, html, errors)
      else
        html
      end
    end
  end

  def do_input_collection(
        _resource,
        _collection,
        _model_name,
        field_name,
        item,
        assoc,
        _params,
        _errors
      ) do
    Logger.error(
      "_input_collection: unknown type for field_name: #{inspect(field_name)}, item[:opts]: #{
        inspect(item[:opts])
      }, assoc: #{inspect(assoc)}"
    )
  end

  def handle_prompt(field_name, item) do
    case get_prompt(field_name, item) do
      false -> nil
      prompt -> option(prompt, value: "")
    end
  end

  def get_prompt(field_name, item) do
    case Map.get(item[:opts], :prompt, nil) do
      nil ->
        nm =
          humanize("#{field_name}")
          |> articlize

        gettext("Select %{nm}", nm: nm)

      other ->
        other
    end
  end
end

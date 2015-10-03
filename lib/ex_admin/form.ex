defmodule ExAdmin.Form do
  require Logger
  import ExAdmin.Utils
  import ExAdmin.Helpers
  import ExAdmin.DslUtils
  import ExAdmin.Form.Fields
  import ExAdmin.ViewHelpers, only: [escape_javascript: 1]
  require IEx

  import Kernel, except: [div: 2]
  use Xain
  import Xain, except: [input: 2, input: 1]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      import Xain, except: [input: 1]
    end
  end

  ################
  # DSL Macros

  def default_form_view(conn, resource, params) do
    [_, res | _] = conn.path_info 
    case ExAdmin.get_registered_by_controller_route(res) do
      nil -> 
        throw :invalid_route
      %{__struct__: _} = defn -> 
        columns = defn.resource_model.__schema__(:fields)
        |> Enum.filter(&(not &1 in [:id, :inserted_at, :updated_at]))
        |> Enum.map(&(build_item resource, &1))
        |> Enum.filter(&(not is_nil(&1)))
        items = [%{type: :inputs, name: "", inputs: columns, opts: []}]
        ExAdmin.Form.build_form(conn, resource, items, params, false)
    end
  end

  defp build_item(resource, name) do
    case translate_field name do 
      field when field == name -> 
        %{type: :input, resource: resource, name: name, opts: %{}}
      field -> 
        case resource.__struct__.__schema__(:association, field) do
          %Ecto.Association.BelongsTo{cardinality: :one, queryable: assoc} -> 
            collection = Application.get_env(:ex_admin, :repo).all assoc
            %{type: :input, resource: resource, name: field, opts: %{collection: collection}}
          _ -> 
            nil
        end
    end
  end

  defp translate_field(field) do
    case Regex.scan ~r/(.+)_id$/, Atom.to_string(field) do
      [[_, assoc]] -> String.to_atom(assoc)
      _ -> field
    end
  end

  defmacro form(resource, [do: block]) do
    contents = quote do
      unquote(block)
    end

    quote location: :keep, bind_quoted: [resource: escape(resource), contents: escape(contents)] do
      def form_view(var!(conn), unquote(resource) = var!(resource), var!(params) = params) do 
        import ExAdmin.Register, except: [actions: 1]
        # var!(query_options) = []
        var!(input_blocks, ExAdmin.Form) = [] 
        var!(script_block, ExAdmin.Form) = nil
        unquote(contents)
        items = var!(input_blocks, ExAdmin.Form) |> Enum.reverse
        script_block = var!(script_block, ExAdmin.Form)
        ExAdmin.Form.build_form(var!(conn), var!(resource), items, var!(params), script_block)
      end

      def get_blocks(var!(conn), unquote(resource) = var!(resource), var!(params) = params) do 
        import ExAdmin.Register, except: [actions: 1]
        var!(input_blocks, ExAdmin.Form) = [] 
        var!(script_block, ExAdmin.Form) = nil
        unquote(contents)
        var!(input_blocks, ExAdmin.Form) |> Enum.reverse
      end

      def ajax_view(conn, params, resources, block) do
        defn = ExAdmin.get_registered_by_controller_route(params[:resource]) 
        resource = defn.resource_model.__struct__
        field_name = String.to_atom params[:field_name]
        model_name = model_name(resource)
        ext_name = ext_name model_name, field_name
        if is_function(block[:opts][:collection]) do
          resources = block[:opts][:collection].(conn, resource)
        end
        view = markup do
          ExAdmin.Form.Fields.input_collection(resource, resources, model_name, field_name, params[:id1], params[:nested2], block, conn.params)
        end

        ~s/$('##{ext_name}-update').html("#{escape_javascript(view)}");/
      end
    end
  end

  defmacro inputs(opts) do
    quote(do: inputs("", unquote(opts)))
  end

  defmacro inputs(name, opts, do: block) do
    quote location: :keep do
      import Xain, except: [input: 1]
      # inputs_save = var!(inputs, ExAdmin.Form) 
      var!(inputs, ExAdmin.Form) = []
      unquote(block)
      items = var!(inputs, ExAdmin.Form) |> Enum.reverse
      # var!(inputs, ExAdmin.Form) = inputs_save
      input_block = %{type: :inputs, name: unquote(name), inputs: items, opts: unquote(opts)}
      var!(input_blocks, ExAdmin.Form) = [input_block | var!(input_blocks, ExAdmin.Form)]
    end

  end
  defmacro inputs(name, do: block) do
    quote location: :keep do
      import Xain, except: [input: 1]
      # inputs_save = var!(inputs, ExAdmin.Form) 
      var!(inputs, ExAdmin.Form) = []
      unquote(block)
      items = var!(inputs, ExAdmin.Form) |> Enum.reverse
      # var!(inputs, ExAdmin.Form) = inputs_save
      input_block = %{type: :inputs, name: unquote(name), inputs: items, opts: []}
      var!(input_blocks, ExAdmin.Form) = [input_block | var!(input_blocks, ExAdmin.Form)]
    end
  end

  defmacro inputs(name, opts) do
    quote location: :keep do
      import Xain, except: [input: 1]
      opts = Enum.into unquote(opts), %{}
      item = %{type: :inputs, name: unquote(name), opts: opts}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  defmacro input(resource, name, opts \\ []) do
    quote do
      opts = Enum.into unquote(opts), %{}
      item = %{type: :input, resource: unquote(resource), name: unquote(name), opts: opts}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  defmacro has_many(resource, name, opts \\ [], fun \\ nil) do
    quote do
      opts = ExAdmin.DslUtils.fun_to_opts unquote(opts), unquote(fun)
      item = %{type: :has_many, resource: unquote(resource), name: unquote(name), opts: opts}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  defmacro actions(do: block) do
    quote do
      var!(inputs, ExAdmin.Form) = []
      var!(items, ExAdmin.Form) = []
      unquote(block)
      items = var!(items, ExAdmin.Form) |> Enum.reverse
      item = %{type: :actions, name: "", items: items}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  defmacro content(do: block) do
    quote do
      contents = unquote(block)
      item = %{type: :content, name: "", content: unquote(block), opts: []}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  defmacro content(items, opts \\ quote(do: [])) do
    quote do
      item = %{type: :content, content: unquote(items), opts: unquote(opts)}
      var!(items, ExAdmin.Form) = [item | var!(items, ExAdmin.Form)]
    end
  end

  defmacro javascript(do: block) do
    quote do
      var!(script_block, ExAdmin.Form) = unquote(block)
    end
  end

  #################
  # Functions

  def build_form(conn, resource, items, params, script_block) do

    # items 
    # |> hd
    # |> Map.get(:inputs)
    # |> Enum.each(&(Logger.warn "==> build_form: item: #{inspect &1}"))
    
    mode = if params[:id], do: :edit, else: :new
    markup do
      model_name = model_name resource
      action = get_action(conn, resource, mode)
      # scripts = ""
      Xain.form "accept-charset": "UTF-8", action: "#{action}", class: "formtastic #{model_name}", 
          id: "new_#{model_name}", method: :post, novalidate: :novalidate  do

        build_hidden_block(conn, mode)
        scripts = build_main_block(conn, resource, model_name, items) 
        |> build_scripts
        build_actions_block(conn, model_name, mode) 
      end 
      put_script_block(scripts)
      put_script_block(script_block)
    end
  end

  defp put_script_block(script_block) do
    if script_block do
      Xain.text "\n"
      Xain.script type: "text/javascript" do
        text "\n" <> script_block <> "\n"
      end
    end
  end

  defp build_scripts(list) do
    head = "$(document).ready(function() {\n"
    script = for i <- list, is_tuple(i), into: head, do: build_script(i)
    script <> "});"
  end

  defp build_script({:change, %{id: id, script: script}}) do
    # $('##{id}').change(function() {
    """
    $(document).on('change','##{id}', function() {
      #{script}
    });
    """
  end
  defp build_script(_other), do: ""

  defp get_action(conn, resource, mode) do
    case mode do 
      :new -> 
        get_route_path(conn, :create)
      :edit -> 
        get_route_path(conn, :update, resource.id)
    end
  end
  defp get_put_fields(:edit) do
    Xain.input(name: "_method", value: "put", type: "hidden")
  end
  defp get_put_fields(_), do: nil

  defp build_hidden_block(conn, mode) do
    csrf = csrf_token(conn)
    div style: "margin:0;padding:0;display:inline" do
      Xain.input(name: "utf8", type: :hidden, value: "✓")
      Xain.input(type: :hidden, name: "_csrf_token", value: csrf)
      get_put_fields(mode)
    end
  end

  defp build_main_block(conn, resource, model_name, schema) do
    errors = Phoenix.Controller.get_flash(conn, :inline_error)
    for item <- schema do
      build_item(conn, item, resource, model_name, errors)
    end
    |> flatten
  end

  defp flatten(list) when is_list(list), do: List.flatten(list)
  defp flatten(other), do: [other]

  @hidden_style [style: "display: none"]

  defp check_display(opts) do
    if Map.get(opts, :display, true), do: [], else: @hidden_style
  end
  defp check_params(display_style, resource, params, model_name, field_name, _ajax) do
    # field_name_str = Atom.to_string(field_name)
    cond do
      params["id"] -> []
      params[model_name][params_name(resource, field_name, params)] -> []
      true -> display_style
    end
  end

  defp params_name(resource, field_name, _params) do
    case resource.__struct__.__schema__(:association, field_name) do
      %{cardinality: :one, owner_key: owner_key} -> 
        Atom.to_string(owner_key)
      %{cardinality: :many, owner_key: owner_key, through: [_, name]} -> 
        Atom.to_string(name) <> "_" <> Inflex.pluralize(Atom.to_string(owner_key))
      _ -> 
        Atom.to_string(field_name)
    end
  end

  def wrap_item(resource, field_name, model_name, label, error, opts, params, contents) do
    as = Map.get opts, :as 
    ajax = Map.get opts, :ajax
    ext_name = ext_name(model_name, field_name)
    
    display_style = check_display(opts)
    |> check_params(resource, params, model_name, field_name, ajax)
   
    {label, hidden}  = case label do 
      {:hidden, l} -> {l, @hidden_style}
      l when l in [:none, false] ->  {"", @hidden_style}
      l -> {l, display_style}
    end
    error = if error in [nil, [], false], do: "", else: "error "
    _wrap_item(ext_name, label, hidden, ajax, error, contents, as)
    ext_name
  end

  def _wrap_item(ext_name, label, hidden, ajax, error, contents, as) when as in [:check_boxes, :radio] do
    li([class: "#{as} input optional #{error}stringish", id: "#{ext_name}_input"] ++ hidden) do
      fieldset ".choices" do
        legend ".label" do
          label humanize(label)
        end
        if ajax do
          div "##{ext_name}-update" do
            if hidden == [] do
              contents.(ext_name)
            end
          end
        else
          contents.(ext_name)
        end
      end
    end
  end
  def _wrap_item(ext_name, label, hidden, ajax, error, contents, _) do
    # TODO: Fix this to use the correct type, instead of hard coding string
    li([class: "string input optional #{error}stringish", id: "#{ext_name}_input"] ++ hidden) do
      if ajax do
        label(".label #{humanize label}", for: ext_name)
        div "##{ext_name}-update" do
          if hidden == [] do
            contents.(ext_name)
          end
        end
      else
        label(".label #{humanize label}", for: ext_name)
        contents.(ext_name)
      end
    end
  end

  defp build_select_binary_tuple_list(collection, item, field_name, resource, model_name, ext_name) do
    select("##{ext_name}_id", name: "#{model_name}[#{field_name}]") do
      handle_prompt(field_name, item)
      for item <- collection do
        {value, name} = case item do
          {value, name} -> {value, name}
          other -> {other, other}
        end
        selected = if Map.get(resource, field_name) == value, 
          do: [selected: :selected], else: []
        option(name, [value: value] ++ selected) 
      end
    end
  end


  def build_item(_conn, %{type: :script, contents: contents}, _resource, _model_name, _errors) do
    script type: "javascript" do 
      text "\n" <> contents <> "\n"
    end
  end

  def build_item(conn, %{type: :input, name: field_name, resource: resource, 
       opts: %{collection: collection}} = item, _resource, model_name, errors) do

    if is_function(collection) do
      collection = collection.(conn, resource)
    end
    module = resource.__struct__
    errors_field_name = if field_name in module.__schema__(:associations) do
      Map.get module.__schema__(:association, field_name), :owner_key
    else
      field_name
    end
    errors = get_errors(errors, errors_field_name)

    label = Map.get item[:opts], :label, field_name
    onchange = Map.get item[:opts], :change
    # ajax = Map.get item[:opts], :ajax

    binary_tuple = binary_tuple?(collection)

    id = wrap_item(resource, field_name, model_name, label, errors, item[:opts], conn.params, fn(ext_name) -> 
      item = update_in item[:opts], &(Map.delete(&1, :change) |> Map.delete(:ajax))
      if binary_tuple do
        build_select_binary_tuple_list(collection, item, field_name, resource, model_name, ext_name) 
      else
        input_collection(resource, collection, model_name, field_name, nil, nil, item, conn.params)
      end
      build_errors(errors)
    end)  
    value = case onchange do
      script when is_binary(script) -> 
        {:change, %{id: id <> "_id", script: onchange}}
      list when is_list(list) -> 
        update = Keyword.get(list, :update)
        params = Keyword.get(list, :params)
        if update do
          # TODO: Use route builder for this
          target = pluralize(field_name)
          nested = pluralize(update)

          # TODO: Need to fix this by looking it up 
          resource_name = pluralize model_name

          {extra, param_str} = 
          case params do
            atom when is_atom(atom) -> extra_javascript(model_name, atom, atom)
            [{param, attr}]         -> extra_javascript(model_name, param, attr)
            _                       -> {"", ""}
          end

          control_id = "#{model_name}_#{update}_input"
          script = "$('##{control_id}').show();\n" <> 
                   extra <> 
                   "console.log('show #{control_id}');\n" <>
                   "$.get('/admin/#{resource_name}/#{target}/'+$(this).val()+'/#{nested}/?field_name=#{update}#{param_str}&format=js');\n"

          {:change, %{id: id <> "_id", script: script}}
        end
      _ -> nil
    end
    if onchange, do: value
  end

  def build_item(conn, %{type: :actions, items: items}, resource, model_name, errors) do
    fieldset ".actions" do
      for i <- items do
        build_item(conn, i, resource, model_name, errors)
      end
    end
  end

  def build_item(_conn, %{type: :content, content: content}, _resource, _model_name, _errors) when is_binary(content) do
    text content
  end
  def build_item(_conn, %{type: :content, content: content}, _resource, _model_name, _errors) do
    text elem(content, 1)
  end

  def build_item(conn, %{type: :input, resource: resource, name: field_name, opts: opts}, 
       _resource, model_name, errors) do
    errors = get_errors(errors, field_name)
    # Logger.warn "--> build_item: field_name: #{inspect field_name}, opts: #{inspect opts}"
    label = get_label(field_name, opts)
    wrap_item(resource, field_name, model_name, label, errors, opts, conn.params, fn(ext_name) -> 
      Map.put_new(opts, :type, :text)
      |> Map.put_new(:maxlength, "255")
      |> Map.put_new(:name, "#{model_name}[#{field_name}]")
      |> Map.put_new(:id, ext_name)
      |> Map.put_new(:value, Map.get(resource, field_name, "") |> escape_value)
      |> Map.delete(:display)
      |> Map.to_list
      |> Xain.input
      build_errors(errors)
    end)
  end

  def build_item(conn, %{type: :has_many, resource: resource, name: field_name, 
      opts: %{fun: fun}}, _resource, model_name, errors) do
    field_field_name = "#{field_name}_attributes"
    human_label = "#{humanize(field_name) |> Inflex.singularize}"

    div ".has_many.#{field_name}" do
      new_record_name_var = new_record_name field_name
      h3 human_label
      li ".input" do
        get_resource_field2(resource, field_name) 
        |> Enum.with_index
        |> Enum.each fn({res, inx}) -> 
          fields = fun.(res) |> Enum.reverse
          ext_name = "#{model_name}_#{field_field_name}_#{inx}"

          new_inx = build_has_many_fieldset(conn, res, fields, inx, ext_name, field_field_name, model_name, errors)
          
          Xain.input [id: "#{ext_name}_id", 
            name: "#{model_name}[#{field_field_name}][#{new_inx}][id]",
            value: "#{res.id}", type: :hidden]  
        end
        {_, html} = markup :nested do
          ext_name = "#{model_name}_#{field_field_name}_#{new_record_name_var}"
          fields = fun.(ExAdmin.Repo.get_assoc_model(resource, field_name)) |> Enum.reverse
          build_has_many_fieldset(conn, nil, fields, new_record_name_var, ext_name, field_field_name, model_name, errors)
        end
      end
      {_, onclick} = Phoenix.HTML.html_escape  ~s|$(this).siblings("li.input").append("#{html}".replace(/#{new_record_name_var}/g,| <>
          ~s|new Date().getTime())); return false;|
      a ".button Add New #{human_label}", href: "#", onclick: onclick
    end
  end

  @doc """
  Handle building an inputs :name, as: ...
  """
  def build_item(conn, %{type: :inputs, name: name, opts: %{collection: collection}}, 
      resource, model_name, errors) when is_atom(name) do

    if is_function(collection) do
      collection = collection.(conn, resource)
    end
    errors = get_errors(errors, name)
    name_ids = "#{Atom.to_string(name) |> Inflex.singularize}_ids"
    assoc_ids = Enum.map(get_resource_field2(resource, name), &(&1.id))
    fieldset(".inputs") do
      ol do
        li ".select.input.optional##{model_name}_#{name}_input" do
          name_str = "#{model_name}[#{name_ids}][]"
          Xain.input name: name_str, type: "hidden", value: ""
          label ".label #{humanize name}", for: "#{model_name}_#{name_ids}"
          select id: "#{model_name}_#{name_ids}", multiple: "multiple", name: name_str do
            for opt <- collection do
              selected = if opt.id in assoc_ids, do: [selected: "selected"], else: []
              option "#{opt.name}", [value: "#{opt.id}"] ++ selected
            end
          end
          build_errors(errors)
        end
      end
    end
  end

  def build_item(conn, %{type: :inputs} = item, resource, model_name, errors) do
    opts = Map.get(item, :opts, [])

    fieldset(".inputs", opts) do
      build_fieldset_legend(item[:name]) 
      ol do
        ret = for inpt <- item[:inputs] do
          build_item(conn, inpt, resource, model_name, errors)
        end
      end
    end
    ret
  end

  def build_has_many_fieldset(conn, res, fields, orig_inx, ext_name, field_field_name, model_name, errors) do
    inx = cond do
      is_nil(res) -> orig_inx 
      res.id ->  orig_inx
      true -> timestamp   # case when we have errors. need to remap the inx 
    end

    fieldset ".inputs.has_many_fields" do
      ol do
        # build the destroy field
        base_name = "#{model_name}[#{field_field_name}][#{inx}]"
        base_id = "#{ext_name}__destroy"
        li [id: "#{base_id}_input", class: "boolean input optional"] do
          name = "#{base_name}[_destroy]"
          Xain.input type: :hidden, value: "0", name: name
          label for: base_id do 
            Xain.input type: :checkbox, id: "#{base_id}", name: name, value: "1"
            text "Remove"
          end
        end

        for field <- fields do
          f_name = field[:name]
          name = "#{base_name}[#{f_name}]"
          errors = get_errors(errors, "#{model_name}[#{field_field_name}][#{orig_inx}][#{f_name}]")
          error = if errors in [nil, [], false], do: "", else: ".error"
          case field[:opts] do
            %{collection: collection} -> 
              is_function(collection) do
                collection = collection.(conn, res)
              end
              li ".select.input.required#{error}", [id: "#{ext_name}_label_input"] do
                label ".label #{humanize f_name}", for: "#{ext_name}_#{f_name}" do
                  abbr "*", title: "required"
                end
                select "##{ext_name}_#{f_name}", [name: name ] do
                  for opt <- collection do
                    if not is_nil(res) and (Map.get(res, f_name) == opt) do
                      option "#{opt}", [value: escape_value(opt), selected: :selected]
                    else
                      option "#{opt}", [value: escape_value(opt)]
                    end
                  end
                end
                build_errors(errors)
              end
            _ -> 
              li ".string.input.required.stringish#{error}", id: "#{ext_name}_#{f_name}_input"  do
                label ".label #{humanize f_name}", for: "#{ext_name}_#{f_name}" do
                  abbr "*", title: "required"
                end
                val = if res, do: [value: Map.get(res, f_name, "") |> escape_value], else: []
                Xain.input([type: :text, maxlength: "255", id: "#{ext_name}_#{f_name}", 
                  name: name] ++ val)
                build_errors(errors)
              end
          end
        end
        unless res do
          li do
            a ".button Delete", href: "#", 
              onclick: ~S|$(this).closest(\".has_many_fields\").remove(); return false;|
          end
        end
      end
    end
    inx
  end

  def get_label(field_name, opts) do
    cond do
      Map.get(opts, :type) in ["hidden", :hidden] -> 
        :none
      Map.get(opts, :display) -> 
        {:hidden, Map.get(opts, :label, field_name) }
      Map.get(opts, :ajax) -> 
        {:ajax, Map.get(opts, :label, field_name)}
      true -> 
        Map.get opts, :label, field_name
    end
  end

  defp new_record_name(field_name) do
    name = field_name
    |> Atom.to_string
    |> Inflex.singularize
    |> String.replace(" ", "_")
    |> String.upcase
    "NEW_#{name}_RECORD"
  end

  defp build_actions_block(conn, model_name, mode) do
    display_name = ExAdmin.Utils.displayable_name_singular conn
    label = if mode == :new, do: "Create", else: "Update"
    fieldset(".actions") do
      ol do
        li(".action.input_action##{model_name}_submit_action") do
          Xain.input name: "commit", type: :submit, value: escape_value("#{label} #{humanize display_name}")
        end
        li(".cancel") do
          a("Cancel", href: get_route_path(conn, :index))
        end
      end
    end
  end

  defp escape_value(value) do
    Phoenix.HTML.html_escape(value) |> elem(1)
  end

  def build_field_errors(conn, field_name) do
    conn.private 
    |> Map.get(:phoenix_flash, %{})
    |> Map.get("inline_error", [])
    |> get_errors(field_name)
    |> Enum.reduce("", fn(error, acc) -> 
      acc <> """
      <p class="inline-errors">#{error_messages error}</p>
      """
    end)
  end

  defp binary_tuple?([]), do: false
  defp binary_tuple?(collection) do
    Enum.all?(collection, &(is_binary(&1) or (is_tuple(&1) and (tuple_size(&1) == 2))))
  end

  def extra_javascript(model_name, param, attr) do
    {"var extra = $('##{model_name}_#{attr}').val();\n", "&#{param}='+extra+'"}
  end

  def get_errors(nil, _field_name), do: nil

  # def get_errors(errors, field_name) when is_binary(field_name) do
  #   get_errors errors, String.to_atom(field_name)
  # end
  def get_errors(errors, field_name) do
    Enum.reduce errors, [], fn({k, v}, acc) -> 
      if k == field_name, do: [v | acc], else: acc
    end
  end

  def build_errors(nil), do: nil
  def build_errors(errors) do
    for error <- errors do
      p ".inline-errors #{error_messages error}"
    end
    errors
  end

  def error_messages(:unique), do: "has already been taken"
  def error_messages(:invalid), do: "has to be valid"
  def error_messages({:too_short, min}), do: "must be longer than #{min - 1}"
  def error_messages({:must_match, field}), do: "must match #{humanize field}"
  def error_messages(:format), do: "has incorrect format"
  def error_messages(other) when is_binary(other), do: other
  def error_messages(other), do: "error: #{inspect other}"
end

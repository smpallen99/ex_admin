defmodule ExAdmin.Form do
  require Logger
  import ExAdmin.Utils
  import ExAdmin.Helpers
  import ExAdmin.DslUtils

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

  defmacro form(resource, [do: block]) do
    contents = quote do
      unquote(block)
    end

    quote location: :keep, bind_quoted: [resource: escape(resource), contents: escape(contents)] do
      def form_view(conn, unquote(resource) = var!(resource), var!(params) = params) do 
        import ExAdmin.Register, except: [actions: 1]
        # var!(query_options) = []
        var!(input_blocks, ExAdmin.Form) = [] 
        var!(script_block, ExAdmin.Form) = nil
        unquote(contents)
        items = var!(input_blocks, ExAdmin.Form) |> Enum.reverse
        script_block = var!(script_block, ExAdmin.Form)
        # IO.puts "----------------------------"
        # Enum.each items, fn(i) -> 
        #   IO.puts "----> form_view item: #{inspect i}"
        # end
        # IO.puts "----------------------------"
        ExAdmin.Form.build_form(conn, var!(resource), items, var!(params), script_block)
      end
    end
  end

  #defmacro inputs(name \\ quote(do: ""), opts \\ quote(do: []))
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
    mode = if params[:id], do: :edit, else: :new
    markup do
      model_name = Map.get(resource, :__struct__, "") |> base_name |> Inflex.parameterize("_")
      action = get_action(conn, resource, mode)

      Xain.form "accept-charset": "UTF-8", action: "#{action}", class: "formtastic #{model_name}", 
          id: "new_#{model_name}", method: :post, novalidate: :novalidate  do

        build_hidden_block(conn, mode)
        build_main_block(conn, resource, model_name, items) 
        build_actions_block(conn, model_name, mode) 
      end 
      if script_block do
        Xain.text "\n"
        Xain.script type: "text/javascript" do
          text "\n" <> script_block <> "\n"
        end
      end
    end
  end
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
  # def build_field_input({field_name, %{type: :collection} = map}, resource, model_name) do

  #   %{fields: assoc_fields, query: query} = map

  #   ext_name = "#{model_name}_#{field_name}"
  #   owner_key = get_association_owner_key(resource, field_name) 

  #   li( class: "string input optional stringish", id: "#{ext_name}_input") do
  #     label(".label #{humanize field_name}", for: ext_name)
  #     select("#{ext_name}_id", name: "#{model_name}[#{owner_key}]") do
  #       for item <- query_association(resource.__struct__, field_name, query) do

  #         selected = if Map.get(resource, owner_key) == item.id, 
  #           do: [selected: :selected], else: []

  #         map_relationship_fields(item, assoc_fields)
  #         option([value: "#{item.id}"] ++ selected)
  #       end
  #     end
  #   end  
  # end


  defp build_main_block(conn, resource, model_name, schema) do
    errors = Phoenix.Controller.get_flash(conn, :inline_error)
    for item <- schema do
      build_item(item, resource, model_name, errors)
    end
  end

  def wrap_item(field_name, model_name, label, error, contents) do
    ext_name = "#{model_name}_#{field_name}"
    error = if error in [nil, [], false], do: "", else: "error "
    li( class: "string input optional #{error}stringish", id: "#{ext_name}_input") do
      label(".label #{humanize label}", for: ext_name)
      contents.(ext_name)
    end
  end

  defp build_select_binary_tuple_list(collection, item, field_name, resource, model_name, ext_name) do
    select("##{ext_name}_id", name: "#{model_name}[#{field_name}]") do
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

  def build_item(%{type: :script, contents: contents}, _resource, model_name, _errors) do
    script type: "javascript" do 
      #text "\n  //<![CDATA[\n" <> contents <> "\n  //]]>\n"
      text "\n" <> contents <> "\n"
    end
  end

  def build_item(%{type: :input, name: field_name, resource: resource, 
       opts: %{collection: collection}} = item, _resource, model_name, errors) do
    errors = get_errors(errors, field_name)
    label = Map.get item[:opts], :label, field_name
    wrap_item(field_name, model_name, label, errors, fn(ext_name) -> 
      if Enum.all?(collection, &(is_binary(&1) or (is_tuple(&1) and (tuple_size(&1) == 2)))) do 
        build_select_binary_tuple_list(collection, item, field_name, resource, model_name, ext_name) 
      else
        owner_key = get_association_owner_key(resource, field_name) 
        assoc_fields = get_association_fields(item[:opts])
        select(id: "#{ext_name}_id", name: "#{model_name}[#{owner_key}]") do
          for item <- collection do

            selected = if Map.get(resource, owner_key) == item.id, 
              do: [selected: :selected], else: []

            map_relationship_fields(item, assoc_fields)
            |> option([value: "#{item.id}"] ++ selected) 
          end
        end
      end
      build_errors(errors)
    end)  
  end

  def build_item(%{type: :actions, items: items}, resource, model_name, errors) do
    fieldset ".actions" do
      for i <- items do
        build_item(i, resource, model_name, errors)
      end
    end
  end

  def build_item(%{type: :content, content: content}, _resource, _model_name, _errors) when is_binary(content) do
    text content
  end
  def build_item(%{type: :content, content: content}, _resource, _model_name, _errors) do
    # {:safe, content} = content
    text elem(content, 1)
  end

  def build_item(%{type: :input, resource: resource, name: field_name, opts: opts}, 
       _resource, model_name, errors) do
    errors = get_errors(errors, field_name)
    label = Map.get opts, :label, field_name
    wrap_item(field_name, model_name, label, errors, fn(ext_name) -> 
      Map.put_new(opts, :type, :text)
      |> Map.put_new(:maxlength, "255")
      |> Map.put_new(:name, "#{model_name}[#{field_name}]")
      |> Map.put_new(:id, ext_name)
      |> Map.put_new(:value, Map.get(resource, field_name, "") |> escape_value)
      |> Map.to_list
      |> Xain.input
      build_errors(errors)
    end)
  end

  def build_item(%{type: :has_many, resource: resource, name: field_name, 
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

          new_inx = build_has_many_fieldset(res, fields, inx, ext_name, field_field_name, model_name, errors)
          
          Xain.input [id: "#{ext_name}_id", 
            name: "#{model_name}[#{field_field_name}][#{new_inx}][id]",
            value: "#{res.id}", type: :hidden]  
        end
        {_, html} = markup :nested do
          ext_name = "#{model_name}_#{field_field_name}_#{new_record_name_var}"
          fields = fun.(ExAdmin.Repo.get_assoc_model(resource, field_name)) |> Enum.reverse
          build_has_many_fieldset(nil, fields, new_record_name_var, ext_name, field_field_name, model_name, errors)
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
  def build_item(%{type: :inputs, name: name, opts: %{collection: collection}}, 
      resource, model_name, errors) when is_atom(name) do
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

  def build_item(%{type: :inputs} = item, resource, model_name, errors) do
    opts = Map.get(item, :opts, [])

    fieldset(".inputs", opts) do
      build_fieldset_legend(item[:name]) 
      ol do
        for inpt <- item[:inputs] do
          build_item(inpt, resource, model_name, errors)
        end
      end
    end
  end

  def build_has_many_fieldset(res, fields, orig_inx, ext_name, field_field_name, model_name, errors) do
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
  def error_messages(other), do: "error: #{inspect other}"
end

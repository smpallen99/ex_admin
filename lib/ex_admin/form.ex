defmodule ExAdmin.Form do
  @moduledoc """
  Override the default new and edit form pages for an ExAdmin resource.

  By default, ExAdmin renders the form page without any additional
  configuration. It renders each column in the model, except the id,
  inserted_at, and updated_at columns in an attributes table.

  To customize the new and edit pages, use the `form` macro.

  For example, the following will show on the id an name fields, as
  well place a selection column and batch actions row on the page:

      defmodule MyProject.ExAdmin.Contact do
        use ExAdmin.Register

        register_resource MyProject.Contact do

          form contact do
            inputs do
              input contact, :first_name
              input contact, :last_name
              input contact, :email
              input contact, :register_date, type: Date
              input contact, :category, collection: MyProject.Category.all
            end

            inputs "Groups" do
              inputs :groups, as: :check_boxes, collection: MyProject.Group.all
            end
          end
        end
      end

  ## The form command

  Call form with a name for your resource and a do block.

  ## The inputs command

  Calling inputs with a do block displays a field set with the specified inputs
  from the block.

  Adding a label to inputs, labels the field set.

  ## The input command

  The first argument is input is alway the resource name give to the form
  command. The second argument is the the field name expressed as an atom.
  Optionally, a third argument can be a keyword list.

  ### Override the default label

      input resource, :name, label: "Customer Name"

  ### Specify a collection

      input resource, :category, collection: Repo.all(Category)

  ### Specify the field names for a collection

      input resource, :user, fields: [:first_name, :email]

  ### Specifying type of control

      input user, :password, type: :password

      # If you use :naive_datetime or :utc_datetime in your schema instead of Ecto.DateTime
      input user, :register_datetime, type: DateTime

  ### Array field support

      # default  tag style
      input user, :nicknames

      # multi select restricted to the provided collection
      input user, :groups, select2: [collection: ~w(Sales Marketing Dev)]

      # tags style with the extra collection options
      input user, :groups, select2: [collection: ~w(Sales Marketing Dev)]

  ### Customizing DateTime fields

      input user, :start_at, options: [sec: []]

  Most of the options from the `datetime_select` control from
  `phoenix_html` should work.

  ### Map field support

  Since maps don't have a defined schema, you can define the schema as an option
  to the input macro. For example:

      form user do
        inputs "User Details" do
          input user, :name
        end
        inputs "Statistics" do
          input user, :stats, schema: [age: :integer, height: :string, birthday: :string]
        end
      end

  ### Array of maps field support

  Like maps, you must provided the schema for an array of maps. For example:

      form user do
        inputs "User Details" do
          input user, :name
        end
        inputs "Addresses" do
          input user, :addresses, schema: [street: :string, city: :string]
        end
      end

  ## Rendering a has_many :through (many-to-many) relationship

  The example at the beginning of the chapter illustrates how to add
  a list of groups, displaying them as check boxes.

      inputs "Groups" do
        inputs :groups, as: :check_boxes, collection: MyProject.Group.all
      end

  ## Nested attributes

  ExAdmin supports in-line creation of a has_many, through: (many-to-many)
  relationship. The example below allows the user to add/delete phone numbers on the
  contact form using the has_many command.

      form contact do
        inputs do
          input contact, :first_name
          input contact, :last_name
          input contact, :email
          input contact, :category, collection: UcxNotifier.Category.all
        end

        inputs "Phone Numbers" do
          has_many contact, :phone_numbers, fn(p) ->
            input p, :label, collection: PhoneNumber.labels
            input p, :number
          end
        end
      end

  Note: has_many does not yet work with simple one-to-many relationships.

  # Adding conditional fields

  The following complicated example illustrates a number of concepts
  possible in a form definition. The example allows management of an
  authentication token for a user while on the edit page.

  First, the `if params[:id] do` condition ensures that the code block
  only executes for an edit form, and not a new form.

  Next, the actions command adds in-line content to an inputs block.

      form user do
        inputs "User Details" do
          input user, :name
          # ...
        end

        if params[:id] do
          inputs "Authentication Token" do
            actions do
              user = Repo.get User, params[:id]
              if user.authentication_token do
                content content_tag(:li, user.authentication_token, style: "padding: 5px 10px")
                content content_tag(:li, token_link("Reset Token", :reset, params[:id]), class: "cancel")
                content content_tag(:li, token_link("Delete Token", :delete, params[:id]), class: "cancel")
              else
                content content_tag(:li, token_link("Create Token", :create, params[:id]),
                  class: "cancel", style: "padding-left: 20px")
              end
            end
          end
        end

      end

  ## The javascript command

  Use the javascript command to add javascript to the form page.

  For example, the following adds a change handler to get a list of
  assets using an ajax call:

      javascript do
        \"""
        $(document).ready(function() {
          $('#asset_assetable_type_id').change(function() {
            $.get('/assets/'+$(this).val()+'/assetables?format=js');
          });
        });
        \"""
      end
  """

  use ExAdmin.Adminlog

  import ExAdmin.Utils
  import ExAdmin.Helpers
  import ExAdmin.DslUtils
  import ExAdmin.Form.Fields
  import ExAdmin.ViewHelpers, only: [escape_javascript: 1]
  require IEx
  import ExAdmin.Theme.Helpers
  alias ExAdmin.Schema

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

  @doc """
  Customize the form page.

  Use the form command to customize the new and edit page forms. Pass
  a name for the resource to be created or modified.
  """
  defmacro form(resource, do: contents) do
    quote location: :keep,
          bind_quoted: [resource: escape(resource), contents: escape(contents)] do
      import ExAdmin.Index, only: [index: 1]

      def form_view(var!(conn), unquote(resource) = var!(resource), var!(params) = params) do
        import ExAdmin.Register, except: [actions: 1]

        var!(input_blocks, ExAdmin.Form) = []
        var!(script_block, ExAdmin.Form) = nil
        unquote(contents)
        items = var!(input_blocks, ExAdmin.Form) |> Enum.reverse()
        script_block = var!(script_block, ExAdmin.Form)

        Module.concat(var!(conn).assigns.theme, Form).build_form(
          var!(conn),
          var!(resource),
          items,
          var!(params),
          script_block,
          ExAdmin.Form.global_script()
        )
      end

      def get_blocks(var!(conn), unquote(resource) = var!(resource), var!(params) = _params) do
        # TODO: do we need the passed params? they are not used.
        _ = {var!(conn), var!(resource), var!(params)}
        import ExAdmin.Register, except: [actions: 1]
        var!(input_blocks, ExAdmin.Form) = []
        var!(script_block, ExAdmin.Form) = nil
        unquote(contents)
        var!(input_blocks, ExAdmin.Form) |> Enum.reverse()
      end

      def ajax_view(conn, params, resource, resources, block) do
        defn = conn.assigns.defn
        field_name = String.to_atom(params[:field_name])
        model_name = model_name(resource)
        ext_name = ext_name(model_name, field_name)

        view =
          markup safe: true do
            ExAdmin.Form.Fields.ajax_input_collection(
              resource,
              resources,
              model_name,
              field_name,
              params[:id1],
              params[:nested2],
              block,
              conn.params
            )
          end

        ~s/$('##{ext_name}_input').html("#{escape_javascript(view)}");/
      end
    end
  end

  @doc """
  Add an fieldset to the form
  """
  defmacro inputs(opts) do
    quote(do: inputs("", unquote(opts)))
  end

  @doc """
  Add a has_many field to a form.
  """
  defmacro inputs(name, opts, do: block) do
    quote location: :keep do
      import Xain, except: [input: 1]
      # inputs_save = var!(inputs, ExAdmin.Form)
      var!(inputs, ExAdmin.Form) = []
      unquote(block)
      items = var!(inputs, ExAdmin.Form) |> Enum.reverse()
      # var!(inputs, ExAdmin.Form) = inputs_save
      input_block = %{type: :inputs, name: unquote(name), inputs: items, opts: unquote(opts)}
      var!(input_blocks, ExAdmin.Form) = [input_block | var!(input_blocks, ExAdmin.Form)]
    end
  end

  @doc """
  Add a named fieldset to a form.

  Works the same as inputs/1, but labels the fieldset with name
  """
  defmacro inputs(name, do: block) do
    quote location: :keep do
      import Xain, except: [input: 1]
      # inputs_save = var!(inputs, ExAdmin.Form)
      var!(inputs, ExAdmin.Form) = []
      unquote(block)
      items = var!(inputs, ExAdmin.Form) |> Enum.reverse()
      # var!(inputs, ExAdmin.Form) = inputs_save
      input_block = %{type: :inputs, name: unquote(name), inputs: items, opts: []}
      var!(input_blocks, ExAdmin.Form) = [input_block | var!(input_blocks, ExAdmin.Form)]
    end
  end

  @doc """
  Add a has_many field to a form.
  """
  defmacro inputs(name, opts) do
    quote location: :keep do
      import Xain, except: [input: 1]
      opts = Enum.into(unquote(opts), %{})
      item = %{type: :inputs, name: unquote(name), opts: opts}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  @doc """
  Display an input field on the form.

  Display all types of form inputs.

  ## Options

    * `:type` - Sets the type of the control (`:password`, `:hidden`, etc)

    * `:label` - Sets a custom label

    * `:collection` - Sets the collection to render for a `belongs_to` relationship

    * `:fields` - Sets a list of fields to be used in a select control.
      For example `input post :user, fields: [:first_name, :last_name]`
      would render a control like:

          <select>
            <option id="1">José Valim</option>
            <option id="2">Chris McCord</option>
          </select>

    * `:prompt` - Sets a HTML placeholder

    * `:change` - Sets change handler to a control. When set to a string,
      the string is assumed to be javascript and added with the control.
      When a keyword list, the list is used to define what should happen
      when the input changes. See the section below on valid keywords.

    * `:ajax` - Used for ajax controls. See ajax below

    * `:display` - When set to false, the control and its label are
      hidden with `style="display: none"`. Use this to hide inputs
      that will later be displayed with javascript or an ajax request

    * `:as` - Sets the type of collection. Valid options are:
      * `:check_boxes` - Use check boxes
      * `:radio` - Use radio buttons

  ## Ajax controls

  Use the ajax: true, change: [...] do allow dynamic updating of
  nested collection inputs.

  For example, assume a page for purchasing
  a product, where the product has a number of options and each option
  has different possible color selections.

  When option 1 is selected, they have the choice of red or black. If
  option 2 is selected, they have the choice of red or green. So, based
  on the option selected, the color select needs to be dynamically reloaded.

  TBD: Complete this



  """
  defmacro input(resource, name, opts \\ []) do
    quote do
      opts = Enum.into(unquote(opts), %{})
      item = %{type: :input, resource: unquote(resource), name: unquote(name), opts: opts}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  @doc """
  Display a nested resource on the form.

  Adds management of a has_many resource to the page, allowing in-line
  addition, editing, and deletion of the nested resource.

  """
  defmacro has_many(resource, name, opts \\ [], fun \\ nil) do
    quote do
      opts = ExAdmin.DslUtils.fun_to_opts(unquote(opts), unquote(fun))
      item = %{type: :has_many, resource: unquote(resource), name: unquote(name), opts: opts}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  @doc """
  Add an action block to a form

  TBD: Add more description here
  """
  defmacro actions(do: block) do
    quote do
      var!(inputs, ExAdmin.Form) = []
      var!(items, ExAdmin.Form) = []
      unquote(block)
      items = var!(items, ExAdmin.Form) |> Enum.reverse()
      item = %{type: :actions, name: "", items: items}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  @doc """
  Add a HTML content block to a form

  For example:

      content do
        \"""
        <div>Something here</div>
        <div>More stuff here</div>
        \"""
      end
  """
  defmacro content(do: block) do
    quote do
      contents = unquote(block)
      item = %{type: :content, name: "", content: unquote(block), opts: []}
      var!(inputs, ExAdmin.Form) = [item | var!(inputs, ExAdmin.Form)]
    end
  end

  @doc """
  Add HTML content to a form.

  Can be called multiple times to append HTML content for a page

  For example:

      content content_tag(:li, user.authentication_token, style: "padding: 5px 10px")
      content content_tag(:li, token_link("Reset Token", :reset, params[:id]), class: "cancel")
      content content_tag(:li, token_link("Delete Token", :delete, params[:id]), class: "cancel")

  """
  defmacro content(items, opts \\ quote(do: [])) do
    quote do
      item = %{type: :content, content: unquote(items), opts: unquote(opts)}
      var!(items, ExAdmin.Form) = [item | var!(items, ExAdmin.Form)]
    end
  end

  @doc """
  Add javascript to the form

  Adds a block of javascript code to the form. Typically used to add
  change or click handlers to elements on the page
  """
  defmacro javascript(do: block) do
    quote do
      var!(script_block, ExAdmin.Form) = unquote(block)
    end
  end

  #################
  # Functions

  defp build_item(resource, defn, name) do
    Adminlog.debug("build_item 1 ....")

    case translate_field(defn, name) do
      field when field == name ->
        %{type: :input, resource: resource, name: name, opts: %{}}

      {:map, _field} ->
        %{type: :input, resource: resource, name: name, opts: %{map: true}}

      {:maps, _field} ->
        %{type: :input, resource: resource, name: name, opts: %{maps: true}}

      field ->
        case resource.__struct__.__schema__(:association, field) do
          %Ecto.Association.BelongsTo{cardinality: :one, queryable: assoc} ->
            collection = Application.get_env(:ex_admin, :repo).all(assoc)
            %{type: :input, resource: resource, name: field, opts: %{collection: collection}}

          _ ->
            nil
        end
    end
  end

  def setup_resource(resource, params, model_name) do
    model_name = String.to_atom(model_name)

    case params[model_name] do
      nil ->
        resource

      model_params ->
        struct(resource, Map.to_list(model_params))
    end
  end

  def put_script_block(script_block) do
    if script_block do
      Xain.script type: "text/javascript" do
        text("\n" <> script_block <> "\n")
      end
    end
  end

  def build_scripts(list) do
    head = "$(function() {\n"
    script = for i <- list, is_tuple(i), into: head, do: build_script(i)
    script <> "});"
  end

  def build_script({:change, %{id: id, script: script}}) do
    """
    $(document).on('change','##{id}', function() {
      #{script}
    });
    """
  end

  def build_script(_other), do: ""

  def get_action(resource, mode) do
    case mode do
      :new ->
        admin_resource_path(resource, :create)

      :edit ->
        admin_resource_path(resource, :update)
    end
  end

  defp get_put_fields(:edit) do
    Xain.input(name: "_method", value: "put", type: "hidden")
  end

  defp get_put_fields(_), do: nil

  def build_hidden_block(_conn, mode) do
    csrf = Plug.CSRFProtection.get_csrf_token()

    div style: "margin:0;padding:0;display:inline" do
      Xain.input(name: "utf8", type: :hidden, value: "✓")
      Xain.input(type: :hidden, name: "_csrf_token", value: csrf)
      get_put_fields(mode)
    end
  end

  def build_main_block(conn, resource, model_name, schema) do
    errors = Phoenix.Controller.get_flash(conn, :inline_error)

    for item <- schema do
      item = put_in(item, [:required], conn.assigns[:ea_required] || [])
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
    cond do
      params["id"] -> []
      params[model_name][params_name(resource, field_name, params)] -> []
      true -> display_style
    end
  end

  defp field_type(resource, field_name) do
    field_type_matching = Application.get_env(:ex_admin, :field_type_matching) || %{}
    original_ft = resource.__struct__.__schema__(:type, field_name)
    Map.get(field_type_matching, original_ft, original_ft)
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

  @doc false
  def wrap_item(resource, field_name, model_name, label, error, opts, params, required, contents) do
    as = Map.get(opts, :as)
    ajax = Map.get(opts, :ajax)
    ext_name = ext_name(model_name, field_name)

    display_style =
      check_display(opts)
      |> check_params(resource, params, model_name, field_name, ajax)

    {label, hidden} =
      case label do
        {:hidden, l} -> {l, @hidden_style}
        l when l in [:none, false] -> {"", @hidden_style}
        l -> {l, display_style}
      end

    {error, hidden} =
      if error in [nil, [], false] do
        {"", hidden}
      else
        {"error ", []}
      end

    {
      theme_module(Form).theme_wrap_item(
        field_type(resource, field_name),
        ext_name,
        label,
        hidden,
        ajax,
        error,
        contents,
        as,
        required
      ),
      ext_name
    }
  end

  def wrap_item_type(type, label, ext_name, contents, error, required) do
    ExAdmin.theme().wrap_item_type(type, label, ext_name, contents, error, required)
  end

  defp build_select_binary_tuple_list(
         collection,
         item,
         field_name,
         resource,
         model_name,
         ext_name
       ) do
    html_opts = item[:opts][:html_opts] || []
    html_opts = Keyword.merge([name: "#{model_name}[#{field_name}]"], html_opts)

    select "##{ext_name}_id.form-control", html_opts do
      handle_prompt(field_name, item)

      for item <- collection do
        {value, name} =
          case item do
            {value, name} -> {value, name}
            other -> {other, other}
          end

        selected = if Map.get(resource, field_name) == value, do: [selected: :selected], else: []
        option(name, [value: value] ++ selected)
      end
    end
  end

  @doc false
  def build_item(_conn, %{type: :script, contents: contents}, _resource, _model_name, _errors) do
    Adminlog.debug("build_item 2:")

    script type: "javascript" do
      text("\n" <> contents <> "\n")
    end
  end

  def build_item(
        conn,
        %{type: :input, field_type: :map, name: field_name, resource: _resource} = item,
        resource,
        model_name,
        _error
      ) do
    Adminlog.debug("build_item 11: #{inspect(field_name)}")

    schema = get_schema(item, field_name)
    data = Map.get(resource, field_name, model_name) || %{}

    for {field, type} <- schema do
      build_input(conn, type, field, field_name, data, model_name)
    end
    |> Enum.join("\n")
  end

  def build_item(
        conn,
        %{type: :input, field_type: {:array, :map}, name: field_name, resource: _resource} = item,
        resource,
        model_name,
        error
      ) do
    Adminlog.debug("build_item 12: #{inspect(field_name)}")

    schema = get_schema(item, field_name)

    human_label = "#{humanize(field_name) |> Inflex.singularize()}"
    new_record_name_var = new_record_name(field_name)

    div ".has_many.#{field_name}" do
      {contents, html} =
        theme_module(conn, Form).build_inputs_has_many(field_name, human_label, fn ->
          resource_contents =
            (Map.get(resource, field_name) || [])
            |> Enum.with_index()
            |> Enum.map(fn {res, inx} ->
              errors = map_array_errors(error, field_name, inx)

              html =
                theme_module(conn, Form).theme_map_field_set(
                  conn,
                  res,
                  schema,
                  inx,
                  field_name,
                  model_name,
                  errors
                )

              html
            end)

          fieldset_contents =
            theme_module(conn, Form).theme_map_field_set(
              conn,
              nil,
              schema,
              new_record_name(field_name),
              field_name,
              model_name,
              nil
            )

          {fieldset_contents, resource_contents}
        end)

      {_, onclick} =
        Phoenix.HTML.html_escape(
          theme_module(conn, Form).has_many_insert_item(contents, new_record_name_var)
        )

      markup do
        html

        theme_module(conn, Form).theme_button(
          "Add New #{human_label}",
          href: "#",
          onclick: onclick,
          type: ".btn-primary"
        )
      end
    end
  end

  @doc """
  Private: Build a belongs_to control.

  Generate a select box for a belongs_to control.
  """
  def build_item(
        conn,
        %{type: :input, name: field_name, resource: _resource, opts: %{collection: collection}} =
          item,
        resource,
        model_name,
        error
      ) do
    Adminlog.debug("build_item 3: #{inspect(field_name)}")

    # IO.puts "build_item 3: #{inspect field_name}"
    collection = if is_function(collection), do: collection.(conn, resource), else: collection
    module = resource.__struct__

    errors_field_name =
      if field_name in module.__schema__(:associations) do
        Map.get(module.__schema__(:association, field_name), :owner_key)
      else
        field_name
      end

    required = if errors_field_name in (conn.assigns[:ea_required] || []), do: true, else: false
    errors = get_errors(error, errors_field_name)

    label = Map.get(item[:opts], :label, field_name)
    onchange = Map.get(item[:opts], :change)

    binary_tuple = binary_tuple?(collection)

    {html, _id} =
      wrap_item(
        resource,
        field_name,
        model_name,
        label,
        errors,
        item[:opts],
        conn.params,
        required,
        fn ext_name ->
          item = update_in(item[:opts], &(Map.delete(&1, :change) |> Map.delete(:ajax)))

          markup do
            if binary_tuple do
              build_select_binary_tuple_list(
                collection,
                item,
                field_name,
                resource,
                model_name,
                ext_name
              )
            else
              input_collection(
                resource,
                collection,
                model_name,
                field_name,
                nil,
                nil,
                item,
                conn.params,
                error
              )
            end

            build_errors(errors, item[:opts][:hint])
          end
        end
      )

    id = ext_name(model_name, field_name)

    value =
      case onchange do
        script when is_binary(script) ->
          {:change, %{id: id <> "_id", script: onchange}}

        list when is_list(list) ->
          update = Keyword.get(list, :update)
          params = Keyword.get(list, :params)

          if update do
            route_path = admin_resource_path(resource.__struct__, :index)
            target = pluralize(field_name)
            nested = pluralize(update)

            {extra, param_str} =
              case params do
                atom when is_atom(atom) -> extra_javascript(model_name, atom, atom)
                [{param, attr}] -> extra_javascript(model_name, param, attr)
                _ -> {"", ""}
              end

            control_id = "#{model_name}_#{update}_input"

            get_cmd =
              if resource.id do
                "$.get('#{route_path}/#{resource.id}/#{target}/'+$(this).val()+'/#{nested}"
              else
                "$.get('#{route_path}/#{target}/'+$(this).val()+'/#{nested}"
              end

            script =
              "$('##{control_id}').show();\n" <>
                extra <>
                "console.log('show #{control_id}');\n" <>
                get_cmd <> "/?field_name=#{update}#{param_str}&format=js');\n"

            {:change, %{id: id <> "_id", script: script}}
          end

        _ ->
          nil
      end

    if onchange do
      {html, value}
    else
      html
    end
  end

  def build_item(conn, %{type: :actions, items: items}, resource, model_name, errors) do
    Adminlog.debug("build_item 4: #{inspect(model_name)}")

    fieldset ".actions" do
      for i <- items do
        build_item(conn, i, resource, model_name, errors)
      end
    end
  end

  def build_item(_conn, %{type: :content, content: content}, _resource, _model_name, _errors)
      when is_binary(content) do
    Adminlog.debug("build_item 5.")
    text(content)
  end

  def build_item(_conn, %{type: :content, content: content}, _resource, _model_name, _errors) do
    Adminlog.debug("build_item 6.")
    text(elem(content, 1))
  end

  def build_item(
        conn,
        %{type: :input, resource: _resource, name: field_name, opts: opts},
        resource,
        model_name,
        errors
      ) do
    Adminlog.debug("build_item 7: #{inspect(field_name)}")
    errors = get_errors(errors, field_name)
    label = get_label(field_name, opts)
    required = if field_name in (conn.assigns[:ea_required] || []), do: true, else: false

    {html, _id} =
      wrap_item(
        resource,
        field_name,
        model_name,
        label,
        errors,
        opts,
        conn.params,
        required,
        fn ext_name ->
          field_type = opts[:type] || field_type(resource, field_name)

          [
            build_control(field_type, resource, opts, model_name, field_name, ext_name),
            build_errors(errors, opts[:hint])
          ]
        end
      )

    html
  end

  def build_item(
        conn,
        %{type: :has_many, resource: _resource, name: field_name, opts: %{fun: fun}},
        resource,
        model_name,
        errors
      ) do
    Adminlog.debug("build_item 8: #{inspect(field_name)}")
    field_field_name = "#{field_name}_attributes"
    human_label = "#{humanize(field_name) |> Inflex.singularize()}"
    new_record_name_var = new_record_name(field_name)

    div ".has_many.#{field_name}" do
      {contents, html} =
        theme_module(conn, Form).build_inputs_has_many(field_name, human_label, fn ->
          resource_content =
            get_resource_field2(resource, field_name)
            |> Enum.with_index()
            |> Enum.map(fn {res, inx} ->
              fields = fun.(res) |> Enum.reverse()
              ext_name = "#{model_name}_#{field_field_name}_#{inx}"

              res =
                cond do
                  is_tuple(res) -> elem(res, 1)
                  true -> res
                end

              {new_inx, html} =
                build_has_many_fieldset(
                  conn,
                  res,
                  fields,
                  inx,
                  ext_name,
                  field_name,
                  field_field_name,
                  model_name,
                  errors
                )

              res_id = ExAdmin.Schema.get_id(res)

              markup do
                html

                Xain.input(
                  id: "#{ext_name}_id",
                  name: "#{model_name}[#{field_field_name}][#{new_inx}][id]",
                  value: "#{res_id}",
                  type: :hidden
                )
              end
            end)

          ext_name = "#{model_name}_#{field_field_name}_#{new_record_name_var}"

          {assoc_model, _} =
            assoc_model_tuple = ExAdmin.Repo.get_assoc_model(resource, field_name)

          fields = fun.(assoc_model_tuple) |> Enum.reverse()

          {_, fieldset_contents} =
            build_has_many_fieldset(
              conn,
              assoc_model.__struct__,
              fields,
              new_record_name_var,
              ext_name,
              field_name,
              field_field_name,
              model_name,
              errors
            )

          {fieldset_contents, resource_content}
        end)

      html

      {_, onclick} =
        Phoenix.HTML.html_escape(
          theme_module(conn, Form).has_many_insert_item(contents, new_record_name_var)
        )

      theme_module(conn, Form).theme_button(
        "Add New #{human_label}",
        href: "#",
        onclick: onclick,
        type: ".btn-primary"
      )
    end
  end

  @doc """
  Handle building an inputs :name, as: ...
  """
  def build_item(
        conn,
        %{type: :inputs, name: name, opts: %{collection: collection} = opts},
        resource,
        model_name,
        errors
      )
      when is_atom(name) do
    Adminlog.debug("build_item 9: #{inspect(name)}")
    collection = if is_function(collection), do: collection.(conn, resource), else: collection
    errors = get_errors(errors, name)
    name_ids = "#{Atom.to_string(name) |> Inflex.singularize()}_ids"

    name_str = "#{model_name}[#{name_ids}][]"
    required = get_required(name, opts)

    theme_module(conn, Form).build_inputs_collection(model_name, name, name_ids, required, fn ->
      markup do
        Xain.input(name: name_str, type: "hidden", value: "")

        if opts[:as] == :check_boxes do
          build_checkboxes(conn, name, collection, opts, resource, model_name, errors, name_ids)
        else
          assoc_ids =
            get_resource_field2(resource, name)
            |> Enum.map(&Schema.get_id(&1))

          select id: "#{model_name}_#{name_ids}",
                 class: "form-control",
                 multiple: "multiple",
                 name: name_str do
            for opt <- collection do
              opt_id = Schema.get_id(opt)
              selected = if opt_id in assoc_ids, do: [selected: "selected"], else: []
              display_name = display_name(opt)
              option("#{display_name}", [value: "#{opt_id}"] ++ selected)
            end
          end
        end

        build_errors(errors, opts[:hint])
      end
    end)
  end

  defp build_checkboxes(conn, name, collection, opts, resource, model_name, errors, name_ids) do
    theme_module(conn, Form).wrap_collection_check_boxes(fn ->
      for opt <- collection do
        opt_id = Schema.get_id(opt)
        name_str = "#{model_name}[#{name_ids}][#{opt_id}]"

        selected =
          cond do
            errors != nil ->
              # error and selected in params
              request_params = Map.get(conn, :body_params, nil)

              ids =
                Map.get(request_params, model_name, %{})
                |> Map.get(name_ids, [])
                |> ExAdmin.EctoFormMappers.checkboxes_to_ids()

              Integer.to_string(opt_id) in ids

            true ->
              assoc_ids = Enum.map(get_resource_field2(resource, name), &Schema.get_id(&1))
              # select and no error
              opt_id in assoc_ids
          end

        display_name = display_name(opt)
        theme_module(conn, Form).collection_check_box(display_name, name_str, opt_id, selected)
      end
    end)
  end

  @doc """
  Setups the default collection on a inputs dsl request and then calls
  build_item again with the collection added
  """
  def build_item(
        conn,
        %{type: :inputs, name: name, opts: %{as: type}} = options,
        resource,
        model_name,
        errors
      )
      when is_atom(name) do
    # Get the model from the atom name
    mod =
      name
      |> Atom.to_string()
      |> String.capitalize()
      |> Inflex.singularize()
      |> String.to_atom()

    module =
      Application.get_env(:ex_admin, :module)
      |> Module.concat(mod)

    opts = put_in(options, [:opts, :collection], apply(module, :all, []))

    # call the build item with the default collection
    build_item(conn, opts, resource, model_name, errors)
  end

  @doc """
  Handle building the items for an input block.

  This is where each of the fields will be build
  """
  def build_item(conn, %{type: :inputs, name: _field_name} = item, resource, model_name, errors) do
    opts = Map.get(item, :opts, [])
    Adminlog.debug("build_item 10: #{inspect(_field_name)}")

    theme_module(conn, Form).form_box(item, opts, fn ->
      theme_module(conn, Form).theme_build_inputs(item, opts, fn ->
        for inpt <- item[:inputs] do
          type = resource.__struct__.__schema__(:type, inpt[:name])
          item = put_in(inpt, [:field_type], type)
          build_item(conn, item, resource, model_name, errors)
        end
      end)
    end)
  end

  defp build_checkboxes(conn, name, collection, opts, resource, model_name, errors, name_ids) do
    theme_module(conn, Form).wrap_collection_check_boxes fn ->
      for opt <- collection do
        opt_id = Schema.get_id(opt)
        name_str = "#{model_name}[#{name_ids}][#{opt_id}]"
        selected = cond do
          errors != nil ->
            # error and selected in params
            request_params = Map.get(conn, :body_params, nil)
            ids = Map.get(request_params, model_name, %{}) |>
                  Map.get(name_ids, []) |>
                  ExAdmin.EctoFormMappers.checkboxes_to_ids
            Integer.to_string(opt_id) in ids
          true ->
            assoc_ids = Enum.map(get_resource_field2(resource, name), &(Schema.get_id(&1)))
            # select and no error
            opt_id in assoc_ids
        end
        display_name = display_name opt
        theme_module(conn, Form).collection_check_box display_name, name_str,
          opt_id, selected
      end
    end
  end



  defp get_schema(item, field_name) do
    schema = item[:opts][:schema]
    unless schema, do: raise("Can't render map without schema #{inspect(field_name)}")
    schema
  end

  def build_input(conn, type, field, field_name, data, model_name, errors \\ nil, index \\ nil) do
    field = to_string(field)
    error = if errors in [nil, [], false], do: "", else: ".has-error"

    {inx, id} =
      if is_nil(index) do
        {"", "#{model_name}_#{field_name}_#{field}"}
      else
        {"[#{index}]", "#{model_name}_#{field_name}_#{index}_#{field}"}
      end

    name = "#{model_name}[#{field_name}]#{inx}[#{field}]"
    label = humanize(field)

    theme_module(conn, Form).build_map(id, label, index, error, fn class ->
      markup do
        []
        |> Keyword.put(:type, input_type(type))
        |> Keyword.put(:class, class)
        |> Keyword.put(:id, id)
        |> Keyword.put(:name, name)
        |> Keyword.put(:value, data[field])
        |> Xain.input()

        build_errors(errors, nil)
      end
    end)
  end

  defp input_type(:string), do: "text"
  defp input_type(:integer), do: "number"
  defp input_type(_), do: "text"

  @doc false
  def build_control(:boolean, resource, opts, model_name, field_name, ext_name) do
    opts =
      unless Map.get(resource, field_name) in [false, nil, "false"] do
        Map.put_new(opts, :checked, "checked")
      else
        opts
      end

    opts =
      opts
      |> Map.put_new(:type, :checkbox)
      |> Map.put_new(:value, "true")
      |> Map.put_new(:name, "#{model_name}[#{field_name}]")
      |> Map.put_new(:id, ext_name)
      |> Map.to_list()

    markup do
      Xain.input(type: :hidden, value: "false", name: "#{model_name}[#{field_name}]")
      Xain.input(opts)
    end
  end

  def build_control(Ecto.DateTime, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> datetime_select(field_name, Map.get(opts, :options, []))
  end

  def build_control(DateTime, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> datetime_select(field_name, Map.get(opts, :options, []))
  end

  def build_control(NaiveDateTime, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> datetime_select(field_name, Map.get(opts, :options, []))
  end

  def build_control(Ecto.Date, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> date_select(field_name, Map.get(opts, :options, []))
  end

  def build_control(Ecto.Time, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> time_select(field_name, Map.get(opts, :options, []))
  end

  def build_control(Elixir.DateTime, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> datetime_select(field_name, Map.get(opts, :options, []))
  end
  def build_control(Elixir.NaiveDateTime, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> datetime_select(field_name, Map.get(opts, :options, []))
  end
  def build_control(Elixir.Date, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> date_select(field_name, Map.get(opts, :options, []))
  end
  def build_control(Elixir.Time, resource, opts, model_name, field_name, _ext_name) do
    %{name: model_name, model: resource, id: model_name, class: "form-control"}
    |> time_select(field_name, Map.get(opts, :options, []))
  end

  def build_control(:text, resource, opts, model_name, field_name, ext_name) do
    value = Map.get(resource, field_name, "") |> escape_value

    options =
      opts
      |> Map.put(:class, "form-control")
      |> Map.put_new(:name, "#{model_name}[#{field_name}]")
      |> Map.put_new(:id, ext_name)
      |> Map.delete(:display)
      |> Map.to_list()

    Xain.textarea(value, options)
  end

  def build_control({:array, type}, resource, opts, model_name, field_name, ext_name)
      when type in ~w(string integer)a do
    name = "#{model_name}-#{field_name}"

    # currently we only support select 2
    opts = Map.put_new(opts, :select2, tags: true)

    ctrl_opts =
      opts
      |> Map.put(:class, "form-control #{name}")
      |> Map.put(:multiple, true)
      |> Map.put_new(:name, "#{model_name}[#{field_name}][]")
      |> Map.put_new(:id, ext_name)
      |> Map.delete(:display)
      |> Map.delete(:select2)
      |> Map.to_list()

    options =
      case Map.get(resource, field_name, []) do
        nil ->
          []

        list when is_list(list) ->
          list

        string when is_binary(string) ->
          String.split(string, " ")
      end

    build_array_control_select2(opts[:select2], name)
    |> build_array_control_control(ctrl_opts, options)
    |> build_array_control_block
  end

  def build_control({:embed, e}, resource, opts, model_name, field_name, ext_name) do
    embed_content = Map.get(resource, field_name) || e.related.__struct__
    embed_module = e.related

    embed_module.__schema__(:fields)
    |> Enum.map(&{&1, embed_module.__schema__(:type, &1)})
    |> Enum.map(fn {field, type} ->
      [
        label(Atom.to_string(field)),
        build_control(
          type,
          embed_content,
          %{},
          "#{model_name}[#{field_name}]",
          field,
          "#{ext_name}_#{field}"
        )
      ]
    end)
  end

  def build_control(type, resource, opts, model_name, field_name, ext_name) do
    {field_type, value} =
      cond do
        type == :file || type |> Kernel.to_string() |> String.ends_with?(".Type") ->
          val = Map.get(resource, field_name, %{}) || %{}
          {:file, Map.get(val, :filename, "")}

        true ->
          {:text, Map.get(resource, field_name, "")}
      end

    value = ExAdmin.Render.to_string(value)

    Map.put_new(opts, :type, field_type)
    |> Map.put(:class, "form-control")
    |> Map.put_new(:maxlength, "255")
    |> Map.put_new(:name, "#{model_name}[#{field_name}]")
    |> Map.put_new(:id, ext_name)
    |> Map.put_new(:value, value |> escape_value)
    |> Map.delete(:display)
    |> Map.to_list()
    |> Xain.input()
  end

  defp build_array_control_control({collection, script}, ctrl_opts, options) do
    select =
      Xain.select ctrl_opts do
        Enum.map(options, fn opt ->
          Xain.option(opt, value: opt, selected: "selected", style: "color: #333")
        end) ++
          Enum.map(collection, fn opt ->
            Xain.option(opt, value: opt)
          end)
      end

    {select, script}
  end

  defp build_array_control_block({select, nil}), do: select
  defp build_array_control_block({select, script}), do: [select, script]

  defp build_array_control_select2(nil, _), do: {nil, []}

  defp build_array_control_select2(select2, name) do
    Keyword.pop(select2, :collection, [])
    |> build_array_control_select2_script_opts
    |> build_array_control_select2_script(name)
  end

  def build_array_control_select2_script_opts({collection, true}) do
    {collection, "{}"}
  end

  def build_array_control_select2_script_opts({collection, list}) when is_list(list) do
    args =
      Enum.reduce(list, [], fn {k, v}, acc ->
        ["#{k}: #{v}" | acc]
      end)
      |> Enum.reverse()
      |> Enum.join(", ")

    {collection, "{#{args}}"}
  end

  def build_array_control_select2_script({collection, options}, name) do
    script =
      Xain.script do
        """
        $(document).ready(function() {
          $(".#{name}").select2(#{options});
        })
        """
      end

    {collection, script}
  end

  def datetime_select(form, field_name, opts \\ []) do
    value = value_from(form, field_name)

    builder =
      Keyword.get(opts, :builder) ||
        fn b ->
          markup do
            date_builder(b, opts)
            span(".date-time-separator")
            time_builder(b, opts)
          end
        end

    builder.(datetime_builder(form, field_name, date_value(value), time_value(value), opts))
  end

  def date_select(form, field_name, opts \\ []) do
    value = Keyword.get(opts, :value, value_from(form, field_name) || Keyword.get(opts, :default))
    builder = Keyword.get(opts, :builder) || &date_builder(&1, opts)
    builder.(datetime_builder(form, field_name, date_value(value), nil, opts))
  end

  defp date_builder(b, _opts) do
    markup do
      b.(:year, [])
      span(".date-separator")
      b.(:month, [])
      span(".date-separator")
      b.(:day, [])
    end
  end

  defp date_value(%{"year" => year, "month" => month, "day" => day}),
    do: %{year: year, month: month, day: day}

  defp date_value(%{year: year, month: month, day: day}),
    do: %{year: year, month: month, day: day}

  defp date_value({{year, month, day}, _}), do: %{year: year, month: month, day: day}
  defp date_value({year, month, day}), do: %{year: year, month: month, day: day}

  defp date_value(nil), do: %{year: nil, month: nil, day: nil}
  defp date_value(other), do: raise(ArgumentError, "unrecognized date #{inspect(other)}")

  def time_select(form, field, opts \\ []) do
    value = Keyword.get(opts, :value, value_from(form, field) || Keyword.get(opts, :default))
    builder = Keyword.get(opts, :builder) || &time_builder(&1, opts)
    builder.(datetime_builder(form, field, nil, time_value(value), opts))
  end

  defp time_builder(b, opts) do
    markup do
      b.(:hour, [])
      span(".time-separator")
      b.(:min, [])

      if Keyword.get(opts, :sec) do
        markup do
          span(".time-separator")
          b.(:sec, [])
        end
      end

      if Keyword.get(opts, :usec) do
        markup do
          span(".time-separator")
          b.(:usec, [])
        end
      end
    end
  end

  defp time_value(%{"hour" => hour, "min" => min} = map),
    do: %{hour: hour, min: min, sec: Map.get(map, "sec", 0), usec: Map.get(map, "usec", 0)}

  defp time_value(%{hour: hour, min: min} = map),
    do: %{hour: hour, min: min, sec: Map.get(map, :sec, 0), usec: Map.get(map, :usec, 0)}

  defp time_value(%{hour: hour, minute: min} = map),
    do: %{
      hour: hour,
      min: min,
      sec: Map.get(map, :second, 0),
      usec: elem(Map.get(map, :microsecond, {0, 0}), 0)
    }

  defp time_value({_, {hour, min, sec, usec}}), do: %{hour: hour, min: min, sec: sec, usec: usec}
  defp time_value({hour, min, sec, usec}), do: %{hour: hour, min: min, sec: sec, usec: usec}
  defp time_value({_, {hour, min, sec}}), do: %{hour: hour, min: min, sec: sec, usec: nil}
  defp time_value({hour, min, sec}), do: %{hour: hour, min: min, sec: sec, usec: nil}
  defp time_value(nil), do: %{hour: nil, min: nil, sec: nil, usec: nil}
  defp time_value(other), do: raise(ArgumentError, "unrecognized time #{inspect(other)}")

  @months [
    {"January", "1"},
    {"February", "2"},
    {"March", "3"},
    {"April", "4"},
    {"May", "5"},
    {"June", "6"},
    {"July", "7"},
    {"August", "8"},
    {"September", "9"},
    {"October", "10"},
    {"November", "11"},
    {"December", "12"}
  ]

  map =
    &Enum.map(&1, fn i ->
      i = Integer.to_string(i)
      {String.rjust(i, 2, ?0), i}
    end)

  @days map.(1..31)
  @hours map.(0..23)
  @minsec map.(0..59)
  @usec map.(0..999)

  defp datetime_builder(form, field, date, time, parent) do
    id = Keyword.get(parent, :id, id_from(form, field))
    name = Keyword.get(parent, :name, name_from(form, field))

    fn
      :year, opts when date != nil ->
        {year, _, _} = :erlang.date()

        {value, opts} =
          datetime_options(:year, (year - 5)..(year + 5), id, name, parent, date, opts)

        build_select(:datetime, :year, value, opts)

      :month, opts when date != nil ->
        {value, opts} = datetime_options(:month, @months, id, name, parent, date, opts)
        build_select(:datetime, :month, value, opts)

      :day, opts when date != nil ->
        {value, opts} = datetime_options(:day, @days, id, name, parent, date, opts)
        build_select(:datetime, :day, value, opts)

      :hour, opts when time != nil ->
        {value, opts} = datetime_options(:hour, @hours, id, name, parent, time, opts)
        build_select(:datetime, :hour, value, opts)

      :min, opts when time != nil ->
        {value, opts} = datetime_options(:min, @minsec, id, name, parent, time, opts)
        build_select(:datetime, :min, value, opts)

      :sec, opts when time != nil ->
        {value, opts} = datetime_options(:sec, @minsec, id, name, parent, time, opts)
        build_select(:datetime, :sec, value, opts)

      :usec, opts when time != nil ->
        {value, opts} = datetime_options(:usec, @usec, id, name, parent, time, opts)
        build_select(:datetime, :usec, value, opts)
    end
  end

  defp build_select(_name, type, value, opts) do
    value =
      if Range.range?(value) do
        Enum.map(value, fn x ->
          val = Integer.to_string(x)
          {val, val}
        end)
      else
        value
      end

    select "", [{:class, "form-control date-time"} | opts] do
      if opts[:prompt], do: handle_prompt(type, opts: %{prompt: opts[:prompt]})
      current_value = "#{opts[:value]}"

      Enum.map(value, fn {k, v} ->
        selected = if v == current_value, do: [selected: "selected"], else: []
        option(k, [{:value, v} | selected])
      end)
    end
  end

  defp datetime_options(type, values, id, name, parent, datetime, opts) do
    opts = Keyword.merge(Keyword.get(parent, type, []), opts)
    suff = Atom.to_string(type)

    {value, opts} = Keyword.pop(opts, :options, values)

    {
      value,
      opts
      |> Keyword.put_new(:id, id <> "_" <> suff)
      |> Keyword.put_new(:name, name <> "[" <> suff <> "]")
      |> Keyword.put_new(:value, Map.get(datetime, type))
    }
  end

  defp value_from(%{model: resource}, field_name) do
    Map.get(resource, field_name, "")
  end

  defp id_from(%{id: id}, field), do: "#{id}_#{field}"
  defp id_from(name, field) when is_atom(name), do: "#{name}_#{field}"

  defp name_from(%{name: name}, field), do: "#{name}[#{field}]"
  defp name_from(name, field) when is_atom(name), do: "#{name}[#{field}]"

  @doc false
  def build_has_many_fieldset(
        conn,
        res,
        fields,
        orig_inx,
        ext_name,
        field_name,
        field_field_name,
        model_name,
        errors
      ) do
    theme_module(conn, Form).theme_build_has_many_fieldset(
      conn,
      res,
      fields,
      orig_inx,
      ext_name,
      field_name,
      field_field_name,
      model_name,
      errors
    )
  end

  @doc false
  def get_label(field_name, opts) do
    cond do
      Map.get(opts, :type) in ["hidden", :hidden] ->
        :none

      Map.get(opts, :display) ->
        {:hidden, Map.get(opts, :label, field_name)}

      Map.get(opts, :ajax) ->
        {:ajax, Map.get(opts, :label, field_name)}

      true ->
        Map.get(opts, :label, field_name)
    end
  end

  defp new_record_name(field_name) do
    name =
      field_name
      |> Atom.to_string()
      |> Inflex.singularize()
      |> String.replace(" ", "_")
      |> String.upcase()

    "NEW_#{name}_RECORD"
  end

  def escape_value(nil), do: nil
  def escape_value(value) when is_map(value), do: value

  def escape_value(value) do
    Phoenix.HTML.html_escape(value) |> elem(1)
  end

  @doc false
  def build_field_errors(conn, field_name) do
    conn.private
    |> Map.get(:phoenix_flash, %{})
    |> Map.get("inline_error", [])
    |> get_errors(field_name)
    |> Enum.reduce("", fn error, acc ->
      acc <>
        """
        <p class="inline-errors">#{error_messages(error)}</p>
        """
    end)
  end

  @doc false
  def default_form_view(conn, resource, params) do
    case conn.assigns.defn do
      nil ->
        throw(:invalid_route)

      %{__struct__: _} = defn ->
        columns =
          defn.resource_model.__schema__(:fields)
          |> Enum.filter(&(&1 not in [:id, :inserted_at, :updated_at]))
          |> Enum.map(&build_item(resource, defn, &1))
          |> Enum.filter(&(not is_nil(&1)))

        items = [%{type: :inputs, name: "", inputs: columns, opts: []}]

        Module.concat(var!(conn).assigns.theme, Form).build_form(
          conn,
          resource,
          items,
          params,
          false,
          ExAdmin.Form.global_script()
        )
    end
  end

  defp binary_tuple?([]), do: false

  defp binary_tuple?(collection) do
    Enum.all?(collection, &(is_binary(&1) or (is_tuple(&1) and tuple_size(&1) == 2)))
  end

  def required_abbr(true) do
    abbr(".required *", title: "required")
  end

  def required_abbr(_), do: ""

  def get_required(field_name, %{required: required}) do
    if field_name in required, do: true, else: false
  end

  def get_required(_, _), do: false

  @doc false
  def extra_javascript(model_name, param, attr) do
    {"var extra = $('##{model_name}_#{attr}').val();\n", "&#{param}='+extra+'"}
  end

  @doc false
  defp map_array_errors(nil, _, _), do: nil

  defp map_array_errors(errors, field_name, inx) do
    Enum.filter_map(
      errors || [],
      fn {k, {_err, opts}} -> k == field_name and opts[:index] == inx end,
      fn {_k, {err, opts}} -> {opts[:field], err} end
    )
  end

  @doc false
  def get_errors(nil, _field_name), do: nil

  def get_errors(errors, field_name) do
    Enum.reduce(errors, [], fn {k, v}, acc ->
      if k == field_name, do: [v | acc], else: acc
    end)
  end

  @doc false
  def build_errors(nil, nil), do: nil

  def build_errors(nil, hint) do
    theme_module(Form).build_hint(hint)
  end

  def build_errors(errors, _) do
    for error <- errors do
      theme_module(Form).build_form_error(error)
    end
  end

  @doc false
  def error_messages(:unique), do: "has already been taken"
  def error_messages(:invalid), do: "has to be valid"
  def error_messages({:too_short, min}), do: "must be longer than #{min - 1}"
  def error_messages({:must_match, field}), do: "must match #{humanize(field)}"
  def error_messages(:format), do: "has incorrect format"
  def error_messages("empty"), do: "can't be blank"

  def error_messages({msg, opts}) when is_binary(msg) do
    count = if is_integer(opts[:count]), do: opts[:count], else: 0
    String.replace(msg, "%{count}", Integer.to_string(count))
  end

  def error_messages(other) when is_binary(other), do: other
  def error_messages(other), do: "error: #{inspect(other)}"

  def global_script,
    do: """
    $(function() {
      $(document).on('click', '.remove_has_many_maps', function() {
        console.log('remove has many maps');
        $(this).closest(".has_many_fields").remove();
        return false;
      });
    });
    """
end

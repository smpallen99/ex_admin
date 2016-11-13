defmodule ExAdmin.Theme.AdminLte2.Form do
  @moduledoc false
  import Kernel, except: [div: 2]
  import Xain
  import ExAdmin.Utils
  import ExAdmin.Form
  require Integer
  use ExAdmin.Adminlog
  import ExAdmin.Helpers
  import ExAdmin.Gettext
  alias ExAdmin.Schema

  @doc false
  def build_form(conn, resource, items, params, script_block) do
    mode = if params[:id], do: :edit, else: :new
    markup safe: true do
      model_name = model_name resource
      action = get_action(resource, mode)
      Xain.form "accept-charset": "UTF-8", action: "#{action}", class: "form-horizontal",
          id: "new_#{model_name}", method: :post, enctype: "multipart/form-data", novalidate: :novalidate  do

        resource = setup_resource(resource, params, model_name)
        {html, scripts_list} =
          build_main_block(conn, resource, model_name, items)
          |> Enum.reduce({[], []}, fn({h, o}, {acc_h, acc_o}) ->
            {[h | acc_h], o ++ acc_o}
          end)
        html = Enum.reverse html

        scripts = build_scripts(scripts_list)
        build_hidden_block(conn, mode)
        div ".box-body" do
          html
        end
        build_actions_block(conn, model_name, mode)
      end
      put_script_block(scripts)
      put_script_block(script_block)
    end
  end

  def theme_build_inputs(_item, _opts, fun) do
    fun.()
  end

  @doc false
  def theme_wrap_item(_type, ext_name, label, hidden, ajax, _error, contents, as, _required) when as in [:check_boxes, :radio] do
    Adminlog.debug "theme_wrap_item 1 #{ext_name}"
    div ".form-group##{ext_name}_input", hidden do
      label ".col-sm-2.control-label", for: "#{ext_name}" do
        humanize(label)
      end
      div ".col-sm-10" do
        if ajax do
          if hidden == [] do
            contents.(ext_name)
          end
        else
          contents.(ext_name)
        end
      end
    end
  end

  @doc """
  Private: Wrap simple controls.

  Wraps simple controls like text inputs in the appropriate div. Adds
  the label also.

  Does not handle collections.
  """

  def theme_wrap_item(type, ext_name, label, hidden, ajax, error, contents, _as, required) do
    Adminlog.debug "theme_wrap_item 2 #{inspect ext_name}"
    div ".form-group##{ext_name}_input", hidden do
      if ajax do
        if hidden == [] do
          markup do
            label(".col-sm-2.control-label", for: ext_name) do
              text humanize(label)
              required_abbr(required)
            end
            div ".col-sm-10" do
              contents.(ext_name)
            end
          end
        end
      else
        wrap_item_type(type, label, ext_name, contents, error, required)
      end
    end
  end

  def build_actions_block(conn, _model_name, mode) do
    display_name = ExAdmin.Utils.displayable_name_singular conn
    label = if mode == :new, do: (gettext "Create"), else: (gettext "Update")
    div ".box-footer" do
      Xain.input ".btn.btn-primary", name: "commit", type: :submit, value: escape_value("#{label} #{humanize display_name}")
      a(".btn.btn-default.btn-cancel " <> (gettext "Cancel"), href: admin_resource_path(conn, :index))
    end
  end

  def build_hint(hint) do
    span ".control-label" do
      i ".fa.fa-info-circle"
      text " #{hint}"
    end
  end
  def build_form_error(error) do
    label ".control-label" do
      i ".fa.fa-times-circle-o"
      text " #{ExAdmin.Form.error_messages(error)}"
    end
  end

  def build_inputs_collection(model_name, name, name_ids, required, fun) do
    div(".form-group") do
      label ".col-sm-2.control-label", for: "#{model_name}_#{name_ids}" do
        text humanize(name)
        required_abbr required
      end
      div ".col-sm-10" do
        fun.()
      end
    end
  end

  def build_inputs_has_many(_field_name, _human_label, fun) do
    {contents, html} = fun.()
    new_html = div ".input" do
      html
    end
    {contents, new_html}
  end

  def has_many_insert_item(html, new_record_name_var) do
    ~s|$(this).siblings("div.input").append("#{html}".replace(/#{new_record_name_var}/g,| <>
      ~s|new Date().getTime())); return false;|
  end

  def form_box(item, _opts, fun) do
    {html, changes} = Enum.reduce(fun.(), {"", []}, fn(item, {htmls, chgs}) ->
      case item do
        bin when is_binary(bin) -> {htmls <> bin, chgs}
        {bin, change} -> {htmls <> bin, [change | chgs]}
      end
    end)
    changes = Enum.reverse changes
    res = div ".box.box-primary" do
      div ".box-header.with-border" do
        h3 ".box-title" do
          text item[:name]
        end
      end
      div ".box-body" do
        html
      end
    end
    {res, changes}
  end

  # TODO: Refactor some of this back into ExAdmin.Form
  def theme_build_has_many_fieldset(conn, res, fields, orig_inx, ext_name, field_name, field_field_name, model_name, errors) do
    inx = cond do
      is_nil(res) -> orig_inx
      is_nil(res.id) -> orig_inx
      Schema.get_id(res) ->  orig_inx
      true -> timestamp   # case when we have errors. need to remap the inx
    end

    required_list = if res do
      res.__struct__.changeset(res).required
    else
      []
    end

    html = div ".box.has_many_fields" do
      div ".box-header.with-border" do
        title = humanize(field_name) |> Inflex.singularize
        h3 ".box-title #{title}"
      end
      div ".box-body" do
        # build the destroy field
        base_name = "#{model_name}[#{field_field_name}][#{inx}]"
        base_id = "#{ext_name}__destroy"
        name = "#{base_name}[_destroy]"
        div [id: "#{base_id}_input", class: "form-group"] do
          div ".col-sm-offset-2" do
            div ".checkbox" do
              Xain.input type: :hidden, value: "0", name: name
              label for: base_id do
                Xain.input type: :checkbox, id: "#{base_id}", name: name, value: "1"
                text (gettext "Remove")
              end
            end
          end
        end

        for field <- fields do
          f_name = field[:name]
          required = if f_name in required_list, do: true, else: false
          name = "#{base_name}[#{f_name}]"
          errors = get_errors(errors, "#{model_name}[#{field_field_name}][#{orig_inx}][#{f_name}]")
          error = if errors in [nil, [], false], do: "", else: ".has-error"
          case field[:opts] do
            %{collection: collection} ->
              collection = if is_function(collection), do: collection.(conn, res), else: collection
              div ".form-group", [id: "#{ext_name}_label_input"] do
                label ".col-sm-2.control-label", for: "#{ext_name}_#{f_name}" do
                  text humanize(f_name)
                  required_abbr required
                end
                div ".col-sm-10" do
                  select "##{ext_name}_#{f_name}#{error}.form-control", [name: name ] do
                    for opt <- collection do
                      if not is_nil(res) and (Map.get(res, f_name) == opt) do
                        option "#{opt}", [value: escape_value(opt), selected: :selected]
                      else
                        option "#{opt}", [value: escape_value(opt)]
                      end
                    end
                  end
                  build_errors(errors, field[:opts][:hint])
                end
              end
            _ ->
              div ".form-group", id: "#{ext_name}_#{f_name}_input"  do
                label ".col-sm-2.control-label", for: "#{ext_name}_#{f_name}" do
                  text humanize(f_name)
                  required_abbr required
                end
                div ".col-sm-10#{error}" do
                  val = if res, do: [value: Map.get(res, f_name, "") |> escape_value], else: []
                  Xain.input([type: :text, maxlength: "255", id: "#{ext_name}_#{f_name}",
                    class: "form-control", name: name] ++ val)
                  build_errors(errors, field[:opts][:hint])
                end
              end
          end
        end
        unless Schema.get_id(res) do
          div ".form-group" do
            a ".btn.btn-default " <> (gettext "Delete"), href: "#",
              onclick: ~S|$(this).closest(\".has_many_fields\").remove(); return false;|
          end
        end
      end
    end
    {inx, html}
  end

  def theme_button(content, attrs) do
    a ".btn#{content}", attrs
  end

  def collection_check_box name, name_str, _id, selected do
    checked = if selected, do: [checked: :checked], else: []
    div ".checkbox" do
      label do
        input [type: :checkbox, name: name_str ] ++ checked
        text name
      end
    end
  end

  def wrap_collection_check_boxes fun do
    fun.()
  end
end

defmodule ExAdmin.Theme.ActiveAdmin.Form do
  @moduledoc false
  import Kernel, except: [div: 2]
  import Xain
  import ExAdmin.Utils
  import ExAdmin.Form
  require Integer
  require Logger
  import ExAdmin.Helpers
  alias ExAdmin.Schema

  @doc false
  def build_form(conn, resource, items, params, script_block) do
    mode = if params[:id], do: :edit, else: :new
    markup do
      model_name = model_name resource
      action = get_action(resource, mode)
      # scripts = ""
      Xain.form "accept-charset": "UTF-8", action: "#{action}", class: "formtastic #{model_name}",
          id: "new_#{model_name}", method: :post, enctype: "multipart/form-data", novalidate: :novalidate  do

        resource = setup_resource(resource, params, model_name)

        build_hidden_block(conn, mode)
        scripts = build_main_block(conn, resource, model_name, items)
        |> build_scripts
        build_actions_block(conn, model_name, mode)
      end
      put_script_block(scripts)
      put_script_block(script_block)
    end
  end

  def theme_build_inputs(item, opts, fun) do
    fieldset(".inputs", opts) do
      build_fieldset_legend(item[:name])
      ol do
        fun.()
      end
    end
  end

  def theme_wrap_item(_type, ext_name, label, hidden, ajax, error, contents, as, required) when as in [:check_boxes, :radio] do
    li([class: "#{as} input optional #{error}stringish", id: "#{ext_name}_input"] ++ hidden) do
      fieldset ".choices" do
        legend ".label" do
          label do
            text humanize(label)
            required_abbr required
          end
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

  @doc false
  def theme_wrap_item(_type, ext_name, label, hidden, ajax, error, contents, _, required) do
    # TODO: Fix this to use the correct type, instead of hard coding string
    li([class: "string input optional #{error}stringish", id: "#{ext_name}_input"] ++ hidden) do
      if ajax do
        label(".label", for: ext_name) do
          text humanize(label)
          required_abbr required
        end
        div "##{ext_name}-update" do
          if hidden == [] do
            contents.(ext_name)
          end
        end
      else
        label(".label", for: ext_name) do
          text humanize(label)
          required_abbr required
        end
        contents.(ext_name)
      end
    end
  end

  def build_actions_block(conn, model_name, mode) do
    display_name = ExAdmin.Utils.displayable_name_singular conn
    label = if mode == :new, do: "Create", else: "Update"
    fieldset(".actions") do
      ol do
        li(".action.input_action##{model_name}_submit_action") do
          Xain.input name: "commit", type: :submit, value: escape_value("#{label} #{humanize display_name}")
        end
        li(".cancel") do
          a("Cancel", href: admin_resource_path(conn, :index))
        end
      end
    end
  end


  def build_form_error(error) do
    p ".inline-errors #{error_messages error}"
  end

  def build_inputs_collection(model_name, name, name_ids, required, fun) do
    fieldset(".inputs") do
      ol do
        li ".select.input.optional##{model_name}_#{name}_input" do
          label ".label", for: "#{model_name}_#{name_ids}" do
            text humanize(name)
            required_abbr required
          end
          fun.()
        end
      end
    end
  end

  def build_inputs_has_many(_field_name, _human_label, fun) do
    li ".input" do
      res = fun.()
    end
    res
  end

  def has_many_insert_item(html, new_record_name_var) do
    ~s|$(this).siblings("li.input").append("#{html}".replace(/#{new_record_name_var}/g,| <>
      ~s|new Date().getTime())); return false;|
  end

  def form_box(_item, _opts, fun) do
    fun.()
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

    fieldset ".inputs.has_many_fields" do
      ol do
        humanize(field_name) |> Inflex.singularize |> h3

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
          required = if f_name in required_list, do: true, else: false
          name = "#{base_name}[#{f_name}]"
          errors = get_errors(errors, "#{model_name}[#{field_field_name}][#{orig_inx}][#{f_name}]")
          error = if errors in [nil, [], false], do: "", else: ".error"
          case field[:opts] do
            %{collection: collection} ->
              collection = if is_function(collection), do: collection.(conn, res), else: collection
              li ".select.input#{error}", [id: "#{ext_name}_label_input"] do
                label ".label", for: "#{ext_name}_#{f_name}" do
                  text humanize(f_name)
                  required_abbr required
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
              li ".string.input.stringish#{error}", id: "#{ext_name}_#{f_name}_input"  do
                label ".label", for: "#{ext_name}_#{f_name}" do
                  text humanize(f_name)
                  required_abbr required
                end
                val = if res, do: [value: Map.get(res, f_name, "") |> escape_value], else: []
                Xain.input([type: :text, maxlength: "255", id: "#{ext_name}_#{f_name}",
                  name: name, required: true] ++ val)
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

  def theme_button(content, attrs) do
    a ".button#{content}", attrs
  end

  def collection_check_box name, name_str, _id, selected do
    checked = if selected, do: [checked: :checked], else: []
    li ".checkbox" do
      label do
        input [type: :checkbox, name: name_str ] ++ checked
        text name
      end
    end
  end

  def wrap_collection_check_boxes fun do
    ol do
      fun.()
    end
  end
end

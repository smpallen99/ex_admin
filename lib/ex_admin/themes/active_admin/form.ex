defmodule ExAdmin.Theme.ActiveAdmin.Form do
  import Kernel, except: [div: 2]
  import Xain
  import ExAdmin.Utils
  import ExAdmin.ViewHelpers
  import ExAdmin.Form
  require Integer
  require Logger
  import ExAdmin.Helpers

  @doc false
  def build_form(conn, resource, items, params, script_block) do
    mode = if params[:id], do: :edit, else: :new
    markup do
      model_name = model_name resource
      action = get_action(conn, resource, mode)
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

  def theme_wrap_item(_type, ext_name, label, hidden, ajax, error, contents, as) when as in [:check_boxes, :radio] do
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

  @doc false
  def theme_wrap_item(_type, ext_name, label, hidden, ajax, error, contents, _) do
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

  def build_actions_block(conn, model_name, mode) do
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

  def build_actions_block(conn, model_name, mode) do
    display_name = ExAdmin.Utils.displayable_name_singular conn
    label = if mode == :new, do: "Create", else: "Update"
    div ".box-footer" do
      Xain.input ".btn.btn-primary", name: "commit", type: :submit, value: escape_value("#{label} #{humanize display_name}")
      a(".btn.btn-default.btn-cancel Cancel", href: get_route_path(conn, :index))
    end
  end

  def build_form_error(error) do
    p ".inline-errors #{error_messages error}"
  end
end

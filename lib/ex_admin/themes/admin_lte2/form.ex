defmodule ExAdmin.Theme.AdminLte2.Form do
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
      div ".box.box-primary" do
        div ".box-header.with-border" do
          h3 ".box-title" do
            text "New Product"
          end
        end
        Xain.form "accept-charset": "UTF-8", action: "#{action}", class: "form-horizontal",
            id: "new_#{model_name}", method: :post, enctype: "multipart/form-data", novalidate: :novalidate  do

          resource = setup_resource(resource, params, model_name)

          build_hidden_block(conn, mode)
          div ".box-body" do
            scripts = build_main_block(conn, resource, model_name, items)
            |> build_scripts
          end
          build_actions_block(conn, model_name, mode)
        end
      end
      put_script_block(scripts)
      put_script_block(script_block)
    end
  end

  def theme_build_inputs(item, opts, fun) do
    fun.()
  end

  @doc false
  def theme_wrap_item(_type, ext_name, label, hidden, ajax, error, contents, as) when as in [:check_boxes, :radio] do
    # li([class: "#{as} input optional #{error}stringish", id: "#{ext_name}_input"] ++ hidden) do
Logger.warn "wrap item 2. ..."
    div ".form-group", hidden do
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
  def theme_wrap_item(type, ext_name, label, hidden, ajax, error, contents, as) do
    # Logger.warn ".... ext_name: #{inspect ext_name}, as: #{inspect as}"
    # TODO: Fix this to use the correct type, instead of hard coding string
    # li([class: "string input optional #{error}stringish", id: "#{ext_name}_input"] ++ hidden) do
    div ".form-group", hidden do
      if ajax do
        label(".col-sm-2.control-label #{humanize label}", for: ext_name)
        div "##{ext_name}-update" do
          if hidden == [] do
            div ".col-sm-10" do
              contents.(ext_name)
            end
          end
        end
      else
        wrap_item_type(type, label, ext_name, contents, error)
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
    label ".control-label" do
      i ".fa.fa-times-circle-o"
      text " #{ExAdmin.Form.error_messages(error)}"
    end
  end
end

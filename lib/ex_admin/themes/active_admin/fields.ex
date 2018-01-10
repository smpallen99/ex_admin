defmodule ExAdmin.Theme.ActiveAdmin.Fields do
  use Xain
  import ExAdmin.Utils
  import ExAdmin.Form.Fields

  def input_checkbox(fun) do
    li ".checkbox" do
      fun.()
    end
  end

  def theme_ajax_input_collection(resource, collection, model_name, field_name, item, params) do
    ext_name = ext_name(model_name, field_name)

    markup do
      label ".col-sm-2.control-label", for: "#{ext_name}" do
        humanize(field_name)
      end

      Xain.div ".col-sm-10" do
        do_input_collection(
          resource,
          collection,
          model_name,
          field_name,
          item,
          resource.__struct__.__schema__(:association, field_name),
          params,
          []
        )
      end
    end
  end
end

defmodule ExAdmin.View do
  
  defprotocol Adapter do
    @fallback_to_any true
    def build_csv(resource, resources)
  end

  defimpl Adapter, for: Any do
    def build_csv(_resource, resources) do
      ExAdmin.CSV.build_csv(resources)
    end
  end
  
end

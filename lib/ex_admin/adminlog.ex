defmodule ExAdmin.Adminlog do
  defmacro __using__(_) do
    quote do
      alias ExAdmin.Adminlog
      require Logger
    end
  end

  defmacro debug(message) do
    if Mix.env() in [:dev, :test] and Application.get_env(:ex_admin, :logger, false) do
      quote do
        Logger.debug(unquote(message))
      end
    end
  end

  defmacro info(message) do
    if Mix.env() in [:dev, :test] and Application.get_env(:ex_admin, :logger, false) do
      quote do
        Logger.info(unquote(message))
      end
    end
  end

  defmacro warn(message) do
    if Mix.env() in [:dev, :test] and Application.get_env(:ex_admin, :logger, false) do
      quote do
        Logger.warn(unquote(message))
      end
    end
  end

  defmacro error(message) do
    if Mix.env() in [:dev, :test] and Application.get_env(:ex_admin, :logger, false) do
      quote do
        Logger.error(unquote(message))
      end
    end
  end
end

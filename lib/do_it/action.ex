defmodule DoIt.Action do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [action: 3, flag: 2, flag: 3]
      @behaviour DoIt.Runner
      Module.register_attribute(__MODULE__, :name, accumulate: false)
      Module.register_attribute(__MODULE__, :short_description, accumulate: false)
      Module.register_attribute(__MODULE__, :flags, accumulate: true)
      Module.register_attribute(__MODULE__, :strict, accumulate: true)
      Module.register_attribute(__MODULE__, :aliases, accumulate: true)
      Module.register_attribute(__MODULE__, :options, accumulate: false)
    end
  end

  defmacro action(name, short_description, do: block) do
    quote do
      Module.put_attribute(__MODULE__, :name, unquote(name))
      Module.put_attribute(__MODULE__, :short_description, unquote(short_description))
      unquote(block)
      Module.put_attribute(__MODULE__, :options, [strict: Module.get_attribute(__MODULE__, :strict), aliases: Module.get_attribute(__MODULE__, :aliases)])
    end
  end

  defmacro flag(name, type, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :flags, {unquote(name), unquote(type), unquote(opts)})
      Module.put_attribute(__MODULE__, :strict, {unquote(name), unquote(type)})
      case List.keymember?(unquote(opts), :alias, 0) do
        true ->
          Module.put_attribute(__MODULE__, :aliases, {unquote(opts[:alias]), unquote(name)})
        _ ->
          nil
      end
    end
  end

end

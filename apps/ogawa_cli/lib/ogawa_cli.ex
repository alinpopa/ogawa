defmodule Ogawa.Cli do
  alias OgawaStream, as: Ogawa

  def main(args \\ []) do
    args |> parse() |> exec()
  end

  defp parse(args) do
    available_opts = [
      {:reject, :string},
      {:add, :string},
      {:remove, :string},
      {:prefix, :string},
      {:take, :integer},
      {:throttle, :integer},
      {:help, :boolean}
    ]

    aliases = [
      {:r, :reject},
      {:a, :add},
      {:R, :remove},
      {:p, :prefix},
      {:h, :help},
      {:t, :take},
      {:T, :throttle}
    ]

    {opts, _, errs} = OptionParser.parse(args, strict: available_opts, aliases: aliases)
    {opts, errs}
  end

  defp exec({_opts, errs = [_ | _]}) do
    show_errs(parse_errs(errs))
  end

  defp exec({opts, []}) do
    reader = %Ogawa.Device.Stdin{}
    writer = %Ogawa.Device.Stdout{}

    with {:ok, nil} <- get_help_arg(opts),
         {:ok, reject_arg} <- get_reject_arg(opts),
         {:ok, add_arg} <- get_add_arg(opts),
         {:ok, remove_arg} <- get_remove_arg(opts),
         {:ok, prefix_arg} <- get_prefix_arg(opts),
         {:ok, take_arg} <- get_take_arg(opts),
         {:ok, throttle_arg} <- get_throttle_arg(opts) do
      Ogawa.make()
      |> Ogawa.from(reader)
      |> Ogawa.to(writer)
      |> build_stream({:reject, reject_arg})
      |> build_stream({:add, add_arg})
      |> build_stream({:remove, remove_arg})
      |> build_stream({:prefix, prefix_arg})
      |> build_stream({:take, take_arg})
      |> build_stream({:throttle, throttle_arg})
      |> Ogawa.sync()
    else
      {:just, :help} ->
        show_help()

      err ->
        show_errs([err])
    end
  end

  defp get_help_arg(opts) do
    case Keyword.get(opts, :help) do
      nil -> {:ok, nil}
      false -> {:ok, nil}
      true -> {:just, :help}
    end
  end

  defp get_reject_arg(opts) do
    reject = Keyword.get(opts, :reject)

    case reject do
      nil ->
        {:ok, nil}

      value ->
        case Integer.parse(value) do
          {number, ""} ->
            {:ok, number}

          _ ->
            case Float.parse(value) do
              {number, ""} -> {:ok, number}
              _ -> {:ok, value}
            end
        end
    end
  end

  defp get_add_arg(opts) do
    case Keyword.get(opts, :add) do
      nil -> {:ok, nil}
      val -> validate_pair(:add, val)
    end
  end

  defp get_remove_arg(opts),
    do: {:ok, Keyword.get(opts, :remove)}

  defp get_prefix_arg(opts) do
    case Keyword.get(opts, :prefix) do
      nil -> {:ok, nil}
      val -> validate_pair(:prefix, val)
    end
  end

  defp get_take_arg(opts) do
    case Keyword.get(opts, :take) do
      nil -> {:ok, nil}
      val when val < 0 -> {:error, {:invalid, :take}}
      val -> {:ok, val}
    end
  end

  defp get_throttle_arg(opts) do
    case Keyword.get(opts, :throttle) do
      nil -> {:ok, nil}
      val when val < 0 -> {:error, {:invalid, :throttle}}
      val -> {:ok, val}
    end
  end

  defp build_stream(ogawa, {:reject, nil}), do: ogawa
  defp build_stream(ogawa, {:reject, val}), do: ogawa |> Ogawa.reject_by_val(val)

  defp build_stream(ogawa, {:add, nil}), do: ogawa
  defp build_stream(ogawa, {:add, {x, y}}), do: ogawa |> Ogawa.add_pair(x, y)

  defp build_stream(ogawa, {:remove, nil}), do: ogawa
  defp build_stream(ogawa, {:remove, key}), do: ogawa |> Ogawa.remove_key(key)

  defp build_stream(ogawa, {:prefix, nil}), do: ogawa
  defp build_stream(ogawa, {:prefix, {x, y}}), do: ogawa |> Ogawa.prefix_key(y, x)

  defp build_stream(ogawa, {:take, nil}), do: ogawa
  defp build_stream(ogawa, {:take, val}), do: ogawa |> Ogawa.take(val)

  defp build_stream(ogawa, {:throttle, nil}), do: ogawa
  defp build_stream(ogawa, {:throttle, val}), do: ogawa |> Ogawa.throttle(val)

  defp show_help() do
    IO.puts("""

    Usage: ./ogawa_cli [options]

    Available options:
      -r/--reject     - reject object based on a value
      -a/--add        - add a key/value pair to each object
      -R/--remove     - remove a given key (and associated value) from each object
      -p/--prefix     - prefix a given key with a value
      -t/--take       - take only a specific number of items from the stream
      -T/--throttle   - consume each stream item no faster than the given seconds per item

    Examples:

      # Reject object based on value
      ogawa_cli -r test1

      # Add a key/value pair
      ogawa_cli -a my_key:my_value

      # Remove a given key
      ogawa_cli -R my_key

      # Prefix a given key
      ogawa_cli -p my_prefix:my_key
    """)
  end

  defp validate_pair(arg, value) when is_binary(value) do
    case String.split(value, ":") do
      [x, y] -> {:ok, {x, y}}
      _ -> {:error, {:invalid, arg}}
    end
  end

  defp parse_errs(errs) do
    Enum.map(errs, fn {field, _} ->
      {:error, {:invalid, field}}
    end)
  end

  defp show_errs(errs) do
    msg =
      Enum.reduce(errs, "", fn {:error, {:invalid, field}}, acc ->
        acc <> "\nInvalid #{field}"
      end)

    IO.puts(msg)
    show_help()
  end
end

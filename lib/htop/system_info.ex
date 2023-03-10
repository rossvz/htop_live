defmodule Htop.SystemInfo do
  use Rustler, otp_app: :htop, crate: "htop_systeminfo"

  # When your NIF is loaded, it will override this function.
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

  def get_cpu, do: :erlang.nif_error(:nif_not_loaded)
end

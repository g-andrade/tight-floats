defmodule tightfloats.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :tightfloats,
     version: @version,
     description: "Bandwidth-friendly IEEE 754 floating-point serialisation"",
     package: package]
  end

  defp package do
    [files: ~w(src rebar.config README.md LICENSE),
     contributors: ["Guilherme Andrade"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/g-andrade/tightfloats"}]
  end
end

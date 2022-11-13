defmodule Html do
  def save(nil), do: nil
    def save({issue_number, content}) do
    filename = "html/#{issue_number}.html"
    :ok = File.write(filename, content)
    filename
  end
end

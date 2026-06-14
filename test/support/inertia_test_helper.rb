# frozen_string_literal: true

module InertiaTestHelper
  def inertia_headers
    {
      "X-Inertia" => "true",
      "X-Inertia-Version" => ViteRuby.digest,
      "X-Requested-With" => "XMLHttpRequest"
    }
  end

  def inertia_get(path)
    get path, headers: inertia_headers
  end

  def inertia_props
    JSON.parse(response.body)["props"]
  end
end

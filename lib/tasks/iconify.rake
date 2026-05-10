# frozen_string_literal: true

require "json"
require "net/http"
require "set"
require "uri"

namespace :iconify do
  # desc "Imprime iconos de Iconify para ecommerce (tiempo, hielo, ingredientes, vegano). " \
  #      "ENV opcional: ICONIFY_KEYWORDS, ICONIFY_PREFIXES, ICONIFY_LIMIT, ICONIFY_MAX_PAGES, ICONIFY_VERBOSE_WARNINGS"
  # task print_ecommerce_icons: :environment do
  #   default_keywords = %w[
  #     ecommerce shop store cart checkout delivery shipping package box order sale discount
  #     clock time timer schedule hour minute day night weather cold ice snow frozen freeze
  #     food ingredient ingredients kitchen cook cooking recipe spice salt sugar flour milk cheese
  #     meat chicken beef fish seafood vegetable fruit vegan vegetarian plant organic healthy
  #     drink coffee tea juice soda beer wine water bottle cup plate fork knife spoon utensils
  #   ]

  #   raw_keywords = ENV.fetch("ICONIFY_KEYWORDS", default_keywords.join(","))
  #   keywords = raw_keywords.split(",").map(&:strip).reject(&:empty?).uniq

  #   raw_prefixes = ENV.fetch("ICONIFY_PREFIXES", "mdi,tabler,fa6-solid,solar,ic")
  #   prefixes = raw_prefixes.split(",").map(&:strip).reject(&:empty?).uniq

  #   limit = Integer(ENV.fetch("ICONIFY_LIMIT", "300"))
  #   max_pages = Integer(ENV.fetch("ICONIFY_MAX_PAGES", "6"))
  #   verbose_warnings = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ICONIFY_VERBOSE_WARNINGS", "false"))

  #   raise ArgumentError, "ICONIFY_LIMIT debe ser >= 1" if limit < 1
  #   raise ArgumentError, "ICONIFY_MAX_PAGES debe ser >= 1" if max_pages < 1
  #   raise ArgumentError, "Debes definir al menos una keyword en ICONIFY_KEYWORDS" if keywords.empty?
  #   raise ArgumentError, "Debes definir al menos un prefijo en ICONIFY_PREFIXES" if prefixes.empty?

  #   icon_names = Set.new
  #   failures = []
  #   pagination_notices = []

  #   keywords.each do |keyword|
  #     start = 0

  #     max_pages.times do |_page_idx|
  #       uri = URI("https://api.iconify.design/search")
  #       uri.query = URI.encode_www_form(
  #         query: keyword,
  #         limit: limit,
  #         start: start
  #       )

  #       response = Net::HTTP.get_response(uri)
  #       unless response.is_a?(Net::HTTPSuccess)
  #         # Iconify puede devolver 400 para offsets altos; lo tratamos como fin de paginación.
  #         if response.code.to_i == 400 && start.positive?
  #           pagination_notices << "query='#{keyword}' start=#{start} status=400 (fin de paginación)"
  #           break
  #         end

  #         failures << "query='#{keyword}' start=#{start} status=#{response.code}"
  #         break
  #       end

  #       payload = JSON.parse(response.body)
  #       icons = Array(payload["icons"]).select { |name| name.is_a?(String) }

  #       break if icons.empty?

  #       icons.each do |icon_name|
  #         next unless icon_name.include?(":")

  #         prefix = icon_name.split(":", 2).first
  #         icon_names.add(icon_name) if prefixes.include?(prefix)
  #       end

  #       break if icons.size < limit

  #       start += limit
  #     rescue JSON::ParserError => e
  #       failures << "query='#{keyword}' start=#{start} json_error=#{e.message}"
  #       break
  #     rescue StandardError => e
  #       failures << "query='#{keyword}' start=#{start} error=#{e.class}: #{e.message}"
  #       break
  #     end
  #   end

  #   sorted_icons = icon_names.to_a.sort

  #   $stdout.puts "[iconify:print_ecommerce_icons] keywords=#{keywords.size} prefixes=#{prefixes.join(',')}"
  #   $stdout.puts "[iconify:print_ecommerce_icons] total_unicos=#{sorted_icons.size}"
  #   $stdout.puts "-" * 72
  #   sorted_icons.each { |icon_name| $stdout.puts icon_name }
  #   $stdout.puts "-" * 72

  #   if verbose_warnings && pagination_notices.any?
  #     $stdout.puts "[iconify:print_ecommerce_icons] fin_de_paginacion (#{pagination_notices.size}):"
  #     pagination_notices.each { |notice| $stdout.puts "  - #{notice}" }
  #   end

  #   unless failures.empty?
  #     $stdout.puts "[iconify:print_ecommerce_icons] avisos (#{failures.size}):"
  #     failures.each { |warning| $stdout.puts "  - #{warning}" }
  #   end
  # end

  desc "Guarda en DB el set curado de iconos Iconify para ecommerce"
  task set_iconify_icons: :environment do
    icon_names = %w[
      fa6-solid:cheese
      fa6-solid:cloud-meatball
      fa6-solid:code-fork
      fa6-solid:fish
      fa6-solid:fish-fins
      fa6-solid:ice-cream
      fa6-solid:kitchen-set
      fa6-solid:plant-wilt
      fa6-solid:plate-wheat
      fa6-solid:shop
      fa6-solid:spoon
      fa6-solid:store
      fa6-solid:utensils
      fa6-solid:water
      fa6-solid:wine-bottle
      fa6-solid:wine-glass
      ic:baseline-cancel-schedule-send
      ic:baseline-coffee
      ic:baseline-delivery-dining
      ic:baseline-discount
      ic:baseline-flourescent
      ic:baseline-food-bank
      ic:baseline-fork-left
      ic:baseline-fork-right
      ic:baseline-kitchen
      ic:baseline-local-drink
      ic:baseline-local-shipping
      ic:baseline-mode-night
      ic:baseline-night-shelter
      ic:baseline-no-food
      ic:baseline-point-of-sale
      ic:baseline-schedule
      ic:baseline-schedule-send
      ic:baseline-severe-cold
      ic:baseline-shop
      ic:baseline-shop-2
      ic:baseline-shopping-cart-checkout
      ic:baseline-soup-kitchen
      ic:baseline-store
      ic:baseline-timer
      ic:baseline-view-day
      ic:baseline-water
      ic:baseline-wine-bar
      ic:outline-cancel-schedule-send
      ic:outline-coffee
      ic:outline-delivery-dining
      ic:outline-discount
      ic:outline-flourescent
      ic:outline-food-bank
      ic:outline-fork-left
      ic:outline-fork-right
      ic:outline-kitchen
      ic:outline-local-drink
      ic:outline-local-shipping
      ic:outline-mode-night
      ic:outline-night-shelter
      ic:outline-no-food
      ic:outline-point-of-sale
      ic:outline-schedule
      ic:outline-schedule-send
      ic:outline-severe-cold
      ic:outline-shop
      ic:outline-shop-2
      ic:outline-shopping-cart-checkout
      ic:outline-soup-kitchen
      ic:outline-store
      ic:outline-timer
      ic:outline-view-day
      ic:outline-water
      ic:outline-wine-bar
      ic:round-cancel-schedule-send
      ic:round-coffee
      ic:round-delivery-dining
      ic:round-discount
      ic:round-flourescent
      ic:round-food-bank
      ic:round-fork-left
      ic:round-fork-right
      ic:round-kitchen
      ic:round-local-drink
      ic:round-local-shipping
      ic:round-mode-night
      ic:round-night-shelter
      ic:round-no-food
      ic:round-point-of-sale
      ic:round-schedule
      ic:round-schedule-send
      ic:round-severe-cold
      ic:round-shop
      ic:round-shop-2
      ic:round-shopping-cart-checkout
      ic:round-soup-kitchen
      ic:round-store
      ic:round-timer
      ic:round-view-day
      ic:round-water
      ic:round-wine-bar
      ic:sharp-cancel-schedule-send
      ic:sharp-coffee
      ic:sharp-delivery-dining
      ic:sharp-discount
      ic:sharp-flourescent
      ic:sharp-food-bank
      ic:sharp-fork-left
      ic:sharp-fork-right
      ic:sharp-kitchen
      ic:sharp-local-drink
      ic:sharp-local-shipping
      ic:sharp-mode-night
      ic:sharp-night-shelter
      ic:sharp-no-food
      ic:sharp-point-of-sale
      ic:sharp-schedule
      ic:sharp-schedule-send
      ic:sharp-severe-cold
      ic:sharp-shop
      ic:sharp-shop-2
      ic:sharp-shopping-cart-checkout
      ic:sharp-soup-kitchen
      ic:sharp-store
      ic:sharp-timer
      ic:sharp-view-day
      ic:sharp-water
      ic:sharp-wine-bar
      ic:twotone-cancel-schedule-send
      ic:twotone-coffee
      ic:twotone-delivery-dining
      ic:twotone-discount
      ic:twotone-flourescent
      ic:twotone-food-bank
      ic:twotone-fork-left
      ic:twotone-fork-right
      ic:twotone-kitchen
      ic:twotone-local-drink
      ic:twotone-local-shipping
      ic:twotone-mode-night
      ic:twotone-night-shelter
      ic:twotone-no-food
      ic:twotone-point-of-sale
      ic:twotone-schedule
      ic:twotone-schedule-send
      ic:twotone-severe-cold
      ic:twotone-shop
      ic:twotone-shop-2
      ic:twotone-shopping-cart-checkout
      ic:twotone-soup-kitchen
      ic:twotone-store
      ic:twotone-timer
      ic:twotone-view-day
      ic:twotone-water
      ic:twotone-wine-bar
      mdi:airplane-schedule
      mdi:baby-bottle
      mdi:baby-bottle-outline
      mdi:beats-per-minute
      mdi:beats-per-minute-tick
      mdi:bed-schedule
      mdi:bed-time
      mdi:beef
      mdi:beef-off
      mdi:beer
      mdi:beer-outline
      mdi:book-schedule
      mdi:bottle-plus
      mdi:bottle-plus-outline
      mdi:bottle-soda
      mdi:bottle-soda-classic
      mdi:bottle-soda-classic-outline
      mdi:bottle-soda-outline
      mdi:bottle-tonic
      mdi:bottle-tonic-outline
      mdi:bottle-wine
      mdi:bottle-wine-outline
      mdi:box
      mdi:box-outline
      mdi:brain-freeze
      mdi:brain-freeze-outline
      mdi:cart
      mdi:cart-discount
      mdi:cart-off
      mdi:cart-outline
      mdi:cart-sale
      mdi:cash-on-delivery
      mdi:cash-schedule
      mdi:cheese
      mdi:cheese-off
      mdi:chicken-leg
      mdi:chicken-leg-off
      mdi:chicken-leg-off-outline
      mdi:chicken-leg-outline
      mdi:clock
      mdi:clock-outline
      mdi:cloud-discount
      mdi:cloud-discount-outline
      mdi:coffee
      mdi:coffee-off
      mdi:coffee-off-outline
      mdi:coffee-outline
      mdi:cold-alert
      mdi:cook
      mdi:cup
      mdi:cup-full
      mdi:cup-full-outline
      mdi:cup-ice
      mdi:cup-off
      mdi:cup-off-outline
      mdi:cup-outline
      mdi:delivery-dining
      mdi:delivery-dining-outline
      mdi:discount
      mdi:discount-box
      mdi:discount-box-outline
      mdi:discount-circle
      mdi:discount-circle-outline
      mdi:discount-outline
      mdi:drink
      mdi:drink-ice
      mdi:drink-off
      mdi:drink-off-outline
      mdi:drink-outline
      mdi:drink-to-go
      mdi:drink-to-go-outline
      mdi:drink-water
      mdi:fan-schedule
      mdi:fish
      mdi:fish-food
      mdi:fish-food-outline
      mdi:fish-off
      mdi:food
      mdi:food-off
      mdi:food-off-outline
      mdi:food-outline
      mdi:freeze-advisory
      mdi:fruit-cherries
      mdi:fruit-cherries-off
      mdi:fruit-citrus
      mdi:fruit-citrus-off
      mdi:fruit-grapes
      mdi:fruit-grapes-outline
      mdi:fruit-pear
      mdi:fruit-pineapple
      mdi:fruit-watermelon
      mdi:glass-wine
      mdi:home-schedule
      mdi:home-schedule-outline
      mdi:hot-cold
      mdi:hours-12
      mdi:hours-24
      mdi:ice-cream
      mdi:ice-pop
      mdi:ice-skate
      mdi:invoice-schedule
      mdi:invoice-schedule-outline
      mdi:invoice-scheduled
      mdi:invoice-scheduled-outline
      mdi:invoice-text-scheduled
      mdi:invoice-text-scheduled-outline
      mdi:kettle-steam
      mdi:kettle-steam-outline
      mdi:kitchen
      mdi:kitchen-counter
      mdi:kitchen-counter-outline
      mdi:kitchen-roll
      mdi:kitchen-roll-outline
      mdi:kitchen-tap
      mdi:kitchen-tap-off
      mdi:knife
      mdi:knife-military
      mdi:lacto-vegetarian
      mdi:local-shipping
      mdi:meat
      mdi:meat-off
      mdi:meat-off-outline
      mdi:meat-outline
      mdi:network-point-of-sale
      mdi:organic
      mdi:organic-outline
      mdi:package
      mdi:package-off
      mdi:package-off-outline
      mdi:package-outline
      mdi:package-up
      mdi:phone-schedule
      mdi:plant
      mdi:plant-outline
      mdi:point-of-sale
      mdi:printer-point-of-sale
      mdi:printer-point-of-sale-alert
      mdi:printer-point-of-sale-alert-outline
      mdi:printer-point-of-sale-cancel
      mdi:printer-point-of-sale-cancel-outline
      mdi:printer-point-of-sale-check
      mdi:printer-point-of-sale-check-outline
      mdi:printer-point-of-sale-cog
      mdi:printer-point-of-sale-cog-outline
      mdi:printer-point-of-sale-edit
      mdi:printer-point-of-sale-edit-outline
      mdi:printer-point-of-sale-minus
      mdi:printer-point-of-sale-minus-outline
      mdi:printer-point-of-sale-network
      mdi:printer-point-of-sale-network-outline
      mdi:printer-point-of-sale-off
      mdi:printer-point-of-sale-off-outline
      mdi:printer-point-of-sale-outline
      mdi:printer-point-of-sale-pause
      mdi:printer-point-of-sale-pause-outline
      mdi:printer-point-of-sale-play
      mdi:printer-point-of-sale-play-outline
      mdi:printer-point-of-sale-plus
      mdi:printer-point-of-sale-plus-outline
      mdi:printer-point-of-sale-refresh
      mdi:printer-point-of-sale-refresh-outline
      mdi:printer-point-of-sale-remove
      mdi:printer-point-of-sale-remove-outline
      mdi:printer-point-of-sale-star
      mdi:printer-point-of-sale-star-outline
      mdi:printer-point-of-sale-stop
      mdi:printer-point-of-sale-stop-outline
      mdi:printer-point-of-sale-sync
      mdi:printer-point-of-sale-sync-outline
      mdi:printer-point-of-sale-wrench
      mdi:printer-point-of-sale-wrench-outline
      mdi:reschedule
      mdi:sale
      mdi:sale-box
      mdi:sale-box-outline
      mdi:sale-circle
      mdi:sale-circle-outline
      mdi:sale-outline
      mdi:salesforce
      mdi:salt
      mdi:schedule
      mdi:scheduled-maintenance
      mdi:scheduled-payment
      mdi:shipping-pallet
      mdi:shop
      mdi:shop-hours
      mdi:shop-hours-outline
      mdi:shop-outline
      mdi:shop-schedule
      mdi:shop-schedule-outline
      mdi:silverware-spoon
      mdi:spoon-sugar
      mdi:spray-bottle
      mdi:stanley-knife
      mdi:store
      mdi:store-24-hour
      mdi:store-cog
      mdi:store-cog-outline
      mdi:store-off
      mdi:store-off-outline
      mdi:store-outline
      mdi:sugar
      mdi:sugar-cube-off
      mdi:sun-schedule
      mdi:sun-schedule-outline
      mdi:sun-time
      mdi:sun-time-outline
      mdi:tea
      mdi:tea-kettle
      mdi:tea-kettle-alert
      mdi:tea-kettle-alert-outline
      mdi:tea-kettle-empty
      mdi:tea-kettle-empty-off
      mdi:tea-kettle-full-off
      mdi:tea-off
      mdi:tea-off-outline
      mdi:tea-outline
      mdi:tea-to-go
      mdi:tea-to-go-outline
      mdi:teach
      mdi:time-of-day
      mdi:time-of-day-outline
      mdi:timer
      mdi:timer-outline
      mdi:truck-delivery
      mdi:truck-delivery-outline
      mdi:truck-freezer
      mdi:truck-shipping
      mdi:utensils
      mdi:utensils-clean
      mdi:utensils-fork
      mdi:utensils-fork-knife
      mdi:utensils-knife
      mdi:utensils-spoon
      mdi:utensils-variant
      mdi:view-day
      mdi:view-day-outline
      mdi:water
      mdi:water-outline
      mdi:weather-cloudy
      mdi:weather-dust
      mdi:weather-fog
      mdi:weather-hail
      mdi:weather-hazy
      mdi:weather-night
      mdi:weather-rainy
      mdi:weather-snowy
      mdi:weather-sunny
      mdi:weather-sunset
      mdi:weather-windy
      mdi:wine
      solar:bottle-bold
      solar:bottle-bold-duotone
      solar:bottle-broken
      solar:bottle-line-duotone
      solar:bottle-linear
      solar:bottle-outline
      solar:box-bold
      solar:box-bold-duotone
      solar:box-broken
      solar:box-line-duotone
      solar:box-linear
      solar:box-outline
      solar:cart-2-bold
      solar:cart-2-bold-duotone
      solar:cart-2-broken
      solar:cart-2-line-duotone
      solar:cart-2-linear
      solar:cart-2-outline
      solar:cart-3-bold
      solar:cart-3-bold-duotone
      solar:cart-3-broken
      solar:cart-3-line-duotone
      solar:cart-3-linear
      solar:cart-3-outline
      solar:cart-4-bold
      solar:cart-4-bold-duotone
      solar:cart-4-broken
      solar:cart-4-line-duotone
      solar:cart-4-outline
      solar:cart-5-bold
      solar:cart-5-bold-duotone
      solar:cart-5-broken
      solar:cart-5-line-duotone
      solar:cart-5-linear
      solar:cart-5-outline
      solar:cart-bold
      solar:cart-bold-duotone
      solar:cart-broken
      solar:cart-line-duotone
      solar:cart-linear
      solar:cart-outline
      solar:cup-bold
      solar:cup-bold-duotone
      solar:cup-broken
      solar:cup-hot-bold
      solar:cup-hot-bold-duotone
      solar:cup-hot-broken
      solar:cup-hot-line-duotone
      solar:cup-hot-linear
      solar:cup-hot-outline
      solar:cup-line-duotone
      solar:cup-linear
      solar:cup-outline
      solar:cup-star-bold
      solar:cup-star-bold-duotone
      solar:cup-star-broken
      solar:cup-star-line-duotone
      solar:cup-star-linear
      solar:cup-star-outline
      solar:delivery-bold
      solar:delivery-bold-duotone
      solar:delivery-broken
      solar:delivery-line-duotone
      solar:delivery-linear
      solar:delivery-outline
      solar:plate-bold
      solar:plate-bold-duotone
      solar:plate-broken
      solar:plate-line-duotone
      solar:plate-linear
      solar:plate-outline
      solar:sale-bold
      solar:sale-bold-duotone
      solar:sale-broken
      solar:sale-line-duotone
      solar:sale-linear
      solar:sale-outline
      solar:sale-square-bold
      solar:sale-square-bold-duotone
      solar:sale-square-broken
      solar:sale-square-line-duotone
      solar:sale-square-linear
      solar:sale-square-outline
      solar:shop-2-bold
      solar:shop-2-bold-duotone
      solar:shop-2-broken
      solar:shop-2-line-duotone
      solar:shop-2-linear
      solar:shop-2-outline
      solar:shop-bold
      solar:shop-bold-duotone
      solar:shop-broken
      solar:shop-line-duotone
      solar:shop-linear
      solar:shop-outline
      solar:tea-cup-bold
      solar:tea-cup-bold-duotone
      solar:tea-cup-broken
      solar:tea-cup-line-duotone
      solar:tea-cup-linear
      solar:tea-cup-outline
      solar:ticket-sale-bold
      solar:ticket-sale-bold-duotone
      solar:ticket-sale-broken
      solar:ticket-sale-line-duotone
      solar:ticket-sale-linear
      solar:ticket-sale-outline
      solar:water-bold
      solar:water-bold-duotone
      solar:water-broken
      solar:water-line-duotone
      solar:water-linear
      solar:water-outline
      tabler:arrow-fork
      tabler:baby-bottle
      tabler:basket-discount
      tabler:beer
      tabler:beer-filled
      tabler:beer-off
      tabler:bottle
      tabler:bottle-filled
      tabler:bottle-off
      tabler:bowl-spoon
      tabler:bowl-spoon-filled
      tabler:box
      tabler:brand-sugarizer
      tabler:bubble-tea
      tabler:bubble-tea-2
      tabler:cheese
      tabler:clock
      tabler:clock-filled
      tabler:clock-hour-1
      tabler:clock-hour-1-filled
      tabler:clock-hour-10
      tabler:clock-hour-10-filled
      tabler:clock-hour-11
      tabler:clock-hour-11-filled
      tabler:clock-hour-12
      tabler:clock-hour-12-filled
      tabler:clock-hour-2
      tabler:clock-hour-2-filled
      tabler:clock-hour-3
      tabler:clock-hour-3-filled
      tabler:clock-hour-4
      tabler:clock-hour-4-filled
      tabler:clock-hour-5
      tabler:clock-hour-5-filled
      tabler:clock-hour-6
      tabler:clock-hour-6-filled
      tabler:clock-hour-7
      tabler:clock-hour-7-filled
      tabler:clock-hour-8
      tabler:clock-hour-8-filled
      tabler:clock-hour-9
      tabler:clock-hour-9-filled
      tabler:cloud-snow
      tabler:coffee
      tabler:coffee-off
      tabler:cup
      tabler:cup-off
      tabler:discount
      tabler:discount-filled
      tabler:discount-off
      tabler:eye-discount
      tabler:filter-2-discount
      tabler:filter-discount
      tabler:fish
      tabler:fish-bone
      tabler:fish-bone-filled
      tabler:fish-hook
      tabler:fish-off
      tabler:flag-discount
      tabler:freeze-column
      tabler:freeze-row
      tabler:freeze-row-column
      tabler:git-fork
      tabler:grill-fork
      tabler:heart-discount
      tabler:hours-12
      tabler:hours-24
      tabler:ice-cream
      tabler:location-discount
      tabler:map-discount
      tabler:meat
      tabler:meat-off
      tabler:menu-order
      tabler:milk
      tabler:milk-filled
      tabler:milk-off
      tabler:milkshake
      tabler:music-discount
      tabler:navigation-discount
      tabler:package
      tabler:package-off
      tabler:pencil-discount
      tabler:plant
      tabler:plant-2
      tabler:plant-2-off
      tabler:plant-off
      tabler:rosette-discount
      tabler:rosette-discount-check
      tabler:rosette-discount-check-filled
      tabler:rosette-discount-filled
      tabler:rosette-discount-off
      tabler:salt
      tabler:shopping-bag-discount
      tabler:shopping-cart-discount
      tabler:teapot
      tabler:template
      tabler:template-filled
      tabler:template-off
      tabler:tools-kitchen
      tabler:tools-kitchen-2
      tabler:tools-kitchen-2-filled
      tabler:tools-kitchen-2-off
      tabler:tools-kitchen-3
      tabler:tools-kitchen-off
      tabler:truck-delivery
    ].uniq

    now = Time.current
    rows = icon_names.map { |name| { name: name, created_at: now, updated_at: now } }

    Icon.upsert_all(rows, unique_by: :index_icons_on_name) # rubocop:disable Rails/SkipsModelValidations

    $stdout.puts "[iconify:set_iconify_icons] iconos_cargados=#{icon_names.size} total_db=#{Icon.count}"
  end
end

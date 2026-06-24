seed_name = ENV.fetch("SEED", "demo")
seed_path = Rails.root.join("db/seeds/#{seed_name}.rb")

unless seed_path.exist?
  available_seeds = Rails.root.glob("db/seeds/*.rb").map { |path| path.basename(".rb").to_s }.sort
  raise ArgumentError, "Unknown seed '#{seed_name}'. Available seeds: #{available_seeds.to_sentence}"
end

load seed_path

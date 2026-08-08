namespace :seed do
  desc "Load the small demo seed"
  task demo: :environment do
    load Rails.root.join("db/seeds/demo.rb")
  end

  desc "Load the large local demo seed for screenshots and stress testing"
  task large_demo: :environment do
    load Rails.root.join("db/seeds/large_demo.rb")
  end
end

namespace :demo do
  desc "Refresh the public demo workspace with current relative dates"
  task refresh: :environment do
    load Rails.root.join("db/seeds/demo.rb")
    puts "Public demo workspace refreshed."
  end
end

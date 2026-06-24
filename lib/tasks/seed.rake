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

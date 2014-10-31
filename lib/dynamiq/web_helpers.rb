module Dynamiq
  module WebHelpers
    def stats
      @stats ||= Dynamiq::Stats.new
    end
  end
end

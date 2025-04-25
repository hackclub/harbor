module MembershipRequirements
  extend ActiveSupport::Concern

  class << self
    def requirements_for_status(status)
      send("#{status}_requirements")
    end

    def eligible_for_status?(user, status)
      requirements = requirements_for_status(status)
      requirements.all? { |requirement| requirement.met?(user) }
    end

    def current_status(user)
      user.membership_type
    end

    def next_status(current_status)
      statuses = User.membership_types.keys
      current_index = statuses.index(current_status.to_s)
      return nil if current_index.nil? || current_index == statuses.length - 1
      statuses[current_index + 1].to_sym
    end

    def humanized_status(status)
      {
        basic: "Basic",
        bronze: "Preferred Bronze",
        silver: "Preferred Silver",
        gold: "Preferred Gold",
        platinum: "Preferred Platinum"
      }[status]
    end

    def requirements_for(status)
      requirements_for_status(status)
    end

    private

    def total_ysws_hours(user)
      user.ysws_projects.sum { |p| p["hours_spent"].to_f }
    end

    def basic_requirements
      [
        Requirement.new(
          name: :has_account,
          description: "Has created an account",
          met_predicate: ->(_) { true }
        )
      ]
    end

    def bronze_requirements
      basic_requirements + [
        Requirement.new(
          name: :hackatime_hours,
          description: "Has logged at least 10 hours with Hackatime",
          met_predicate: ->(user) do
            ::Heartbeat.where(user: user)
                       .with_valid_timestamps
                       .duration_seconds >= 10.hours
          end
        )
      ]
    end

    def silver_requirements
      bronze_requirements + [
        Requirement.new(
          name: :ysws_hours,
          description: "Has at least 20 hours of approved YSWS projects",
          met_predicate: ->(user) { total_ysws_hours(user) >= 20 }
        )
      ]
    end

    def gold_requirements
      silver_requirements + [
        Requirement.new(
          name: :ysws_hours,
          description: "Has at least 50 hours of approved YSWS projects",
          met_predicate: ->(user) { total_ysws_hours(user) >= 50 }
        )
      ]
    end

    def platinum_requirements
      gold_requirements + [
        Requirement.new(
          name: :ysws_hours,
          description: "Has at least 100 hours of approved YSWS projects",
          met_predicate: ->(user) { total_ysws_hours(user) >= 100 }
        )
      ]
    end
  end

  class Requirement
    attr_reader :name, :description, :met_predicate

    def initialize(name:, description:, met_predicate:)
      @name = name
      @description = description
      @met_predicate = met_predicate
    end

    def met?(user)
      met_predicate.call(user)
    end
  end
end

require 'rails_admin/generic_support'

module RailsAdmin
  class AbstractModel
    # Returns all models for a given Rails app
    def self.all
      models = []

      Dir.glob(Rails.root.join("app/models/**/*.rb")).each do |filename|
        File.read(filename).scan(/class ([\w\d_\-:]+)/).flatten.each do |model_name|
          models << new(lookup(model_name)) rescue RuntimeError
        end
      end

      models.sort!{|x, y| x.model.to_s <=> y.model.to_s}
    end

    attr_accessor :model

    def initialize(model)
      model = self.class.lookup(model.to_s.camelize) unless model.is_a?(Class)
      @model = model
      self.extend(GenericSupport)
      ### TODO more ORMs support
      require 'rails_admin/active_record_support'
      self.extend(ActiverecordSupport)
    end

    private

    # Given a string +model_name+, finds the corresponding model class
    # or raises.
    def self.lookup(model_name)
      excluded_models.include?(model_name) && raise("RailsAdmin could not find model #{model_name}")

      begin
        # TODO: Should probably require the right part of ActiveSupport for this
        model = model_name.constantize
      rescue NameError
        raise "RailsAdmin could not find model #{model_name}"
      end

      if superclasses(model).include?(ActiveRecord::Base)
        model
      else
        raise "#{model_name} is not an ActiveRecord model"
      end
    end

    def self.superclasses(klass)
      superclasses = []
      while klass
        superclasses << klass.superclass if klass && klass.superclass
        klass = klass.superclass
      end
      superclasses
    end

    def self.excluded_models
      models = RailsAdmin::Config.excluded_models.map(&:to_s)
      models << ::Devise.mappings.keys[0].to_param.capitalize if defined?(::Devise)
      models << ['History']
    end

  end
end

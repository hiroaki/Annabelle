class ModelPresenterBase
  attr_accessor :view_context, :model

  def initialize(view_context, model)
    unless view_context.kind_of?(ActionView::Base)
      raise ArgumentError, "Expected ActionView::Base, got #{view_context.class.name}"
    end

    @view_context = view_context
    @model = model
    yield(self) if block_given?
  end

  def method_missing(method, *args, &block)
    if view_context.respond_to?(method)
      view_context.public_send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    view_context.respond_to?(method) || super
  end

  class << self
    def build(view_context, models)
      return enum_for(:build, view_context, models) unless block_given?
      models.each { |model| yield new(view_context, model) }
    end
  end
end

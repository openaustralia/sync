module Sync
  module Actions

    # Render all sync'd partials for resource to string and publish update action
    # to pubsub server with rendered resource messages
    #
    # resource - The ActiveModel resource
    # options - The Hash of options
    #   default_scope - The ActiveModel resource to scope the update channel to
    #   scope - Either a String, a symbol, an instance of ActiveModel or
    #           Sync::Scope or an Array containing a combination to scope 
    #           the update channel to. Will be concatenated to an optional 
    #           default_scope
    #
    def sync_update(resource, options = {})
      sync resource, :update, options
    end

    # Render all sync'd partials for resource to string and publish destroy action
    # to pubsub server with rendered resource messages
    #
    # resource - The ActiveModel resource
    # options - The Hash of options
    #   default_scope - The ActiveModel resource to scope the update channel to
    #   scope - Either a String, a symbol, an instance of ActiveModel or
    #           Sync::Scope or an Array containing a combination to scope 
    #           the destroy channel to. Will be concatenated to an optional 
    #           default_scope
    #
    def sync_destroy(resource, options = {})
      sync resource, :destroy, options
    end

    # Render all sync'd partials for resource to string and publish action
    # to pubsub server with rendered resource messages
    #
    # resource - The ActiveModel resource
    # action - The Symbol action to publish. One of :update, :destroy
    # options - The Hash of options
    #   default_scope - The ActiveModel resource to scope the action channel to
    #   scope - Either a String, a symbol, an instance of ActiveModel or
    #           Sync::Scope or an Array containing a combination to scope 
    #           the channel to. Will be concatenated to an optional default_scope
    #
    def sync(resource, action, options = {})
      scope = options[:scope]
      resources = [resource].flatten
      messages = resources.collect do |resource|
        all_partials(resource, sync_render_context, scope).collect do |partial|
          partial.message(action)
        end
      end

      Sync.client.batch_publish(messages.flatten)
    end

    # Render all sync'd partials for resource to string and publish 
    # new action to pubsub server with rendered resource messages
    #
    # resource - The ActiveModel resource, or Array of ActiveModel resources
    # action - The Symbol action to publish. One of :update, :destroy
    # options - The Hash of options
    #   default_scope - The ActiveModel resource to scope the new channel to
    #   scope - Either a String, a symbol, an instance of ActiveModel or
    #           Sync::Scope or an Array containing any combination to scope 
    #           the new channel to. Will be concatenated to an optional 
    #           default_scope
    #
    def sync_new(resource, options = {})
      scope = options[:scope]
      resources = [resource].flatten
      messages = resources.collect do |resource|
        all_partials(resource, sync_render_context, scope).collect do |partial|
          creator = partial.creator_for_scope(scope)
          creator.message
        end
      end

      Sync.client.batch_publish(messages.flatten)
    end

    private

    # The Context class handling partial rendering
    def sync_render_context
      @sync_render_context ||= Renderer.new
    end

    # Returns Array of Partials for all given resource and context, including
    # both Partial and RefetchPartial instances
    def all_partials(resource, context, scope = nil)
      Partial.all(resource, context, scope) + RefetchPartial.all(resource, context, scope)
    end
  end
end
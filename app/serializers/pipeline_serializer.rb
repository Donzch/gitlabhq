class PipelineSerializer < BaseSerializer
  InvalidResourceError = Class.new(StandardError)

  entity PipelineEntity

  def with_pagination(request, response)
    tap { @paginator = Gitlab::Serializer::Pagination.new(request, response) }
  end

  def paginated?
    @paginator.present?
  end

  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)
      resource = resource.includes(:project)
      resource = resource.includes(:pending_builds,
        :retryable_builds,
        :cancelable_statuses,
        :manual_actions,
        :artifacts)
      resource = resource.includes(pending_builds: :project)
      resource = resource.includes(manual_actions: :project)
      resource = resource.includes(artifacts: :project)
    end

    if paginated?
      super(@paginator.paginate(resource), opts)
    else
      super(resource, opts)
    end
  end

  def represent_status(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:status] }] })
    data.dig(:details, :status) || {}
  end
end

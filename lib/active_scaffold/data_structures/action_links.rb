ActiveScaffold::DataStructures::ActionLinks.class_eval do
  # adds an ActionLink, creating one from the arguments if need be
  def add(action, options = {})
    link = action.is_a?(ActiveScaffold::DataStructures::ActionLink) ? action : ActiveScaffold::DataStructures::ActionLink.new(action, options)
    # NOTE: this duplicate check should be done by defining the comparison operator for an Action data structure
    @set << link unless @set.any?{|a| a.action == link.action and a.controller == link.controller and a.parameters == link.parameters} || link.hidden
  end
end
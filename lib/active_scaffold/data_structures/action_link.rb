ActiveScaffold::DataStructures::ActionLink.class_eval do
  attr_accessor :hidden # Julien: When set to true, the link will not be shown
  # provides a quick way to set any property of the object from a hash
  def initialize(action, options = {})
    # set defaults
    self.action = action.to_s
    self.label = action
    self.confirm = false
    self.type = :collection
    self.inline = true
    self.method = :get
    self.crud_type = :delete if [:destroy].include?(action.to_sym)
    self.crud_type = :create if [:create, :new].include?(action.to_sym)
    self.crud_type = :update if [:edit, :update].include?(action.to_sym)
    self.crud_type ||= :read
    self.html_options = {}
    self.hidden = false # Julien: When set to true, the link will not be shown
    # apply quick properties
    options.each_pair do |k, v|
      setter = "#{k}="
      self.send(setter, v) if self.respond_to? setter
    end
  end
end

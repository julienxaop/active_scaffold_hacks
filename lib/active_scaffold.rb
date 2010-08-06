require "active_scaffold/constraints"
require "active_scaffold/data_structures/action_link"
require "active_scaffold/data_structures/action_links"
ActiveScaffold::ClassMethods.class_eval do
  def active_scaffold(model_id = nil, &block)
    # initialize bridges here
    ActiveScaffold::Bridge.run_all

    # converts Foo::BarController to 'bar' and FooBarsController to 'foo_bar' and AddressController to 'address'
    model_id = self.to_s.split('::').last.sub(/Controller$/, '').pluralize.singularize.underscore unless model_id

    # run the configuration
    @active_scaffold_config = ActiveScaffold::Config::Core.new(model_id)
    @active_scaffold_config_block = block
    self.links_for_associations
    self.active_scaffold_superclasses_blocks.each {|superblock| self.active_scaffold_config.configure &superblock}
    self.active_scaffold_config.configure &block if block_given?
    self.active_scaffold_config._configure_sti unless self.active_scaffold_config.sti_children.nil?
    self.active_scaffold_config._load_action_columns

    # defines the attribute read methods on the model, so record.send() doesn't find protected/private methods instead
    klass = self.active_scaffold_config.model
    klass.define_attribute_methods unless klass.generated_methods?

    @active_scaffold_overrides = []
    ActionController::Base.view_paths.each do |dir|
      active_scaffold_overrides_dir = File.join(dir,"active_scaffold_overrides")
      @active_scaffold_overrides << active_scaffold_overrides_dir if File.exists?(active_scaffold_overrides_dir)
    end
    @active_scaffold_overrides.uniq! # Fix rails duplicating some view_paths
    @active_scaffold_frontends = []
    if active_scaffold_config.frontend.to_sym != :default
      active_scaffold_custom_frontend_path = File.join(Rails.root, 'vendor', 'plugins', ActiveScaffold::Config::Core.plugin_directory, 'frontends', active_scaffold_config.frontend.to_s , 'views')
      @active_scaffold_frontends << active_scaffold_custom_frontend_path
    end
    active_scaffold_default_frontend_path = File.join(Rails.root, 'vendor', 'plugins', ActiveScaffold::Config::Core.plugin_directory, 'frontends', 'default' , 'views')
    active_scaffold_default_hacked_frontend_path = File.join(Rails.root, 'vendor', 'plugins', (ActiveScaffold::Config::Core.plugin_directory + "_hacks"), 'frontends', 'default' , 'views')
    @active_scaffold_frontends << active_scaffold_default_hacked_frontend_path # Julien: This will add the hacked views included in active_scaffold_hacks/frontends/default/views/
    @active_scaffold_frontends << active_scaffold_default_frontend_path
    @active_scaffold_custom_paths = []

    # include the rest of the code into the controller: the action core and the included actions
    module_eval do
      include ActiveScaffold::Finder
      include ActiveScaffold::Constraints
      include ActiveScaffold::AttributeParams
      include ActiveScaffold::Actions::Core
      active_scaffold_config.actions.each do |mod|
        name = mod.to_s.camelize
        include "ActiveScaffold::Actions::#{name}".constantize

        # sneak the action links from the actions into the main set
        if link = active_scaffold_config.send(mod).link rescue nil
          active_scaffold_config.action_links << link
        end
      end
    end
    self.active_scaffold_config._add_sti_create_links if self.active_scaffold_config.add_sti_create_links?
  end
end
ActiveScaffold::Constraints.class_eval do
  #protected
  # We do NOT want to use .search_sql. If anything, search_sql will refer
  # to a human-searchable value on the associated record.
  def condition_from_association_constraint(association, value)
    # ActiveScaffold: when the reverse association is a :belongs_to, the id for the associated object only exists as
    # the primary_key on the other table. so for :has_one and :has_many (when the reverse is :belongs_to),
    # we have to use the other model's primary_key.
    #
    # please see the relevant tests for concrete examples.
    field = if [:has_one, :has_many].include?(association.macro)
      association.klass.primary_key
    elsif [:has_and_belongs_to_many].include?(association.macro)
      association.association_foreign_key
    else
      association.options[:foreign_key] || association.name.to_s.foreign_key
    end

    table = case association.macro
    when :has_and_belongs_to_many
      association.options[:join_table]
    when :belongs_to, :has_many, :has_one # Julien: I've add the :has_many and :has_one relation in this 'when'
      # In the 'belongs_to' case, we will perform the lookup on the table that belongs to the other table (ok, active scaffold was already correct in that case)
      # But in the 'has_many' case, we'll perform the lookup on the table that has many objects of the other table (activescaffold used the table that belongs to the other in both cases!)
      active_scaffold_config.model.table_name
    else
      association.table_name # Julien: since my hack above, this line will not be used anymore
    end
    if association.options[:primary_key]
      value = association.klass.find(value).send(association.options[:primary_key])
    end
    # Julien:
    # 'value' contain the id of the calling object.
    # In the 'has_many' case, we will perform the lookup on the table that has_many object of the other table so the value should be the id of the object that has many objects of this other table
    if [:has_many, :has_one].include?(association.macro) #julien: 
      # association.klass is the table that belongs_to the other and value is the id of the calling object. (So association.klass.find(value) is the calling object. We'll found the id of the object that have many
      #objects of the other table by calling the 'foreign_key' to the table that belongs_to the other
      value = association.klass.find(value).send(association.options[:foreign_key] || association.name.to_s.foreign_key)
    end
    # Julien: Thanks to my hack the table and the value used in the condition below is now fixed for the :has_many and :has_one cases
    condition = constraint_condition_for("#{table}.#{field}", value)
    if association.options[:polymorphic]
      condition = merge_conditions(
        condition,
        constraint_condition_for("#{table}.#{association.name}_type", params[:parent_model].to_s)
      )
    end
    condition
  end
end
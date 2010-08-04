ActiveRecord::Reflection::AssociationReflection.class_eval do
  def reverse(parent_id = nil)
    if @reverse.nil?
      if (not self.options[:polymorphic]) || parent_id
        klass_name = self.class_name.constantize rescue nil
        if self.options[:polymorphic] && !klass_name
          parent_doc = self.active_record.find(parent_id)
          klass_name = parent_doc.send(self.options[:foreign_type]).constantize rescue nil
          self.instance_eval{@class_name = klass_name.name}
        end
        reverse_matches = reverse_matches_for(klass_name) rescue nil
        # grab first association, or make a wild guess
        @reverse = reverse_matches.blank? ? false : reverse_matches.first.name
      end
    end
    @reverse
  end

  protected
  def reverse_matches_for(klass)
    reverse_matches = []
    # stage 1 filter: collect associations that point back to this model and use the same primary_key_name
    klass.reflect_on_all_associations.each do |assoc|
      # skip over has_many :through associations
      next if assoc.options[:through]

      next unless assoc.options[:polymorphic] or assoc.class_name.constantize == self.active_record
      case [assoc.macro, self.macro].find_all{|m| m == :has_and_belongs_to_many}.length
        # if both are a habtm, then match them based on the join table
        when 2
        next unless assoc.options[:join_table] == self.options[:join_table]

        # if only one is a habtm, they do not match
        when 1
        next

        # otherwise, match them based on the primary_key_name
        when 0
        next unless assoc.primary_key_name.to_sym == self.primary_key_name.to_sym
      end

      reverse_matches << assoc
    end
    # stage 2 filter: name-based matching (association name vs self.active_record.to_s)
#    reverse_matches.find_all do |assoc|   # Julien: I commented this block as this give a bug in the case of a loop relation between a same model (my hack below fix that.) # And this also did nothing as this method returns reverse_mathces at this end
#
#      self.active_record.to_s.underscore.include?(assoc.name.to_s.pluralize.singularize)
#
#    end if reverse_matches.length > 1

    #Julien: If we have a relation that loop to herself (both belongs_to and has_many relation for a same model) then we may have two reverse_matches (ex: "same_model_rel" and "same_model_rels")
    # In that example, if self.name is "same_models" then the reverse_matching should be "same_model" and if self.name is "same_model" then the reverse_matching should be "same_models"
    # Here is my hack:
    reverse_matches = reverse_matches.find_all do |assoc|
      self.name.to_s != assoc.name.to_s
    end if reverse_matches.length > 1

    reverse_matches
  end
end
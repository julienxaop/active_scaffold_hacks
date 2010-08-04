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
end
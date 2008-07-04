class Class
  # Dinamically creates a proxy for given class methods.
  #
  # Example:
  # 
  #   class Repository
  #     def self.path
  #       @@path
  #     end
  #   
  #     class_method_proxy :path
  #   end
  #
  # It produces:
  #   # Proxy method for <tt>Repository#path</tt>
  #   def path
  #     self.class.path
  #   end
  #   private :path
  def class_method_proxy(*method_names)
    method_names.each do |m|
      self.class_eval %{
        # Proxy method for <tt>#{self.class.name}##{m}</tt>
        def #{m}(*args, &block)
          self.class.#{m}(*args, &block)
        end
        private :#{m}
      }, __FILE__, __LINE__
    end
  end
end

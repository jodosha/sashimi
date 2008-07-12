class Array
  # Transform the current +Array+ to a path.
  #
  # It's an alias for <tt>File#join</tt>.
  #
  #    %w(path to app).to_path # => path/to/app+
  #    %w(path to app).to_path(true) # => /Users/luca/path/to/app
  def to_path(absolute = false)
    path = File.join(self)
    path = File.expand_path(path) if absolute
    path
  end

  # Transform the current +Array+ to an absolute path.
  #
  #    %w(path to app).to_absolute_path # => /Users/luca/path/to/app
  #    %w(path to app).to_abs_path # => /Users/luca/path/to/app
  def to_absolute_path
    to_path(true)
  end
  alias_method :to_abs_path, :to_absolute_path
end

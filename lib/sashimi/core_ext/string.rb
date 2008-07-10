class String
  # Transform the current +String+ to a system path,
  # according to the current platform file system.
  #
  #  "path/to/app".to_path # => path/to/app (on *nix)
  #  "path/to/app".to_path # => path\to\app (on Windows)
  #
  #  "path/to/app".to_path(true) # => /Users/luca/path/to/app (on *nix)
  #  "path/to/app".to_path(true) # => C:\path\to\app (on Windows)
  def to_path(absolute = false)
    self.split(/\/\\/).to_path(absolute)
  end
end
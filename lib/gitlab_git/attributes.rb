module Gitlab
  module Git
    # Class for parsing Git attribute files and extracting the attributes for
    # file patterns.
    #
    # Unlike Rugged this parser only needs a single IO call (a call to `open`),
    # vastly reducing the time spent in extracting attributes.
    #
    # This class _only_ supports parsing the attributes file located at
    # `$GIT_DIR/info/attributes` as GitLab doesn't use any other files
    # (`.gitattributes` is copied to this particular path).
    #
    # Basic usage:
    #
    #     attributes = Gitlab::Git::Attributes.new(some_repo.path)
    #
    #     attributes.attributes('README.md') # => { "eol" => "lf }
    class Attributes
      # path - The path to the Git repository.
      def initialize(path)
        @path = path
        @patterns = nil
      end

      # Returns all the Git attributes for the given path.
      #
      # path - A path to a file for which to get the attributes.
      #
      # Returns a Hash.
      def attributes(path)
        patterns.each do |pattern, attrs|
          return attrs if File.fnmatch(pattern, path)
        end

        {}
      end

      # Returns a Hash containing the file patterns and their attributes.
      def patterns
        @patterns ||= parse_file
      end

      # Parses an attribute string.
      #
      # These strings can be in the following formats:
      #
      #     text      # => { "text" => true }
      #     -text     # => { "text" => false }
      #     key=value # => { "key" => "value" }
      #
      # string - The string to parse.
      #
      # Returns a Hash containing the attributes and their values.
      def parse_attributes(string)
        values = {}
        dash = '-'
        equal = '='

        string.split(/\s+/).each do |chunk|
          # Data such as "foo = bar" should be treated as "foo" and "bar" being
          # separate boolean attributes.
          next if chunk == equal

          # Input: "-foo"
          if chunk.start_with?(dash)
            key = chunk.byteslice(1, chunk.length - 1)

            values[key] = false

          # Input: "foo=bar"
          elsif chunk.include?(equal)
            key, value = chunk.split(equal, 2)

            values[key] = value

          # Input: "foo"
          else
            values[chunk] = true
          end
        end

        values
      end

      # Iterates over every line in the attributes file.
      def each_line
        full_path = File.join(@path, 'info/attributes')

        return unless File.exist?(full_path)

        File.open(full_path, 'r') do |handle|
          handle.each_line do |line|
            yield line.strip
          end
        end
      end

      private

      # Parses the Git attributes file.
      def parse_file
        pairs = []
        comment = '#'

        each_line do |line|
          next if line.start_with?(comment) || line.empty?

          pattern, attrs = line.split(/\s+/, 2)

          pairs << [pattern, parse_attributes(attrs)]
        end

        # Newer entries take precedence over older entries.
        pairs.reverse.to_h
      end
    end
  end
end

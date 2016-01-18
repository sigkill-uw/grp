module StyleCompiler
  class StyleScheme
    attr_reader :rules, :parent_id, :name
    attr_accessor :special_rules

    public

    def initialize(name, author, description, parent_id, rules)
      raise ArgumentError("StyleScheme requires a name") if name.nil?

      @name = name
      @author = author
      @description = description
      @parent_id = parent_id
      @rules = rules
      @special_rules = {}
    end

    def inherit_from(parent)
      @rules.update(parent.rules) { |key, old, new| old } unless parent.nil?
    end

    def serialize(pretty = false, tabulation = "  ", scope = ".grp-hilight")
      result = "/* Style scheme name: #{@name}"
      result += "\n * Author: #{@author}" unless @author.nil?
      result += "\n * \"#{@description}\"" unless @description.nil?
      result += " */\n"

      @rules.each { |id, rule|
        result += (pretty) ? "\n" : ""
        result += scope + " " unless scope.nil?
        result += "." + escape_css_identifier(id)
        result += (pretty) ? " {\n" : "{"
        result += ((rule.reference.nil?) ?
          rule.serialize(pretty, tabulation) :
          ((!@rules[rule.reference].nil?) ? @rules[rule.reference].serialize(pretty, tabulation) : ""));
        result += (pretty) ? "}\n" : "}"
      }

      @special_rules.each { |selector, rule|
        result += (pretty) ? "\n" : ""
        result += scope + " " unless scope.nil?
        result += selector
        result += (pretty) ? " {\n" : "{"
        result += ((rule.reference.nil?) ?
          rule.serialize(pretty, tabulation) :
          ((!@rules[rule.reference].nil?) ? @rules[rule.reference].serialize(pretty, tabulation) : ""));
        result += (pretty) ? "}\n" : "}"
      }

      result + ((!pretty) ? "\n" : "");
    end

    private

    def escape_css_identifier(identifier)
      escaped = ""

      identifier.each_char { |ch| 
          escaped += (unless(ch.between?('A', 'Z')  or ch.between?('a', 'z') or ch.between?('0', '9') or ch == '-' or ch == '_')
            "\\" + ch
          else
            ch
          end)
      }

      escaped
    end
  end
end

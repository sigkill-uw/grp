# encoding: UTF-8

# style_compiler.rb
# Defines a class representing a compiler capable of processing GtkSourceView style schemes.
# Given an array of filenames, the compile reads and processes the corresponding style definitions
# into StyleScheme objects, which can then be serialized easily into CSS.

# GtkSourceView styles are XML; we parse them with Nokogiri
require "nokogiri"
require "set"

# The data structures constructed by the compiler
# A StyleRule specifies a named rule for styling text (bold, italic, underline, color, etc.)
# A StyleScheme is a set of these rules, together with a little metadata.
require_relative "style_scheme"
require_relative "style_rule"

# Module containing the functions and data structures of the compiler
module StyleCompiler
  @@schema = nil

  def use_schema(filename)
    @@schema = Nokogiri::XML::RelaxNG(File.open(filename))
  end

  # StyleCompiler::compile
  # Given an array of filename, and a hash of previously-compiled styles associated with their IDs,
  # yields a pair (styles, messages) representing the GtkSourceView styles defined by the given
  # filenames (in addition to the precompiled styles; keyed by style ID) and the human-readable =
  # information and error messages yielded from the compilation process
  def compile(filenames, precompiled_styles = {})
    # The hash to be returned
    compiled_styles = precompiled_styles.clone

    # The set of styles which have a parent style. We resolve those references at the end
    waiting_on_parent = Set.new

    # The messages yielded by the compilation process
    messages = []

    # Iterate over finalenames
    filenames.each { |filename|

      # We catch syscall (IO) errors and Nokogiri syntax errors in this block
      begin

        # Parse the XML document in strict mode. If we're pedantic about the schema,
        # we might as well be pedantic about the syntax as well.
        # This call throws SyntaxError
        document = Nokogiri::XML(File.open(filename, "r")) { |config| config.strict }

        # Validate the document against the schema and throw the resultant error if required
        validation_errors = (!@@schema.nil?) ? @@schema.validate(document) : []
        raise validation_errors[0] if(!validation_errors.empty?)

        # palette is a hash returning a string suitable for use in CSS, representing a given color
        # We populate the hash with the color palette defined in the XML document, but we also
        # parse non-palette colors manually in the block below
        palette = Hash.new { |hash, color_string|

          # If we get to this point, color_string wasn't defined in the palette,
          # in which case the color is only valid if it begins with a hash.
          # Return nil otherwise

          if(!color_string.nil? and color_string[0] == "#")
            # Color strings of the form #f00 or #f00000 (hex digits, case insensitive)
            # are already valid in CSS. Other colors are assumed to be web-safe color
            # names, so we quote them and strip the hash.
            if(/\A#((\d|[a-f]){3}){1,2}\z/i =~ color_string)
              color_string
            else
              escaped = color_string[1, color_string.length - 1].sub('"', '\\"')
              "\"#{escaped}\""
            end
          else
            nil
          end
        }

        # Populate the palette
        document.css("color").each { |color_elem|
          palette[color_elem["name"]] = color_elem["value"]
        }

        # Hash of rules to be passed on to the StyleScheme constructor
        rules = {}

        # Every rule corresponds pretty directly to a style tag in the XML.
        # A rule is basically just a tuple of style info. This is kind of ugly.
        # The StyleRule constructor is okay with taking nils, so everything works.
        document.css("style").each { |style_elem|
          rules[style_elem["name"]] = StyleRule.new(
            palette[style_elem["foreground"]],
            palette[style_elem["background"]],
            (style_elem["bold"] == "true"),
            (style_elem["italic"] == "true"),
            style_elem["underline"],
            palette[style_elem["underline-color"]],
            (style_elem["strikethrough"] == "true"),
            style_elem["scale"],
            style_elem["use-style"])
        }

        # Check for duplicates and warn
        if(compiled_styles.key?(document.root["id"]))
          messages << "Apparent duplicate ID #{document.root["id"]} in provided style files; later file is being used"
        end

        # Set the new style in the hash
        compiled_styles[document.root["id"]] = StyleScheme.new(
            # The schema specifies that exactly one of these tags is present. It's necessary
            ((!document.root["name"].nil?) ?
               document.root["name"] :
               document.root["_name"]),

            # This tag may or may not be present. StyleScheme is okay with nil
            ((!document.at_css("author").nil?) ?
                document.at_css("author").text :
                nil),

            # One or none of these tags may be present
            ((!document.at_css("description").nil?) ?
              document.at_css("description").text :
              ((!document.at_css("_description").nil?) ? document.at_css("_description").text : nil)),

            # If this attribute is present, the scheme has a parent. We process that later
            document.root["parent-scheme"],

            # The hash of rules we parsed above
            rules)

      # If the scheme has a parent, tack it on to the queue
      if(!document.root["parent-scheme"].nil?)
        waiting_on_parent << document.root["id"]
      end

      # These rescue blocks pretty much eat the errors, but whatever.
      # This module is basically a holistic solution rather than a random library function.

      # IO error
      rescue SystemCallError => ex
        messages << "I/O error when attempting to compile #{filename}: #{ex.message}"

      # Nokogiri error
      rescue Nokogiri::XML::SyntaxError => ex
        messages << "Parse or validation error when attempting to compile #{filename}: #{ex.message} [#{ex.line}:#{ex.column}]"

      # Success, I guess
      else
        messages << "Successfully parsed and compiled #{filename}, yielding style ID #{document.root["id"]}"

      end
    }

    # Resolve the parentage of any style with a parent
    waiting_on_parent.to_a.each { |id|
      resolve_parent(id, compiled_styles, waiting_on_parent)
    }

    # Return the pair of styles and messages
    return compiled_styles, messages
  end

  # StyleCompiler::resolve_parent
  # Given an ID as a string, a hash of styles keyed by their ID, and a set of style IDs that need processing,
  # processes the given ID by applying any non-overridden styles defined in its parent.
  def resolve_parent(id, compiled_styles, waiting_on_parent)

    # If we actually need to process this id,
    if(waiting_on_parent.include?(id))

      # Take the id of its parent
      parent_id = compiled_styles[id].parent_id

      # We don't want to process this again
      waiting_on_parent.delete(id)

      # Possibly resolve the parent (because it may itself have ancestors)
      resolve_parent(parent_id, compiled_styles, waiting_on_parent)

      # Apply the parental styles to the current style
      compiled_styles[id].inherit_from(compiled_styles[parent_id])

      # This solution does not detect cycles or missing parents. I think it's okay as it is,
      # but in a more granular library it might be appropriate to change that.
    end
  end

  module_function :compile, :use_schema, :resolve_parent
end

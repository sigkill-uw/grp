# encoding: UTF-8

# GtkSourceView styles are XML; we parse them with Nokogiri
require "nokogiri"
require "set"

# Module containing the functions and data structures of the compiler
module LanguageCompiler
  @@schema = nil

  def use_schema(filename)
    @@schema = Nokogiri::XML::RelaxNG(File.open(filename))
  end

  def compile(filenames)
    languages = {}

    # The messages yielded by the compilation process
    messages = []

    # Iterate over filenames
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

        languages[document.root["id"]] = ((!document.root["name"].nil?) ?
          document.root["name"] : document.root["_name"])

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
        messages << "Successfully parsed and compiled #{filename}, yielding language ID #{document.root["id"]}"
      end
    }

    return languages, messages
  end

  module_function :compile, :use_schema
end

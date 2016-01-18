module StyleCompiler
  class StyleRule
    attr_reader :reference

    public

    def initialize(fg_color, bg_color, bold, italic, underline_style, underline_color, strikethrough, scale, reference)
      @fg_color = fg_color
      @bg_color = bg_color
      @bold = bold
      @italic = italic
      @underline_style = underline_style
      @underline_color = underline_color
      @strikethrough = strikethrough
      @scale = scale
      @reference = reference
    end

    def serialize(pretty = false, tabulation = "  ")
      result = ""
      add = ((pretty) ?
        Proc.new { |key, val| result += "#{tabulation}#{key}: #{val};\n" } :
        Proc.new { |key, val| result += "#{key}:#{val};" })

      add.call("color", @fg_color) unless @fg_color.nil?
      add.call("background-color", @bg_color) unless @bg_color.nil?
      add.call("font-weight", "bold") if @bold
      add.call("font-style", "italic") if @italic

      if(!@underline_style.nil? and @underline_style != "none" and @underline_style != "false")
        add.call("text-decoration",
          "underline" +
          ((@strikethrough) ? " line-through" : "") +
          ((@underline_style == "error") ? " wavy" : "") +
          ((!@underline_color.nil?) ? " #{@underline_color}" : ""))
      elsif(@strikethrough)
        add.call("text-decoration", "line-through")
      end

      begin
        add.call("font-size", "#{Float(@scale) * 100}%") unless @scale.nil?
      rescue TypeError
        add.call("font-size", @scale)
      end

      result
    end
  end
end

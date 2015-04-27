class MarkdownHelper
  require 'coderay'
  require 'redcarpet'
  attr_accessor :raw, :parsed

  def initialize(raw)
    @raw = raw
    @parsed = ""
    @languages = [:ruby, :cmd, :javascript] 
    @coderay_options = {
      :line_numbers => :table,
      :line_number_anchors => false,
      :css => :class
    }
  end

  def remove_hexo_marks
    @raw.gsub!('<div class="highlight-block">', "")
    @raw.gsub!("<\/div>", "")
    @raw.gsub!("<snippet>", "`")
    @raw.gsub!("<\/snippet>", "`")
  end

  def parse_markdown
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, 
                                        fenced_code_blocks: true
                                       )
    @raw = markdown.render(@raw)
  end

  def parse_code_block_style
    while first_index = @raw =~ /<pre>/
      # parse pre tag
      closing_index = @raw =~ /<\/pre>/
      height_multiplier =  @raw[first_index...closing_index].count("\n")
      @parsed += @raw[0..first_index+4].gsub!("pre", "pre style='height:#{height(height_multiplier)}px;'")
      # parse coderay
      @raw = @raw[first_index+5..-1]
      end_index = @raw =~ />/
      code_class = @raw[0..end_index]
      @language = check_language(code_class)
      @parsed += @raw[0..end_index]
      @raw = @raw[end_index+1..-1]
      end_block_index = @raw =~ /<\/code>/
      block = CodeRay.scan(@raw[0...end_block_index], @language).html(@coderay_options)   
      @parsed += block
      # add following content
      @raw = @raw[end_block_index-1..-1]
      end_block_end_index = @raw =~ /<\/pre>/
      @parsed += @raw[0..end_block_end_index+5]
      @raw = @raw[end_block_end_index+6..-1]
    end
    @parsed += @raw
  end

  def parse_marks
    @parsed.gsub!("&amp;quot;","&quot;") # 去除雙括號
    @parsed.gsub!('&amp;<span class="comment">#39;',"&#39;") # 去除單括號(Coderay誤認為註解)
    @parsed.gsub!('&amp;#39;</span>',"&#39;") # 去除單括號(Coderay誤認為註解的結尾)
    @parsed.gsub!('&amp;#39;',"&#39;") # 去除其他單括號
  end

  private

    def check_language(class_attr)
      @languages.each do |lang|
        return lang if class_attr.index(lang.to_s)
      end
      :html
    end

    def height(multiplier)
      base = 35
      line_height = 20
      return (base + line_height * multiplier).to_s
    end

end
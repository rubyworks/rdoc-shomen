class RDoc::Options
  # true/false to include full source
  attr_accessor :source
  # true/false to use YAML instead of JSON
  attr_accessor :yaml
end

class RDoc::TopLevel
  #
  def to_h
    {
       :path     => path,
       :name     => base_name,
       :fullname => full_name,
       :rootname => absolute_name,
       :modified => last_modified,
       :diagram  => diagram
    }
  end

  #
  #def to_json
  #  to_h.to_json
  #end
end


class RDoc::ClassModule
  #
  def with_documentation?
    document_self_or_methods || classes_and_modules.any?{ |c| c.with_documentation? }
  end

  #
  def document_self_or_methods
    document_self || method_list.any?{ |m| m.document_self }
  end

#  #
#  def to_h
#    {
#      :name       => name,
#      :fullname   => full_name,
#      :type       => type,
#      :path       => path,
#      :superclass => module? ? nil : superclass
#    }
#  end
#
#  def to_json
#    to_h.to_json
#  end
end


module RDoc::SourceCodeAccess

  #
  def source_code_raw
    return '' unless @token_stream
    src = ""
    @token_stream.each do |t|
      next unless t
      src << t.text
    end
    #add_line_numbers(src)
    src
  end

  #
  def source_code_location
    src = source_code_raw
    if md = /File (.*?), line (\d+)/.match(src)
      file = md[1]
      line = md[2]
    else
      file = "(unknown)"
      line = 0
    end
    return file, line
  end

end


class RDoc::AnyMethod
  include RDoc::SourceCodeAccess

#  # NOTE: dont_rename_initialize isn't used
#  def to_h
#    {
#      :name         => name,
#      :fullname     => full_name,
#      :prettyname   => pretty_name,
#      :path         => path,
#      :type         => type,
#      :visibility   => visibility,
#      :blockparams  => block_params,
#      :singleton    => singleton,
#      :text         => text,
#      :aliases      => aliases,
#      :aliasfor     => is_alias_for,
#      :aref         => aref,
#      :parms        => params,
#      :callseq      => call_seq
#      #:paramseq     => param_seq,
#    }
#  end

#  #
#  def to_json
#    to_h.to_json
#  end
end

class RDoc::Attr
  include RDoc::SourceCodeAccess
end

=begin

# DEPRECATE ASAP
require "rdoc/parser/c"
# New RDoc somehow misses class comemnts.
# copyied this function from "2.2.2" 
if ['2.4.2', '2.4.3'].include? RDoc::VERSION
  class RDoc::Parser::C
    def find_class_comment(class_name, class_meth)
      comment = nil
      if @content =~ %r{((?>/\*.*?\*/\s+))
                     (static\s+)?void\s+Init_#{class_name}\s*(?:_\(\s*)?\(\s*(?:void\s*)\)}xmi then
        comment = $1
      elsif @content =~ %r{Document-(?:class|module):\s#{class_name}\s*?(?:<\s+[:,\w]+)?\n((?>.*?\*/))}m
        comment = $1
      else
        if @content =~ /rb_define_(class|module)/m then
          class_name = class_name.split("::").last
          comments = []
          @content.split(/(\/\*.*?\*\/)\s*?\n/m).each_with_index do |chunk, index|
            comments[index] = chunk
            if chunk =~ /rb_define_(class|module).*?"(#{class_name})"/m then
              comment = comments[index-1]
              break
            end
          end
        end
      end
      class_meth.comment = mangle_comment(comment) if comment
    end
  end
end

=end


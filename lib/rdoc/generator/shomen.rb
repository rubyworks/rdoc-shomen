require 'fileutils'
require 'pathname'
require 'yaml'
require 'json'

require 'rdoc/rdoc'
require 'rdoc/generator'
require 'rdoc/generator/markup'

require 'shomen/metadata'
require 'shomen/model'  # TODO: have metadata in model

require 'rdoc/generator/shomen_extensions'

# Shomen Adaptor for RDoc utilizes the rdoc tool to parse ruby source code
# to build a Shomen documenation file.
#
# RDoc is almost entirely a free-form documentation system, so it is not
# possible for Shomen to fully harness all the details it can support from
# the RDoc documentation, such as method argument descriptions.
#
class RDoc::Generator::Shomen

  #
  DESCRIPTION = 'Shomen documentation format'

  # Register shomen generator with RDoc.
  RDoc::RDoc.add_generator(self)

  #include RDocShomen::Metadata

  # Standard generator factory method.
  #
  # options - Generator options.
  #
  # Returns new RDoc::Generator::Shomen instance.
  def self.for(options)
    new(options)
  end

  # User options from the command line.
  attr :options

  #
  def self.setup_options(options)
    options.source = false
    options.yaml   = false

    opt = options.option_parser

    opt.separator nil
    opt.separator "Shomen generator options:"
    opt.separator nil
    opt.on("--yaml", "Generate YAML document instead of JSON.") do |value|
      options.yaml = true
    end
    opt.separator nil
    opt.on("--source", "Include full source code for scripts.") do |value|
      options.github = true
    end
  end

  # List of all classes and modules.
  #def all_classes_and_modules
  #  @all_classes_and_modules ||= RDoc::TopLevel.all_classes_and_modules
  #end

  # In the world of the RDoc Generators #classes is the same
  # as #all_classes_and_modules. Well, except that its sorted 
  # too. For classes sans modules, see #types.
  #
  def classes
    @classes ||= RDoc::TopLevel.all_classes_and_modules.sort
  end

  # Only toplevel classes and modules.
  def classes_toplevel
    @classes_toplevel ||= classes.select {|klass| !(RDoc::ClassModule === klass.parent) }
  end

  #
  def files
    @files ||= (
      @files_rdoc.select{ |f| f.parser != RDoc::Parser::Simple }
    )
  end

  # List of toplevel files. RDoc supplies this via the #generate method.
  def files_toplevel
    @files_toplevel ||= (
      @files_rdoc.select{ |f| f.parser == RDoc::Parser::Simple }
    )
  end

  #
  def files_hash
    @files ||= RDoc::TopLevel.files_hash
  end

  # List of all methods in all classes and modules.
  def methods_all
    @methods_all ||= classes.map{ |m| m.method_list }.flatten.sort
  end

  # List of all attributes in all classes and modules.
  def attributes_all
    @attributes_all ||= classes.map{ |m| m.attributes }.flatten.sort
  end

  #
  def constants_all
    @constants_all ||= classes.map{ |c| c.constants }.flatten
  end

  ## TODO: What's this then?
  ##def json_creatable?
  ##  RDoc::TopLevel.json_creatable?
  ##end

  # RDoc needs this to function.
  def class_dir ; nil ; end

  # RDoc needs this to function.
  def file_dir  ; nil ; end

  # TODO: Rename ?
  def shomen
    @table || {}
  end

  # Build the initial indices and output objects based on an array of
  # top level objects containing the extracted information.
  #
  # files - Files to document.
  #
  # Returns nothing.
  def generate(files)
    @files_rdoc = files.sort

    @table = {}

    generate_metadata
    generate_constants
    generate_classes
    #generate_attributes
    generate_methods
    generate_documents
    generate_scripts   # must be last b/c it depends on the others

    # TODO: method accessor fields need to be handled

    # THINK: Internal referencing model, YAML and JSYNC ?
    #ref_table = reference_table(@table)

    if options.yaml
      out = @table.to_yaml
    else
      out = JSON.generate(@table)
    end

    if options.op_dir == '-'
      puts out
    else
      File.open(output_file, 'w') do |f|
        f << out
      end unless $dryrun
    end

  #rescue StandardError => err
  #  debug_msg "%s: %s\n  %s" % [ err.class.name, err.message, err.backtrace.join("\n  ") ]
  #  raise err
  end

  #
  def output_file
    name = project_metadata['name']
    vers = project_metadata['version']

    if name && vers
      "#{name}-#{vers}.json"
    else
     'doc.json'
    end
  end

protected

  # Initialize new generator.
  #
  # options - Generator options.
  #
  # Returns new RDoc::Generator::Shomen instance.
  def initialize(options)
    @options = options
    #@options.diagram = false  # why?

    @path_base   = Pathname.pwd.expand_path

    # TODO: This is probably not needed any more.
    @path_output = Pathname.new(@options.op_dir).expand_path(@path_base)
  end

  # Current pathname.
  attr :path_base

  # The output path.
  attr :path_output

  #
  def path_output_relative(path=nil)
    if path
      path.to_s.sub(path_base.to_s+'/', '')
    else
      @path_output_relative ||= path_output.to_s.sub(path_base.to_s+'/', '')
    end
  end

  #
  def project_metadata
    @project_metadata ||= Shomen::Metadata.new
  end

  #
  def generate_metadata
    @table['(metadata)'] = project_metadata.to_h
  end

  # Add constants to table.
  def generate_constants
    debug_msg "Generating constant documentation:"
    constants_all.each do |rdoc|
      model = Shomen::Model::Constant.new

      model.path      = rdoc.parent.full_name + '::' + rdoc.name
      model.name      = rdoc.name
      model.namespace = rdoc.parent.full_name
      model.comment   = rdoc.comment.text
      model.format    = 'rdoc'
      model.value     = rdoc.value
      model.files     = ["/#{rdoc.file.full_name}"]

      @table[model.path] = model.to_h
    end
  end

  # Add classes (and modules) to table.
  def generate_classes
    debug_msg "Generating class/module documentation:"

    classes.each do |rdoc_class|
      debug_msg "%s (%s)" % [ rdoc_class.full_name, rdoc_class.path ]

      if rdoc_class.type=='class'
        model = Shomen::Model::Class.new
      else
        model = Shomen::Model::Module.new
      end

      model.path             = rdoc_class.full_name
      model.name             = rdoc_class.name
      model.namespace        = rdoc_class.full_name.split('::')[0...-1].join('::')
      model.includes         = rdoc_class.includes.map{ |x| x.name }  # FIXME: How to "lookup" full name?
      model.extensions       = []                                     # TODO:  How to get extensions?
      model.comment          = rdoc_class.comment.to_s #text
      model.format           = 'rdoc'
      model.constants        = rdoc_class.constants.map{ |x| complete_name(x.name, rdoc_class.full_name) }
      model.modules          = rdoc_class.modules.map{ |x| complete_name(x.name, rdoc_class.full_name) }
      model.classes          = rdoc_class.classes.map{ |x| complete_name(x.name, rdoc_class.full_name) }
      model.methods          = rdoc_class.method_list.map{ |m| method_name(m) }.uniq
      model.accessors        = rdoc_class.attributes.map{ |a| method_name(a) }.uniq  #+ ":#{a.rw}" }.uniq
      model.files            = rdoc_class.in_files.map{ |x| "/#{x.full_name}" }

      if rdoc_class.type == 'class'
        # HACK: No idea why RDoc is returning some weird superclass:
        #   <RDoc::NormalClass:0xd924d4 class Object < BasicObject includes: []
        #     attributes: [] methods: [#<RDoc::AnyMethod:0xd92b8c Object#fileutils
        #     (public)>] aliases: []>
        # Maybe it has something to do with #fileutils?
        model.superclass = (
          case rdoc_class.superclass
          when nil
          when String
            rdoc_class.superclass
          else
            rdoc_class.superclass.full_name
          end
        )
      end

      @table[model.path] = model.to_h
    end
  end

  # TODO: How to get literal interface separate from call-sequnces?

  # Transform RDoc methods to Shomen model and add to table.
  def generate_methods
    debug_msg "Generating method documentation:"

    list = methods_all + attributes_all

    list.each do |rdoc_method|
      #debug_msg "%s" % [rdoc_method.full_name]

      #full_name  = method_name(m)
      #'prettyname'   => m.pretty_name,
      #'type'         => m.type, # class or instance

      model = Shomen::Model::Method.new

      model.path        = method_name(rdoc_method)
      model.name        = rdoc_method.name
      model.namespace   = rdoc_method.parent_name
      model.comment     = rdoc_method.comment.text
      model.format      = 'rdoc'
      model.aliases     = rdoc_method.aliases.map{ |a| method_name(a) }
      model.alias_for   = method_name(rdoc_method.is_alias_for)
      model.singleton   = rdoc_method.singleton

      model.declarations << rdoc_method.type.to_s #singleton ? 'class' : 'instance'
      model.declarations << rdoc_method.visibility.to_s

      model.interfaces = []
      if rdoc_method.call_seq
        rdoc_method.call_seq.split("\n").each do |cs|
          cs = cs.to_s.strip
          model.interfaces << parse_interface(cs) unless cs == ''
        end
      end
      model.interfaces << parse_interface("#{rdoc_method.name}#{rdoc_method.params}")

      model.returns    = []  # RDoc doesn't support specifying return values
      model.file       = '/'+rdoc_method.source_code_location.first
      model.line       = rdoc_method.source_code_location.last.to_i
      model.source     = rdoc_method.source_code_raw

      if rdoc_method.respond_to?(:c_function)
        model.language = rdoc_method.c_function ? 'c' : 'ruby'
      else
        model.language = 'ruby'
      end

      @table[model.path] = model.to_h
    end
  end

#--
=begin
  #
  def generate_attributes
#$stderr.puts "HERE!"
#$stderr.puts attributes_all.inspect
#exit
    debug_msg "Generating attributes documentation:"
    attributes_all.each do |rdoc_attribute|
      debug_msg "%s" % [rdoc_attribute.full_name]

      adapter = Shomen::RDoc::MethodAdapter.new(rdoc_attribute)
      data    = Shomen::Model::Method.new(adapter).to_h

      @table[data['path']] = data

      #code       = m.source_code_raw
      #file, line = m.source_code_location

      #full_name = method_name(m)

      #'prettyname'   => m.pretty_name,
      #'type'         => m.type, # class or instance

      #model_class = m.singleton ? Shomen::Model::Function : Shomen::Model::Method
      #model_class = Shomen::Model::Attribute

      #@table[full_name] = model_class.new(
      #  'path'         => full_name,
      #  'name'         => m.name,
      #  'namespace'    => m.parent_name,
      #  'comment'      => m.comment.text,
      #  'access'       => m.visibility.to_s,
      #  'rw'           => m.rw,  # TODO: better name ?
      #  'singleton'    => m.singleton,
      #  'aliases'      => m.aliases.map{ |a| method_name(a) },
      #  'alias_for'    => method_name(m.is_alias_for),
      #  'image'        => m.params,
      #  'arguments'    => [],
      #  'parameters'   => [],
      #  'block'        => m.block_params, # TODO: what is block?
      #  'interface'    => m.arglists,
      #  'returns'      => [],
      #  'file'         => file,
      #  'line'         => line,
      #  'source'       => code
      #).to_h
    end
  end
=end
#++

  # Parse method interface.
  #
  # TODO: remove any trailing comment too
  def parse_interface(interface)
    args, block = [], {}

    interface, returns = interface.split(/[=-]\>/)
    interface = interface.strip
    if i = interface.index(/\)\s*\{/)
      block['image'] = interface[i+1..-1].strip
      interface = interface[0..i].strip
    end

    arguments = interface.strip.sub(/^.*?\(/,'').chomp(')')
    arguments = arguments.split(/\s*\,\s*/)
    arguments.each do |a|
      if a.start_with?('&')
        block['name'] = a
      else
        n,v = a.split('=')
        args << (v ? {'name'=>n,'default'=>v} : {'name'=>n})
      end
    end

    result = {}
    result['signature'] = interface
    result['arguments'] = args
    result['block']     = block unless block.empty?
    result['returns']   = returns.strip if returns
    return result
  end
  private :parse_interface

  # Generate entries for information files, e.g. `README.rdoc`.
  def generate_documents
    files_toplevel.each do |rdoc_document|
      absolute_path = File.join(path_base, rdoc_document.full_name)

      model = Shomen::Model::Document.new

      model.path     = rdoc_document.full_name
      model.name     = File.basename(absolute_path)
      model.created  = File.mtime(absolute_path)
      model.modified = File.mtime(absolute_path)
      model.text     = File.read(absolute_path) #file.comment
      model.format   = mime_type(absolute_path)

      @table['/'+model.path] = model.to_h
    end
  end

  # TODO: Add loadpath and make file path relative to it?

  # Generate script entries.
  def generate_scripts
    #debug_msg "Generating file documentation in #{path_output_relative}:"
    #templatefile = self.path_template + 'file.rhtml'

    files.each do |rdoc_file|
      debug_msg "%s" % [rdoc_file.full_name]

      absolute_path = File.join(path_base, rdoc_file.full_name)
      #rel_prefix  = self.path_output.relative_path_from(outfile.dirname)

      model = Shomen::Model::Script.new

      model.path      = rdoc_file.full_name
      model.name      = File.basename(rdoc_file.full_name)
      model.created   = File.ctime(absolute_path)
      model.modified  = File.mtime(absolute_path)

      # http://github.com/rubyworks/qed/blob/master/ lib/qed.rb

      # TODO: Add option to rdoc command line tool instead of using ENV.

      if ENV['source']
        model.source   = File.read(absolute_path) #file.comment
        model.language = mime_type(absolute_path)
      end

      webcvs = options.webcvs || project_metadata['webcvs']
      if webcvs
        model.uri      = File.join(webcvs, model.path)  # TODO: use open-uri ?
        model.language = mime_type(absolute_path)
      end

      #model.header   =
      #model.footer   =
      model.requires  = rdoc_file.requires.map{ |r| r.name }
      model.constants = rdoc_file.constants.map{ |c| c.full_name }

      # note that this utilizes the table we are building
      # so it needs to be the last thing done.
      @table.each do |k, h|
        case h['!']
        when 'module'
          model.modules ||= []
          model.modules << k if h['files'].include?(rdoc_file.full_name)
        when 'class'
          model.classes ||= []
          model.classes << k if h['files'].include?(rdoc_file.full_name)
        when 'method'
          model.methods ||= []
          model.methods << k if h['file'] == rdoc_file.full_name
        when 'class-method'
          model.class_methods ||= []
          model.class_methods << k if h['file'] == rdoc_file.full_name
        end
      end

      @table['/'+model.path] = model.to_h
    end
  end

  # Returns String of fully qualified name.
  def complete_name(name, namespace)
    if name !~ /^#{namespace}/
      "#{namespace}::#{name}"
    else
      name
    end
  end

  #
  def collect_methods(class_module, singleton=false)
    list = []
    class_module.method_list.each do |m|
      next if singleton ^ m.singleton
      list << method_name(m)
    end
    list.uniq
  end

  #
  def collect_attributes(class_module, singleton=false)
    list = []
    class_module.attributes.each do |a|
      next if singleton ^ a.singleton
      #p a.rw
      #case a.rw
      #when :write, 'W'
      #  list << "#{method_name(a)}="
      #else
        list << method_name(a)
      #end
    end
    list.uniq
  end

  #
  def method_name(method)
    return nil if method.nil?
    if method.singleton
      i = method.full_name.rindex('::')     
      method.full_name[0...i] + '.' + method.full_name[i+2..-1]
    else
      method.full_name
    end
  end

  #
  def mime_type(path)
    case File.extname(path)
    when '.rb', '.rbx' then 'text/ruby'
    when '.c' then 'text/c-source'
    when '.rdoc' then 'text/rdoc'
    when '.md', '.markdown' then 'text/markdown'
    else 'text/plain'
    end
  end

  # Output progress information if rdoc debugging is enabled

  def debug_msg(msg)
    return unless $DEBUG_RDOC
    case msg[-1,1]
      when '.' then tab = "= "
      when ':' then tab = "== "
      else          tab = "* "
    end
    $stderr.puts(tab + msg)
  end

end



#--
=begin
  #
  # N O T  U S E D
  #

  # Sort based on how often the top level namespace occurs, and then on the
  # name of the module -- this works for projects that put their stuff into
  # a namespace, of course, but doesn't hurt if they don't.
  def sort_salient(classes)
    nscounts = classes.inject({}) do |counthash, klass|
      top_level = klass.full_name.gsub( /::.*/, '' )
      counthash[top_level] ||= 0
      counthash[top_level] += 1
      counthash
    endfiles_toplevel
    classes.sort_by{ |klass|
      top_level = klass.full_name.gsub( /::.*/, '' )
      [nscounts[top_level] * -1, klass.full_name]
    }.select{ |klass|
      klass.document_self
    }
  end
=end

=begin
  # Loop through table and convert all named references into bonofied object
  # references.
  def reference_table(table)
    debug_msg "== Generating Reference Table"
    new_table = {}
    table.each do |key, entry|
      debug_msg "%s" % [key]
      data = entry.dup
      new_table[key] = data
      case data['!']
      when 'script'
        data["constants"]  = ref_list(data["constants"])
        data["modules"]    = ref_list(data["modules"])
        data["classes"]    = ref_list(data["classes"])
        data["functions"]  = ref_list(data["functions"])
        data["methods"]    = ref_list(data["methods"])
      when 'file'
      when 'constant'
        data["namespace"]  = ref_item(data["namespace"])
      when 'module', 'class'
        data["namespace"]  = ref_item(data["namespace"])
        data["includes"]   = ref_list(data["includes"])
        #data["extended"]  = ref_list(data["extended"])
        data["constants"]  = ref_list(data["constants"])
        data["modules"]    = ref_list(data["modules"])
        data["classes"]    = ref_list(data["classes"])
        data["functions"]  = ref_list(data["functions"])
        data["methods"]    = ref_list(data["methods"])
        data["files"]      = ref_list(data["files"])
        data["superclass"] = ref_item(data["superclass"]) if data.key?("superclass")
      when 'method', 'function'
        data["namespace"]  = ref_item(data["namespace"])
        data["file"]       = ref_item(data["file"])
      end
    end
    new_table
  end

  # Given a key, return the matching table item. If not found return the key.
  def ref_item(key)
    @table[key] || key
  end

  # Given a list of keys, return the matching table items.
  def ref_list(keys)
    #keys.map{ |k| @table[k] || k }
    keys.map{ |k| @table[k] || nil }.compact
  end

=end
#++


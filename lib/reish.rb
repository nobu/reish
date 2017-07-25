#
#   reish.rb - 
#   	Copyright (C) 2014-2017 Keiju ISHITSUKA
#				(Penta Advanced Labrabries, Co.,Ltd)
#
# --
#
#   
#

require "reish/locale"
require "reish/init-reish"
require "reish/shell"
require "reish/completion"

module Reish

  INSPECT_LEBEL = 1

  class Abort < Exception;end

  @CONF={}
  @COMP = {}
  @COMP[:INPUT_METHOD] = {}

  def Reish.conf
    @CONF
  end

  def Reish.comp
    @COMP
  end

  def Reish::start(ap_path = nil)
    $0 = File::basename(ap_path, ".rb") if ap_path
    Reish.setup(ap_path)

    if @CONF[:OPT_C]
      im = StringInputMethod.new(@CONF[:OPT_C])
      sh = MainShell.new(im)
    elsif @CONF[:OPT_TEST_CMPL]
      compl = @COMP[:COMPLETOR].new(Shell.new)
      compl.candidate(@CONF[:OPT_TEST_CMPL])
      exit
    elsif !ARGV.empty?
      f = ARGV.shift
      sh = MainShell.new(f)
    else
      sh = MainShell.new
    end
    const_set(:MAIN_SHELL, sh)

    sh.start
  end

  def Reish::active_thread?
    Thread.current[:__REISH_CURRENT_SHELL__]
  end

  def Reish::current_shell
    Thread.current[:__REISH_CURRENT_SHELL__]
  end

  def Reish::current_shell=(sh)
    Thread.current[:__REISH_CURRENT_SHELL__] = sh
  end

  def Reish::inactivate_command_search(ifnoactive: nil, &block)
    sh = Thread.current[:__REISH_CURRENT_SHELL__]
    return ifnoactive.call if !sh && ifnoactive

    sh.inactivate_command_search &block
  end

  def Reish::conf_tempkey(prefix = "__Reish__", postfix = "__", &block)
    begin
      s = Thread.current.__id__.to_s(16).tr("-", "M")
      key = (prefix+s+postfix).intern
    
      block.call key
    ensure
      @CONF.delete(key)
    end
  end

  DefaultEncodings = Struct.new(:external, :internal)
  class << Reish
    private
    def set_encoding(extern, intern = nil)
      verbose, $VERBOSE = $VERBOSE, nil
      Encoding.default_external = extern unless extern.nil? || extern.empty?
      Encoding.default_internal = intern unless intern.nil? || intern.empty?
      @CONF[:ENCODINGS] = Reish::DefaultEncodings.new(extern, intern)
      [$stdin, $stdout, $stderr].each do |io|
	io.set_encoding(extern, intern)
      end
      @CONF[:LC_MESSAGES].instance_variable_set(:@encoding, extern)
    ensure
      $VERBOSE = verbose
    end
  end
end

class Object
  include Reish::OSSpace
end


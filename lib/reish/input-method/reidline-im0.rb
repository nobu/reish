#
#   reish/input-method/input-method.rb - input methods used irb
#                         oroginal version from irb.
#   	Copyright (C) 2014-2017 Keiju ISHITSUKA
#				(Penta Advanced Labrabries, Co.,Ltd)
#
require "forwardable"

require 'reish/src_encoding'
require 'reish/magic-file'

require "reish/reidline"


module Reish
  class ReidlineInputMethod0 < InputMethod
    extend Forwardable

    # Creates a new input method object using Readline
    def initialize(exenv)
      super

      @reidline = Reidline.new
      @reidline.multi_line_mode = true

      @line_no = 0
      @line = []
      @eof = false

      @completable = true

      @completor = nil

      #        @stdin = IO.open(STDIN.to_i, :external_encoding => Reish.conf[:LOCALE].encoding, :internal_encoding => "-")
      #        @stdout = IO.open(STDOUT.to_i, 'w', :external_encoding => Reish.conf[:LOCALE].encoding, :internal_encoding => "-")

      #	@completor = nil
      #        Readline.completion_proc = nil

#      @lex = Lex.new
#      @parser = Parser.new(@lex)
#      @queue = Queue.new
#      im = QueueInputMethod.new(@queue)
#      @lex.initialize_input
#      @lex.set_input(im) do
# 	if l = im.gets
# #	    print l  if Reish::debug_cmpl?
# 	  else
# #	    print "\n" if Reish::debug_cmpl?
# 	  end
# 	  l
#    end

      @reidline.set_closed_proc do |line|
	ret = nil
	begin
	  @lex = Lex.new
	  @parser = Parser.new(@lex)
	  @queue = Queue.new
	  im = QueueInputMethod.new(nil, @queue)
	  @lex.initialize_input
	  @lex.set_input(im) do
	    if l = im.gets
#	    print l  if Reish::debug_cmpl?
	    else
#	    print "\n" if Reish::debug_cmpl?
	    end
	    l
	  end
	  
	  @closing_checker = Thread.start{
	    r = nil
	    begin
	      @parser.do_parse
	      r = true
	    rescue
	      @reidline.message($!.message)
#	      @queue.clear
	      r = false
	    end
	    r
	  }


	  @queue.push line
	  until @queue.empty?
	    sleep 0.01
	  end
	  if !@closing_checker.alive?
	    ret = @closing_checker.value
	  end
# 	begin
# 	  @completion_checker.value
# 	rescue 
	  
# 	end
	  ret
	ensure
	  @closing_checker.kill
#	  reset_completion_checker
	end
	ret
      end
    end

    attr_accessor :completor

#     def reset_completion_checker
#       @rcc += 1
#       @completion_checker.kill
#       @completion_checker = Thread.start{
# begin
# 	@queue.clear
# 	@lex.initialize_input
# 	@parser.do_parse
# ensure
# 	@queue.clear
# p "OUT#{@rcc}"
# end
#       }
#     end

    #      attr_accessor :completor

    # Reads the next line from this input method.
    #
    # See IO#gets for more information.
    def gets
      #        Readline.input = @stdin
      #        Readline.output = @stdout

      #	Readline.completion_proc = @completor.completion_proc if @completor

      begin
	if l = @reidline.gets
	  #          HISTORY.push(l) if !l.empty?
	  @line[@line_no += 1] = l + "\n"
	else
	  @eof = true
	  l
	end
      rescue Interrupt
#	completion_cheker_reset
	raise
      end
    end

    # Whether the end of this input method has been reached, returns +true+
    # if there is no more data to read.
    #
    # See IO#eof? for more information.
    def eof?
      @eof
    end

    # Whether this input method is still readable when there is no more data to
    # read.
    #
    # See IO#eof for more information.
    def readable_after_eof?
      true
    end

    # Returns the current line number for #io.
    #
    # #line counts the number of times #gets is called.
    #
    # See IO#lineno for more information.
    def line(line_no)
      @line[line_no]
    end

    # The external encoding for standard input.
    def encoding
      @stdin.external_encoding
    end

    def tty?
      STDIN.tty?
    end 

    def real_io
      STDIN
    end

    def_delegator :@reidline, :set_cmpl_proc
  end
end

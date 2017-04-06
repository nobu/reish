#
#   completion.rb - 
#   	$Release Version: $
#   	$Revision: 1.1 $
#   	$Date: 1997/08/08 00:57:08 $
#   	Copyright (C) 1996-2010 Keiju ISHITSUKA
#				(Penta Advanced Labrabries, Co.,Ltd)
#
# --
#
#   
#
require "pp"

require "reish/completion-helper"

module Reish

  class Completor

    def initialize
      @lex = Lex.new
      @parser = Parser.new(@lex)

      @lex.debug_lex_state=Reish::conf[:YYDEBUG]
      @parser.yydebug = Reish::conf[:YYDEBUG]
      @parser.test_cmpl = true
    end

    def candidate(str)
      im = StringInputMethod.new(str)

      @lex.initialize_input
      @lex.set_input(im) do
	if l = im.gets
	  print l if Reish::conf[:VERBOSE]
	else
	  print "\n"
	end
	l
      end

      parsed = nil
      begin 
	input_unit = [@parser.yyparse(@lex, :racc_token_cmpl)]
	puts "PARSE COMPLETED"

	parsed = true

      rescue ParserComplSupp
	puts "PARSE IMCOMLETED"
	require "pp"
	puts "TEST_CMPL:"
	pp @parser.test_cmpl

	parsed = false
	input_unit = @parser.test_cmpl

	puts "INDENT CURRENT: #{@lex.indent_current.inspect}"
      end

      puts "INPUT UNIT:"
      pp input_unit
      puts "SPACE_SEEN: #{@lex.space_seen}"
      puts "LAST_TOKEN:"
      pp @lex.pretoken
      puts "LEX_STATE:"
      pp @lex.lex_state_sym

#      if @lex.lex_state?(Lex::EXPR_ARG) && @lex.pretoken === ID && !@lex.space_seen
#	# ls
#      elsif 

      puts "PATH:"
      path = find_path(input_unit, @lex.pretoken)
      pp path
      puts "PATH: END"

      if @lex.space_seen
	if @lex.lex_state?(Lex::EXPR_BEG | Lex::EXPR_DO_BEG)
	  puts "IDENT CMPL: BEG"
	  puts "CANDIDATE: ANY COMMAND"
	elsif @lex.lex_state?(Lex::EXPR_ARG | Lex::EXPR_END)
	  puts "IDENT CMPL: ARG/END"
	  
	  receiver = find_argumentable_emlepment_in_path(@lex.pretoken, path, input_unit)

	  puts "CANDINATE: ARGUMENT OF: #{receiver.inspect}"
	else
	  # EXPR_MID | EXPR_ARG | EXPR_FNAME | 
	  #   EXPR_DOT | EXPR_CLASS | EXPR_EQ_ARG

	  puts "CANDINATE: ARGUMENT OF: UNKNOWN"
	  puts "LEX STATE: #{@lex.state_sym}"
	end
      else
	case @lex.pretoken
	when SimpleToken
	  case @lex.pretoken.token_id
	  when :NL, '\\', :ASSOC, :XSTRING_END, :XSTRING_BEG,
	      :LPARLEN_ARG, "(", :LBLACK_A, :LBLACK_I, :LBRACE_H, :LBRACE_I,
	      "]", ")", "}", ":", :DOT_COMMAND, ".", ';', :AND_AND, :OR_OR,
	      :LBLACK_A, :LBRACE_H, "$"
	    puts "CANDIDATE: ANY COMMAND"
	  end
	when SpecialToken
	  case @lex.pretoken.value
	  when '|', "&", "&&", "||", "$", "-", "+", "/", "*", 
	      ">=", "<=", "==", "<=>", "=~", "!~"
	    puts "CANDIDATE: SPECIAL(#{@lex.pretoken.value})"
	  end
	when ReservedWordToken
	  case @lex.pretoken.token_id
	  when "=", :BANG, '|', :SYMBEG, :COLON2, 
	      "$if", "$unless", "$while", "$until", "$rescue",
	      *Lex::Redirection2ID.values, 
	      *Lex::PseudoVars, 
	      *Lex::PreservedWord.values
	    puts "CANDIDATE: RESERVE(#{@lex.pretoken.token_id})"
	  end
	when TestToken
	  puts "CANDIDATE: TEST(#{@lex.pretoken.value})"

	when IDToken
	  puts "CANDIDATE: ID(#{@lex.pretoken.value})"
	  
	when WordToken
	  receiver = find_argumentable_emlepment_in_path(@lex.pretoken, path, input_unit)
	  puts "CANDINATE: ARGUMENT: (#{@lex.pretoken.value}) OF: #{receiver.inspect}"

	when StringToken
	  if @lex.lex_state?(Lex::EXPR_INSTR)
	    receiver = find_argumentable_emlepment_in_path(@lex.pretoken, path, input_unit)
	    puts "CANDINATE: ARGUMENT STR(#{@lex.pretoken.inspect}) OF: #{receiver.inspect}"
	  else
	    receiver = find_argumentable_emlepment_in_path(@lex.pretoken, path, input_unit)
	    puts "CANDINATE: ANY ARGUMENT OF: #{receiver.inspect}"
	  end
	end
      end
    end

    ARGUMENTABLE_ELEMENT = [
      :IN,
      #CASE,
      :WHEN,
      :BREAK,
      :NEXT,
      :RAISE,
      :RETURN,
      :YIELD,
      :LBLACK_A,
      :LBRACE_H,
      :LPAREN_ARG,
      :ID,
      :PATH, 
      :TEST, 
      :SPECIAL,
      Node::SimpleCommand
    ]

    def find_argumentable_emlepment_in_path(token, path, input_unit)
      for p in path.reverse
	case p
	when *ARGUMENTABLE_ELEMENT
#puts "FAE PATH: #{p.inspect}"
	  return p
	end
      end

#puts "FAE: search in INPUT_UNIT: #{input_unit.inspect}"

      input_unit.reverse.each do |n|
	case n
	when *ARGUMENTABLE_ELEMENT
#puts "FAE IU: #{n.inspect}"
	  return n
	end
      end
      nil
    end

    def find_path(list, node)
      path = []
      list.reverse.each do |tree|

	case tree
	when nil
	when Token
	  if tree.equal?(node)
	    path.push tree
	  end
	when Node
	  helper = CompletionHelper.new(node)
	  tree.accept(helper)
	  unless helper.path.empty?
	    path = helper.path
	  end
	when Array
	  p = find_path(tree, node)
	  if p 
	    path = p
	  end
	else
	  raise "想定していないものです(#{tree.inspect})"
	end
      end
      path
    end


    ReservedWords = [
      "BEGIN", "END",
      "alias", "and", 
      "begin", "break", 
      "case", "class",
      "def", "defined", "do",
      "else", "elsif", "end", "ensure",
      "false", "for", 
      "if", "in", 
      "module", 
      "next", "nil", "not",
      "or", 
      "redo", "rescue", "retry", "return",
      "self", "super",
      "then", "true",
      "undef", "unless", "until",
      "when", "while",
      "yield",
    ]
      
    CompletionProc = proc{ |input|
      shell = Reish::current_shell
      
      puts "input: #{input}"

      case input
      when /^(\/[^\/]*\/)\.([^.]*)$/
	# Regexp
puts "R"
	receiver = $1
	message = Regexp.quote($2)

	candidates = Regexp.instance_methods(true).collect{|m| m.to_s}
	select_message(receiver, message, candidates)

      when /^([^\]]*\])\.([^.]*)$/
	# Array
puts "A"
	receiver = $1
	message = Regexp.quote($2)

	candidates = Array.instance_methods(true).collect{|m| m.to_s}
	select_message(receiver, message, candidates)

      when /^([^\}]*\})\.([^.]*)$/
	# Proc or Hash
puts "PH"
	receiver = $1
	message = Regexp.quote($2)

	candidates = (Proc.instance_methods(true) | Hash.instance_methods(true)).collect{|m| m.to_s}
	select_message(receiver, message, candidates)
	
      when /^(:[^:.]*)$/
 	# Symbol
puts "S"
	if Symbol.respond_to?(:all_symbols)
	  sym = $1
	  candidates = Symbol.all_symbols.collect{|s| ":" + s.id2name}
	  candidates.grep(/^#{sym}/)
	else
	  []
	end

      when /^::([A-Z][^:\.\(]*)$/
	# Absolute Constant or class methods
puts "AC/CM"
	receiver = $1
	candidates = Object.constants.collect{|v| v.to_s}
	candidates.grep(/^#{receiver}/).collect{|e| "::" + e}

#      when /^(((::)?[A-Z][^:.\(]*)+)::?([^:.]*)$/
#      when /^[A-Z][^:.\(]*(::[A-Z][^:.\(]*)+$/
      when /^([A-Z].*)::([^:.]+)*$/
	# Constant or class methods
puts "C/CM"
	receiver = $1
	if $2
	  message = Regexp.quote($2)
	else
	  message = ""
	end
	
	begin
	  candidates = eval("#{receiver}.constants | #{receiver}.methods", bind).collect{|m| m.to_s}
	rescue Exception
	  candidates = []
	end
	candidates.grep(/^#{message}/).collect{|e| receiver + "::" + e}

      when /^(:[^:.]+)\.([^.]*)$/
	# Symbol
puts "S2"
	receiver = $1
	message = Regexp.quote($2)

	candidates = Symbol.instance_methods(true).collect{|m| m.to_s}
	select_message(receiver, message, candidates)
      #when /^([0-9_]+(\.[0-9_]+)?(e[0-9]+)?)\.([^.]*)$/

      when /^(-?(0[dbo])?[0-9_]+(\.[0-9_]+)?([eE]-?[0-9]+)?)\.([^.]*)$/
	# Numeric
puts "N"
	receiver = $1
	message = Regexp.quote($5)

	begin
	  candidates = eval(receiver, bind).methods.collect{|m| m.to_s}
	rescue Exception
	  candidates = []
	end
	select_message(receiver, message, candidates)

      when /^(-?0x[0-9a-fA-F_]+)\.([^.]*)$/
	# Numeric(0xFFFF)
puts "N2"
	receiver = $1
	message = Regexp.quote($2)

	begin
	  candidates = eval(receiver, bind).methods.collect{|m| m.to_s}
	rescue Exception
	  candidates = []
	end
	select_message(receiver, message, candidates)

      when /^(\$[^.]*)$/
puts "G"
	candidates = global_variables.grep(Regexp.new(Regexp.quote($1)))

#      when /^(\$?(\.?[^.]+)+)\.([^.]*)$/
#      when /^((\.?[^.]+)+)\.([^.]*)$/
      when /^([^."].*)\.([^.]*)$/
	# variable
puts "V"
	receiver = $1
	if $2
	  message = Regexp.quote($2)
	else
	  message = ""
	end

	p receiver
	p message

	gv = eval("global_variables", bind).collect{|m| m.to_s}
	lv = eval("local_variables", bind).collect{|m| m.to_s}
	cv = eval("self.class.constants", bind).collect{|m| m.to_s}
	
	if (gv | lv | cv).include?(receiver)
	  # foo.func and foo is local var.
	  candidates = eval("#{receiver}.methods", bind).collect{|m| m.to_s}
	elsif /^[A-Z]/ =~ receiver and /\./ !~ receiver
	  # Foo::Bar.func
	  begin
	    candidates = eval("#{receiver}.methods", bind).collect{|m| m.to_s}
	  rescue Exception
	    candidates = []
	  end
	else
	  # func1.func2
	  candidates = []
	  ObjectSpace.each_object(Module){|m|
	    begin
	      name = m.name
	    rescue Exception
	      name = ""
	    end
	    next if name != "IRB::Context" and 
	      /^(IRB|SLex|RubyLex|RubyToken)/ =~ name
	    candidates.concat m.instance_methods(false).collect{|x| x.to_s}
	  }
	  candidates.sort!
	  candidates.uniq!
	end
	select_message(receiver, message, candidates)

      when /^\.([^.]*)$/
	# unknown(maybe String)
puts "U"

	receiver = ""
	message = Regexp.quote($1)

p message

	candidates = String.instance_methods(true).collect{|m| m.to_s}
	select_message(receiver, message, candidates)

      else
puts "E"
	candidates = eval("methods | private_methods | local_variables | self.class.constants", bind).collect{|m| m.to_s}
			  
	(candidates|ReservedWords).grep(/^#{Regexp.quote(input)}/)
      end
    }

    Operators = ["%", "&", "*", "**", "+",  "-",  "/",
      "<", "<<", "<=", "<=>", "==", "===", "=~", ">", ">=", ">>",
      "[]", "[]=", "^",]

    def self.select_message(receiver, message, candidates)
      candidates.grep(/^#{message}/).collect do |e|
	case e
	when /^[a-zA-Z_]/
	  receiver + "." + e
	when /^[0-9]/
	when *Operators
	  #receiver + " " + e
	end
      end
    end
  end
end

if Readline.respond_to?("basic_word_break_characters=")
  Readline.basic_word_break_characters= " \t\n\"\\'`><=;|&{("
end
Readline.completion_append_character = nil
Readline.completion_proc = Reish::Completor::CompletionProc

#
#   editor/buffer.rb - 
#   	Copyright (C) 1996-2010 Keiju ISHITSUKA
#				(Penta Advanced Labrabries, Co.,Ltd)
#

require "observer"
require 'forwardable'
module Reish

  module Editor
    class Buffer
      extend Forwardable

      include Enumerable
      include Observable

      def initialize(lines = ["\n"])
	@buffer = lines.collect{|l| l[-1] = ""}
      end

      def_delegator :@buffer, :size
      def_delegator :@buffer, :[]
      def_delegator :@buffer, :each
      def_delegator :@buffer, :last

      def contents
	@buffer.join("\n")
      end

      def eol?(row, col)
	@buffer[row].size == col
      end

      def insert(row, col, str)
	@buffer[row][col,0] = str
	changed
	notify_observers(:insert, row, col, str.size)
      end

      def delete(row, col)
	@buffer[row].slice!(col, 1)
	if @buffer[row].size == 0 && @buffer.size > 1
	  @buffer.slice!(row)
	end
	changed
	notify_observers(:delete, row, col)
      end

      def insert_cr(row, col)
	if eol?(row, col)
	  @buffer.insert(row + 1, "")
	  changed
	  notify_observers(:insert_line, row)
	else
	  sub = @buffer[row].slice!(col..-1)
	  @buffer.insert(row + 1, sub)
	  changed
	  notify_observers(:split_line, row, col)
	end
      end

      #前行と結合
      def join_line(row)
	len = @buffer[row].size
	col = @buffer[row-1].size
	@buffer[row-1].insert(-1, @buffer[row])
	@buffer.slice!(row)

	changed
	notify_observers(:delete_line, row)
	changed
	notify_observers(:insert, row-1, col, len)
      end
    end
  end
end


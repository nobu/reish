#
#   lam-buffer.rb - 
#   	Copyright (C) 1996-2010 Keiju ISHITSUKA
#				(Penta Advanced Labrabries, Co.,Ltd)
#

require "reish/reidline/message-pager"

module Reish
  class Reidline
    class LamPager<MessagePager

      def initialize(view, ary = [])
	super

	@cols = nil
	@col_width = nil
      end

      attr_reader :col_width

      def cols
	return @cols if @cols
	@col_width = @buffer.collect{|c| c.size}.max + 1
	
	@cols = win_width.div(@col_width)
	@cols
      end

      def size
	d, m = @buffer.size.divmod(cols)
#ttyput "SIZE"
#ttyput d, m, cols, @buffer.size
	d += 1 if m > 0
	d
      end

      def [](idx, len = nil)
	if len
	  ary = []
	  len.times do |i|
	    ary.push self[idx+i]
	  end
	  return LamPager.new(@view, ary)
	end

	case idx
	when Integer
	  return nil if idx >= size

	  col = ""
	  o, m = idx.divmod(win_height)
	  off = o*(win_height*cols)+m

	  height = win_height
	  if (o+1)*height > size 
	    height = size - o*win_height
	  end
	  
	  @cols.times do |i|
	    s = @buffer[off + i*height]
	    break unless s
	    col.concat s
	    col.concat " "*(@col_width-s.size)
	  end
	  col
	when Range
	  if idx.last < 0
	    idx = idx.first .. (size - idx.last)
	  end
	  ary = []
	  idx.each do |i|
	    ary.push self[i]
	  end
	  ary
	end
      end

      alias line []

      def each(&block)
	(0..(size-1)).each do |i|
	  e = self[i]
#	  break unless e
	  block.call e
	end
      end

      def last
	self[size-1]
      end

      def inspect
	"#<LamPager: @view=#{@view} @cols=#{@cols} @col_width=#{@col_width} @buffer=#{@buffer.inspect}>"
      end

    end
  end
end



	
	

      
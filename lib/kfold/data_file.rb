
module Kfold
  class DataFile
    attr_reader :filename, :delimiter, :granularity, :preamble, :preamble_lines

    def initialize(filename, delimiter = "\n", granularity = 1, preamble_lines = 0)
      @filename, @delimiter, @granularity, @preamble_lines = filename, delimiter, granularity, preamble_lines
      @preamble = ""
    end

    def num_entries
      @num_entres ||= count_entries
    end

    def num_blocks
      @num_blocks ||= (self.num_entries.to_f/self.granularity.to_f).ceil
    end

    def breakdown(parts = 10)
      blocks_per_part, rest = self.num_blocks.divmod(parts)
      msg = "#{num_entries} entries into #{parts} parts, #{blocks_per_part} blocks of #{self.granularity} entries per part"
      if rest > 0
        msg += " (plus #{rest} extra blocks in last part)"
      end
      msg
    end

    def each_entry_in_parts(parts = 10)
      blocks_per_part, rest = num_blocks.divmod(parts)
      cur_part = 1
      cur_block = 1
      cur_entry = 0
      block_entries = 0
      part_entries = 0
      File.open(self.filename, "r") do |f|
        @preamble_lines.times do |_|
          # not worrying about custom delim...
          @preamble << f.gets
        end
        f.each_line(self.delimiter) do |entry|
          cur_entry += 1
          yield cur_part, entry
          block_entries += 1
          part_entries += 1
          if block_entries == self.granularity
            # End of this block
            if cur_block == blocks_per_part and not cur_part == parts
              # End of this part
              cur_part += 1
              cur_block = 1
            else
              cur_block += 1
            end
            block_entries = 0
          end
        end
      end
    end

    protected

    def count_entries
      num_entries = 0
      last_empty = false
      File.foreach(self.filename, self.delimiter) do |entry|
        last_empty = (entry == '')
        num_entries += 1
      end
      num_entries -= 1 if last_empty
      num_entries
    end

  end
end

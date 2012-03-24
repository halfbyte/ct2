 class Sample < BinData::Record
  endian :big
  string :name, :length => 22, :trim_padding => true
  uint16 :len
  uint8 :raw_finetune
  uint8 :volume
  uint16 :repeat
  uint16 :replen

  def finetune
    raw_finetune >= 8 ? raw_finetune - 16 : raw_finetune
  end

  def finetune=(ft)
    raw_finetune.asign(ft < 0 ? ft + 16 : ft)
  end

end

class PatternNote < BinData::Record
  bit4 :sample_hi
  bit12 :period
  bit4 :sample_lo
  bit4 :command
  bit8 :command_params

  def sample
    (sample_hi << 4) + sample_lo
  end

  def sample=(s)
    sample_hi.assign (sample >> 4) & 0xF
    sample_lo.assign (sample & 0xF)
  end
end

class PatternRow < BinData::Record
  array :notes, :type => ::PatternNote, :initial_length => 4
end

class Pattern < BinData::Record
  array :rows, :type => ::PatternRow, :initial_length => 64
end

class ProtrackerModule < BinData::Record
  endian :big
  string :name, :length => 20, :trim_padding => true
  array :samples, :type => ::Sample, :initial_length => 31
  uint8 :num_patterns
  uint8 :unused
  array :pattern_table, :type => :uint8, :initial_length =>  128
  string :cookie, :length => 4
  array :patterns, :type => ::Pattern, :initial_length => lambda { self.max_pattern_index + 1 }
  array :sample_data, :initial_length => lambda { self.samples.length } do
    string :read_length => lambda { self.samples[index].len * 2 }
  end

  def max_pattern_index
    self.pattern_table.inject(0) {|m,p| p > m ? p : m}
  end

end
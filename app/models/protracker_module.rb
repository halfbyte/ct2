require 'base64'
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
  uint8 :pattern_table_length
  uint8 :unused
  array :pattern_table, :type => :uint8, :initial_length =>  128
  string :cookie, :length => 4
  array :patterns, :type => ::Pattern, :initial_length => lambda { pattern_table.inject(0) {|m,p| p > m ? p : m} + 1 }
  array :sample_data, :initial_length => lambda { samples.length } do
    string :read_length => lambda { samples[index].len * 2 }
  end

  def encoded_sample_data
    sample_data.map do |sd|
      Base64.strict_encode64(sd.snapshot)
    end
  end

  def update_from_json(json)
    name.assign(json['name']) if json['name']
    json['samples'].each_with_index do |sample, i|
      samples[i].assign(
        name: sample['name'],
        len: sample['length'].to_i / 2,
        repeat: sample['repeat'].to_i / 2,
        replen: sample['replen'].to_i / 2,
        volume: sample['volume'],
        raw_finetune: sample['finetune'] < 0 ? sample['finetune'] + 16 : sample['finetune']
      )
    end
    pattern_table.assign(json['pattern_table'])
    pattern_table_length.assign(json['pattern_table_length'])
    json['patterns'].each_with_index do |pattern, p|
      pattern.each_with_index do |row, r|
        row.each_with_index do |note, n| 
          patterns[p].rows[r].notes[n].assign(
            period: note['period'],
            sample_hi: (note['sample'] & 0xF0) >> 4,
            sample_lo: (note['sample'] & 0x0F),
            command: note['command'],
            command_params: note['command_params']
          )
        end
      end
    end

    json['sample_data'].each_with_index do |sample, i|
      raw_sample = Base64.strict_decode64(sample)
      puts "sample_encoding #{raw_sample.encoding}" 
      puts raw_sample.force_encoding('ascii-8bit')
      if raw_sample.length > 0
        puts "sample_len_#{i} #{raw_sample.length}"
        puts "sample_len according to metadata: #{samples[i].len.snapshot}" 
        sample_data[i].assign(raw_sample)
      end
    end


  end
  

end
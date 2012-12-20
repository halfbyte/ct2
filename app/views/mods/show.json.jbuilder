json.name @pt.name.snapshot
json.samples @pt.samples do |json, sample|
  json.name sample.name.snapshot
  json.length sample.len.snapshot * 2
  json.repeat sample.repeat.snapshot * 2
  json.replen sample.replen.snapshot * 2
  json.finetune sample.finetune
  json.volume sample.volume.snapshot
end
json.pattern_table @pt.pattern_table.snapshot
json.pattern_table_length @pt.pattern_table_length.snapshot
json.patterns @pt.patterns do |json, pattern|
  json.array!(pattern.rows) do |json, row|
    json.array!(row.notes) do |json, note|
      json.period note.period.snapshot
      json.sample note.sample
      json.command note.command.snapshot
      json.command_params note.command_params.snapshot

    end
  end
end

json.sample_data @pt.encoded_sample_data

class Mod
  # convert array of charcodes to sting
  # seems to magically work.  
  NOTES: ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-', 'B#']
  atos: (a) ->
    s = String.fromCharCode(a...)
  signed_nybble: (a) ->
    if a >= 8 then a-16 else a
  note_from_text: (note) ->
    return "---" if note == 0
    oct = Math.floor((note - 1) / 12)
    @NOTES[(note - 1) % 12] + oct


  constructor: (data) ->
    @samples = []
    @patterns = []
    subdata = new Uint8Array(data, 1080, 4);
    if @atos(subdata) == 'M.K.'
      @name = @atos(new Uint8Array(data, 0, 20));
      for i in [0..30]
        sample = {}
        sample.name = @atos(new Uint8Array(data, 20 + (30*i), 22))
        sample_data = new Uint8Array(data, 20 + (30*i) + 22, 8)
        sample.length = ((sample_data[0] << 8) + (sample_data[1])) * 2
        sample.finetune = @signed_nybble(sample_data[2] & 0x0F)
        sample.raw_finetune = sample_data[2] & 0x0F
        sample.volume = sample_data[3]
        sample.repeat = ((sample_data[4] << 8) + (sample_data[5])) * 2
        sample.replen = ((sample_data[6] << 8) + (sample_data[7])) * 2
        @samples.push(sample)

      pattern_data = new Uint8Array(data, 950, 2)
      @pattern_table_length = pattern_data[0]
      @pattern_table = new Uint8Array(data, 952, 128)
      @num_patterns = _.max(@pattern_table)
      
      for p in [0..@num_patterns]
        pattern = []
        pattern_data = new Uint8Array(data, 1084 + (p * 1024), 1024)
        for s in [0..63]
          step = []
          for c in [0..3]
            note = {}
            note.raw_data = [pattern_data[(s * 16) + (c * 4)], pattern_data[(s * 16) + (c * 4) + 1], pattern_data[(s * 16) + (c * 4) + 2], pattern_data[(s * 16) + (c * 4) + 3]] 
            note.period = ((pattern_data[(s * 16) + (c * 4)] & 0x0F) << 8) + (pattern_data[(s * 16) + (c * 4) + 1] & 0xF0) + (pattern_data[(s * 16) + (c * 4) + 1] & 0x0F)
            note.note = find_note(note.period)
            note.note_text = @note_from_text(note.note)
            note.sample = (pattern_data[(s * 16) + (c * 4)] & 0xF0) + ((pattern_data[(s * 16) + (c * 4) + 2] & 0xF0) >> 4)
            note.command = (pattern_data[(s * 16) + (c * 4) + 2] & 0x0F)
            note.command_params = (pattern_data[(s * 16) + (c * 4) + 3] & 0xF0) + (pattern_data[(s * 16) + (c * 4) + 3] & 0x0F)
            note.hex_command_params = note.command_params.toString(16)

            step.push(note)
          pattern.push(step)
        @patterns.push(pattern)

      offset = 1084 + ((@num_patterns + 1) * 1024)
      for sample in @samples
        sample.data = new Int8Array(data, offset, sample.length)
        offset += sample.length
    else
      raise('Invalid Module Data')

find_note = (period) ->
  note = 0
  bestd = Math.abs(period - Player::BASE_PTABLE[0])
  if (period)
    for i in [1..60]
      d = Math.abs(period - Player::BASE_PTABLE[i])
      if d < bestd
        bestd = d
        note = i
  note



clamp = (x, min, max) ->
  Math.max(min, Math.min(max, x))

lerp = (a, b, f) ->
  a + f * (b - a)

sinc = (x) ->
  if x then Math.sin(x) / x else 1

sqr = (x) ->
  x * x

hamming = (x) ->
  if (x > -1 && x < 1)
    sqr(Math.cos(x * Math.PI / 2.0))
  else
    0

class MixerVoice


  constructor: ->
    @sample_len = 0
    @loop_len = 0
    @period = 65535
    @volume = 0
    @pos =  0.0
    @sample = null


  render: (buffer, offset, samples) ->
    return if !@sample


    for i in [0...samples]

      @pos += (3740000.0/ @period) /(48000.0)

      int_pos = Math.floor(@pos)
      if int_pos >= @sample_len 
        
        @pos -= @loop_len
        int_pos -= @loop_len

      next_pos = int_pos + 1
      next_pos -= @loop_len if next_pos >= @sample_len

      next_fac = @pos - Math.floor(@pos)
      inv_fac = 1.0 - next_fac
      sample = @sample[int_pos] * inv_fac + @sample[next_pos] * next_fac
      buffer[i + offset] += (sample / 128.0 * (@volume / 64.0)) * 0.5

  trigger: (sample, len, loop_len, offset) ->
    @sample = sample
    @sample_len = len
    @loop_len = loop_len
    @pos = Math.min(offset, @sample_len - 1)



class Mixer

  PAULARATE: 3740000
  OUTRATE: 48000
  constructor: ->
    @voices = []
    for i in [0..3]
      @voices.push(new MixerVoice())
    @master_volume = 0.66
    @master_separation = 0.5

  render: (l_buf, r_buf, offset, samples) ->
    for ch in [0..3]
      if ch == 1 || ch == 2
        @voices[ch].render(l_buf, offset, samples)
      else
        @voices[ch].render(r_buf, offset, samples)

class Channel
  constructor: (@player) ->
    @note = 0
    @period = 0
    @fxbuf = new Int16Array(16)
    @fxbuf_14 = new Int16Array(16)
    @sample = 0
    @finetune = 0
    @volume = 0
    @loopstart = 0
    @loopcount = 0
    @retrig_count = 0
    @vib_wave = 0
    @vib_retr = 0
    @vib_pos = 0
    @vib_ampl = 0
    @vib_speed  = 0
    @trem_wave = 0
    @trem_retr = 0
    @trem_pos = 0
    @trem_ampl = 0
    @trem_speed = 0

  to_unsigned: (n) ->
    if n < 0 then n + 16 else n

  get_period: (offs = 0, fineoffs = 0) ->
    ft = @finetune + fineoffs
    while ft > 7
      offs++
      ft -= 16
    while ft < -8
      offs--
      ft += 16
    if @note
      @player.PTABLE[ @to_unsigned(ft) & 0x0f ][clamp(@note+offs-1,0,59)]
    else
      0
  set_period: (offs = 0, fineoffs = 0) ->
    if @note
      @period = @get_period(offs, fineoffs)



class Player

  constructor: ->
    @module = null
    @channels = []
    for i in [0..3]
      @channels.push(new Channel(this))

    @mixer = new Mixer()
    @calc_ptable()
    @calc_vibtable()
    @bpm = 125
    @reset()
    @playing = false
    @soundbridge = SoundBridge(2, 48000, '/javascripts/vendor/');
    window.setTimeout(
      =>
        @soundbridge.setCallback(@soundbridge_render)
        @soundbridge.play()
      1000
    )




  BASE_PTABLE: [
    0, 1712,1616,1525,1440,1357,1281,1209,1141,1077,1017, 961, 907,
    856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
    428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
    214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113,
    107, 101,  95,  90,  85,  80,  76,  71,  67,  64,  60,  57]
  OUTRATE: 48000
  OUTFPS: 50

  channels: []

  speed: 0
  tick_rate: 0
  tr_counter: 0
  cur_tick: 0
  cur_row: 0
  cur_pos: 0
  delay: 0


  load: (file, callback)->
    reader = new FileReader()

    reader.onerror = (evt)->
      #TODO: the callback expects an err not an evt
      callback(evt)

    reader.onloadend = (evt)=>
      if (evt.target.readyState == FileReader.DONE)
        result = evt.target.result;
        

        @module = new Mod(result);
        
        @reset()

        callback()

    reader.readAsArrayBuffer(file);
    "LOADING #{file}"

  play: ->
    @playing = true
    console.log 'PLAYING'

  stop: ->
    @playing = false
    for ch in [0..3]
      @mixer.voices[ch].volume = 0
      @channels[ch].volume = 0
    console.log 'STOPPING'

  soundbridge_render: (bridge, length, channels) =>
    
    l_buf = new Float32Array(length);
    r_buf = new Float32Array(length);
    @render(l_buf, r_buf, length);
    for i in [0...length]
      bridge.addToBuffer(l_buf[i], r_buf[i]);

  calc_ptable: ->
    @PTABLE = []
    for ft in [0..16]
      rft = -(if ft >= 8 then ft - 16 else ft)
      
      fac = Math.pow(2.0, rft / (12.0 * 16.0))
      
      periods = []
      for i in [0..59]
        periods.push(Math.round(@BASE_PTABLE[i] * fac))
      @PTABLE.push(periods)
    
    @PTABLE

  calc_vibtable: ->
    @VIB_TABLE = []
    for i in [0..2]
      @VIB_TABLE.push([])

    for ampl in [0..14]
      scale = ampl + 1.5
      shift = 0
      @VIB_TABLE[0][ampl] = []
      @VIB_TABLE[1][ampl] = []
      @VIB_TABLE[2][ampl] = []
      for x in [0..63]
        @VIB_TABLE[0][ampl].push(Math.floor(scale * Math.sin(x * Math.PI / 32.0) + shift))
        @VIB_TABLE[1][ampl].push(Math.floor(scale * ((63-x)/31.5-1.0) + shift))
        @VIB_TABLE[2][ampl].push(Math.floor(scale * (if (x<32) then 1 else -1) + shift))

  calc_tick_rate: (bpm) ->
    @bpm = bpm
    @tick_rate = (125 * @OUTRATE) / (bpm * @OUTFPS)
  
  trig_single_note: (ch, sample, note) ->
    channel = @channels[ch]
    voice = @mixer.voices[ch]
    sample = @module.samples[sample]
    offset = 0
    channel.note = note
    channel.set_period()
    voice.period = channel.period
    channel.volume = 64
    voice.volume = 64
    if sample.replen > 2
      voice.trigger(sample.data, sample.repeat + sample.replen, sample.replen, offset)
    else
      voice.trigger(sample.data, sample.length, 1, offset)
    channel.vib_pos = 0    
    channel.trem_pos = 0

  trig_note: (ch, note) ->

    channel = @channels[ch]
    voice = @mixer.voices[ch]
    
    sample = @module.samples[channel.sample - 1]
    offset = 0
    offset = channel.fxbuf[9] << 8 if note.command == 9
    if note.command != 3 && note.command != 5
      channel.set_period()
      if sample.replen > 2
        voice.trigger(sample.data, sample.repeat + sample.replen, sample.replen, offset)
      else
        voice.trigger(sample.data, sample.length, 1, offset)
        

      channel.vib_pos = 0 if !channel.vib_retr
      channel.trem_pos = 0 if !channel.trem_retr

  reset: ->
    @calc_tick_rate(125)
    @speed = 6
    @tr_counter = 0
    @cur_tick = 0
    @cur_row = 0
    @cur_pos = 0
    @delay = 0

  tick: ->
    line = @module.patterns[@module.pattern_table[@cur_pos]][@cur_row]
    ch = 0
    for note in line
      voice = @mixer.voices[ch]
      channel = @channels[ch]
      fxpl = note.command_params & 0x0F
      trem_vol = 0
      if (!@cur_tick)
        
        if note.sample
          channel.sample = note.sample
          channel.finetune = @module.samples[note.sample - 1].finetune
          channel.volume = @module.samples[note.sample - 1].volume
        if note.command_params
          channel.fxbuf[note.command] = note.command_params
          
        if note.note && (note.command != 14 || ((note.command_params >> 4) != 13))

          channel.note = note.note
          @trig_note(ch, note)
          
          

        switch(note.command)
          when 4, 6
            channel.vib_ampl = channel.fxbuf[4] & 0x0f if channel.fxbuf[4] & 0x0f
            channel.vib_speed = channel.fxbuf[4] >> 4 if channel.fxbuf[4] & 0xf0
            channel.set_period(0, @VIB_TABLE[channel.vib_wave][channel.vib_ampl - 1][channel.vib_pos]) if channel.vib_ampl
          when 7
            channel.trem_ampl = channel.fxbuf[7] & 0x0f if channel.fxbuf[7] & 0x0f
            channel.trem_speed = channel.fxbuf[7] >> 4 if channel.fxbuf[7] & 0xf0
            trem_vol = @VIB_TABLE[channel.trem_wave][channel.trem_ampl - 1][channel.trem_pos] if channel.trem_ampl
          when 12
            channel.volume = clamp(note.command_params, 0, 64)
          when 14
            channel.fxbuf_14[note.command_params >> 4] = fxpl if fxpl
            switch (note.command_params >> 4)
              when 1
                channel.period = Math.max(113, channel.period - channel.fxbuf_14[1])
              when 2
                channel.period = Math.min(856, channel.period + channel.fxbuf_14[1])
              when 4
                channel.vib_wave = fxpl & 3
                channel.vib_wave = 0 if channel.vib_wave == 3
                channel.vib_retr = fxpl & 4
              when 5
                channel.finetune = fxpl
                channel.finetune -= 16 if channel.finetune >= 8
              when 7
                channel.trem_wave = fxpl & 3
                channel.trem_wave = 0 if channel.trem_wave == 3
                channel.trem_retr = fxpl & 4
              when 9
                if channel.fxbuf_14[9] && !note.note
                  @trig_note(ch, note)
                  channel.retrig_count = 0
              when 10
                channel.volume = Math.min(channel.volume + channel.fxbuf_14[10], 64)
              when 11
                channel.volume = Math.max(channel.volume - channel.fxbuf_14[11], 0)
              when 14
                @delay = channel.fxbuf_14[14]
          when 15
            if note.command_params
              if note.command_params <= 32
                @speed = note.command_params
              else
                @calc_tick_rate(note.command_params)

      else
        switch(note.command)
          when 0
            if note.command_params
              arp_no = 0
              switch(@cur_tick % 3)
                when 1
                  arp_no = note.command_params >> 4
                when 2
                  arp_no = note.command_params & 0x0F
              channel.set_period(arp_no)
          when 1
            channel.period = Math.max(113, channel.period - channel.fxbuf[1])
          when 2
            channel.period = Math.min(856, channel.period + channel.fxbuf[2])
          when 5
            if channel.fxbuf[5] & 0xF0
              channel.volume = Math.min(channel.volume + (channel.fxbuf[5] >> 4), 64)
            else
              channel.volume = Math.max(channel.volume - (channel.fxbuf[5] & 0x0f), 0)
            np = channel.get_period()
            if channel.period > np
              channel.period = Math.max(channel.period - channel.fxbuf[3], np)
            else if channel.period < np
              channel.period = Math.min(channel.period + channel.fxbuf[3], np)
          when 3
            np = channel.get_period()
            if channel.period > np
              channel.period = Math.max(channel.period - channel.fxbuf[3], np)
            else if channel.period < np
              channel.period = Math.min(channel.period + channel.fxbuf[3], np)

          when 6
            if channel.fxbuf[6] & 0xF0
              channel.volume = Math.min(channel.volume + (channel.fxbuf[6] >> 4), 64)
            else
              channel.volume = Math.max(channel.volume - (channel.fxbuf[6] & 0x0F), 0)
            channel.set_period(0, @VIB_TABLE[channel.vib_wave][channel.vib_ampl - 1][channel.vib_pos]) if channel.vib_ampl
            channel.vib_pos = (channel.vib_pos + channel.vib_speed) & 0x3f


          when 4
            channel.set_period(0, @VIB_TABLE[channel.vib_wave][channel.vib_ampl - 1][channel.vib_pos]) if channel.vib_ampl
            channel.vib_pos = (channel.vib_pos + channel.vib_speed) & 0x3f
          when 7
            @trem_vol = @VIB_TABLE[channel.trem_wave][channel.trem_ampl][channel.trem_pos]
            channel.trem_pos = (channel.trem_pos + c.trem_speed) & 0x3f
          when 10
            
            if channel.fxbuf[10] & 0xF0            
              channel.volume = Math.min(channel.volume + (channel.fxbuf[10] >> 4), 64)
            else
              channel.volume = Math.max(channel.volume - (channel.fxbuf[10] & 0x0f), 0)
          when 11
            if @cur_tick == @speed - 1
              @cur_row -= 1
              @cur_pos = note.command_params
          when 13
            if @cur_tick = @speed - 1
              @cur_pos++
              @cur_row = (10 * (note.command_params >> 4) + (note.command_params & 0x0f)) - 1
          when 14
            switch (note.command_params >> 4)
              when 6
                if !fxpl
                  channel.loopstart = @cur_row
                else if (@cur_tick == @speed - 1)
                  if (channel.loopcount < fxpl)
                    @cur_row = channel.loopstart - 1
                    channel.loopcount++
                  else
                    channel.loopcount = 0
              when 9
                channel.retrig_count++
                if (channel.retrig_count == channel.fxbuf_14[9])
                  channel.retrig_count = 0
                  @trig_note(ch, note)
              when 12
                if @cur_tick == channel.fxbuf_14[12]
                  channel.volume = 0
              when 13
                channel.note = note.note
                @trig_note(ch, note) if @cur_tick == channel.fxbuf_14[13]

      voice.volume = clamp(channel.volume + trem_vol, 0, 64)

      voice.period = channel.period

      ch++

    @cur_tick++
    if @cur_tick >= @speed * (@delay + 1)
      @cur_tick = 0
      @cur_row++
      @delay = 0

    if @cur_row >= 64
      @cur_row = 0
      @cur_pos++

    @cur_pos = 0 if @cur_pos >= @module.pattern_table_length
    



  render: (l_buf, r_buf, len) ->
    
    offset = 0
    
    while (len > 0)
      todo = Math.min(len, @tr_counter)
      if todo
        @mixer.render(l_buf, r_buf, offset, todo)
        offset += todo
        len -= todo
        @tr_counter -= todo
      else
        @tick() if @playing
        @tr_counter = Math.floor(@tick_rate)
    



# give the app a single instance only
window.Player = new Player()

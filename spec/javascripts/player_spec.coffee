#= require application

describe 'Player', ->
  beforeEach ->
    window.SoundBridge = -> 'mockSoundBridge'
    window.Player = new window.CT2.player.Player();

  it 'works', ->
    window.Player.play()
    expect(window.Player.playing).to.equal(true)

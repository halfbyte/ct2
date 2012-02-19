(function() {

  describe('Player', function() {
    beforeEach(function() {
      return window.SoundBridge = function() {
        return 'mockSoundBridge';
      };
    });
    it('loads a file', function() {
      return expect(Player.load('file.mod')).toEqual('LOADING file.mod');
    });
    return it('works', function() {
      return expect(Player.play()).toEqual('PLAYING');
    });
  });

}).call(this);

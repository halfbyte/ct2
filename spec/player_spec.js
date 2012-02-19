(function() {

  describe('Player', function() {
    it('loads a file', function() {
      return expect(Player.load('file.mod')).toEqual('LOADING file.mod');
    });
    return it('works', function() {
      return expect(Player.play()).toEqual('PLAYING');
    });
  });

}).call(this);

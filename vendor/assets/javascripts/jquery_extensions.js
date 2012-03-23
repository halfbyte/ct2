(function($) {
  $.fn.extend({
    // snatched from document cloud source
    // See Backbone.View#setMode...
    setMode : function(state, group) {
      group = group || 'mode';
      var re = new RegExp("\\w+_" + group + "(\\s|$)", 'g');
      var mode = (state === null) ? "" : state + "_" + group;
      this.each(function(){
        this.className = (this.className.replace(re, '') + ' ' + mode).replace(/\s\s/g, ' ');
      });
      return mode;
    }
  });
})(jQuery);
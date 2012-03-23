(function() {
  window.stringToArrayBuffer = function(input, callback) {
    var bb = new (window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder)();
    bb.append(input);
    var f = new FileReader();
    f.onloadend = function(e) { console.log(e.target.result); if(e.target.readyState === FileReader.DONE) callback(e.target.result); };
    f.onerror = function(e) { callback(e)};
    f.readAsArrayBuffer(bb.getBlob());  
  };
  window.ArrayBufferToString = function(input, callback) {
    var bb = new (window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder)();
    bb.append(input);
    var f = new FileReader();
    f.onloadend = function(e) { if(e.target.readyState === FileReader.DONE) callback(e.target.result); };
    f.onerror = function(e) { callback(e)};
    f.readAsBinaryString(bb.getBlob());
  }
})();

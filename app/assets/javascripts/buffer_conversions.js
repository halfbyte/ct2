(function() {
  // window.stringToArrayBuffer = function(input, callback) {
  //   var bb = new (window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder)();
  //   bb.append(input);
  //   var f = new FileReader();
  //   f.onloadend = function(e) { console.log(e.target.result); if(e.target.readyState === FileReader.DONE) callback(e.target.result); };
  //   f.onerror = function(e) { callback(e)};
  //   f.readAsArrayBuffer(bb.getBlob());  
  // };

  window.base64ToInt8 = function(input, success, error) {
    var bb = new (window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder)();
    bb.append(atob(input));
    var f = new FileReader();
    f.onloadend = function(e) { 
      if(e.target.readyState === FileReader.DONE && typeof(success) == 'function') {
        var array = new Int8Array(e.target.result, 0, e.target.result.byteLength);
        success(array);
      }
    };
    f.onerror = function(e) { if(typeof(error) == 'function') error(e)};
    f.readAsArrayBuffer(bb.getBlob());
  }

  // window.ArrayBufferToString = function(input, callback) {
  //   var bb = new (window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder)();
  //   bb.append(input);
  //   var f = new FileReader();
  //   f.onloadend = function(e) { if(e.target.readyState === FileReader.DONE) callback(e.target.result); };
  //   f.onerror = function(e) { callback(e)};
  //   f.readAsBinaryString(bb.getBlob());
  // }
})();

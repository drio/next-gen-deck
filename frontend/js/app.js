/* Load the app when the DOM is ready. Thanks Jquery. */
$(function(){
  $.getJSON('http://localhost:7379/get/stats', function(data){
    var o = $.parseJSON(data.get);
    console.log(o["rhesus-23_samples_endometriosis-1"]["per_dups"]);
  });
});

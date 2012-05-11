/* Load the app when the DOM is ready. Thanks Jquery. */
$(function(){

  $.getJSON('http://localhost:7379/hvals/per_dups', function(data){
    console.log(data);
  });

});

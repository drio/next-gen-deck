/* Load the app when the DOM is ready. Thanks Jquery. */
$(function(){
  $.getJSON('http://localhost:7379/get/stats', function(data){
    var bams       = $.parseJSON(data.get),
        a_per_dups = [];

    _.each(_.values(bams), function(e, i){
      a_per_dups.push([i, e["per_dups"]]);
    });

    //console.log(bams["rhesus-23_samples_endometriosis-1"]["per_dups"]);
    console.log(a_per_dups);

    var dataset = [];
    var numDataPoints = 100;
    var yRange = Math.random() * 1000;
    for (var i = 0; i < numDataPoints; i++) {
      var newNumber1 = i;
      var newNumber2 = Math.round(Math.random() * yRange);
      dataset.push([newNumber1, newNumber2]);
    }

    plots.barplot("#main-plot", a_per_dups);
    //plots.barplot("#main-plot", dataset);
  });
});

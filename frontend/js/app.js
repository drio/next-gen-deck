/* Load the app when the DOM is ready. Thanks Jquery. */
$(function(){
    // Generate data for testing
    var gen_testing_data = function() {
      var tdata = { _1d: [], _2d: []};
      var numDataPoints = 255;
      var yRange = Math.random() * 255;
      for (var i = 0; i < numDataPoints; i++) {
        var newNumber1 = i;
        var newNumber2 = Math.round(Math.random() * yRange);
        tdata._2d.push([newNumber1, newNumber2]);
        tdata._1d.push(newNumber2);
      }
      return tdata;
    }

    // Do all the plotting when the data is ready. d has data.
    var make_main_plot = function(d) {
  }

  // Make a call to get our data so we can plot
  $.getJSON('http://localhost:7379/get/stats', function(data){
    // bams is an object. Each key is formed with the full path
    // to the bam. The value is another object with metrics for
    // that bam.
    var bams = $.parseJSON(data.get),
        data = {};

    // We will need this when the user clicks in a particular bam
    data.stats = bams;

    // Need the per_dups for all the bams in an 2d array.
    // x is just the index and y is the actual per_dups for that bam
    data.a_per_dups = [];
    _.each(_.values(bams), function(e, i){
      data.a_per_dups.push([i, e["per_dups"]]);
    });

    // Main plot here
    plots.dotplot("#main-plot", data.a_per_dups, 800, 200);

    // Second part; table of stats
    //plots.table("#table", [[1,2], [3,4]]);

    // Now the Insert size plot
    //plots.dotplot("#isize-plot", d.a_per_dups, 550, 200);

    // Finally read1/read2 barplots
    //var gd = gen_testing_data;
    //plots.barplot("#mapq-plot-r1", gd()._1d, 550, 200);
    //plots.barplot("#mapq-plot-r2", gd()._1d, 550, 200);

  });
});

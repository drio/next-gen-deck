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

  // When the user clicks a bam, plot the details
  var plot_details = function(d, id) {
    // These are the prefixes for the redis keys.
    // TODO: this is very hardcoded.. refactor ..
    var seeds   = ["is-", "mq-r1-", "mq-r2-"],
        rd_keys = []; // Will hold the actual redis keys

    d.sp_data = { amount_collected: 0 }; // Store the data for the ajax requests
    _.each(seeds, function(e) {
      var rd_key = e + d.a_ids[id]; // build the actual redis key
      // As the callbacks are served, save the data. Use amount_collected to
      // determine if we are done
      $.getJSON('http://localhost:7379/get/' + rd_key, function(json_d) {
        var o  = $.parseJSON(json_d.get);
        ++d.sp_data.amount_collected;
        // The json object returned has two attributes, one is the type and
        // the other is the actual data
        d.sp_data[o.type] = o.data;
        if (d.sp_data.amount_collected === 3) {
          console.log("Ready to do things ...");
        }
      });
    });

    //console.log("Click ..." + d.a_ids[id]);

    // Users wants details for an specific bam
    // Second part; table of stats
    //plots.table("#table", [[1,2], [3,4]]);

    // Now the Insert size plot
    //plots.dotplot("#isize-plot", d.a_per_dups, 550, 200);

    // Finally read1/read2 barplots
    //var gd = gen_testing_data;
    //plots.barplot("#mapq-plot-r1", gd()._1d, 550, 200);
    //plots.barplot("#mapq-plot-r2", gd()._1d, 550, 200);
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

    // Let's extract some data from the bams datastruct and put it
    // in a more convenient way.
    data.a_per_dups = [];
    data.a_ids      = [];
    var _i = 0; // index
    _.each(bams, function(val, key){
      data.a_per_dups.push([_i++, val["per_dups"]]);
      data.a_ids.push(key);
    });

    // Main plot here
    // The funcion is the callback for when the user clicks a bam in the
    // main plot
    plots.dotplot("#main-plot", data.a_per_dups, 800, 200, function(d, i) {
      plot_details(data, i);
    });
  });
});

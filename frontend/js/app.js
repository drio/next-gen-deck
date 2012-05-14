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

  // Plot the table and the other plots now that we know what bam the
  // user is interested on and we have the data
  var plot_details = function(d, id) {
    var p_data = []; // data plot
    console.log("Ready to plot things ...");

    // Plot table
    _.each(d.stats[id], function(val, key){ p_data.push([key, val]); });
    $("#table").html(""); plots.table("#table", p_data);

    // Plot the isize dotpot
    p_data = [];
    _.each(d.sp_data.isize, function(val, key) { p_data.push([key, val]); });
    $("#isize-plot").html(""); plots.dotplot("#isize-plot", p_data, 550, 200);

    // Finally read1/read2 barplots
    // TODO: DRY
    p_data = [];
    _.each(d.sp_data["mq-r1"], function(val, key) { p_data.push(val); });
    $("#mapq-plot-r1").html(""); plots.barplot("#mapq-plot-r1", p_data, 850, 200);

    p_data = [];
    _.each(d.sp_data["mq-r2"], function(val, key) { p_data.push(val); });
    $("#mapq-plot-r2").html(""); plots.barplot("#mapq-plot-r2", p_data, 850, 200);

    // Reveale the layer that contains the subplots
    d3.selectAll("#second-area").style("display", "block");
}

  // When the user clicks a bam, pull the data details so we can plot
  var pull_details = function(d, i) { // data, index
    // These are the prefixes for the redis keys.
    // TODO: this is very hardcoded.. refactor ..
    var seeds   = ["is-", "mq-r1-", "mq-r2-"],
        rd_keys = [], // Will hold the actual redis keys
        id      = d.a_ids[i]; // id name of the bam we are interested on

    // We have in d.stats all the basic stats for that sample, but we have
    // to pull the rest of the data for the other plots. sp_data stands for
    // subplot data.
    d.sp_data = { amount_collected: 0 }; // Store the data for the ajax requests
    _.each(seeds, function(e) {
      var rd_key = e + id; // build the actual redis key
      // As the callbacks are served, save the data. Use amount_collected to
      // determine if we are done
      $.getJSON('http://localhost:7379/get/' + rd_key, function(json_d) {
        var o  = $.parseJSON(json_d.get);
        ++d.sp_data.amount_collected;
        // The json object returned has two attributes, one is the type and
        // the other is the actual data
        d.sp_data[o.type] = o.data;
        if (d.sp_data.amount_collected === 3) // All ajax calls done
          plot_details(d, id);
      });
    });
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
      pull_details(data, i);
    });
  });
});

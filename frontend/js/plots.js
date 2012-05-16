var plots = (function() {
  var plots = {};

  /*
   * Creates a table in the given selection.
   * Data has to be an Array of Arrays.
   */
  plots.table = function(sel, data) {
    var humanize    = d3.format(",d"),
        all_numbers = /^\d+$/;

    d3.select(sel)
        .append("table")

        .selectAll("tr")
        .data(data)
        .enter()
        .append("tr")

        .selectAll("td")
        .data(function(d){ return d;})
        .enter()
        .append("td")
        .text(function(d) {
          if (all_numbers.test(d))
            return humanize(d);
          else
            return d;
        })
  }

  /*
   * Plots a barplot in sel, using data, and with
   * width w and height h.
   */
  plots.barplot = function(sel, data, w, h) {
    var bar_padding = 1;

    var svg = d3.select(sel)
                  .append("svg")
                  .attr("width", w)
                  .attr("height", h);

    var y = d3.scale.linear()
              .domain([0, d3.max(data)])
              .range([bar_padding, h]);

    svg.selectAll("rect")
       .data(data)
       .enter()
       .append("rect")
         .attr("x", function(d, i) { return i * (w / data.length); })
         .attr("y", function(d)    { return h - y(d); })
         .attr("width", w / data.length - bar_padding)
         .attr("height", function(d) { return y(d); });
         //.attr("fill", function(d) { return "rgb(0, 0, " + (d * 10) + ")"; });

    /*
    svg.selectAll("text")
       .data(data)
       .enter()
       .append("text")
       .text(function(d) { return d; })
       .attr("x", function(d, i) { return i * (w / data.length) + 5; })
       .attr("y", function(d) { return h - (d * 4) + 15; })
       .attr("font-family", "sans-serif")
       .attr("font-size", "11px")
       .attr("fill", "white");
    */
  }

  /*
   * Plots a dotplot in sel, using data, and with
   * width w and height h.
   * cb_md can be a callback for the mousedown event
   */
  plots.dotplot = function(sel, data, w, h, extras) {
    var padding = extras.padding,
        radio   = extras.radio;

    var x = d3.scale.linear()
              .domain([0, d3.max(data, function(d) { return d[0];})])
              .range([padding, w - padding * 2]);

    var y = d3.scale.linear()
              .domain([0, d3.max(data, function(d) { return d[1];})])
              .range([h - padding, padding]);

    var x_axis = d3.svg.axis()
                   .scale(x)
                   .orient("bottom");

    var y_axis = d3.svg.axis()
                   .scale(y)
                   .orient("left");

    var svg = d3.select(sel)
                .append("svg")
                .attr("width", w)
                .attr("height", h);

    var circles = svg.selectAll("circle")
      .data(data)
      .enter()
      .append("circle")
      .attr("cx", function(d) { return x(d[0]); })
      .attr("cy", function(d) { return y(d[1]); })
      .attr("r", radio);

    // We don't want these features unless the user gave us
    // a toggle method
    if (extras.hasOwnProperty('cb_toggle') &&
        typeof extras.cb_toggle !== undefined) {
      circles
      .on("mouseover", function(d, i) { extras.cb_toggle(d3.select(this), i); })
      .on("mouseout", function(d, i) { extras.cb_toggle(d3.select(this), i); })
      .on("mousedown", extras.cb_md);
    }

    svg.append("g")
        .attr("class", "axis")
        .attr("transform", "translate(0," + (h - padding) + ")")
        .call(x_axis);

    svg.append("g")
        .attr("class", "axis")
        .attr("transform", "translate(" + padding + ",0)")
        .call(y_axis);
  };

  return plots;
})();

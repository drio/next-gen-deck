var plots = (function() {
  var plots = {};

  plots.barplot = function(sel, data, w, h) {
    var padding = 20,
        radio   = 4;

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

    svg.selectAll("circle")
       .data(data)
       .enter()
       .append("circle")
       .attr("cx", function(d) { return x(d[0]); })
       .attr("cy", function(d) { return y(d[1]); })
       .attr("r", radio);

    /*
    svg.selectAll("text")
        .data(data)
        .enter()
        .append("text")
        .text(function(d)       { return d[0] + "," + d[1]; })
        .attr("x", function(d)  { return x(d[0]); })
        .attr("y", function(d)  { return y(d[1]); })
        .attr("font-family", "sans-serif")
        .attr("font-size", "11px")
        .attr("fill", "red");
    */

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


d3.dsv(",", "board_games.csv", function(d) {
    return {
      source: d.source,
      target: d.target,
      value: +d.value
    }
  }).then(function(data) {
  
    var links = data;
  
    var nodes = {};
  
    // compute the distinct nodes from the links.
    links.forEach(function(link) {
        link.source = nodes[link.source] || (nodes[link.source] = {name: link.source});
        link.target = nodes[link.target] || (nodes[link.target] = {name: link.target});
    });
  
    var width = 1200,
        height = 700;
  
    var force = d3.forceSimulation()
        .nodes(d3.values(nodes))
        .force("link", d3.forceLink(links).distance(100))
        .force('center', d3.forceCenter(width / 2, height / 2))
        .force("x", d3.forceX())
        .force("y", d3.forceY())
        .force("charge", d3.forceManyBody().strength(-250))
        .alphaTarget(1)
        .on("tick", tick);
  
    var svg = d3.select("body").append("svg")
        .attr("width", width)
        .attr("height", height);
  
    // add the links
    var path = svg.append("g")
        .selectAll("path")
        .data(links)
        .enter()
        .append("path")
        .attr("class", function(d) { return "link " + d.type; })
        .style("stroke",function(d){
            if (d.value == 0) {return "gray";}
            else if (d.value == 1) {return "green";}
        })
        .style("stroke-dasharray",function(d){
            if (d.value == 0) {return null;}
            else {return ("4,3");} 
        })
        .style("stroke-width",function(d){
            if(d.value == 0) {return "4";}
            else if (d.value == 1) {return "1";}
        });
  
    // define the nodes
    var node = svg.selectAll(".node")
        .data(force.nodes())
        .enter().append("g")
        .attr("class", "node")
        .on("dblclick",unpin)
        .call(d3.drag()
            .on("start", dragstarted)
            .on("drag", dragged)
            .on("end", dragended));
    


    // set scale for node radius
    var minRadius = 2;
    var y = d3.scaleLinear()
       .range([minRadius,30]);
    console.log(y)

    var ColorGradients = ["#f7fcfd","#e5f5f9","#ccece6","#99d8c9","#66c2a4","#41ae76","#238b45","#006d2c","#00441b", "#004529"];

    // add the nodes and set text labels
    node.append("circle")
        .attr("id", function(d){
           return (d.name.replace(/\s+/g,'').toLowerCase());
        })
        .attr("r", function(d) {
            d.weight = links.filter(function(l) {
              return l.source.index == d.index || l.target.index == d.index
            }).length;
            console.log("d weight", d.weight)
            return minRadius + (d.weight * 3);
          })
        .style("fill",function(d){
         return ColorGradients[parseInt(d.weight)-1]
        })
        .style("stroke-width","3")
    
    node.append('text') //append text elements within all g elements
        .attr("text-anchor","start") //set attribute text anchor alignment at start
        .attr("dx", "1em") //relative x axis of text 0.7 to the right
        .attr("dy","-1em") //relative y axis 0.7 up
        .text(function(d){return d.name}) //return individual data name
        .style("font-weight","bold"); //set to bold
  
    // add the curvy lines
    function tick() {
        path.attr("d", function(d) {
            var dx = d.target.x - d.source.x,
                dy = d.target.y - d.source.y,
                dr = Math.sqrt(dx * dx + dy * dy);
            return "M" +
                d.source.x + "," +
                d.source.y + "A" +
                dr + "," + dr + " 0 0,1 " +
                d.target.x + "," +
                d.target.y;
        });
  
        node.attr("transform", function(d) {
            return "translate(" + d.x + "," + d.y + ")"; 
        });
    };
  
    function dragstarted(d) {
        if (!d3.event.active) force.alphaTarget(0.3).restart();
        d.fx = d.x;
        d.fy = d.y;
    };
  
    function dragged(d) {
        d.fx = d3.event.x;
        d.fy = d3.event.y;
    };
  
    function dragended(d) {
        if (!d3.event.active) force.alphaTarget(0);
        //if (d.fixed == true) {
        //    d.fx = d.x;
        //    d.fy = d.y;
        //}
        //else {
        //    d.fx = null;
        //    d.fy = null;
        //}
        d.fixed = true;
        d.fx = d.x;
        d.fy = d.y;
        d3.select(this).select("circle")
          .style("stroke-width", "9")
          .style("stroke","#c06c84")
          .style("fill","#355c7d");
    };

    function unpin(d) {
            d.fixed = false;
            d.fx = null;
            d.fy = null;
            d3.select(this).select("circle")
            .style("stroke-width", "3")
            .style("stroke","black")
            .style("fill",function(d){
                return ColorGradients[parseInt(d.weight)-1]
            })
    };
    
    // Add GaTech UserName
    svg.append('text')
    .attr("id","credit")
    .attr("transform", "translate(" + (width-120) + " ," + (15) + ")")
    .attr("text-anchor", "end")
    .text("jciaravino3");

  }).catch(function(error) {
    console.log(error);
  });
  
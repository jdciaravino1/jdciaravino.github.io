// Define Margins according to margin convention supplied

var margin = {top: 100, right: 150 , bottom: 100, left: 150};

// define width and height as the inner dimensions of the chart area.

var width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;



// define X and Y scales

// define x
//var xScale = d3.scaleTime()
//    .range([0,width]); //output

// define y
//var yScale = d3.scaleLinear()
//    .range([height,0]); //output

// create svg
var svga = d3.select("body").append("svg")
.attr("width", width + margin.left + margin.right)
.attr("height", height + margin.top + margin.bottom)
.attr("id", "svg-a")
.append("g")
.attr("transform", "translate(" + margin.left + "," + margin.top + ")")
.attr("id", "plot-a");

//create formula to format time for ticks later
const formatTime = d3.timeFormat("%b %y")
console.log(typeof formatTime(new Date("11/1/2016"))) // check that this works on first row date

//create  formula to convert sstring to date
const converttodate = d3.timeParse("%Y-%m-%d")
console.log(typeof converttodate("2016-11-01")) // check that this works on first row date
console.log(converttodate("2016-11-01")) // check that this works on first row date

//path to csv
var pathToCsv = "boardgame_ratings.csv";

//read data in
d3.dsv(",", pathToCsv, function (d) {
    return {
     date: converttodate(d.date), // no conversion for now
     catan_count: +d["Catan=count"],
     dominion_count: +d["Dominion=count"],
     codenames_count: +d["Codenames=count"],
     terraforming_mars_count: +d["Terraforming Mars=count"],
     gloomhaven_count: +d["Gloomhaven=count"],
     magic_count: +d["Magic: The Gathering=count"],
     dixit_count: +d["Dixit=count"],
     monopoly_count: +d["Monopoly=count"]
      // format data attributes if required
    };
    }).then(function (data) {
        dataset = data // hand csv data to global var so its accessible later
        console.log(dataset)

    // define X and Y scales

    // define x
    var xScale = d3.scaleTime()
    .domain([d3.min(dataset,function(d) { return d.date; }), d3.max(dataset, function(d) {return d.date}) ]) //input
    .range([0,width]); //output


    // define y
    var yScale = d3.scaleLinear()
    .domain([0,d3.max(dataset, function(d) {return d.catan_count})]) //input
    .range([height,0]); //output
    
    //create title
    d3.select("#svg-a")
        .append("text")
        .attr("id","title-a")
        .attr("transform", "translate(" + ((width + margin.left + margin.right)/2) + "," + (margin.top-30) + ")")
        .attr("text-anchor", "middle")
        .attr('fill',"black")
        .style('font-size',"20px")
        .attr('font-weight',"bold")
        .text("Number of Ratings 2016-2020")

    //create x axis
    svga.append("g")
        .attr("class", "axis")
        .attr("id","x-axis-a")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(xScale).ticks(10,"%b %y"));

    // x axis label    
    svga.select("#x-axis-a")
        .append('text')
        .attr("id","x-axis label")
        .attr("transform", "translate(" + (width/2) + "," + 40 + ")")
        .attr("text-anchor", "middle")
        .attr('fill',"black")
        .style('font-size',"14px")
        .attr('font-weight',"bold")
        .text("Month");
    
   

    //create y axis
    svga.append("g")
        .attr("class", "axis")
        .attr("id","y-axis-a")
        //.attr("transform", "translate(0," + height + ")")
        .call(d3.axisLeft().scale(yScale));
    
     // y axis label
     svga.select("#y-axis-a")
     .append('text')
     .attr("id","x-axis label")
     .attr("x",-140)
     .attr("y",-60)
     .attr("transform", "rotate(-90)")
     .attr("text-anchor", "middle")
     .attr('fill',"black")
     .style('font-size',"14px")
     .attr('font-weight',"bold")
     .text("Num of Ratings");


    ///initial attempt to do this one by one
    var line1 = d3.line()
        .x(function(d) { 
            return xScale(d.date)
        }) 
        .y(function(d) {
            //console.log(d.catan_count)
            return yScale(d.catan_count)
        }) 
        .curve(d3.curveMonotoneX) 

    var line2 = d3.line()
        .x(function(d) { 
            return xScale(d.date)
        }) 
        .y(function(d) {
            //console.log(d.catan_count)
            return yScale(d.dominion_count)
        }) 
        .curve(d3.curveMonotoneX) 
    
    //2nd attempt - create loop for creating all lines
    plotlines = svga.append('g')
        .attr('id','lines-a')
    
    //create array of columns
    const count_values = ["catan_count","dominion_count","codenames_count","terraforming_mars_count","gloomhaven_count","magic_count","dixit_count","monopoly_count"]
    const labels = ["Catan","Dominion","Codenames","Terraforming Mars","Gloomhaven","Magic: The Gathering","Dixit","Monopoly"]
    
    //create color palette for strokes
    const colors = ['#1f77b4','#ff7f0e','#2ca02c','#d62728','#9467bd','#8c564b','#e377c2','#7f7f7f','#bcbd22','#17becf']
    var counter = 0

    //Loop through all values in array created above
    count_values.forEach(function(name){
        counter = counter + 1
        //console.log(counter)
        var new_line = d3.line()
            .x(function(d){return xScale(d.date);})
            .y(function(d){return yScale(d[name]);})
            .curve(d3.curveMonotoneX);
        //console.log(new_line)

        plotlines.append("path")
            .datum(dataset) 
            .style("fill","none")
            .attr("class", "line") 
            .attr("d", new_line)
            .style("stroke", function(d) {
                if (name.localeCompare("catan_count")==0){return colors[0];}
                else if (name.localeCompare("dominion_count")==0){return colors[1];}
                else if (name.localeCompare("codenames_count")==0){return colors[2];}
                else if (name.localeCompare("terraforming_mars_count")==0){return colors[3];}
                else if (name.localeCompare("gloomhaven_count")==0){return colors[4];}
                else if (name.localeCompare("magic_count")==0){return colors[5];}
                else if (name.localeCompare("dixit_count")==0){return colors[6];}
                else if (name.localeCompare("monopoly_count")==0){return colors[7];}
            })
        plotlines.append("text") //append text labels
            .attr('id',"line label")
            .attr("class","line label")
            //.attr("x", 780) //relative x axis of text 0.7 to the right
            //.attr("y", 0) //relative y axis 0.7 up
            .attr("transform", "translate(" + (width+20) + "," + yScale(dataset[dataset.length-1][name]) + ")")
            .attr("text-anchor", "start")
            .style("fill","blue")
            .style('stroke-width',0)
            .style('font-size',"12px")
            //.attr('font-weight',"bold")
            .text(function(d) {
                if (name.localeCompare("catan_count")==0){return labels[0];}
                else if (name.localeCompare("dominion_count")==0){return labels[1];}
                else if (name.localeCompare("codenames_count")==0){return labels[2];}
                else if (name.localeCompare("terraforming_mars_count")==0){return labels[3];}
                else if (name.localeCompare("gloomhaven_count")==0){return labels[4];}
                else if (name.localeCompare("magic_count")==0){return labels[5];}
                else if (name.localeCompare("dixit_count")==0){return labels[6];}
                else if (name.localeCompare("monopoly_count")==0){return labels[7];}
            });
    });

    }).catch(function (error) {
        console.log(error);
      });
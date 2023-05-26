// Define Margins according to margin convention supplied

//var margin = {top: 100, right: 150 , bottom: 100, left: 150};

// define width and height as the inner dimensions of the chart area.

//var width = 960 - margin.left - margin.right,
   //height = 500 - margin.top - margin.bottom;



// define X and Y scales

// define x
//var xScale = d3.scaleTime()
//    .range([0,width]); //output

// define y
//var yScale = d3.scaleLinear()
//    .range([height,0]); //output

// create svg
var svgd = d3.select("body").append("svg")
.attr("width", width + margin.left + margin.right)
.attr("height", height + margin.top + margin.bottom)
.attr("id", "svg-c-2")
.append("g")
.attr("transform", "translate(" + margin.left + "," + margin.top + ")")
.attr("id", "plot-c-2");

//create formula to format time for ticks later
//const formatTime = d3.timeFormat("%b %y")
//console.log(typeof formatTime(new Date("11/1/2016"))) // check that this works on first row date

//create  formula to convert sstring to date
//const converttodate = d3.timeParse("%Y-%m-%d")
//console.log(typeof converttodate("2016-11-01")) // check that this works on first row date
//console.log(converttodate("2016-11-01")) // check that this works on first row date

//path to csv
//var pathToCsv = "boardgame_ratings.csv";

//read data in
d3.dsv(",", pathToCsv, function (d) {
    return {
     date: converttodate(d.date), // no conversion for now
     catan_count: +d["Catan=count"],
     catan_rank: +d['Catan=rank'],
     dominion_count: +d["Dominion=count"],
     dominion_rank: +d['Dominion=rank'],
     codenames_count: +d["Codenames=count"],
     codenames_rank: +d['Codenames=rank'],
     terraforming_mars_count: +d["Terraforming Mars=count"],
     terraforming_mars_rank: +d['Terraforming Mars=rank'],
     gloomhaven_count: +d["Gloomhaven=count"],
     gloomhaven_rank: +d['Gloomhaven=rank'],
     magic_count: +d["Magic: The Gathering=count"],
     magic_rank: +d['Magic: The Gathering=rank'],
     dixit_count: +d["Dixit=count"],
     dixit_rank: +d['Dixit=rank'],
     monopoly_count: +d["Monopoly=count"],
     monopoly_rank: +d['Monopoly=rank']
      // format data attributes if required
    };
    }).then(function (data) {
        dataset = data // hand csv data to global var so its accessible later
        //console.log(dataset)

    // define X and Y scales

    // define x
    var xScale = d3.scaleTime()
    .domain([d3.min(dataset,function(d) { return d.date; }), d3.max(dataset, function(d) {return d.date}) ]) //input
    .range([0,width]); //output


    // define y
    var yScale = d3.scaleLog()
    .domain([1,d3.max(dataset, function(d) {return d.catan_count})]) //input
    .range([height,0]); //output
    
    //create title
    d3.select("#svg-c-2")
        .append("text")
        .attr("id","title-c-2")
        .attr("transform", "translate(" + ((width + margin.left + margin.right)/2) + "," + (margin.top-30) + ")")
        .attr("text-anchor", "middle")
        .attr('fill',"black")
        .style('font-size',"20px")
        .attr('font-weight',"bold")
        .text("Number of Ratings 2016-2020 (Log Scale)")

    //create x axis
    svgd.append("g")
        .attr("class", "axis")
        .attr("id","x-axis-c-2")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(xScale).ticks(10,"%b %y"));

    // x axis label    
    svgd.select("#x-axis-c-2")
        .append('text')
        .attr("id","x-axis label")
        .attr("transform", "translate(" + (width/2) + "," + 40 + ")")
        .attr("text-anchor", "middle")
        .attr('fill',"black")
        .style('font-size',"14px")
        .attr('font-weight',"bold")
        .text("Month");
    
   

    //create y axis
    svgd.append("g")
        .attr("class", "axis")
        .attr("id","y-axis-c-2")
        //.attr("transform", "translate(0," + height + ")")
        .call(d3.axisLeft().scale(yScale));
    
     // y axis label
     svgd.select("#y-axis-c-2")
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
    plotlines = svgd.append('g')
        .attr('id','lines-c-2')
    
    symbolsb = svgd.append('g')
        .attr('id', 'symbols-c-2')
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

    //plot lines
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
        //console.log(dataset)

 
                
    //plot text
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

    //plot circles
    var circle_names= ['Catan','Codenames','Terraforming Mars', 'Gloomhaven'] 
    //dataset for circles
    const rank_values = ["catan_rank","codenames_rank","terraforming_mars_rank","gloomhaven_rank"]
    const count_values2 = ["catan_count","codenames_count","terraforming_mars_count","gloomhaven_count"]
    const rank_labels = ["Catan","Codenames","Terraforming Mars","Gloomhaven"]
    
    //create every 3rd item for symbol data
    var sym_data = []
    for (i=2; i < dataset.length; i=i+3){
        sym_data.push(dataset[i]);
    };
    
    var counter2 = 0 //create count variable

    count_values2.forEach(function(name){
    counter2 = counter2 + 1
    //plot circles + text on lines
    symbolsb.selectAll()
        .data(sym_data)
        .enter()
        .append('circle')
        .attr("class", "dots")
        .attr("cx", function(d) {return xScale(d.date)})
        .attr('cy', function(d) {return yScale(d[name])})
        .attr("r",12)
        .style("fill", function(d) {
            if (name.localeCompare("catan_count")==0){return colors[0];}
            //else if (name.localeCompare("dominion_count")==0){return colors[1];}
            else if (name.localeCompare("codenames_count")==0){return colors[2];}
            else if (name.localeCompare("terraforming_mars_count")==0){return colors[3];}
            else if (name.localeCompare("gloomhaven_count")==0){return colors[4];}
        })
    
    symbolsb.selectAll()
        .data(sym_data)
        .enter()
        .append('text')
        .attr('id',"dot-label")
        .attr("class","dot-label")
        .attr("transform", function(d){return "translate(" + (xScale(d.date)) + ", " + (yScale(d[name])+3)+")";})
        .attr('text-anchor','middle')
        .style("fill","white")
        .style('stroke-width',0)
        .style('font-size',"12px")
        //.attr("transform", function(d){return "translate(" + xScale(d.date) + ", " + yScale(d[name])+")";})
        .text(function(d){
            return d[rank_values[counter2-1]]
        });
    
    });


    //create legend
    legendb = svgd.append('g')
        .attr('id','legend-c-2')

    legendb.append('circle')
        .attr("class", "dots")
        .attr("cx",width+60)
        .attr("cy", height)
        .attr("r",12)
        .style("fill", "black")   

    legendb.append('text')
        .attr('id',"legend-label")
        .attr("class","legend-label")
        .attr("x", width+60)
        .attr("y", height+2)
        .attr('text-anchor','middle')
        .style("fill","white")
        .style('stroke-width',0)
        .style('font-size',"8px")
        .text("Rank");
    
    legendb.append('text')
        .attr('id',"legend-label2")
        .attr("class","legend-label")
        .attr("x", width+60)
        .attr("y", height+25)
        .attr('text-anchor','middle')
        .style("fill","black")
        .style('stroke-width',0)
        .style('font-size',"9px")
        .text("BoardGameGeek Ranking");


    }).catch(function (error) {
        console.log(error);
      });
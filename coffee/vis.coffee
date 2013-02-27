
root = exports ? this


displayMap = (data) ->
  width = 960
  height = 500
# -96.7465324480928,32.8894912458806
  map = L.map('map').setView([32.889, -96.74653], 9)
  api_key = "088d3df822cb4b33b9d95e9cedf889a5"
  L.tileLayer("http://{s}.tile.cloudmade.com/#{api_key}/997/256/{z}/{x}/{y}.png").addTo(map)

  svg = d3.select(map.getPanes().overlayPane).append('svg')
  g = svg.append('g').attr("class", "leaflet-zoom-hide")

  data.forEach (d) ->
    # console.log(d['y'])
    # console.log(d['x'])
    if d['y'] and d['x']
      d.ll = new L.LatLng(d['y'],d['x'])

    if d['min_x'] and d['min_y'] and d['max_x'] and d['max_y']
      # d.bounds = [[d['min_y'], d['min_x']], [d['max_y'], d['max_x']]]
      d.bounds = [[d['max_y'], d['max_x']], [d['min_y'], d['min_x']]]

  feature_map = {}
  features = []
  data.forEach (d) ->
    if d.ll
      # c = new L.CircleMarker(d.ll)
      c = new L.Rectangle(d.bounds)
      c.bindPopup(d['name'])
      # feature_map[d['name']] = c
      feature_map[c] = d
      # c.setRadius(20)
      features.push(c)
      
  circles = new L.layerGroup(features)

  console.log(feature_map)


  highlight = (e) ->
    layer = e.target
    layer.setStyle({color: '#666'})
    if !L.Browser.ie && !L.Browser.opera
      layer.bringToFront()

  unhighlight = (e) ->
    layer = e.target
    layer.setStyle({color: 'blue'})

  click = (e) ->
    layer = e.target
    data = feature_map[layer]
    if data

    else
      console.log("error: no data")

  onEachFeature = (layer) ->
    layer.on({mouseover:highlight,mouseout:unhighlight,click:click})
    # layer.bindPopup(feature_map[layer]['name'])

  circles.eachLayer(onEachFeature)
  circles.addTo(map)

  # circle = g.selectAll("circle")
  #   .data(data)
  #   .enter().append("circle")
  #   .attr("r", 40)

  # project = (datum) ->
  #   point = map.latLngToLayerPoint(new L.LatLng(datum['x'], datum['y']))
  #   [point.x, point.y]

  update = () ->
    # bottomLeft = project(bounds[0])
    # topRight = project(bounds[1])

    # svg.attr("width", 50)
    #   .attr("height", 50)
    #   .style("margin-left", 20 + 'px')
    #   .style("margin-top", 30 + 'px')

    # g.attr("transform", "translate(#{-10},#{-10})")


  map.on('viewreset', update)
  update()

    

$ ->
  display = (error, data) ->
    displayMap(data)


  d3.csv('data/web_data_fakenames_utf.csv', display)




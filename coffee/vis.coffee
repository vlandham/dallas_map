
root = exports ? this
map = null
map_icons_layer = null
all_data = null
data = null
top_data = null
weight_max = 10

data_by_id = {}
id = (d) -> d["name"]

root.options = {}

update_hash = () =>
  encoded = rison.encode(root.options)
  document.location.hash = encoded

update_options = () =>
  root.options = {}
  if document.location.hash
    root.options = rison.decode(document.location.hash.replace(/^#/,""))
  else
    root.options = {}
    root.options.weights = {}

ranges = {
  overall_score: [-1.7, 0.7]
  schools_index: [-3.0, 3.7]
  safety_index:  [-3.2, 0.9]
  appreciation_index: [-2.30, 3.10]
  affordability_index: [-1.8, 3.10]
  parks_index: [-1.1, 3.5]
  commute_index: [-3.1, 2.3]
  pet_index: [-2.0, 1.5]
  walkability_index: [-1.0, 3.1]
  landscaping_index: [-1.6, 3.0]
  quiet_index: [-1.6, 2.4]
  go_do_index: [-1.5, 3.1]
}

# intial try
# think i can do better
# calculate_weighted_score = (weights, data) ->
#   # scale = d3.scale.linear().range([0,100])
#   data.forEach (d) ->
#     total = 0
#     d3.entries(weights).forEach (weight_entry) ->
#       total += (d[weight_entry.key] * (weight_entry.value + 1))
#     d.weighted_score = total

calculate_weighted_score = (weights, data) ->
  # scale = d3.scale.linear().range([0,100])
  data.forEach (d) ->
    total = 0
    d3.entries(weights).forEach (weight_entry) ->
      total += (d[weight_entry.key] * ((weight_entry.value / weight_max) + 0.01))
    d.weighted_score = total

sort_by_weighted_score = (data) ->
  data.sort (a,b) -> b.weighted_score - a.weighted_score
  data

filter_top_data = (data) ->
  data[0...10]



# ---
# Function used to ensure our raw data is in the correct format for the rest
# of the visualization.
# Right now, it ensures the columns listed in sort_key are floats
# ---
prepare_data = (data) ->
  scales = {}
  d3.entries(ranges).forEach (entry) ->
    scale = d3.scale.linear().range([0,100])
    scale.domain(entry.value)
    scales[entry.key] = scale

  data.forEach (d) ->
    d3.entries(scales).forEach (entry) ->
      d[entry.key] = entry.value(parseFloat(d[entry.key]))
    if d['y'] and d['x']
      d.ll = new L.LatLng(d['y'],d['x'])
      d.marker = new L.Marker(d.ll, {title:d.name})
      d.marker.bindPopup(d.name)

    if d['min_x'] and d['min_y'] and d['max_x'] and d['max_y']
      d.bounds = [[d['min_y'], d['min_x']], [d['max_y'], d['max_x']]]
      d.rect = new L.Rectangle(d.bounds)
      d.rect.bindPopup(d['name'])
  data

prepare_data_by_id = (data) ->
  data_by_id = {}
  data.forEach (d) ->
    data_by_id[id(d)] = d


highlight = (e) ->
  layer = e.target
  # layer.setStyle({color: '#666'})
  # if !L.Browser.ie && !L.Browser.opera
  #   layer.bringToFront()

unhighlight = (e) ->
  layer = e.target
  # layer.setStyle({color: 'blue'})

click = (e) ->
  layer = e.target
  # data = feature_map[layer]
  # if data

  # else
  #   console.log("error: no data")

onEachFeature = (layer) ->
  layer.on({mouseover:highlight,mouseout:unhighlight,click:click})
    # layer.bindPopup(feature_map[layer]['name'])

display_icons = (features) ->
  map_icons_layer.clearLayers()
  features.forEach (f) ->
    map_icons_layer.addLayer(f)
  map_icons_layer.eachLayer(onEachFeature)

update_map = (data) ->
  features = []
  data.forEach (d) ->
    if d.marker
      features.push(d.marker)
  display_icons(features)

displayMap = (data) ->
  width = 620
  height = 400
# -96.7465324480928,32.8894912458806
  map = L.map('large-map').setView([32.889, -96.74653], 9)
  api_key = "088d3df822cb4b33b9d95e9cedf889a5"
  L.tileLayer("http://{s}.tile.cloudmade.com/#{api_key}/997/256/{z}/{x}/{y}.png").addTo(map)

  map_icons_layer = new L.layerGroup()
  map_icons_layer.addTo(map)
  update_map(data)

show_details = (n_data) ->
  ordered_weights = d3.entries(root.options.weights)
  ordered_weights.sort (a,b) -> b.value - a.value
  d3.select("#details").selectAll(".detail").remove()
  d3.select("#details").selectAll(".detail")
    .data(ordered_weights)
    .enter().append("li")
    .attr("class", "detail")
    .text((d) -> "#{d.key}: #{toFixed(n_data[d.key], 2)}")

update_top_ten = (top_data) ->
  d3.select("#top_ten_list").selectAll(".top").remove()
  tops = d3.select("#top_ten_list").selectAll(".top")
    .data(top_data)

  tops.enter().append("li")
    .attr("class", "top")
    .text((d) -> d.name)
  tops.on "mouseover", (d) ->
    highlight_on_map(d)
    show_details(d)

  # top_ten_content = "<ol>\n"
  # top_data.forEach (d) ->
  #   top_ten_content += "<li>#{d.name}</li>\n"
  # top_ten_content += "</ol>\n"

  # $('#top_ten_list').html(top_ten_content)

highlight_on_map = (bubble_data) ->
  if bubble_data.marker
    # map.zoomIn(12)
    # map.panTo(bubble_data.marker.getLatLng())
    latlon = bubble_data.marker.getLatLng()
    offset = map._getNewTopLeftPoint(latlon).subtract(map._getTopLeftPoint())
    map.panBy(offset)
    bubble_data.marker.openPopup()

update = () ->
  # root.options.weights = weights
  calculate_weighted_score(root.options.weights, all_data)
  all_data = sort_by_weighted_score(all_data)
  top_data = filter_top_data(all_data)
  update_map(top_data)
  update_top_ten(top_data)
  highlight_on_map(top_data[0])

initial_weights = {
  schools_index: 1
  safety_index: 0
  appreciation_index: 2
  affordability_index: 1
  parks_index: 3
  commute_index: 1
  pet_index: 0
  walkability_index: 2
  landscaping_index: 0
  quiet_index: 1
  go_do_index: 2
}
# slider_start_values = {
#   schools_index_slider: 1
#   safety_index_slider: 0
#   appreciation_index_slider: 2
#   affordability_index_slider: 1
#   parks_index_slider: 3
#   commute_index_slider: 1
#   pet_index_slider: 0
#   walkability_index_slider: 2
#   landscaping_index_slider: 0
#   quiet_index_slider: 1
#   go_do_index_slider: 2
# }
    
$ ->
  hashchange = () ->
    console.log('update')
    update()

  display = (error, csv) ->
    all_data = prepare_data(csv)
    prepare_data_by_id(all_data)
    data = all_data
    displayMap(data)
    update()

  update_options()

  d3.select(window)
    .on("hashchange", hashchange)

  d3.entries(initial_weights).forEach (entry) ->
    # this appears to be necessary as it was
    # calling values that were '0' the same as 
    # values that weren't there
    if typeof root.options.weights[entry.key] is 'undefined'
      console.log(entry.key)
      console.log(root.options.weights[entry.key])
      root.options.weights[entry.key] = parseInt(entry.value)

  sliders = $('.slider')
  sliders.each () ->
    $(this).empty().slider({
      range: false
      max: weight_max
      min: 0
      step: 1
      value: root.options.weights[$(this).attr("id").replace("_slider","")]
      create: (event, ui) ->
        self = $(this)
        dom_id = self.attr("id").replace("_slider","")
        root.options.weights[dom_id] = self.slider("option", "value")
        # update current sliders text
        value_id = "#" + self.attr("id") + "_amount"
        $(value_id).text(self.slider("option", "value"))
      slide: (event, ui) ->
        self = $(this)

        # update current sliders text
        value_id = "#" + self.attr("id") + "_amount"
        $(value_id).text(ui.value)
  
        # set weight for current slider
        dom_id = self.attr("id").replace("_slider","")
        root.options.weights[dom_id] = ui.value
        
        # set weights for other sliders
        sliders.not(this).each () ->
          slider = $(this)
          dom_id = slider.attr("id").replace("_slider", "")
          root.options.weights[dom_id] = slider.slider("option", "value")

        update_hash()
    })

  $("#slider_reset").on "click", (event) ->
    event.preventDefault()
    sliders.each () ->
      $(this).slider("value", 0)


  d3.csv('data/web_data_fakenames_utf.csv', display)





root = exports ? this
map = null
map_icons_layer = null
all_data = null
data = null
top_data = null
weights = {}

data_by_id = {}
id = (d) -> d["name"]

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

calculate_weighted_score = (weights, data) ->
  scale = d3.scale.linear().range([0,100])
  data.forEach (d) ->
    total = 0
    d3.entries(weights).forEach (weight_entry) ->
      total += (d[weight_entry.key] * weight_entry.value)
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

    if d['min_x'] and d['min_y'] and d['max_x'] and d['max_y']
      d.bounds = [[d['min_y'], d['min_x']], [d['max_y'], d['max_x']]]
      d.rect = new L.Rectangle(d.bounds)
      d.rect.bindPopup(d['name'])
  data

# prepare_data_by_id = (data) ->
#   data_by_id = {}
#   data.forEach (d) ->
#     data_by_id[id(d)] = d


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
    if d.rect
      features.push(d.rect)
  display_icons(features)

displayMap = (data) ->
  width = 620
  height = 400
# -96.7465324480928,32.8894912458806
  map = L.map('large-map').setView([32.889, -96.74653], 9)
  api_key = "088d3df822cb4b33b9d95e9cedf889a5"
  L.tileLayer("http://{s}.tile.cloudmade.com/#{api_key}/997/256/{z}/{x}/{y}.png").addTo(map)

  # svg = d3.select(map.getPanes().overlayPane).append('svg')
  # g = svg.append('g').attr("class", "leaflet-zoom-hide")

  map_icons_layer = new L.layerGroup()
  map_icons_layer.addTo(map)
  update_map(data)


update_top_ten = (top_data) ->
  top_ten_content = "<ol>\n"
  top_data.forEach (d) ->
    top_ten_content += "<li>#{d.name}</li>\n"
  top_ten_content += "</ol>\n"

  $('#top_ten_list').html(top_ten_content)


update_data = () ->
  calculate_weighted_score(weights, all_data)
  all_data = sort_by_weighted_score(all_data)
  top_data = filter_top_data(all_data)
  update_map(top_data)
  update_top_ten(top_data)

slider_start_values = {
  schools_index_slider: 10
  safety_index_slider: 0
  appreciation_index_slider: 20
  affordability_index_slider: 10
  parks_index_slider: 30
  commute_index_slider: 10
  pet_index_slider: 0
  walkability_index_slider: 20
  landscaping_index_slider: 0
  quiet_index_slider: 10
  go_do_index_slider: 20
}
    
$ ->
  display = (error, csv) ->
    all_data = prepare_data(csv)
    # prepare_data_by_id(all_data)
    data = all_data
    displayMap(data)
    update_data()
 
  sliders = $('.slider')
  sliders.each () ->
    $(this).empty().slider({
      range: false
      max: 100
      min: 0
      step: 10
      value: slider_start_values[$(this).attr("id")]
      create: (event, ui) ->
        self = $(this)
        id = self.attr("id").replace("_slider","")
        weights[id] = self.slider("option", "value")
        console.log(weights)
      slide: (event, ui) ->
        total = 0
        self = $(this)

        # update current sliders text
        value_id = "#" + self.attr("id") + "_amount"
        $(value_id).text(ui.value)
  
        # set weight for current slider
        id = self.attr("id").replace("_slider","")
        weights[id] = ui.value
        
        # set weights for other sliders
        sliders.not(this).each () ->
          slider = $(this)
          id = slider.attr("id").replace("_slider", "")
          weights[id] = slider.slider("option", "value")

        update_data()
    })


  d3.csv('data/web_data_fakenames_utf.csv', display)




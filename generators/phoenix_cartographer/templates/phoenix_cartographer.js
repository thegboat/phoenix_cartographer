phoenix_cartographer = {
  map : null, // the map
  icons : {}, // cache icons so identical icons are not created and are shared
  locations : {}, // phoenix_cartographer database of locations
  info_window: new google.maps.InfoWindow(), // shared info window
  orig_zoom : null,
  orig_bounds : null,
  orig_center : null,
  init_map : function(name, opts){
    opts = opts || {}
    this.map = new google.maps.Map(document.getElementById(name),{scrollwheel: opts['scrollwheel'], center: new google.maps.LatLng(0, 0), zoom: 0, mapTypeId: google.maps.MapTypeId.ROADMAP});
    this.init_home_button();
    this.store_original_options(opts);
    this.auto_center()
    this.init_locations(opts['locations'], opts['visible_tag'])
  },
  store_original_options : function(opts){
    if(parseInt(opts['zoom'])){
      var center = opts['center'] || [0,0]
      this.orig_zoom = parseInt(opts['zoom'])
      this.orig_center = new google.maps.LatLng(center[0], center[1])
    }
    if(opts['bounds']){
      var sw = new google.maps.LatLng(opts['bounds'][0][0], opts['bounds'][0][1])
      var ne = new google.maps.LatLng(opts['bounds'][1][0], opts['bounds'][1][1])
      this.orig_bounds = new google.maps.LatLngBounds(sw, ne)
    }
  },
  infowindow_listener_init : function(marker){
    google.maps.event.addListener(marker, "click", function() { phoenix_cartographer.infowindow_open(marker) });
  },
  infowindow_open : function(marker){
    this.info_window.close()
    var content = [], ele;
    //find the location object of marker
    var loc = this.locations[marker.loc]
    //build content from all locations markers that should be visible
    for(var l=loc.visible_markers.length, c = 0;c<l;c++){
      cur_marker = loc.visible_markers[c]
      ele = document.getElementById(cur_marker.name)
      if(!ele) continue;
      content = content.concat(ele.innerHTML)
    }
    this.info_window.content = content.join("<br />")
    this.map.setCenter(loc.position)
    this.info_window.open(this.map, marker)
  },
  //set center, zoom and bounds
  auto_center : function(){
    if(this.orig_zoom){
      this.map.setCenter(this.orig_center)
      this.map.setZoom(this.orig_zoom)
    }
    else{
      this.map.setCenter(this.orig_bounds.getCenter())
      this.map.fitBounds(this.orig_bounds)
    }
  },
  //build a new icon; it will be cached and shared with other markers who need it
  init_icon : function(icon_name){
    var url = "/images/phoenix_cartographer/numbers/" + icon_name + ".png"
    var icon = this.icons[icon_name] = new google.maps.MarkerImage(
      url,
      google.maps.Size(20, 34),
      google.maps.Point(0,0),
      google.maps.Point(  6, 20),
      google.maps.Size( 20, 34)
    )
    return icon
  },
  //add our locations to phoenix_cartographer datastore
  init_locations : function(locations, tags){
    var marker, loc, v_exp = {};
    //tags for initial visiblity
    if(tags) {
      for(var l=tags.length,i=0; i<l;i++) {v_exp[tags[i]] = true}
    }
    for(var i=locations.length-1; i>=0; i--){
      loc = locations[i]
      loc.name = "loc_" + String(i)
      this.locations[loc.name] = loc
      loc.position = new google.maps.LatLng(loc.lat, loc.lon)
      loc.lat = loc.lon = null  //free this memory
      this.reset_marker(loc, v_exp, tags)
    }
  },
  //reset all markers according to the visibility expression
  reset_markers : function(v_exp){
    var marker, loc;
    //force close infowindow
    this.info_window.close()
    //cycle through each location
    for(loc_name in this.locations){
      loc = this.locations[loc_name]
      this.reset_marker(loc, v_exp)
    }
  },
  //determine, if any what marker to display for location
  //only_if_tagged is optional
  reset_marker : function(loc, v_exp, only_if_tagged){
    var marker, icon, icon_name, visible_uniq = [], number;
    //set current visible marker invisible if any
    if(loc.marker) loc.marker.setVisible(false)
    //remove marker
    loc.marker = null
    //reset visible markers to empty (none visible)
    loc.visible_markers = []
    //cycle through marker data
    for(var l=loc.data.length, c = 0;c<l;c++){
      marker = loc.data[c]
      //test_tags ... add marker data to visible_markers if visibility is true
      if(this.test_tags(marker.tags, v_exp, only_if_tagged)) {
        loc.visible_markers.push(marker)
        //this calculates the number to display ... counts
        if(marker.uniq && visible_uniq.indexOf(marker.uniq) == -1) visible_uniq.push(marker.uniq)
      }
    }
    //if we have at least one
    if( marker = loc.visible_markers[0]){
      //determine number to display
      number = visible_uniq.length < loc.visible_markers.length ? visible_uniq.length : loc.visible_markers.length
      //build icon name
      icon_name = marker.icon + "_" + this.get_icon_number(number)
      //get shared icon resource or create new one
      icon = this.icons[icon_name] || this.init_icon(icon_name)
      //create a visible marker
      loc.marker = new google.maps.Marker({map: this.map, position: loc.position,icon: icon})
      //associate marker with location for quick look ups
      loc.marker.loc = loc.name
      //add event callback for infowindow
      this.infowindow_listener_init(loc.marker)
    }
  },
  //always display 1 or more never display more than 9
  get_icon_number : function(number){
    if(number == 0) return 1
    if(number > 9) return 9
    return number
  },
  //tags is an Array of tags to test against; the tags of a marker
  //v_exp is JSON object of tags as keys and true/false as values
  //  a tag key with true value means markers with that tag should be visible
  //  a tag key with false value means markers with that tag should be invisible
  //only_tagged argument instructs only to make visible markers that have a tag explicitly set to true in v_exp
  //  it is optional and by default is false
  test_tags : function(tags, v_exp, only_tagged){
    //start as false if we want only_tagged else true
    var rtn = !only_tagged
    for(var i in tags){
      //if any are false we want no visiblity end loop return false
      if(v_exp[tags[i]] == false) return false
      //set rtn value to true only once ... this code is only executed when only_tagged is true
      if(!rtn && v_exp[tags[i]]) rtn = true
    }
    //if only_tagged was not set this will always be true
    //else it will be true only if v_exp had a tag of true for this marker
    return rtn
  },
  init_home_button : function(){
    // Create a div to hold the control.
    var controlDiv = document.createElement('div');

    // Set CSS styles for the DIV containing the control
    // Setting padding to 5 px will offset the control
    // from the edge of the map.
    controlDiv.style.padding = '5px';

    // Set CSS for the control border.
    var controlUI = document.createElement('div');
    controlUI.style.backgroundColor = 'white';
    controlUI.style.borderStyle = 'solid';
    controlUI.style.borderWidth = '2px';
    controlUI.style.cursor = 'pointer';
    controlUI.style.textAlign = 'center';
    controlUI.title = 'Click to set the map to Home';
    controlDiv.appendChild(controlUI);

    // Set CSS for the control interior.
    var controlText = document.createElement('div');
    controlText.style.fontFamily = 'Arial,sans-serif';
    controlText.style.fontSize = '12px';
    controlText.style.paddingLeft = '4px';
    controlText.style.paddingRight = '4px';
    controlText.innerHTML = '<strong>Home<strong>'
    controlUI.appendChild(controlText);
    this.map.controls[google.maps.ControlPosition.TOP_LEFT].push(controlDiv);
    google.maps.event.addDomListener(controlDiv, 'click', function() {
      phoenix_cartographer.info_window.close()
      phoenix_cartographer.auto_center()
    });
  }
}

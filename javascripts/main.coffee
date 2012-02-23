dojo.require "dijit.layout.BorderContainer"
dojo.require "dijit.layout.ContentPane"
dojo.require "esri.map"
dojo.require "esri.dijit.Popup"

dojo.addOnLoad ->
  initExtent = new esri.geometry.Extent
    xmin: -9270392
    ymin: 5247043
    xmax: -9269914
    ymax: 5247401
    spatialReference:
      wkid: 102100
  
  lineColor  = new dojo.Color [255,0,0]
  fillColor  = new dojo.Color [255,255,0,0.25]
  lineSymbol = new esri.symbol.SimpleLineSymbol esri.symbol.SimpleLineSymbol.STYLE_SOLID, lineColor, 2
  fill       = new esri.symbol.SimpleFillSymbol esri.symbol.SimpleFillSymbol.STYLE_SOLID, lineSymbol, fillColor
  popup      = new esri.dijit.Popup { fillSymbol: fill }, dojo.create "div"

  map = new esri.Map "map",
    infoWindow: popup
    extent: initExtent

  basemap = new esri.layers.ArcGISDynamicMapServiceLayer "http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"
  map.addLayer basemap

  landBaseLayer = new esri.layers.ArcGISDynamicMapServiceLayer "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/BloomfieldHillsMichigan/Parcels/MapServer",
    opacity: 0.55
  map.addLayer landBaseLayer

  dojo.connect map, "onLoad", (_map_) ->
    identifyTask                  = new esri.tasks.IdentifyTask "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/BloomfieldHillsMichigan/Parcels/MapServer"
    identifyParams                = new esri.tasks.IdentifyParameters()
    identifyParams.tolerance      = 3
    identifyParams.returnGeometry = true
    identifyParams.layerIds       = [0, 2]
    identifyParams.layerOption    = esri.tasks.IdentifyParameters.LAYER_OPTION_ALL
    identifyParams.width          = _map_.width
    identifyParams.height         = _map_.height

    dojo.connect _map_, "onClick", (evt) ->
      identifyParams.geometry = evt.mapPoint
      identifyParams.mapExtent = _map_.extent

      deferred = identifyTask.execute identifyParams
      deferred.addCallback (response) ->
        dojo.map response, (result) ->
          feature = result.feature
          feature.attributes.layerName = result.layerName
          if result.layerName is "Tax Parcels" then feature.setInfoTemplate new esri.InfoTemplate "","${Postal Address} <br/> Owner of record: ${First Owner Name}"
          else if result.layerName is "Building Footprints" then feature.setInfoTemplate new esri.InfoTemplate "", "Parcel ID: ${PARCELID}"
          feature
      _map_.infoWindow.setFeatures [ deferred ]
      _map_.infoWindow.show evt.mapPoint

    dojo.connect dijit.byId("map"), "resize", _map_, _map_.resize

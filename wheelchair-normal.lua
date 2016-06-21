-- Foot profile

local find_access_tag = require("lib/access").find_access_tag

-- Begin of globals
barrier_whitelist = { [""] = true, ["bollard"] = true, ["entrance"] = true, ["border_control"] = true, ["toll_booth"] = true, ["sally_port"] = true, ["gate"] = true, ["no"] = true, ["block"] = true, ["kerb"] = true}
access_tag_whitelist = { ["yes"] = true, ["foot"] = true, ["permissive"] = true, ["designated"] = true  }
access_tag_blacklist = { ["no"] = true, ["private"] = true, ["agricultural"] = true, ["forestry"] = true }
access_tag_restricted = { ["destination"] = true, ["delivery"] = true }
access_tags_hierachy = { "foot", "access" }
service_tag_restricted = { ["parking_aisle"] = true }
ignore_in_grid = { ["ferry"] = true }
restriction_exception_tags = { "foot" }

walking_speed = 3 -- in km/h - but as speed is the rating criteria, total time is useless
minwidth = 0.8 -- in m
maxkerbheight = 0.03 -- in m
maxincline = 3 -- in %;  explicitely tag ramps with wheelchair=yes!
maxincline_across = 6

speeds = {
  ["primary"] = 0.1,
  ["primary_link"] = 0.1,
  ["secondary"] = 0.2,
  ["secondary_link"] = 0.2,
  ["tertiary"] = 0.3,
  ["tertiary_link"] = 0.3,
  ["unclassified"] = 0.5,
  ["residential"] = 1,
  ["sidewalk"] = walking_speed,
  ["road"] = walking_speed,
  ["living_street"] = walking_speed,
  ["service"] = walking_speed*0.75,
  ["track"] = walking_speed,
  ["path"] = walking_speed,
  ["steps"] = walking_speed*0.1, -- have to take it if it has a ramp
  ["pedestrian"] = walking_speed,
  ["platform"] = walking_speed,
  ["footway"] = walking_speed,
  ["pier"] = walking_speed,
  ["default"] = walking_speed
}

route_speeds = {
  ["ferry"] = 5
}

platform_speeds = {
  ["platform"] = walking_speed
}

amenity_speeds = {
  ["parking"] = walking_speed,
  ["parking_entrance"] = walking_speed
}

man_made_speeds = {
  ["pier"] = walking_speed
}

surface_speeds = {
  ["fine_gravel"] =   walking_speed*0.25,
  ["gravel"] =        walking_speed*0.05,
  ["pebblestone"] =   0,
  ["cobblestone"] =   walking_speed*0.5,
  ["cobblestone:flattened"] =   walking_speed*0.5,
  ["paving_stones"] =   walking_speed*0.9,
  ["mud"] =           0,
  ["sand"] =          0,
  ["grass"] =         0,
  ["ground"] =         0,
  ["earth"] =         0,
  ["grass_paver"] =         0,
  ["unpaved"] =       walking_speed*0.1
}

smoothness_speed_factor = {
  ["excellent"] =         1,
  ["good"] =         1,
  ["intermediate"] =         0.5,
  ["bad"] =         0,
  ["very_bad"] =         0,
  ["horrible"] =         0,
  ["impassable"] =         0,
}

leisure_speeds = {
  ["track"] = walking_speed
}

traffic_signal_penalty   = 2
u_turn_penalty           = 2
use_turn_restrictions    = false
local fallback_names     = true

local obey_oneway        = true

--modes
local mode_normal = 1
local mode_ferry = 2

function get_exceptions(vector)
  for i,v in ipairs(restriction_exception_tags) do
    vector:Add(v)
  end
end

function node_function (node, result)
  local wheelchair = node:get_value_by_key("wheelchair")
  local kerbheight = node:get_value_by_key("kerb:height")
  local kerbtype = node:get_value_by_key("kerb")
  local width = node:get_value_by_key("width")

  local barrier = node:get_value_by_key("barrier")
  local access = find_access_tag(node, access_tags_hierachy)
  local highway = node:get_value_by_key("highway")
  local wheelchair_ramp = node:get_value_by_key("ramp:wheelchair")
  local crossing = node:get_value_by_key("crossing")
  local humps = node:get_value_by_key("traffic_calming")

  -- flag node if it carries a traffic light
  if highway and highway == "traffic_signals" then
    result.traffic_lights = true
  end
  -- wheelchair tag overrides all
  if wheelchair and (wheelchair == "yes" or wheelchair == "designated" ) then
      result.barrier = false
      return 1
  end
  if wheelchair and wheelchair ~= "" and (barrier and barrier ~= "" and barrier ~= "no") or (humps and humps ~= "" and humps ~= "no") then -- all other values (limited is only for wheelchair with help) on barriers
      result.barrier = true
      return 1
  end

  
  -- if step tagged on a node, they are a barrier
  if highway and highway == "steps" and not (wheelchair_ramp and wheelchair_ramp == "yes") then
    result.barrier = true
    return 1
  end
  -- nodes with crossing=no are a no-cross
  if crossing and crossing == "no" then
    result.barrier = true
    return 1
  end

  if width and width ~= "" then
      if width:match("^[0-9.]+%s?m?$") then
          lwidth = tonumber(width:match("^[0-9.]+"))
          if lwidth ~= nil then
              if lwidth >= minwidth then
                  result.barrier = false
              else
                  result.barrier = true
                  return 1
              end
          end
      elseif width:match("^[0-9.]+%s?cm$") then
          lwidth = tonumber(width:match("^[0-9.]+"))
          if lwidth ~= nil then
              if lwidth >= minwidth*100 then
                  result.barrier = false
              else
                  result.barrier = true
                  return 1
              end
          end
      end
  end

  -- barrier: kerb:height is the crucial value
  -- is it only [0-9.], then it is in m
  -- is the unit cm
  if kerbheight and kerbheight ~= "" then
      if kerbheight:match("^[0-9.]+%s?m?$") then
          lheight = tonumber(kerbheight:match("^[0-9.]+"))
          if lheight ~= nil then
              if lheight <= maxkerbheight then
                  result.barrier = false
              else
                  result.barrier = true
              end
              return 1
          end
      elseif kerbheight:match("^[0-9.]+%s?cm$") then
          lheight = tonumber(kerbheight:match("^[0-9.]+"))
          if lheight ~= nil then
              if lheight <= maxkerbheight*100 then
                  result.barrier = false
              else
                  result.barrier = true
              end
              return 1
          end
      end
      -- couldn't be parsed, ignore
  end
  -- no kerbheight set or not readable
  if kerbtype and kerbtype ~= "" then
      if kerbtype == "flush" or kerbtype == "lowered" or kerbtype == "no" then
          result.barrier = false
      else
          result.barrier = true
      end
      return 1
  end

  -- parse access and barrier tags
  if access and access ~= "" then
    if access_tag_blacklist[access] then
      result.barrier = true
    else
      result.barrier = false
    end
  elseif barrier and barrier ~= "" then
    if barrier_whitelist[barrier] then
      result.barrier = false
    else
      result.barrier = true
    end
  end

  return 1
end

function way_function (way, result)
  -- initial routability check, filters out buildings, boundaries, etc
  local highway = way:get_value_by_key("highway")
  local wheelchair_ramp = way:get_value_by_key("ramp:wheelchair")
  local leisure = way:get_value_by_key("leisure")
  local route = way:get_value_by_key("route")
  local man_made = way:get_value_by_key("man_made")
  local railway = way:get_value_by_key("railway")
  local amenity = way:get_value_by_key("amenity")
  local public_transport = way:get_value_by_key("public_transport")

  local wheelchair = way:get_value_by_key("wheelchair")
  local width = way:get_value_by_key("width")
  local incline = way:get_value_by_key("incline")
  local incline_across = way:get_value_by_key("incline:across")
  local sidewalk = way:get_value_by_key("sidewalk")

  if (not highway or highway == '') and
    (not leisure or leisure == '') and
    (not route or route == '') and
    (not railway or railway=='') and
    (not amenity or amenity=='') and
    (not man_made or man_made=='') and
    (not public_transport or public_transport=='')
    then
    return
  end

  -- don't route on ways that are still under construction
  if highway=='construction' then
      return
  end

  if wheelchair and (wheelchair == "no" or wheelchair == "limited") then
      return
  end

  if highway and highway == "steps" and not ( (wheelchair_ramp and  wheelchair_ramp == "yes") or (wheelchair and wheelchair == "yes") ) then
      return
  end

  -- access
  local access = find_access_tag(way, access_tags_hierachy)
  if access_tag_blacklist[access] then
    return
  end

  local name = way:get_value_by_key("name")
  local footway_type = way:get_value_by_key("footway")
  local ref = way:get_value_by_key("ref")
  local junction = way:get_value_by_key("junction")
  local onewayClass = way:get_value_by_key("oneway")
  local oneway_cycle = way:get_value_by_key("oneway:bicycle")
  local oneway_foot = way:get_value_by_key("oneway:foot")
  local oneway_wheelchair = way:get_value_by_key("oneway:wheelchair")
  local cycleway = way:get_value_by_key("cycleway")
  local cycleway_right = way:get_value_by_key("cycleway:right")
  local cycleway_left = way:get_value_by_key("cycleway:left")
  local duration  = way:get_value_by_key("duration")
  local service  = way:get_value_by_key("service")
  local area = way:get_value_by_key("area")
  local foot = way:get_value_by_key("foot")
  local surface = way:get_value_by_key("surface")

   -- name
  if ref and "" ~= ref and name and "" ~= name then
    result.name = name .. ' / ' .. ref
    elseif ref and "" ~= ref then
      result.name = ref
  elseif name and "" ~= name then
    result.name = name
  elseif footway_type and "" ~= footway_type then
      result.name = footway_type
  elseif highway and fallback_names then
    result.name = "{highway:"..highway.."}"  -- if no name exists, use way type
                                            -- this encoding scheme is excepted to be a temporary solution
  end

    -- roundabouts
  if "roundabout" == junction then
    result.roundabout = true
  end

    -- speed
  if route_speeds[route] then
    -- ferries (doesn't cover routes tagged using relations)
    result.ignore_in_grid = true
  if duration and durationIsValid(duration) then
    result.duration = math.max( 1, parseDuration(duration) )
  else
    result.forward_speed = route_speeds[route]
    result.backward_speed = route_speeds[route]
  end
    result.forward_mode = mode_ferry
    result.backward_mode = mode_ferry
  elseif railway and platform_speeds[railway] then
    -- railway platforms (old tagging scheme)
    result.forward_speed = platform_speeds[railway]
    result.backward_speed = platform_speeds[railway]
  elseif platform_speeds[public_transport] then
    -- public_transport platforms (new tagging platform)
    result.forward_speed = platform_speeds[public_transport]
    result.backward_speed = platform_speeds[public_transport]
  elseif amenity and amenity_speeds[amenity] then
    -- parking areas
    result.forward_speed = amenity_speeds[amenity]
    result.backward_speed = amenity_speeds[amenity]
  elseif leisure and leisure_speeds[leisure] then
    -- running tracks
    result.forward_speed = leisure_speeds[leisure]
    result.backward_speed = leisure_speeds[leisure]
  elseif speeds[highway] then
    -- regular ways
    result.forward_speed = speeds[highway]
    result.backward_speed = speeds[highway]
  elseif access and access_tag_whitelist[access] then
      -- unknown way, but valid access tag
    result.forward_speed = walking_speed
    result.backward_speed = walking_speed
  end

  --if has sidewalk tagged as implicit, set speed to normal
  if sidewalk and (sidewalk == "both" or sidewalk == "left" or sidewalk == "right") then
      result.forward_speed = speeds["sidewalk"]
      result.backward_speed = speeds["sidewalk"]
  end

  -- oneway
  if onewayClass and onewayClass ~= "" then
    if oneway_wheelchair and oneway_wheelchair == "no"  then 
      -- do nothing
    elseif oneway_foot and oneway_foot == "no" then
      -- do nothing
    elseif highway == "cycleway" and foot and (foot == "yes" or foot == "designated" or foot == "permissive" ) then 
      -- do nothing
    elseif sidewalk and (sidewalk == "both" or sidewalk == "left" or sidewalk == "right") then
      -- do nothing
    elseif cycleway and (cycleway == "opposite" or cycleway == "opposite_lane" or cycleway == "opposite_track" ) then
      -- do nothing
    elseif oneway_cycle and oneway_cycle == "no" then
      -- do nothing

    else -- catch all remaining-block
      if onewayClass == "yes" or onewayClass == "1" or onewayClass == "true" then
        result.backward_mode = 0
      elseif onewayClass == "-1" then
        result.forward_mode = 0
      end
    end

  end

  -- surfaces
  if surface then
    surface_speed = surface_speeds[surface]
    if surface_speed then
      result.forward_speed = math.min(result.forward_speed, surface_speed)
      result.backward_speed  = math.min(result.backward_speed, surface_speed)
    end
  end

  if not wheelchair or not ( wheelchair and (wheelchair == "yes" or wheelchair == "designated") ) then
      -- set speed to 0 for too much inclined
      if incline and incline ~= "" then
          if incline:match("^-?[0-9.]+%s?%%?$") then
              lincline = tonumber(incline:match("[0-9.]+"))
              if lincline ~= nil and lincline > maxincline then
                  result.forward_speed = 0
                  result.backward_speed = 0
              end
          end
          if (incline == "up" or incline == "down") and not (wheelchair_ramp and wheelchair_ramp == "yes") then -- is only set when not known exactly - and most people only recognize or see inclines > 3% as relevant
              result.forward_speed = 0
              result.backward_speed = 0
          end
      end
      if incline_across and incline_across ~= "" then
          if incline_across:match("^-?[0-9.]+%s?%%?$") then
              lincline = tonumber(incline_across:match("[0-9.]+"))
              if lincline ~= nil and lincline > maxincline_across then
                  result.forward_speed = 0
                  result.backward_speed = 0
              end
          end
      end

      -- set speed to 0 for too narrow:
      if width and width ~= "" then
          if width:match("^[0-9.]+%s?m?$") then
              lwidth = tonumber(width:match("^[0-9.]+"))
              if lwidth ~= nil and lwidth < minwidth then
                  result.forward_speed = 0
                  result.backward_speed = 0
              end
          elseif width:match("^[0-9.]+%s?cm$") then
              lwidth = tonumber(width:match("^[0-9.]+"))
              if lwidth ~= nil and lwidth < minwidth*100 then
                  result.forward_speed = 0
                  result.backward_speed = 0
              end
          end
      end
  end

end

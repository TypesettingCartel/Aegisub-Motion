script_name = "Aegisub-Motion"
script_description = "A set of tools for simplifying the process of creating and applying motion tracking data with Aegisub."
script_author = "torque"
script_version = "0.5.0"
local config_file = "aegisub-motion.conf"
local success, re, onetime_init, init_input, parse_input, populateInputBox, dialogPreproc, getSelInfo, spoof_table, extraLineMetrics, ensuretags, frame_by_frame, mochaRatios, possify, orginate, makexypos, clippinate, transformate, scalify, rotate, munch, cleanup, dialog_sort, readconf, writeconf, splitconf, configscope, confmaker, trimnthings, collecttrim, dcos, dacos, dsin, dasin, dtan, datan, fix, check_user_cancelled, conformdialog, makebuttons, windowerr, printmem, debug, warn, round, getvideoname, isvideo
local gui, guiconf, winpaths, encpre, global, alltags, globaltags, importanttags
require("karaskel")
require("clipboard")
success, re = pcall(require, "aegisub.re")
if not (success) then
  re = require("re")
end
onetime_init = function()
  if gui then
    return 
  end
  winpaths = not aegisub.decode_path('?data'):match('/')
  gui = {
    main = {
      linespath = {
        "textbox",
        0,
        1,
        10,
        4,
        name = "linespath",
        hint = "Paste data or the path to a file containing it. No quotes or escapes."
      },
      pref = {
        "textbox",
        0,
        14,
        10,
        3,
        name = "pref",
        hint = "The prefix",
        hint = "The directory any generated files will be written to."
      },
      preflabel = {
        "label",
        0,
        13,
        10,
        1,
        label = "                  Files will be written to this directory."
      },
      datalabel = {
        "label",
        0,
        0,
        10,
        1,
        label = "                       Paste data or enter a filepath."
      },
      optlabel = {
        "label",
        0,
        6,
        5,
        1,
        label = "Data to be applied:"
      },
      rndlabel = {
        "label",
        7,
        6,
        3,
        1,
        label = "Rounding"
      },
      xpos = {
        "checkbox",
        0,
        7,
        1,
        1,
        name = "xpos",
        value = true,
        label = "&x",
        hint = "Apply x position data to the selected lines."
      },
      ypos = {
        "checkbox",
        1,
        7,
        1,
        1,
        name = "ypos",
        value = true,
        label = "&y",
        hint = "Apply y position data to the selected lines."
      },
      origin = {
        "checkbox",
        2,
        7,
        2,
        1,
        name = "origin",
        value = false,
        label = "&Origin",
        hint = "Move the origin along with the position."
      },
      clip = {
        "checkbox",
        4,
        7,
        2,
        1,
        name = "clip",
        value = false,
        label = "&Clip",
        hint = "Move clip along with the position (note: will also be scaled and rotated if those options are selected)."
      },
      scale = {
        "checkbox",
        0,
        8,
        2,
        1,
        name = "scale",
        value = true,
        label = "&Scale",
        hint = "Apply scaling data to the selected lines."
      },
      border = {
        "checkbox",
        2,
        8,
        2,
        1,
        name = "border",
        value = true,
        label = "&Border",
        hint = "Scale border with the line (only if Scale is also selected)."
      },
      shadow = {
        "checkbox",
        4,
        8,
        2,
        1,
        name = "shadow",
        value = true,
        label = "&Shadow",
        hint = "Scale shadow with the line (only if Scale is also selected)."
      },
      blur = {
        "checkbox",
        4,
        9,
        2,
        1,
        name = "blur",
        value = true,
        label = "Bl&ur",
        hint = "Scale blur with the line (only if Scale is also selected, does not scale \\be)."
      },
      rotation = {
        "checkbox",
        0,
        9,
        3,
        1,
        name = "rotation",
        value = false,
        label = "&Rotation",
        hint = "Apply rotation data to the selected lines."
      },
      posround = {
        "intedit",
        7,
        7,
        3,
        1,
        name = "posround",
        value = 2,
        min = 0,
        max = 5,
        hint = "How many decimal places of accuracy the resulting positions should have."
      },
      sclround = {
        "intedit",
        7,
        8,
        3,
        1,
        name = "sclround",
        value = 2,
        min = 0,
        max = 5,
        hint = "How many decimal places of accuracy the resulting scales should have (also applied to border, shadow, and blur)."
      },
      rotround = {
        "intedit",
        7,
        9,
        3,
        1,
        name = "rotround",
        value = 2,
        min = 0,
        max = 5,
        hint = "How many decimal places of accuracy the resulting rotations should have."
      },
      wconfig = {
        "checkbox",
        0,
        11,
        4,
        1,
        name = "wconfig",
        value = false,
        label = "&Write config",
        hint = "Write current settings to the configuration file."
      },
      relative = {
        "checkbox",
        4,
        11,
        3,
        1,
        name = "relative",
        value = true,
        label = "R&elative",
        hint = "Start frame should be relative to the line's start time rather than to the start time of all selected lines"
      },
      stframe = {
        "intedit",
        7,
        11,
        3,
        1,
        name = "stframe",
        value = 1,
        hint = "Frame used as the starting point for the tracking data. \"-1\" corresponds to the last frame."
      },
      linear = {
        "checkbox",
        4,
        12,
        2,
        1,
        name = "linear",
        value = false,
        label = "Li&near",
        hint = "Use transforms and \\move to create a linear transition, instead of frame-by-frame."
      },
      sortd = {
        "dropdown",
        5,
        5,
        4,
        1,
        name = "sortd",
        hint = "Sort lines by",
        value = "Default",
        items = {
          "Default",
          "Time"
        },
        hint = "The order to sort the lines after they have been tracked."
      },
      sortlabel = {
        "label",
        1,
        5,
        4,
        1,
        name = "sortlabel",
        label = "      Sort Method:"
      }
    },
    clip = {
      clippath = {
        "textbox",
        0,
        1,
        10,
        4,
        name = "clippath",
        hint = "Paste data or the path to a file containing it. No quotes or escapes."
      },
      label = {
        "label",
        0,
        0,
        10,
        1,
        label = "                 Paste data or enter a filepath."
      },
      xpos = {
        "checkbox",
        0,
        6,
        1,
        1,
        name = "xpos",
        value = true,
        label = "&x",
        hint = "Apply x position data to the selected lines."
      },
      ypos = {
        "checkbox",
        1,
        6,
        1,
        1,
        name = "ypos",
        value = true,
        label = "&y",
        hint = "Apply y position data to the selected lines."
      },
      scale = {
        "checkbox",
        0,
        7,
        2,
        1,
        name = "scale",
        value = true,
        label = "&Scale"
      },
      rotation = {
        "checkbox",
        0,
        8,
        3,
        1,
        name = "rotation",
        value = false,
        label = "&Rotation"
      },
      relative = {
        "checkbox",
        4,
        6,
        3,
        1,
        name = "relative",
        value = true,
        label = "R&elative"
      },
      stframe = {
        "intedit",
        7,
        6,
        3,
        1,
        name = "stframe",
        value = 1
      }
    },
    t = {
      vidlabel = {
        "label",
        0,
        0,
        30,
        1,
        label = "The path to the loaded video"
      },
      input = {
        "textbox",
        0,
        1,
        30,
        1,
        name = "input"
      },
      idxlabel = {
        "label",
        0,
        2,
        30,
        1,
        label = "The path to the index file."
      },
      index = {
        "textbox",
        0,
        3,
        30,
        1,
        name = "index"
      },
      sflabel = {
        "label",
        0,
        4,
        15,
        1,
        label = "Start frame"
      },
      startf = {
        "intedit",
        0,
        5,
        15,
        1,
        name = "startf"
      },
      eflabel = {
        "label",
        15,
        4,
        15,
        1,
        label = "End frame"
      },
      endf = {
        "intedit",
        15,
        5,
        15,
        1,
        name = "endf"
      },
      oplabel = {
        "label",
        0,
        6,
        30,
        1,
        label = "Video file to be written"
      },
      output = {
        "textbox",
        0,
        7,
        30,
        1,
        name = "output"
      }
    }
  }
  for _, dlg in pairs(gui) do
    conformdialog(dlg)
  end
  encpre = {
    x264 = '"#{encbin}" --crf 16 --tune fastdecode -i 250 --fps 23.976 --sar 1:1 --index "#{prefix}#{index}.index" --seek #{startf} --frames #{lenf} -o "#{prefix}#{output}[#{startf}-#{endf}].mp4" "#{inpath}#{input}"',
    ffmpeg = '"#{encbin}" -ss #{startt} -t #{lent} -sn -i "#{inpath}#{input}" "#{prefix}#{output}[#{startf}-#{endf}]-%%05d.jpg"',
    avs2yuv = 'echo FFVideoSource("#{inpath}#{input}",cachefile="#{prefix}#{index}.index").trim(#{startf},#{endf}).ConvertToRGB.ImageWriter("#{prefix}#{output}-[#{startf}-#{endf}]\\",type="png").ConvertToYV12 > "#{prefix}encode.avs"#{nl}mkdir "#{prefix}#{output}-[#{startf}-#{endf}]"#{nl}"#{encbin}" -o NUL "#{prefix}encode.avs"#{nl}del "#{prefix}encode.avs"'
  }
  do
    global = {
      prefix = "?video",
      encoder = "x264",
      encbin = "",
      gui_trim = false,
      autocopy = true,
      acfilter = true,
      delsourc = false
    }
    global.enccom = encpre[global.encoder] or ""
  end
  gui.conf = table.copy_deep(gui.main)
  do
    local _with_0 = gui.conf
    _with_0.clippath, _with_0.linespath, _with_0.wconfig = nil
    _with_0.encbin, _with_0.pref = table.copy(_with_0.pref), nil
    _with_0.encbin.value, _with_0.encbin.name = global.encbin, "encbin"
    _with_0.encbin.hint = "The full path to the encoder binary (unless it's in your PATH)"
    _with_0.datalabel.label = "       Enter the path to your prefix here (include trailing slash)."
    _with_0.preflabel.label = "First box: path to encoder binary; second box: encoder command."
  end
  for k, e in pairs(conformdialog({
    gui_trim = {
      "checkbox",
      3,
      22,
      4,
      1,
      value = global.trim,
      label = "Enable trim GUI",
      name = "gui_trim",
      hint = "Set whether or not the trim gui should appear."
    },
    enccom = {
      "textbox",
      0,
      17,
      10,
      4,
      value = global.enccom,
      name = "enccom",
      hint = "The encoding command that will be used. If you change this, set the preset to \"custom\"."
    },
    prefix = {
      "textbox",
      0,
      1,
      10,
      4,
      value = global.prefix,
      name = "prefix",
      hint = "The folder to which all generated files will be written."
    },
    encoder = {
      "dropdown",
      0,
      11,
      2,
      1,
      value = global.encoder,
      name = "encoder",
      items = {
        "x264",
        "ffmpeg",
        "avs2yuv",
        "custom"
      },
      hint = "Choose one of the encoding command presets (set to custom if you have made any modifications to the defaults)"
    },
    delsourc = {
      "checkbox",
      0,
      21,
      2,
      1,
      value = global.delsourc,
      label = "Delete",
      name = "delsourc",
      hint = "Delete the source lines instead of commenting them out."
    },
    autocopy = {
      "checkbox",
      3,
      21,
      3,
      1,
      value = global.autocopy,
      label = "Autocopy",
      name = "autocopy",
      hint = "Automatically copy the contents of the clipboard into the tracking data box on script run."
    },
    acfilter = {
      "checkbox",
      7,
      21,
      3,
      1,
      value = global.acfilter,
      label = "Copy Filter",
      name = "acfilter",
      hint = "Only automatically copy the clipboard if it appears to contain tracking data."
    }
  })) do
    gui.conf[k] = e
  end
  alltags = {
    xscl = [[\fscx([%d%.]+)]],
    yscl = [[\fscy([%d%.]+)]],
    ali = [[\an([1-9])]],
    zrot = [[\frz?([%-%d%.]+)]],
    bord = [[\bord([%d%.]+)]],
    xbord = [[\xbord([%d%.]+)]],
    ybord = [[\ybord([%d%.]+)]],
    shad = [[\shad([%-%d%.]+)]],
    xshad = [[\xshad([%-%d%.]+)]],
    yshad = [[\yshad([%-%d%.]+)]],
    reset = [[\r([^\\}]*)]],
    alpha = [[\alpha&H(%x%x)&]],
    l1a = [[\1a&H(%x%x)&]],
    l2a = [[\2a&H(%x%x)&]],
    l3a = [[\3a&H(%x%x)&]],
    l4a = [[\4a&H(%x%x)&]],
    l1c = [[\c&H(%x+)&]],
    l1c2 = [[\1c&H(%x+)&]],
    l2c = [[\2c&H(%x+)&]],
    l3c = [[\3c&H(%x+)&]],
    l4c = [[\4c&H(%x+)&]],
    clip = [[\clip%((.-)%)]],
    iclip = [[\iclip%((.-)%)]],
    be = [[\be([%d%.]+)]],
    blur = [[\blur([%d%.]+)]],
    fax = [[\fax([%-%d%.]+)]],
    fay = [[\fay([%-%d%.]+)]]
  }
  globaltags = {
    fad = "\\fad%([%d]+,[%d]+%)",
    fade = "\\fade%(([%d]+),([%d]+),([%d]+),([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+)%)",
    clip = ""
  }
  importanttags = {
    ['\\fscx'] = {
      opt = {
        a = "scale",
        b = "scale"
      },
      key = "scale_x",
      skip = 0
    },
    ['\\fscy'] = {
      opt = {
        a = "scale",
        b = "scale"
      },
      key = "scale_y",
      skip = 0
    },
    ['\\bord'] = {
      opt = {
        a = "border",
        b = "scale"
      },
      key = "outline",
      skip = 0
    },
    ['\\shad'] = {
      opt = {
        a = "shadow",
        b = "scale"
      },
      key = "shadow",
      skip = 0
    },
    ['\\frz'] = {
      opt = {
        a = "rotation",
        b = "rotation"
      },
      key = "angle"
    }
  }
  guiconf = {
    main = {
      "sortd",
      "xpos",
      "ypos",
      "origin",
      "clip",
      "posround",
      "scale",
      "border",
      "shadow",
      "blur",
      "sclround",
      "rotation",
      "rotround",
      "relative",
      "stframe",
      "linear"
    },
    clip = {
      "xpos",
      "ypos",
      "scale",
      "rotation",
      "relative",
      "stframe"
    }
  }
  for k, v in pairs(global) do
    table.insert(guiconf, k)
  end
end
init_input = function(sub, sel)
  onetime_init()
  local setundo = aegisub.set_undo_point
  printmem("GUI startup")
  local conf, accd = dialogPreproc(sub, sel)
  local btns = {
    main = makebuttons({
      {
        ok = "&Go"
      },
      {
        clip = "&\\clip..."
      },
      {
        cancel = "&Abort"
      }
    }),
    clip = makebuttons({
      {
        ok = "&Go clippin'"
      },
      {
        cancel = "&Cancel"
      },
      {
        abort = "&Abort"
      }
    })
  }
  local dlg = "main"
  while true do
    local _continue_0 = false
    repeat
      local clipconf, button, config
      do
        local _with_0 = btns[dlg]
        button, config = aegisub.dialog.display(gui[dlg], _with_0.__list, _with_0.__namedlist)
      end
      local _exp_0 = button
      if btns.main.clip == _exp_0 then
        dlg = "clip"
        _continue_0 = true
        break
      elseif btns.main.ok == _exp_0 or btns.clip.ok == _exp_0 then
        clipconf = clipconf or { }
        local _list_0 = guiconf.clip
        for _index_0 = 1, #_list_0 do
          local field = _list_0[_index_0]
          if clipconf[field] == nil then
            clipconf[field] = gui.clip[field].value
          end
        end
        if config.linespath == "" then
          config.linespath = false
        end
        if config.wconfig then
          writeconf(conf, {
            main = config,
            clip = clipconf,
            global = global
          })
        end
        if config.stframe == 0 then
          config.stframe = 1
        end
        if clipconf.stframe == 0 then
          clipconf.stframe = 1
        end
        if config.xpos or config.ypos then
          config.position = true
        end
        if clipconf.xpos or clipconf.ypos then
          clipconf.position = true
        end
        config.yconst = not config.ypos
        config.xconst = not config.xpos
        clipconf.yconst = not clipconf.ypos
        clipconf.xconst = not clipconf.xpos
        if config.clip then
          clipconf.stframe = config.stframe
        end
        if config.clip or clipconf.clippath then
          config.linear = false
        end
        if clipconf.clippath == "" or clipconf.clippath == nil then
          if not config.linespath then
            windowerr(false, "No tracking data was provided.")
          end
          clipconf.clippath = false
        else
          config.clip = false
        end
        aegisub.progress.title("Mincing Gerbils")
        printmem("Go")
        local newsel = frame_by_frame(sub, accd, config, clipconf)
        if munch(sub, newsel) then
          newsel = { }
          for x = 1, #sub do
            if tostring(sub[x].effect):match("^aa%-mou") then
              table.insert(newsel, x)
            end
          end
        end
        aegisub.progress.title("Reformatting Gerbils")
        cleanup(sub, newsel, config)
        break
      else
        if dlg == 'main' or button == btns.clip.abort then
          aegisub.progress.task("ABORT")
          aegisub.cancel()
        else
          dlg = "main"
          _continue_0 = true
          break
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  setundo("Motion Data")
  return printmem("Closing")
end
parse_input = function(mocha_table, input, shx, shy)
  printmem("Start of input parsing")
  local sect, care = 0, 0
  local ftab
  ftab, mocha_table.xpos, mocha_table.ypos, mocha_table.xscl, mocha_table.yscl, mocha_table.zrot = { }, { }, { }, { }, { }, { }
  local datams = io.open(input, "r")
  local datastring = ""
  if datams then
    for line in datams:lines() do
      line = line:gsub("[\r\n]*", "")
      datastring = datastring .. (line .. "\n")
      table.insert(ftab, line)
    end
    datams:close()
  else
    input = input:gsub("[\r]*", "")
    datastring = input
    ftab = input:split("\n")
  end
  local _list_0 = {
    "Position",
    "Scale",
    "Rotation",
    "Source Width\t%d+",
    "Source Height\t%d+",
    "Adobe After Effects 6.0 Keyframe Data"
  }
  for _index_0 = 1, #_list_0 do
    local pattern = _list_0[_index_0]
    windowerr(datastring:match(pattern), 'Error parsing data. "After Effects Transform Data [anchor point, position, scale and rotation]" expected.')
  end
  local xmult = shx / tonumber(datastring:match("Source Width\t([0-9]+)"))
  local ymult = shy / tonumber(datastring:match("Source Height\t([0-9]+)"))
  do
    for keys, valu in ipairs(ftab) do
      if not valu:match("^\t") then
        local _exp_0 = valu
        if "Position" == _exp_0 then
          sect = 1
        elseif "Scale" == _exp_0 then
          sect = sect + 2
        elseif "Rotation" == _exp_0 then
          sect = sect + 4
        end
      else
        local val = valu:split("\t")
        local _exp_0 = sect
        if 1 == _exp_0 then
          if valu:match("%d") then
            table.insert(mocha_table.xpos, tonumber(val[2]) * xmult)
            table.insert(mocha_table.ypos, tonumber(val[3]) * ymult)
          end
        elseif 3 == _exp_0 then
          if valu:match("%d") then
            table.insert(mocha_table.xscl, tonumber(val[2]))
            table.insert(mocha_table.yscl, tonumber(val[3]))
          end
        elseif 7 == _exp_0 then
          if valu:match("%d") then
            table.insert(mocha_table.zrot, -tonumber(val[2]))
          end
        end
      end
    end
    mocha_table.flength = #mocha_table.xpos
    local _list_1 = {
      #mocha_table.ypos,
      #mocha_table.xscl,
      #mocha_table.yscl,
      #mocha_table.zrot
    }
    for _index_0 = 1, #_list_1 do
      local x = _list_1[_index_0]
      windowerr(x == mocha_table.flength, 'Error parsing data. "After Effects Transform Data [anchor point, position, scale and rotation]" expected.')
    end
  end
  for prefix, field in pairs({
    x = "xpos",
    y = "ypos",
    xs = "xscl",
    ys = "yscl",
    r = "zrot"
  }) do
    local dummytab = table.copy(mocha_table[field])
    table.sort(dummytab)
    mocha_table[prefix .. "min"] = dummytab[1]
    mocha_table[prefix .. "max"] = dummytab[#dummytab]
    debug("%smax: %g; %smin: %g", prefix, mocha_table[prefix .. "max"], prefix, mocha_table[prefix .. "min"])
  end
  return printmem("End of input parsing")
end
populateInputBox = function()
  if global.autocopy then
    local paste = clipboard.get() or ""
    if global.acfilter then
      if paste:match("^Adobe After Effects 6.0 Keyframe Data") then
        gui.main.linespath.value = paste
      end
    else
      gui.main.linespath.value = paste
    end
  end
end
dialogPreproc = function(sub, sel)
  aegisub.progress.title("Selecting Gerbils")
  local accd = getSelInfo(sub, sel)
  local _list_0 = {
    gui.main.stframe,
    gui.clip.stframe
  }
  for _index_0 = 1, #_list_0 do
    local f = _list_0[_index_0]
    f.min = -accd.totframes
    f.max = accd.totframes
  end
  local conf
  do
    conf = configscope()
    if conf then
      if not readconf(conf, {
        main = gui.main,
        clip = gui.clip,
        global = global
      }) then
        warn("Failed to read config!")
      end
    end
  end
  populateInputBox()
  gui.main.pref.value = aegisub.decode_path(global.prefix)
  return conf, accd
end
getSelInfo = function(sub, sel)
  printmem("Initial")
  local strt
  for x = 1, #sub do
    if sub[x].class == "dialogue" then
      strt = x - 1
      break
    end
  end
  aegisub.progress.title("Collecting Gerbils")
  local _ = nil
  local accd = { }
  accd.meta, accd.styles = karaskel.collect_head(sub, false)
  accd.lines = { }
  accd.endframe = aegisub.frame_from_ms(sub[sel[1]].end_time)
  accd.startframe = aegisub.frame_from_ms(sub[sel[1]].start_time)
  local numlines = #sel
  for i = #sel, 1, -1 do
    do
      local line = sub[sel[i]]
      line.num = sel[i]
      line.hnum = line.num - strt
      karaskel.preproc_line(sub, accd.meta, accd.styles, line)
      if not line.effect then
        line.effect = ""
      end
      sub[sel[i]] = extraLineMetrics(line)
      line.startframe = aegisub.frame_from_ms(line.start_time)
      line.endframe = aegisub.frame_from_ms(line.end_time)
      line.is_comment = line.comment == true
      if line.startframe < accd.startframe then
        debug("Line %d: startframe changed from %d to %d", line.num - strt, accd.startframe, line.startframe)
        accd.startframe = line.startframe
      end
      if line.endframe > accd.endframe then
        debug("Line %d: endframe changed from %d to %d", line.num - strt, accd.endframe, line.endframe)
        accd.endframe = line.endframe
      end
      if line.endframe - line.startframe > 1 then
        table.insert(accd.lines, line)
      end
    end
  end
  accd.totframes = accd.endframe - accd.startframe
  assert(#accd.lines > 0, "You have to select at least one line that is longer than one frame long.")
  printmem("End of preproc loop")
  return accd
end
spoof_table = function(parsed_table, opts, len)
  do
    local _with_0 = parsed_table
    len = len or #_with_0.xpos
    _with_0.xpos = _with_0.xpos or { }
    _with_0.ypos = _with_0.ypos or { }
    _with_0.xscl = _with_0.xscl or { }
    _with_0.yscl = _with_0.yscl or { }
    _with_0.zrot = _with_0.zrot or { }
    if not opts.position then
      for k = 1, len do
        _with_0.xpos[k], _with_0.ypos[k] = 0, 0
      end
    else
      if opts.yconst then
        for k = 1, len do
          _with_0.ypos[k] = 0
        end
      end
      if opts.xconst then
        for k = 1, len do
          _with_0.xpos[k] = 0
        end
      end
    end
    if not opts.scale then
      for k = 1, len do
        _with_0.xscl[k], _with_0.yscl[k] = 100, 100
      end
    end
    if not opts.rotation then
      for k = 1, len do
        _with_0.zrot[k] = 0
      end
    end
    _with_0.s = 1
    if opts.reverse then
      _with_0.s = _with_0.flength
    end
    return _with_0
  end
end
extraLineMetrics = function(line)
  line.trans = { }
  local fstart, fend = line.text:match("\\fad%((%d+),(%d+)%)")
  line.text = line.text:gsub(globaltags.fad, "")
  local lextrans
  lextrans = function(trans)
    local t_start, t_end, t_exp, t_eff = trans:sub(2, -2):match("([%-%d]+),([%-%d]+),([%d%.]*),?(.+)")
    t_exp = tonumber(t_exp) or 1
    table.insert(line.trans, {
      tonumber(t_start),
      tonumber(t_end),
      t_exp,
      t_eff
    })
    return debug("Line %d: \\t(%g,%g,%g,%s) found", line.hnum, t_start, t_end, t_exp, t_eff)
  end
  local alphafunc
  alphafunc = function(alpha)
    local str = ""
    if tonumber(fstart) > 0 then
      str = str .. ("\\alpha&HFF&\\t(%d,%s,1,\\alpha%s)"):format(0, fstart, alpha)
    end
    if tonumber(fend) > 0 then
      str = str .. ("\\t(%d,%d,1,\\alpha&HFF&)"):format(line.duration - tonumber(fend), line.duration)
    end
    return str
  end
  line.text = line.text:gsub("^{(.-)}", function(block1)
    if fstart then
      local replaced = false
      block1 = block1:gsub("\\alpha(&H%x%x&)", function(alpha)
        replaced = true
        return alphafunc(alpha)
      end)
      if not (replaced) then
        block1 = block1 .. alphafunc(alpha_from_style(line.styleref.color1))
      end
    else
      block1 = block1:gsub("\\fade%(([%d]+),([%d]+),([%d]+),([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+)%)", function(a, b, c, d, e, f, g)
        return ("\\alpha&H%02X&\\t(%s,%s,1,\\alpha&H%02X&)\\t(%s,%s,1,\\alpha&H%02X&)"):format(a, d, e, b, f, g, c)
      end)
    end
    block1:gsub("\\t(%b())", lextrans)
    return '{' .. block1 .. '}'
  end)
  line.text = line.text:gsub("([^^])({.-})", function(i, block)
    if fstart then
      block = block:gsub("\\alpha(&H%x%x&)", alphafunc)
    end
    block:gsub("\\t(%b())", lextrans)
    return i .. block
  end)
  line.text = line.text:gsub("\\(i?clip)(%b())", function(clip, points)
    line.clips = clip
    points = points:gsub("([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)", function(leftX, topY, rightX, botY)
      return ("m %s %s l %s %s %s %s %s %s"):format(leftX, topY, rightX, topY, rightX, botY, leftX, botY)
    end, 1)
    points:gsub("%(([%d]*),?(.-)%)", function(scl, clip)
      do
        line.sclip = tonumber(scl)
        if line.sclip then
          line.rescaleclip = true
        else
          line.sclip = 1
        end
      end
      line.clip = clip
    end, 1)
    return '\\' .. clip .. '(' .. line.clip .. ')'
  end)
  return line
end
ensuretags = function(line, opts, styles, dim)
  do
    local _with_0 = line
    if _with_0.margin_v ~= 0 then
      _with_0._v = _with_0.margin_v
    else
      _with_0._v = _with_0.styleref.margin_v
    end
    if _with_0.margin_l ~= 0 then
      _with_0._l = _with_0.margin_l
    else
      _with_0._l = _with_0.styleref.margin_l
    end
    if _with_0.margin_r ~= 0 then
      _with_0._r = _with_0.margin_r
    else
      _with_0._r = _with_0.styleref.margin_r
    end
    _with_0.ali = _with_0.text:match("\\an([1-9])") or _with_0.styleref.align
    _with_0.xpos, _with_0.ypos = _with_0.text:match("\\pos%(([%-%d%.]+),([%-%d%.]+)%)")
    if not _with_0.xpos then
      _with_0.xpos = fix.xpos[_with_0.ali % 3 + 1](dim.x, _with_0._l, _with_0._r)
      _with_0.ypos = fix.ypos[math.ceil(_with_0.ali / 3)](dim.y, _with_0._v)
      _with_0.text = ("{\\pos(%d,%d)}%s"):format(_with_0.xpos, _with_0.ypos, _with_0.text):gsub("^({.-)}{", "%1")
    end
    _with_0.oxpos, _with_0.oypos = _with_0.text:match("\\org%(([%-%d%.]+),([%-%d%.]+)%)")
    _with_0.oxpos = _with_0.oxpos or _with_0.xpos
    _with_0.oypos = _with_0.oypos or _with_0.ypos
    _with_0.origindx = _with_0.xpos - _with_0.oxpos
    _with_0.origindy = _with_0.ypos - _with_0.oypos
    local mergedtext = _with_0.text:gsub("}{", "")
    local ovr_at_start = mergedtext:match("^{(.-)}")
    local reformatblock
    reformatblock = function(block, rstyle)
      if rstyle == nil then
        rstyle = nil
      end
      for tag, str in pairs(importanttags) do
        if opts[str.opt.a] and opts[str.opt.b] then
          if not ovr_at_start or not ovr_at_start:match(tag .. "[%-%d%.]+") then
            local scheck = line.styleref[str.key]
            local srepl
            if rstyle then
              srepl = rstyle[str.key]
            else
              srepl = scheck
            end
            if tonumber(scheck) ~= str.skip then
              block = block .. (tag .. "%g"):format(srepl)
            end
          end
        end
      end
      return block
    end
    local block = reformatblock("")
    _with_0.text = ("{%s}%s"):format(block, _with_0.text)
    if ovr_at_start and block:len() > 0 then
      _with_0.text = _with_0.text:gsub("^({.-)}{", "%1")
    end
    _with_0.text = _with_0.text:gsub("{([^}]*\\r)([^\\}]*)(.-)}", function(before, rstyle, rest)
      local styletab = styles[rstyle] or _with_0.styleref
      return "{" .. before .. rstyle .. reformatblock("", styletab) .. rest .. "}"
    end)
    return _with_0
  end
end
frame_by_frame = function(sub, accd, opts, clipopts)
  local newlines, operations, mocha, clipa, dim, _, main, float2str, linearmodo, nonlinearmodo
  newlines = { }
  operations = { }
  mocha = { }
  clipa = { }
  dim = {
    x = accd.meta.res_x,
    y = accd.meta.res_y
  }
  _ = nil
  main = function()
    printmem("Start of main loop")
    local calc_abs_frame
    calc_abs_frame = function(opts)
      if opts.stframe >= 0 then
        return opts.stframe
      else
        return accd.totframes + opts.stframe + 1
      end
    end
    if opts.linespath then
      parse_input(mocha, opts.linespath, accd.meta.res_x, accd.meta.res_y)
      assert(accd.totframes == mocha.flength, ("Number of frames selected (%d) does not match parsed line tracking data length (%d)."):format(accd.totframes, mocha.flength))
      spoof_table(mocha, opts)
      if not opts.relative then
        mocha.start = calc_abs_frame(opts)
      end
      if opts.clip then
        clipa = mocha
      end
    end
    if clipopts.clippath then
      parse_input(clipa, clipopts.clippath, accd.meta.res_x, accd.meta.res_y)
      assert(accd.totframes == clipa.flength, ("Number of frames selected (%d) does not match parsed clip tracking data length (%d)."):format(accd.totframes, clipa.flength))
      opts.linear = false
      opts.clip = true
      spoof_table(clipa, clipopts)
      if not opts.linespath then
        spoof_table(mocha, opts, #clipa.xpos)
      end
      if not clipopts.relative then
        clipa.start = calc_abs_frame(clipopts)
      end
    end
    local _list_0 = accd.lines
    for _index_0 = 1, #_list_0 do
      local v = _list_0[_index_0]
      local derp = sub[v.num]
      derp.comment = true
      sub[v.num] = derp
      if not v.is_comment then
        v.comment = false
      end
    end
    if opts.position then
      operations["(\\pos)%(([%-%d%.]+,[%-%d%.]+)%)"] = possify
      if opts.origin then
        operations["(\\org)%(([%-%d%.]+,[%-%d%.]+)%)"] = orginate
      end
    end
    if opts.scale then
      operations["(\\fsc[xy])([%d%.]+)"] = scalify
      if opts.border then
        operations["(\\[xy]?bord)([%d%.]+)"] = scalify
      end
      if opts.shadow then
        operations["(\\[xy]?shad)([%-%d%.]+)"] = scalify
      end
      if opts.blur then
        operations["(\\blur)([%d%.]+)"] = scalify
      end
    end
    if opts.rotation then
      operations["(\\frz?)([%-%d%.]+)"] = rotate
    end
    printmem("End of table insertion")
    local modo
    if opts.linear then
      modo = linearmodo
    else
      modo = nonlinearmodo
    end
    local _list_1 = accd.lines
    for _index_0 = 1, #_list_1 do
      local currline = _list_1[_index_0]
      do
        printmem("Outer loop")
        currline.rstartf = currline.startframe - accd.startframe + 1
        currline.rendf = currline.endframe - accd.startframe
        if opts.clip and currline.clip then
          clipa.clipme = true
        end
        currline.effect = "aa-mou" .. currline.effect
        local calc_rel_frame
        calc_rel_frame = function(opts)
          if tonumber(opts.stframe) >= 0 then
            return currline.rstartf + opts.stframe - 1
          else
            return currline.rendf + opts.stframe + 1
          end
        end
        if opts.relative then
          mocha.start = calc_rel_frame(opts)
        end
        if clipopts.relative and clipa.clipme then
          clipa.start = calc_rel_frame(clipopts)
        end
        ensuretags(currline, opts, accd.styles, dim)
        currline.alpha = -datan(currline.ypos - mocha.ypos[mocha.start], currline.xpos - mocha.xpos[mocha.start])
        if opts.origin then
          currline.beta = -datan(currline.oypos - mocha.ypos[mocha.start], currline.oxpos - mocha.xpos[mocha.start])
        end
        currline.orgtext = currline.text
        modo(currline)
      end
    end
    for x = #sub, 1, -1 do
      if tostring(sub[x].effect):match("^aa%-mou") then
        table.insert(newlines, x)
      end
    end
    return newlines
  end
  float2str = function(f)
    return ("%g"):format(round(f, opts.posround))
  end
  linearmodo = function(currline)
    do
      local _with_0 = currline
      local one = aegisub.ms_from_frame(aegisub.frame_from_ms(_with_0.start_time))
      local two = aegisub.ms_from_frame(aegisub.frame_from_ms(currline.start_time) + 1)
      local three = aegisub.ms_from_frame(aegisub.frame_from_ms(currline.end_time) - 1)
      local four = aegisub.ms_from_frame(aegisub.frame_from_ms(_with_0.end_time))
      local maths = math.floor(0.5 * (one + two) - currline.start_time)
      local mathsanswer = math.floor(0.5 * (three + four) - currline.start_time)
      local posmatch
      posmatch, _ = "(\\pos)%(([%-%d%.]+,[%-%d%.]+)%)"
      if operations[posmatch] then
        _with_0.text = _with_0.text:gsub(posmatch, function(tag, val)
          local exes, whys = { }, { }
          local _list_0 = {
            _with_0.rstartf,
            _with_0.rendf
          }
          for _index_0 = 1, #_list_0 do
            local x = _list_0[_index_0]
            local cx, cy = val:match("([%-%d%.]+),([%-%d%.]+)")
            mochaRatios(mocha, x)
            cx = (cx + mocha.diffx) * mocha.ratx + (1 - mocha.ratx) * mocha.currx
            cy = (cy + mocha.diffy) * mocha.raty + (1 - mocha.raty) * mocha.curry
            local r = math.sqrt((cx - mocha.currx) ^ 2 + (cy - mocha.curry) ^ 2)
            cx = mocha.currx + r * dcos(_with_0.alpha + mocha.zrotd)
            cy = mocha.curry - r * dsin(_with_0.alpha + mocha.zrotd)
            table.insert(exes, float2str(cx))
            table.insert(whys, float2str(cy))
          end
          local s = ("\\move(%s,%s,%s,%s,%d,%d)"):format(exes[1], whys[1], exes[2], whys[2], maths, mathsanswer)
          debug("%s", s)
          return s
        end)
        _, operations[posmatch] = operations[posmatch], nil
      end
      for pattern, func in pairs(operations) do
        check_user_cancelled()
        _with_0.text = _with_0.text:gsub(pattern, function(tag, val)
          local values = { }
          local _list_0 = {
            _with_0.rstartf,
            _with_0.rendf
          }
          for _index_0 = 1, #_list_0 do
            local x = _list_0[_index_0]
            mochaRatios(mocha, x)
            table.insert(values, func(val, currline, mocha, opts, tag))
          end
          return ("%s%g\\t(%d,%d,1,%s%g)"):format(tag, values[1], maths, mathsanswer, tag, values[2])
        end)
      end
      sub[_with_0.num] = currline
      operations[posmatch] = _
      return _with_0
    end
  end
  nonlinearmodo = function(currline)
    do
      local _with_0 = currline
      for x = _with_0.rendf, _with_0.rstartf, -1 do
        printmem("Inner loop")
        debug("Round %d", x)
        aegisub.progress.title(("Processing frame %g/%g"):format(x, _with_0.rendf - _with_0.rstartf + 1))
        aegisub.progress.set((x - _with_0.rstartf) / (_with_0.rendf - _with_0.rstartf) * 100)
        check_user_cancelled()
        _with_0.start_time = aegisub.ms_from_frame(accd.startframe + x - 1)
        _with_0.end_time = aegisub.ms_from_frame(accd.startframe + x)
        if not _with_0.is_comment then
          _with_0.time_delta = _with_0.start_time - aegisub.ms_from_frame(accd.startframe)
          local _list_0 = _with_0.trans
          for _index_0 = 1, #_list_0 do
            local kv = _list_0[_index_0]
            _with_0.text = transformate(currline, kv)
            check_user_cancelled()
          end
          mochaRatios(mocha, x)
          for pattern, func in pairs(operations) do
            _with_0.text = _with_0.text:gsub(pattern, function(tag, val)
              return tag .. func(val, currline, mocha, opts, tag)
            end)
            check_user_cancelled()
          end
          if clipa.clipme then
            _with_0.text = _with_0.text:gsub("\\i?clip%b()", function(a)
              return clippinate(currline, clipa, x), 1
            end)
          end
          _with_0.text = _with_0.text:gsub('\1', "")
        end
        sub.insert(_with_0.num + 1, currline)
        _with_0.text = _with_0.orgtext
      end
      if global.delsourc then
        sub.delete(_with_0.num)
      end
      return _with_0
    end
  end
  return main()
end
mochaRatios = function(mocha, x)
  do
    local _with_0 = mocha
    _with_0.ratx = _with_0.xscl[x] / _with_0.xscl[_with_0.start]
    _with_0.raty = _with_0.yscl[x] / _with_0.yscl[_with_0.start]
    _with_0.diffx = _with_0.xpos[x] - _with_0.xpos[_with_0.start]
    _with_0.diffy = _with_0.ypos[x] - _with_0.ypos[_with_0.start]
    _with_0.zrotd = _with_0.zrot[x] - _with_0.zrot[_with_0.start]
    _with_0.currx = _with_0.xpos[x]
    _with_0.curry = _with_0.ypos[x]
    return _with_0
  end
end
possify = function(pos, line, mocha, opts)
  local oxpos, oypos = pos:match("([%-%d%.]+),([%-%d%.]+)")
  local nxpos, nypos = makexypos(tonumber(oxpos), tonumber(oypos), mocha)
  local r = math.sqrt((nxpos - mocha.currx) ^ 2 + (nypos - mocha.curry) ^ 2)
  nxpos = mocha.currx + r * dcos(line.alpha + mocha.zrotd)
  nypos = mocha.curry - r * dsin(line.alpha + mocha.zrotd)
  debug("pos: (%f,%f) -> (%f,%f)", oxpos, oypos, nxpos, nypos)
  return ("(%g,%g)"):format(round(nxpos, opts.posround), round(nypos, opts.posround))
end
orginate = function(opos, line, mocha, opts)
  local oxpos, oypos = opos:match("([%-%d%.]+),([%-%d%.]+)")
  local nxpos, nypos = makexypos(tonumber(oxpos), tonumber(oypos), mocha)
  debug("org: (%f,%f) -> (%f,%f)", oxpos, oypos, nxpos, nypos)
  return ("(%g,%g)"):format(round(nxpos, opts.posround), round(nypos, opts.posround))
end
makexypos = function(xpos, ypos, mocha)
  local nxpos = (xpos + mocha.diffx) * mocha.ratx + (1 - mocha.ratx) * mocha.currx
  local nypos = (ypos + mocha.diffy) * mocha.raty + (1 - mocha.raty) * mocha.curry
  return nxpos, nypos
end
clippinate = function(line, clipa, iter)
  local cx, cy, ratx, raty, diffrz
  do
    cx, cy = clipa.xpos[iter], clipa.ypos[iter]
    ratx = clipa.xscl[iter] / clipa.xscl[clipa.start]
    raty = clipa.yscl[iter] / clipa.yscl[clipa.start]
    diffrz = clipa.zrot[iter] - clipa.zrot[clipa.start]
  end
  debug("cx: %f cy: %frx: %f ry: %f\nfrz: %f\n", cx, cy, ratx, raty, diffrz)
  local sclfac = 2 ^ (line.sclip - 1)
  local clip = line.clip:gsub("([%.%d%-]+) ([%.%d%-]+)", function(x, y)
    local xo, yo = x, y
    x = (tonumber(x) - clipa.xpos[clipa.start] * sclfac) * ratx
    y = (tonumber(y) - clipa.ypos[clipa.start] * sclfac) * raty
    local r = math.sqrt(x ^ 2 + y ^ 2)
    local alpha = datan(y, x)
    x = cx * sclfac + r * dcos(alpha - diffrz)
    y = cy * sclfac + r * dsin(alpha - diffrz)
    debug("Clip: %d %d -> %d %d", xo, yo, x, y)
    if line.rescaleclip then
      x = x * (1024 / sclfac)
      y = y * (1024 / sclfac)
    end
    return ("%d %d"):format(round(x), round(y))
  end)
  local scale
  if line.rescaleclip then
    scale = "11,"
  else
    scale = ""
  end
  return ("\\%s(%s)"):format(line.clips, scale .. clip)
end
transformate = function(line, trans)
  local t_s = trans[1] - line.time_delta
  local t_e = trans[2] - line.time_delta
  debug("Transform: %d,%d -> %d,%d", trans[1], trans[2], t_s, t_e)
  return line.text:gsub("\\t%b()", ("\\%st(%d,%d,%g,%s)"):format(string.char(1), t_s, t_e, trans[3], trans[4]), 1)
end
scalify = function(scale, line, mocha, opts, tag)
  local newScale = scale * mocha.ratx
  debug("%s: %f -> %f", tag:sub(2), scale, newScale)
  return round(newScale, opts.sclround)
end
rotate = function(rot, line, mocha, opts)
  local zrot = rot + mocha.zrotd
  debug("frz: -> %f", zrot)
  return round(zrot, opts.rotround)
end
munch = function(sub, sel)
  local changed = false
  for _index_0 = 1, #sel do
    local num = sel[_index_0]
    check_user_cancelled()
    local l1 = sub[num - 1]
    local l2 = sub[num]
    if l1.text == l2.text and l1.effect == l2.effect then
      l1.end_time = l2.end_time
      debug("Munched line %d", num)
      sub[num - 1] = l1
      sub.delete(num)
      changed = true
    end
  end
  return changed
end
cleanup = function(sub, sel, opts)
  opts = opts or { }
  local linediff
  local cleantrans
  cleantrans = function(cont)
    local t_s, t_e, ex, eff = cont:sub(2, -2):match("([%-%d]+),([%-%d]+),([%d%.]*),?(.+)")
    if tonumber(t_e) <= 0 then
      return ("%s"):format(eff)
    end
    if tonumber(t_s) > linediff or tonumber(t_e) < tonumber(t_s) then
      return ""
    end
    if tonumber(ex) == 1 or ex == "" then
      return ("\\t(%s,%s,%s)"):format(t_s, t_e, eff)
    end
    return ("\\t(%s,%s,%s,%s)"):format(t_s, t_e, ex, eff)
  end
  local ns = { }
  for i, v in ipairs(sel) do
    aegisub.progress.title(("Castrating gerbils: %d/%d"):format(i, #sel))
    local lnum = sel[#sel - i + 1]
    do
      local line = sub[lnum]
      linediff = line.end_time - line.start_time
      line.text = line.text:gsub("}" .. string.char(6) .. "{", "")
      line.text = line.text:gsub(string.char(6), "")
      line.text = line.text:gsub("\\t(%b())", cleantrans)
      line.text = line.text:gsub("{}", "")
      for a in line.text:gmatch("{(.-)}") do
        aegisub.progress.set(math.random(100))
        local transforms = { }
        line.text = line.text:gsub("\\(i?clip)%(1,m", "\\%1(m")
        a = a:gsub("(\\t%b())", function(transform)
          debug("Cleanup: %s found", transform)
          table.insert(transforms, transform)
          return string.char(3)
        end)
        for k, v in pairs(alltags) do
          local _, num = a:gsub(v, "")
          a = a:gsub(v, "", num - 1)
        end
        for _index_0 = 1, #transforms do
          local trans = transforms[_index_0]
          a = a:gsub(string.char(3), trans, 1)
        end
        line.text = line.text:gsub("{.-}", string.char(1) .. a .. string.char(2), 1)
      end
      line.text = line.text:gsub(string.char(1), "{")
      line.text = line.text:gsub(string.char(2), "}")
      line.effect = line.effect:gsub("aa%-mou", "", 1)
      sub[lnum] = line
    end
  end
  if opts.sortd ~= "Default" then
    sel = dialog_sort(sub, sel, opts.sortd)
  end
end
dialog_sort = function(sub, sel, sor)
  local sortF = ({
    Time = function(l, n)
      return {
        key = l.start_time,
        num = n,
        data = l
      }
    end,
    Actor = function(l, n)
      return {
        key = l.actor,
        num = n,
        data = l
      }
    end,
    Effect = function(l, n)
      return {
        key = l.effect,
        num = n,
        data = l
      }
    end,
    Style = function(l, n)
      return {
        key = l.style,
        num = n,
        data = l
      }
    end,
    Layer = function(l, n)
      return {
        key = l.layer,
        num = n,
        data = l
      }
    end
  })[sor]
  local lines = { }
  for _index_0 = 1, #sel do
    local v = sel[_index_0]
    table.insert(lines, sortF(sub[v], v))
    check_user_cancelled()
  end
  local strt = sel[1]
  table.sort(lines, function(a, b)
    return a.key > b.key or (a.key == b.key and a.num > b.num)
  end)
  for i = #sel, 1, -1 do
    sub.delete(sel[i])
    check_user_cancelled()
  end
  sel = { }
  for i, v in ipairs(lines) do
    aegisub.progress.title(("Sorting gerbils: %d/%d"):format(i, #lines))
    aegisub.progress.set(i / #lines * 100)
    table.insert(sel, strt)
    sub.insert(strt, v.data)
    check_user_cancelled()
  end
  return sel
end
readconf = function(conf, guitab)
  debug("Opening config file: %s", conf)
  local cf = io.open(conf, 'r')
  if not cf then
    return nil
  end
  local valtab = { }
  local thesection = nil
  debug("Reading config file...")
  for line in cf:lines() do
    local section = line:match("#(%w+)")
    if section then
      valtab[section] = { }
      thesection = section
      debug("Section: %s", thesection)
    elseif thesection == nil then
      return nil
    else
      local key, val = splitconf(line)
      debug("Read: %s -> %s", key, tostring(val:tobool()))
      valtab[thesection][key:gsub("^ +", "")] = val:tobool()
    end
  end
  cf:close()
  for section, sectab in pairs(guitab) do
    for ident, value in pairs(valtab[section]) do
      if section == "global" then
        debug("Set: global.%s = %s (%s)", ident, tostring(value), type(value))
        sectab[ident] = value
      else
        if sectab[ident] then
          debug("Set: gui.%s.%s = %s (%s)", section, ident, tostring(value), type(value))
          sectab[ident].value = value
        end
      end
    end
  end
  return true
end
writeconf = function(conf, optab)
  local cf = io.open(conf, 'w+')
  if not cf then
    warn('Config write failed! Check that %s exists and has write permission.\n', cf)
    return nil
  end
  local configlines = { }
  for section, tab in pairs(optab) do
    table.insert(configlines, ("#%s\n"):format(section))
    if section == "global" then
      for ident, value in pairs(tab) do
        table.insert(configlines, ("  %s:%s\n"):format(ident, tostring(value)))
      end
    else
      local _list_0 = (guiconf[section])
      for _index_0 = 1, #_list_0 do
        local field = _list_0[_index_0]
        if tab[field] ~= nil then
          table.insert(configlines, ("  %s:%s\n"):format(field, tostring(tab[field])))
        end
      end
    end
  end
  for _index_0 = 1, #configlines do
    local v = configlines[_index_0]
    debug("Write: %s -> config", v:gsub("^ +", ""))
    cf:write(v)
  end
  cf:close()
  debug("Config written to %s", conf)
  return true
end
splitconf = function(s)
  return s:gsub("[\r\n]+", ""):match("^(.-):(.*)$")
end
configscope = function()
  if not config_file or re.match(tostring(config_file), [[^(?:/|[A-Z]:\\)]], re.ICASE) then
    return config_file
  end
  local cfs = aegisub.decode_path("?script/" .. config_file)
  do
    local f = io.open(cfs)
    if f then
      f:close()
      return cfs
    end
  end
  return aegisub.decode_path("?user/" .. config_file)
end
confmaker = function()
  onetime_init()
  local lvaltab = { }
  local conf = configscope()
  if not readconf(conf, {
    main = gui.conf,
    clip = gui.clip,
    global = global
  }) then
    warn("Config read failed!")
  end
  for key, value in pairs(global) do
    if gui.conf[key] then
      gui.conf[key].value = value
    end
  end
  gui.conf.enccom.value = encpre[global.encoder] or gui.conf.enccom.value
  local btns = {
    conf = makebuttons({
      {
        ok = "&Write"
      },
      {
        ["local"] = "Write &local"
      },
      {
        clip = "&\\clip..."
      },
      {
        cancel = "&Abort"
      }
    }),
    clip = makebuttons({
      {
        ok = "&Write"
      },
      {
        ["local"] = "Write &local"
      },
      {
        cancel = "&Cancel"
      },
      {
        abort = "&Abort"
      }
    })
  }
  local dlg = "conf"
  while true do
    local _continue_0 = false
    repeat
      local clipconf, button, config
      do
        local _with_0 = btns[dlg]
        button, config = aegisub.dialog.display(gui[dlg], _with_0.__list, _with_0.__namedlist)
      end
      local _exp_0 = button
      if btns.conf.clip == _exp_0 then
        dlg = "clip"
        _continue_0 = true
        break
      elseif btns.conf.ok == _exp_0 or btns.conf["local"] == _exp_0 or btns.clip.ok == _exp_0 or btns.clip["local"] == _exp_0 then
        clipconf = clipconf or { }
        if button == "Write local" then
          conf = aegisub.decode_path("?script/" .. config_file)
        end
        if global.encoder ~= config.encoder then
          config.enccom = encpre[config.encoder] or config.enccom
        end
        for key, value in pairs(global) do
          global[key] = config[key]
          config[key] = nil
        end
        local _list_0 = guiconf.clip
        for _index_0 = 1, #_list_0 do
          local field = _list_0[_index_0]
          if clipconf[field] == nil then
            clipconf[field] = gui.clip[field].value
          end
        end
        writeconf(conf, {
          main = config,
          clip = clipconf,
          global = global
        })
        break
      else
        if dlg == "conf" or button == btns.clip.abort then
          aegisub.cancel()
        else
          dlg = "conf"
          _continue_0 = true
          break
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
trimnthings = function(sub, sel)
  onetime_init()
  local conf = configscope()
  if conf then
    if not readconf(conf, {
      global = global
    }) then
      warn("Failed to read config!")
    end
  end
  local tokens = { }
  do
    tokens.encbin = global.encbin
    tokens.prefix = aegisub.decode_path(global.prefix)
    tokens.nl = "\n"
    collecttrim(sub, sel, tokens)
    tokens.input = getvideoname(sub):gsub("[A-Z]:\\", ""):gsub(".+[^\\/]-[\\/]", "")
    assert(not tokens.input:match("?dummy"), "No dummy videos allowed. Sorry.")
    tokens.inpath = aegisub.decode_path("?video/")
    tokens.index = tokens.input:match("(.+)%.[^%.]+$")
    tokens.output = tokens.index
    if global.gui_trim then
      gui.t.input.value = tokens.input
      gui.t.index.value = tokens.index
      gui.t.startf.value = tokens.startf
      gui.t.endf.value = tokens.endf
      gui.t.output.value = tokens.output
      local button, opts = aegisub.dialog.display(gui.t)
      if not button then
        return 
      end
      for k, v in pairs(opts) do
        tokens[k] = v
      end
      tokens.startt = aegisub.ms_from_frame(tokens.startf)
      tokens.endt = aegisub.ms_from_frame(tokens.endf)
      tokens.lenf = tokens.endf - tokens.startf
      tokens.lent = tokens.endt - tokens.startt
    end
    tokens.startt, tokens.endt, tokens.lent = tokens.startt / 1000, tokens.endt / 1000, tokens.lent / 1000
  end
  local platform = ({
    {
      ext = '.bat',
      exec = '""%s""',
      postexec = '\nif errorlevel 1 (echo Error & pause & del %0) else del %0'
    },
    {
      ext = '.sh',
      exec = 'sh "%s"',
      postexec = ' 2>&1\nrm $0'
    }
  })[(function()
    if winpaths then
      return 1
    else
      return 2
    end
  end)()]
  local encsh = tokens.prefix .. "a-mo.encode" .. platform.ext
  local sh = io.open(encsh, "w+")
  assert(sh, "Encoding command could not be written. Check your prefix.")
  sh:write(global.enccom:gsub("#(%b{})", function(token)
    return tokens[token:sub(2, -2)]
  end) .. platform.postexec)
  sh:close()
  local output = io.popen(platform.exec:format(encsh))
  local outputstr = output:read()
  debug(outputstr)
  return output:close()
end
collecttrim = function(sub, sel, tokens)
  do
    local _with_0 = tokens
    local s = sub[sel[1]]
    _with_0.startt, _with_0.endt = s.start_time, s.end_time
    for _index_0 = 1, #sel do
      local v = sel[_index_0]
      local l = sub[v]
      local lst, let = l.start_time, l.end_time
      if lst < _with_0.startt then
        _with_0.startt = lst
      end
      if let > _with_0.endt then
        _with_0.endt = let
      end
    end
    _with_0.startf = aegisub.frame_from_ms(_with_0.startt)
    _with_0.endf = aegisub.frame_from_ms(_with_0.endt) - 1
    _with_0.lenf = _with_0.endf - _with_0.startf + 1
    _with_0.lent = _with_0.endt - _with_0.startt
    return _with_0
  end
end
string.split = function(self, sep)
  local fields
  sep, fields = sep or ":", { }
  string.gsub(self, "([^" .. tostring(sep) .. "]+)", function(c)
    return table.insert(fields, c)
  end)
  return fields
end
string.tobool = function(self)
  local _exp_0 = self:lower()
  if 'true' == _exp_0 then
    return true
  elseif 'false' == _exp_0 then
    return false
  else
    return self
  end
end
table.tostring = function(t)
  if type(t) ~= 'table' then
    return tostring(t)
  end
  local s = ''
  local i = 1
  while t[i] ~= nil do
    if #s ~= 0 then
      s = s .. ', '
    end
    s = s .. table.tostring(t[i])
    i = i + 1
  end
  for k, v in pairs(t) do
    if type(k) ~= 'number' or k > i then
      if #s ~= 0 then
        s = s .. ', '
      end
      local key = type(k) == 'string' and k or '[' .. table.tostring(k) .. ']'
      s = s .. key .. '=' .. table.tostring(v)
    end
  end
  return '{' .. s .. '}'
end
dcos = function(a)
  return math.cos(math.rad(a))
end
dacos = function(a)
  return math.deg(math.acos(a))
end
dsin = function(a)
  return math.sin(math.rad(a))
end
dasin = function(a)
  return math.deg(math.asin(a))
end
dtan = function(a)
  return math.tan(math.rad(a))
end
datan = function(y, x)
  return math.deg(math.atan2(y, x))
end
fix = {
  xpos = {
    function(sx, l, r)
      return sx - r
    end,
    function(sx, l, r)
      return l
    end,
    function(sx, l, r)
      return sx / 2
    end
  },
  ypos = {
    function(sy, v)
      return sy - v
    end,
    function(sy, v)
      return sy / 2
    end,
    function(sy, v)
      return v
    end
  }
}
check_user_cancelled = function()
  if aegisub.progress.is_cancelled() then
    return error("User cancelled")
  end
end
conformdialog = function(dlg)
  for _, e in pairs(dlg) do
    for k, v in pairs({
      class = e[1],
      x = e[2],
      y = e[3],
      width = e[4],
      height = e[5]
    }) do
      e[k] = v
    end
  end
  return dlg
end
makebuttons = function(extendedlist)
  local btns = {
    __list = { },
    __namedlist = { }
  }
  for _index_0 = 1, #extendedlist do
    local L = extendedlist[_index_0]
    for k, v in pairs(L) do
      btns[k] = v
      btns.__namedlist[k] = v
      table.insert(btns.__list, v)
    end
  end
  return btns
end
windowerr = function(bool, message)
  if not bool then
    aegisub.dialog.display({
      {
        class = "label",
        label = message
      }
    }, {
      "&Close"
    }, {
      cancel = "&Close"
    })
    return error(message)
  end
end
printmem = function(a)
  return debug("%s memory usage: %gkB", tostring(a), collectgarbage("count"))
end
debug = function(...)
  aegisub.log(4, ...)
  return aegisub.log(4, '\n')
end
warn = function(...)
  aegisub.log(2, ...)
  return aegisub.log(2, '\n')
end
round = function(num, idp)
  local mult = 10 ^ (idp or 0)
  return math.floor(num * mult + 0.5) / mult
end
getvideoname = function(sub)
  for x = 1, #sub do
    if sub[x].key == "Video File" then
      return sub[x].value:gsub("^ ", "")
    end
  end
end
isvideo = function()
  if aegisub.frame_from_ms(0) then
    return true
  end
  return false, "Validation failed: you don't have a video loaded."
end
aegisub.register_macro("Motion Data - Apply", "Applies properly formatted motion tracking data to selected subtitles.", init_input, isvideo)
aegisub.register_macro("Motion Data - Trim", "Cuts and encodes the current scene for use with motion tracking software.", trimnthings, isvideo)
if config_file then
  return aegisub.register_macro("Motion Data - Config", "Full config management.", confmaker)
end

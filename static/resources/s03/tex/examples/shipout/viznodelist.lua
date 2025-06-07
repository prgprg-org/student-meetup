--
--  viznodelist.lua
--  speedata publisher
--
--  Written 2010-2020 by Patrick Gundlach.
--  This file is released in the spirit of the well known MIT license
--  (see https://opensource.org/licenses/MIT for more information)
--
-- visualizes nodelists using graphviz

-- usage example:

-- \setbox0\hbox{\vbox{\hbox{abc}}\vbox{x}}
-- \directlua{
--   require("viznodelist")
--   viznodelist.nodelist_visualize(0,"mybox.gv")
-- }
--
-- \bye

-- and then open "mybox.gv" with graphviz

--
-- nodelist_visualize takes three arguments:
-- 1: the number of the box or the box itself (when called from Lua)
-- 2: the filename of the dot-file to create
-- 3: the options table (optional). Known keywords:
--    - showdisc = <boolean> (defaults to false)
--
--
-- Newest file is at https://gist.github.com/pgundlach/556247


local io,string,table = io,string,table
local assert,tostring,type = assert,tostring,type
local tex,texio,node,unicode,font,status=tex,texio,node,unicode,font,status
local pairs = pairs
local print = print

module(...)

local factor = 2^16

-- tostring(a_node) looks like "<node    nil <    172 >    nil : hlist 2>", so we can
-- grab the number in the middle (172 here) as a unique id. So the node
-- is named "node172"
local function get_nodename(n)
  return "\"n" .. string.gsub(tostring(n), "^<node%s+%S+%s+<%s+(%d+).*","%1") .. "\""
end

local function link_to( n,nodename,label )
  if n then
    local t = node.type(n.id)
    local nodename_n = get_nodename(n)
    if t=="temp" or t=="nested_list" then return end

    local ret
    if label=="prev" then
      -- ignore nodes where node.prev.next does not exist.
      -- TODO: this should be more clever: ignore prev pointers of the first nodes in a list.
      if not n.next then return end
      ret = string.format("%s:%s:w -> %s:title\n",nodename,label,get_nodename(n))
    elseif label=="head" then
      ret = string.format("%s:%s -> %s:title\n",nodename,label,get_nodename(n))
    else
      ret = string.format("%s:%s -> %s:title\n",nodename,label,get_nodename(n))
    end
    return ret
  end
end

local function get_subtype( n )
  typ = node.type(n.id)
  local subtypes = {
    hlist = {
      [0] = "unknown origin",
      "created by linebreaking",
      "explicit box command",
      "parindent",
      "alignment column or row",
      "alignment cell",
    },
    glyph = {
      [0] = "character",
      "glyph",
      "ligature",
    },
    disc  = {
      [0] = "\\discretionary",
      "\\-",
      "- (auto)",
      "h&j (simple)",
      "h&j (hard, first item)",
      "h&j (hard, second item)",
    },
    glue = {
      [0]   = "skip",
      [1]   = "lineskip",
      [2]   = "baselineskip",
      [3]   = "parskip",
      [4]   = "abovedisplayskip",
      [5]   = "belowdisplayskip",
      [6]   = "abovedisplayshortskip",
      [7]   = "belowdisplayshortskip",
      [8]   = "leftskip",
      [9]   = "rightskip",
      [10]  = "topskip",
      [11]  = "splittopskip",
      [12]  = "tabskip",
      [13]  = "spaceskip",
      [14]  = "xspaceskip",
      [15]  = "parfillskip",
      [16]  = "thinmuskip",
      [17]  = "medmuskip",
      [18]  = "thickmuskip",
      [100] = "leaders",
      [101] = "cleaders",
      [102] = "xleaders",
      [103] = "gleaders"
    },
    rule = {
      [2]   = "image"
  }
  }
  subtypes.whatsit = node.whatsits()
  if subtypes[typ] then
    return subtypes[typ][n.subtype] or tostring(n.subtype)
  else
    return tostring(n.subtype)
  end
  assert(false)
end

local function label(n,tab )
  local typ = node.type(n.id)
  local nodename = get_nodename(n)
  local subtype = get_subtype(n)
  local ret = string.format("%s [ label = \"<title> name: %s (id %s) | <sub> type: %s  |  { <prev> prev |<next> next }",nodename or "??",typ or "??",string.gsub(nodename,"\"","") or "??",subtype or "?")
  if tab then
    for i=1,#tab do
      if tab[i][1] then
        ret = ret .. string.format("|<%s> %s",tab[i][1],tab[i][2])
      end
    end
  end
  return ret .. "\"]\n"
end

local function draw_node( n,tab )
  local ret = {}
  if not tab then
    tab = {}
  end
  local nodename = get_nodename(n)
  local attlist = n.attr
  if attlist then
    attlist = attlist.next
    while attlist do
      tab[#tab + 1] = { "", string.format("attr%d=%d",attlist.number, attlist.value) }
      attlist = attlist.next
    end
  end
  local properties = node.getproperty(n)

  if properties then
    for k,v in pairs(properties) do
      tab[#tab + 1] = { "", string.format("%s=%s\\l",k, v) }
    end
  end
  ret[#ret + 1] = label(n,tab)
  ret[#ret + 1] = link_to(n.next,nodename,"next")
  ret[#ret + 1] = link_to(n.prev,nodename,"prev")
  return table.concat(ret)
end

local function sanitize(num)
    if num > 0x110000 then num = 65533 end
    local c = unicode.utf8.char(num)
    local ret = c:gsub("\"","\\\"")
    return ret
end

local function draw_action( n )
  local nodename = get_nodename(n)
  local ret = string.format("%s [ label = \"<title> name: %s ", nodename, "action")
  local tab = {
    {"action_type", string.format("action_type: %s", tostring(n.action_type))},
    {"action_id" ,  string.format("action_id: %s",tostring(n.action_id))},
    {"named_id",    string.format("named_id: %s",tostring(n.named_id))},
    {"file",        string.format("file: %s",tostring(n.file))},
    {"new_window" , string.format("new_window: %s",tostring(n.new_window))},
    {"data",        string.format("data: %s",tostring(n.data):gsub(">","\\>"):gsub("<","\\<"))},
    {"refcount" ,   string.format("ref_count: %s",tostring(n.ref_count))},
  }
  for i=1,#tab do
    if tab[i][1] then
      ret = ret .. string.format("|<%s> %s",tab[i][1],tab[i][2])
    end
  end
  return ret .. "\"]\n"
end

local function dot_analyze_nodelist( head, options )
  local ret = {}
  local typ,nodename
	while head do
	  typ = node.type(head.id)
	  nodename = get_nodename(head)

  	if typ == "hlist" then
      local tmp = {}
      if head.width ~= 0 then
        local width = string.format("width %gpt",head.width / factor)
        tmp[#tmp + 1] = {"width",width}
      end
      if head.height ~= 0 then
        local height= string.format("height %gpt",head.height / factor)
        tmp[#tmp + 1] = {"height",height}
      end
      if head.depth ~= 0 then
        local depth = string.format("depth %gpt",head.depth / factor)
        tmp[#tmp + 1] = {"depth",depth}
      end
      if head.glue_set ~= 0 then
        local glue_set = string.format("glue_set %g",head.glue_set)
        tmp[#tmp + 1] =  {"glue_set",glue_set}
      end
      if head.glue_sign ~= 0 then
        local glue_sign = string.format("glue_sign %g",head.glue_sign)
        tmp[#tmp + 1] ={"glue_sign",glue_sign}
      end
      if head.glue_order ~= 0 then
        local glue_order = string.format("glue_order %d",head.glue_order)
        tmp[#tmp + 1] = {"glue_order",glue_order}
      end
      if head.shift ~= 0 then
  	    local shift = string.format("shift %gpt",head.shift / factor)
        tmp[#tmp + 1] = {"shift",shift }
      end
      tmp[#tmp + 1] = {"head", "head"}
      ret[#ret + 1] = draw_node(head, tmp)
  	  if head.head then
	      ret[#ret + 1] = link_to(head.head,nodename,"head")
  	    ret[#ret + 1] = dot_analyze_nodelist(head.head,options)
  	  end
  	elseif typ == "vlist" then
      local tmp = {}
      if head.width ~= 0 then
        local width = string.format("width %gpt",head.width / factor)
        tmp[#tmp + 1] = {"width",width}
      end
      if head.height ~= 0 then
        local height= string.format("height %gpt",head.height / factor)
        tmp[#tmp + 1] = {"height",height}
      end
      if head.depth ~= 0 then
        local depth = string.format("depth %gpt",head.depth / factor)
        tmp[#tmp + 1] = {"depth",depth}
      end
      if head.glue_set ~= 0 then
        local glue_set = string.format("glue_set %g",head.glue_set)
        tmp[#tmp + 1] =  {"glue_set",glue_set}
      end
      if head.glue_sign ~= 0 then
        local glue_sign = string.format("glue_sign %g",head.glue_sign)
        tmp[#tmp + 1] ={"glue_sign",glue_sign}
      end
      if head.glue_order ~= 0 then
        local glue_order = string.format("glue_order %d",head.glue_order)
        tmp[#tmp + 1] = {"glue_order",glue_order}
      end
      if head.shift ~= 0 then
  	    local shift = string.format("shift %gpt",head.shift / factor)
        tmp[#tmp + 1] = {"shift",shift }
      end
      tmp[#tmp + 1] = {"head", "head"}
      ret[#ret + 1] = draw_node(head, tmp)
  	  if head.head then
	      ret[#ret + 1] = link_to(head.head,nodename,"head")
  	    ret[#ret + 1] = dot_analyze_nodelist(head.head,options)
  	  end
  	elseif typ == "glue" then
  	    local subtype = get_subtype(head)
        local spec
        if node.has_field(head,"spec") then
            spec = head.spec
        else
            spec = head
        end
  	  local spec_string = string.format("%gpt", spec.width / factor)
  	  if spec.stretch ~= 0 then
  	    local stretch_order, shrink_order
  	    if spec.stretch_order == 0 then
  	      stretch_order = string.format(" + %gpt",spec.stretch / factor)
  	    else
  	      stretch_order = string.format(" + %g fi%s", spec.stretch  / factor, string.rep("l",spec.stretch_order - 1))
  	    end

  	    spec_string = spec_string .. stretch_order

  	  end
  	  if spec.shrink ~= 0 then
  	    if spec.shrink_order == 0 then
  	      shrink_order = string.format(" - %gpt",spec.shrink / factor)
  	    else
  	      shrink_order = string.format(" - %g fi%s", spec.shrink  / factor, string.rep("l",spec.shrink_order - 1))
  	    end

  	    spec_string = spec_string .. shrink_order
  	  end

      if head.leader then
          ret[#ret + 1] = draw_node(head,{ {"subtype", subtype},{"spec",spec_string},{"leaders","leaders"} })
          ret[#ret + 1] = dot_analyze_nodelist(head.leader,options)
          ret[#ret + 1] = link_to(head.leader,nodename,"leaders")
      else
          ret[#ret + 1] = draw_node(head,{ {"subtype", subtype},{"spec",spec_string} })
      end

  	elseif typ == "kern" then
      ret[#ret + 1] = draw_node(head,{ {"kern", string.format("kern: %gpt",head.kern / factor) } })
  	elseif typ == "rule" then
  	  local wd,ht,dp
  	  if head.width  == -1073741824 then wd = "width: flexible"  else wd = string.format("width: %gpt", head.width  / factor) end
  	  if head.height == -1073741824 then ht = "height: flexible" else ht = string.format("height: %gpt", head.height / factor) end
  	  if head.depth  == -1073741824 then dp = "depth: flexible"  else dp = string.format("depth: %gpt", head.depth  / factor) end
      local subtype
      ret[#ret + 1] = draw_node(head,{ {"wd", wd  },{"ht", ht },{"dp", dp }  })
  	elseif typ == "penalty" then
      ret[#ret + 1] = draw_node(head,{ {"penalty", string.format("%d",head.penalty) } })
  	elseif typ == "disc" then
  	  if options.showdisc then
  	    ret[#ret + 1] = draw_node(head, { {"pre","pre"},{"post","post"},{"replace","replace"} })
  	    if head.pre then
  	      ret[#ret + 1] = dot_analyze_nodelist(head.pre,options)
	        ret[#ret + 1] = link_to(head.pre,nodename,"pre")
  	    end
  	    if head.post then
  	      ret[#ret + 1] = dot_analyze_nodelist(head.post,options)
	        ret[#ret + 1] = link_to(head.post,nodename,"post")
  	    end
  	    if head.replace then
  	      ret[#ret + 1] = dot_analyze_nodelist(head.replace,options)
	        ret[#ret + 1] = link_to(head.replace,nodename,"replace")
  	    end
      else
	      ret[#ret + 1] = draw_node(head, { } )
      end
  	elseif typ == "glyph" then
      local ch = string.format("char: '%s'",sanitize(head.char))
  	  local lng = string.format("lang: %d",head.lang)
  	  local fnt = string.format("font: %d",head.font)
      local wd  = string.format("width: %gpt", head.width / factor)
      local ht  = string.format("height: %gpt", head.height / factor)
      local dp  = string.format("depth: %gpt", head.depth / factor)
  	  local comp
      if options.showdisc then
  	    comp = {"comp","components"}
  	  else
  	    comp = {}
  	  end
      ret[#ret + 1] = draw_node(head,{ {"char", ch} ,{"lang",lng },{"font",fnt},{"width", wd},{"height", ht},{"depth", dp}, comp })
      if head.components and options.showdisc then
        ret[#ret + 1] = dot_analyze_nodelist(head.components,options)
	      ret[#ret + 1] = link_to(head.components,nodename,"comp")
      end
    elseif typ == "math" then
      ret[#ret + 1] = draw_node(head, { "math", head.subtype == 0 and "on" or "off" })
    elseif typ == "whatsit" then
        local st = get_subtype(head)
        if st == "dir" then
            ret[#ret + 1] = draw_node(head, { { "dir", head.dir } })
        elseif st == "pdf_start_link" then
            local wd  = string.format("width (pt): %gpt",  head.width / factor)
            local ht  = string.format("height: %gpt", head.height / factor)
            local dp  = string.format("depth %gpt",  head.depth / factor)
            local objnum = string.format("objnum %d",head.objnum)
            ret[#ret + 1] = draw_action(head.action)
            ret[#ret + 1] = link_to(head.action,nodename,"action")
            ret[#ret + 1] = draw_node(head, {{ "subtype", "pdf_start_link"}, {"width", wd},{"widthraw",head.width}, {"height" , ht}, {"depth",dp}, {"objnum", objnum}, {"action", "action"}})
        elseif st == "pdf_end_link" then
            ret[#ret + 1] = draw_node(head, {{ "subtype", "pdf_end_link"}})
        elseif st == "pdf_literal" then
            ret[#ret + 1] = draw_node(head,{ {"subtype", "literal"},{"data",data} })
        elseif st == "pdf_refximage" then
            local wd  = string.format("width (pt): %gpt",  head.width / factor)
            local ht  = string.format("height: %gpt", head.height / factor)
            local dp  = string.format("depth %gpt",  head.depth / factor)
            local objnum = string.format("objnum %d",head.objnum or 0)
            ret[#ret + 1] = draw_node(head,{ {"subtype", "image"},{"width", wd}, {"height" , ht}, {"depth",dp}, {"objnum", objnum} })
        elseif st == "pdf_colorstack" then
            local stack,cmd,data
            stack = string.format("stack: %d",head.stack)
            if status.luatex_version < 79 then
                cmd = string.format("cmd: %d",  head.cmd)
            else
                cmd = string.format("cmd: %d",  head.command)
            end
            data  = string.format("data: %s", head.data)
            ret[#ret + 1] = draw_node(head,{ {"subtype", "colorstack"},{"stack",stack},{"cmd",cmd},{"data",data} })
        elseif st == "user_defined" then
            local uid,t, val
            uid = string.format("user_id= %s",tostring(head.user_id))
            t   = string.format("type = %s",tostring(head.type))
            val  = string.format("value = %s", tostring(head.value))
            ret[#ret + 1] = draw_node(head,{ {"subtype", "user_defined"},{"userid",uid},{"type",t},{"value",val} })
        elseif st == "local_par" then
            ret[#ret + 1] = draw_node(head, {{ "subtype","local_par"}})
        elseif st == "pdf_dest" then
            local namedid = string.format("named_id=%s",tostring(head.named_id))
            local destid = string.format("dest_id=%s",tostring(head.dest_id))
            ret[#ret + 1] = draw_node(head, { {"named_id",namedid},{"dest_id",destid} })
        elseif st == "pdf_annot" then
            local wd  = string.format("width (pt): %gpt",  head.width / factor)
            local ht  = string.format("height: %gpt", head.height / factor)
            local dp  = string.format("depth %gpt",  head.depth / factor)
            local objnum = string.format("objnum %d",head.objnum)
            local data  = string.format("data: %s", string.gsub(head.data,"<","\\<" ):gsub(">","\\>" ))
            ret[#ret + 1] = draw_node(head, {{ "subtype","pdf_annot"},{"width", wd}, {"height" , ht}, {"depth",dp}, {"objnum",objnum},{"data",data}})
        elseif st == "pdf_save" then
            ret[#ret + 1] = draw_node(head, {{ "subtype","pdf_save" }})
        elseif st == "pdf_restore" then
            ret[#ret + 1] = draw_node(head, {{ "subtype","pdf_restore" }})
        else
            ret[#ret + 1] = draw_node(head, {{ "subtype",st }})
            texio.write_nl(string.format("whatsit type %s not handled",st))
        end
    else
      -- texio.write_nl(string.format("not handled id %d",head.id))
      ret[#ret + 1] = draw_node(head, { })
    end

    head = head.next
	end
  return table.concat(ret)
end


function nodelist_visualize( box,filename,options )
  assert(box,"No box given")
  assert(filename,"No filename given")
  local box_to_analyze
  if type(box)=="number" then
    box_to_analyze = tex.box[box]
  else
    box_to_analyze = box
  end
  local gv = dot_analyze_nodelist(box_to_analyze,options or {})
  local outfile = io.open(filename,"wb")
  outfile:write([[
digraph g {
graph [
rankdir = "LR"
];
node [ shape = "record"]
]])
  outfile:write(gv)
  outfile:write("}\n")
  outfile:close()
end


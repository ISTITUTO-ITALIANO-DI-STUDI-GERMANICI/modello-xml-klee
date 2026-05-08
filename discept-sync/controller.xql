xquery version "3.1";

import module namespace request = "http://exist-db.org/xquery/request";

let $path   := request:get-attribute("$exist:path")
let $method := request:get-method()

return
  if ($path = "/" or $path = "") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="index.html"/>
    </dispatch>

  (: GET /api/euporia :)
  else if ($path = "/api/euporia" or $path = "/api/euporia/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="/exist/apps/discept-sync/src/api/euporia.xql"/>
    </dispatch>

  (: DiScEPT listCollection: GET /data/alignments/ :)
  else if ($path = "/data/alignments/" or $path = "/data/alignments") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="/exist/apps/discept-sync/src/api/rest-bridge.xql"/>
    </dispatch>

  (: DiScEPT fetchFile / writeFile: GET|PUT /data/alignments/{name}.xml :)
  else if (matches($path, "^/data/alignments/[^/]+\.xml$")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="/exist/apps/discept-sync/src/api/rest-bridge.xql"/>
    </dispatch>

  else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <cache-control cache="yes"/>
    </dispatch>

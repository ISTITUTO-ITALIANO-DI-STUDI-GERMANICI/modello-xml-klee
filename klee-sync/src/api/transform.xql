xquery version "3.1";

import module namespace klee="http://example.org/klee-sync/transform"
  at "../modules/transform.xqm";
import module namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";

let $raw    := request:get-uploaded-file-data("file")
let $xml-text := util:binary-to-string($raw, "UTF-8")
let $doc    := parse-xml($xml-text)

return klee:convert($doc)

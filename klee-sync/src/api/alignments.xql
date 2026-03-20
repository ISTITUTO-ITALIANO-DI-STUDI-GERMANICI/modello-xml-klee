xquery version "3.1";

import module namespace request  = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace xmldb    = "http://exist-db.org/xquery/xmldb";
import module namespace util     = "http://exist-db.org/xquery/util";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $BASE     := "/db/apps/klee-sync/data";
declare variable $ALIGN    := $BASE || "/alignments";
declare variable $VERSIONS := $BASE || "/versions";

declare function local:json-response($status as xs:integer, $body as xs:string) {
    response:set-status-code($status),
    response:set-header("Content-Type", "application/json; charset=UTF-8"),
    $body
};

declare function local:xml-response($doc as document-node()?) {
    if (empty($doc))
    then (
        response:set-status-code(404),
        response:set-header("Content-Type", "application/json"),
        '{"error":"Not found"}'
    )
    else (
        response:set-header("Content-Type", "application/xml; charset=UTF-8"),
        $doc
    )
};

declare function local:to-filename($name as xs:string) as xs:string {
    replace(normalize-space($name), "[^\w\-\.]", "_") || ".xml"
};

declare function local:ts() as xs:string {
    let $s := replace(string(current-dateTime()), "[-:]", "")
    let $s := replace($s, "\.\d+.*$", "")
    return substring($s, 1, 15)
};

declare function local:meta-title($doc as document-node()?) as xs:string {
    if (empty($doc)) then "--"
    else
        let $root  := ($doc/tei:TEI, $doc/*[local-name() = "TEI"])[1]
        let $title := ($root//tei:teiHeader//tei:title)[1]/normalize-space()
        return if ($title) then $title else "--"
};

declare function local:meta-authors($doc as document-node()?) as xs:string {
    if (empty($doc)) then "--"
    else
        let $root    := ($doc/tei:TEI, $doc/*[local-name() = "TEI"])[1]
        let $authors := $root//tei:teiHeader//tei:author/normalize-space()
        return if ($authors) then string-join($authors, ", ") else "--"
};

declare function local:meta-langs($doc as document-node()?) as xs:string {
    if (empty($doc)) then ""
    else
        let $root  := ($doc/tei:TEI, $doc/*[local-name() = "TEI"])[1]
        let $langs := distinct-values(
                          $root//tei:TEI/tei:teiHeader//tei:language/@ident/string()
                      )
        return string-join($langs, ", ")
};

declare function local:meta-alignments($doc as document-node()?) as xs:integer {
    if (empty($doc)) then 0
    else
        let $root := ($doc/tei:TEI, $doc/*[local-name() = "TEI"])[1]
        return count($root//tei:linkGrp[@type = "translation"]/tei:link)
};

declare function local:list() {
    let $files := xmldb:get-child-resources($ALIGN)[ends-with(., ".xml")]
    let $items :=
        for $f in $files
        let $doc      := doc($ALIGN || "/" || $f)
        let $modified := xmldb:last-modified($ALIGN, $f)
        let $size     := xmldb:size($ALIGN, $f)
        let $vcount   :=
            let $pname := replace($f, "\.xml$", "")
            return if (xmldb:collection-available($VERSIONS))
                   then count(xmldb:get-child-resources($VERSIONS)[starts-with(., $pname || "_") and ends-with(., ".xml")])
                   else 0
        let $name     := replace($f, "\.xml$", "")
        let $mod-str  := if ($modified castable as xs:dateTime) then string($modified) else ""
        order by $f
        return
            '{"name":"'     || replace($name,                        '"', '\\"') || '",' ||
            '"file":"'      || $f                                                 || '",' ||
            '"title":"'     || replace(local:meta-title($doc),   '"', '\\"')     || '",' ||
            '"authors":"'   || replace(local:meta-authors($doc), '"', '\\"')     || '",' ||
            '"langs":"'     || replace(local:meta-langs($doc),   '"', '\\"')     || '",' ||
            '"alignments":' || local:meta-alignments($doc)                       || ','  ||
            '"versions":'   || $vcount                                           || ','  ||
            '"modified":"'  || $mod-str                                          || '",' ||
            '"size":'       || $size                                              || '}'
    return
        local:json-response(200, "[" || string-join($items, ",") || "]")
};

declare function local:get($project as xs:string) {
    let $uri := $ALIGN || "/" || local:to-filename($project)
    return local:xml-response(if (doc-available($uri)) then doc($uri) else ())
};

declare function local:versions($project as xs:string) {
    let $pname := replace(local:to-filename($project), "\.xml$", "")
    let $files :=
        if (xmldb:collection-available($VERSIONS))
        then xmldb:get-child-resources($VERSIONS)[starts-with(., $pname || "_") and ends-with(., ".xml")]
        else ()
    let $items :=
        for $f in $files
        let $modified := xmldb:last-modified($VERSIONS, $f)
        let $size     := xmldb:size($VERSIONS, $f)
        let $mod-str  := if ($modified castable as xs:dateTime) then string($modified) else ""
        let $ts       := replace($f, "^.+_(\d{8}T\d{6})\.xml$", "$1")
        order by $f descending
        return
            '{"file":"'     || replace($f, '"', '\\"') || '",' ||
            '"timestamp":"' || $ts                     || '",' ||
            '"modified":"'  || $mod-str                || '",' ||
            '"size":'       || $size                   || '}'
    return
        local:json-response(200, "[" || string-join($items, ",") || "]")
};

declare function local:get-version($project as xs:string, $version as xs:string) {
    let $uri := $VERSIONS || "/" || $version
    return local:xml-response(if (doc-available($uri)) then doc($uri) else ())
};

declare function local:save($project as xs:string) {
    let $raw  := request:get-data()
    let $body :=
        typeswitch ($raw)
            case document-node() return $raw
            case element()       return document { $raw }
            case xs:base64Binary return
                let $text := util:binary-to-string($raw, "UTF-8")
                return if (normalize-space($text) != "") then parse-xml($text) else ()
            default return
                let $text := string($raw)
                return if (normalize-space($text) != "")
                       then try { parse-xml($text) } catch * { () }
                       else ()

    let $is-tei := exists($body) and exists($body/(tei:TEI | self::tei:TEI))

    return
        if (not($is-tei))
        then local:json-response(422, '{"error":"Not a valid TEI DiScEPT document (tei:TEI root expected)"}')
        else
            let $fname  := local:to-filename($project)
            let $pname  := replace($fname, "\.xml$", "")
            let $ts     := local:ts()
            let $vfname := $pname || "_" || $ts || ".xml"

            let $_v := xmldb:store($VERSIONS, $vfname, $body)
            let $_c := xmldb:store($ALIGN, $fname, $body)

            return
                if ($_c)
                then local:json-response(201,
                    '{"saved":"'    || $fname                       || '",' ||
                    '"version":"'   || $vfname                      || '",' ||
                    '"timestamp":"' || $ts                          || '",' ||
                    '"alignments":' || local:meta-alignments($body) || '}')
                else local:json-response(500, '{"error":"Failed to save file"}')
};

declare function local:delete($project as xs:string) {
    let $fname := local:to-filename($project)
    let $pname := replace($fname, "\.xml$", "")
    let $uri   := $ALIGN || "/" || $fname
    return
        if (not(doc-available($uri)))
        then local:json-response(404, '{"error":"Project not found"}')
        else (
            xmldb:remove($ALIGN, $fname),
            if (xmldb:collection-available($VERSIONS))
            then
                for $vf in xmldb:get-child-resources($VERSIONS)[starts-with(., $pname || "_") and ends-with(., ".xml")]
                return xmldb:remove($VERSIONS, $vf)
            else (),
            local:json-response(200, '{"deleted":"' || $fname || '"}')
        )
};

let $method  := request:get-method()
let $action  := request:get-parameter("action", "list")
let $project := request:get-parameter("project", "")
let $version := request:get-parameter("version", "")

return
    if      ($action = "list")
    then local:list()

    else if ($action = "get" and $project != "")
    then local:get($project)

    else if ($action = "versions" and $project != "")
    then local:versions($project)

    else if ($action = "get-version" and $project != "" and $version != "")
    then local:get-version($project, $version)

    else if ($action = "save" and $project != "" and $method = "POST")
    then local:save($project)

    else if ($action = "delete" and $project != "" and $method = "DELETE")
    then local:delete($project)

    else local:json-response(400, '{"error":"Invalid parameters"}')

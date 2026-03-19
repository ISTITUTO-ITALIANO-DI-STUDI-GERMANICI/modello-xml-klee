xquery version "3.1";

import module namespace request  = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace xmldb    = "http://exist-db.org/xquery/xmldb";
import module namespace util     = "http://exist-db.org/xquery/util";

declare namespace tei   = "http://www.tei-c.org/ns/1.0";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare variable $BASE     := "/db/apps/klee-sync/data";
declare variable $ALIGN    := $BASE || "/alignments";
declare variable $VERSIONS := $BASE || "/versions";

declare function local:to-filename($name as xs:string) as xs:string {
    replace(normalize-space($name), "[^\w\-\.]", "_") || ".xml"
};

declare function local:ts() as xs:string {
    let $s := replace(string(current-dateTime()), "[-:]", "")
    return substring(replace($s, "\.\d+.*$", ""), 1, 15)
};

declare function local:project-from-path() as xs:string {
    let $path  := request:get-attribute("$exist:path")
    let $fname := tokenize($path, "/")[last()]
    return replace($fname, "\.xml$", "")
};

declare function local:is-collection-path() as xs:boolean {
    let $path := request:get-attribute("$exist:path")
    return ends-with($path, "/data/alignments") or ends-with($path, "/data/alignments/")
};

declare function local:do-list() {
    let $files := xmldb:get-child-resources($ALIGN)[ends-with(., ".xml")]
    return (
        response:set-header("Content-Type", "application/xml; charset=UTF-8"),
        <exist:result xmlns:exist="http://exist.sourceforge.net/NS/exist">
            {for $f in $files return <exist:resource name="{$f}"/>}
        </exist:result>
    )
};

declare function local:do-get($project as xs:string) {
    let $uri := $ALIGN || "/" || local:to-filename($project)
    return
        if (doc-available($uri))
        then (
            response:set-header("Content-Type", "application/xml; charset=UTF-8"),
            doc($uri)
        )
        else (
            response:set-status-code(404),
            <error>Not found</error>
        )
};

declare function local:do-put($project as xs:string) {
    let $raw  := request:get-data()
    let $body :=
        typeswitch ($raw)
            case document-node() return $raw
            case element()       return document { $raw }
            case xs:base64Binary return
                let $t := util:binary-to-string($raw, "UTF-8")
                return if (normalize-space($t) != "") then parse-xml($t) else ()
            default return
                let $t := string($raw)
                return if (normalize-space($t) != "")
                       then try { parse-xml($t) } catch * { () }
                       else ()

    let $is-tei := exists($body) and exists($body/(tei:TEI | self::tei:TEI))

    return
        if (not($is-tei))
        then (
            response:set-status-code(422),
            <error>Not a valid TEI DiScEPT document</error>
        )
        else
            let $fname  := local:to-filename($project)
            let $pname  := replace($fname, "\.xml$", "")
            let $ts     := local:ts()
            let $vfname := $pname || "_" || $ts || ".xml"
            let $vcol   := $VERSIONS || "/" || $pname

            let $_ :=
                if (not(xmldb:collection-available($vcol)))
                then xmldb:create-collection($VERSIONS, $pname)
                else ()

            let $_v := xmldb:store($vcol, $vfname, $body)
            let $_c := xmldb:store($ALIGN, $fname, $body)

            return
                if ($_c)
                then (
                    response:set-status-code(201),
                    <ok version="{$vfname}" timestamp="{$ts}"/>
                )
                else (
                    response:set-status-code(500),
                    <error>Failed to save</error>
                )
};

declare function local:do-delete($project as xs:string) {
    let $fname := local:to-filename($project)
    let $vcol  := $VERSIONS || "/" || replace($fname, "\.xml$", "")
    return (
        if (doc-available($ALIGN || "/" || $fname)) then xmldb:remove($ALIGN, $fname) else (),
        if (xmldb:collection-available($vcol))       then xmldb:remove($vcol)          else (),
        <ok deleted="{$fname}"/>
    )
};

let $method := request:get-method()

return
    if (local:is-collection-path()) then
        if ($method = "GET") then local:do-list()
        else (response:set-status-code(405), <error>Method not allowed</error>)
    else
        let $project := local:project-from-path()
        return
            if      ($method = "GET")    then local:do-get($project)
            else if ($method = "PUT")    then local:do-put($project)
            else if ($method = "DELETE") then local:do-delete($project)
            else (response:set-status-code(405), <error>Method not allowed</error>)

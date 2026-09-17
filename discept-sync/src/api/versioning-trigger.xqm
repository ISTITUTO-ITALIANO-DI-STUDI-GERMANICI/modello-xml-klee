xquery version "3.1";

module namespace trigger = "http://exist-db.org/xquery/trigger";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare variable $trigger:VERSIONS := "/db/apps/discept-sync/data/versions";

declare function trigger:after-create-document($uri as xs:anyURI) {
    trigger:snapshot($uri)
};

declare function trigger:after-update-document($uri as xs:anyURI) {
    trigger:snapshot($uri)
};

declare function trigger:ts() as xs:string {
    let $s := replace(string(current-dateTime()), "[-:]", "")
    return substring(replace($s, "\.\d+.*$", ""), 1, 15)
};

declare function trigger:snapshot($uri as xs:anyURI) {
    let $fname  := tokenize(string($uri), "/")[last()]
    let $pname  := replace($fname, "\.xml$", "")
    let $vfname := $pname || "_" || trigger:ts() || ".xml"
    return
        if (doc-available($uri) and xmldb:collection-available($trigger:VERSIONS))
        then xmldb:store($trigger:VERSIONS, $vfname, doc($uri))
        else ()
};

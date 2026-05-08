xquery version "3.1";

import module namespace xmldb   = "http://exist-db.org/xquery/xmldb";
import module namespace sm      = "http://exist-db.org/xquery/securitymanager";
import module namespace discept = "http://example.org/discept-sync/transform"
    at "/db/apps/discept-sync/src/modules/transform.xqm";

declare variable $target external;

let $align    := xs:anyURI($target || "/data/alignments")
let $versions := xs:anyURI($target || "/data/versions")
let $euporia  := xs:anyURI($target || "/data/euporia")
let $cfg-root := "/db/system/config/db/apps/discept-sync/data/alignments"
let $klee-src := "/db/apps/klee/data/annoParsed.xml"

return (
    (: ── collection.xconf for alignments :)
    if (not(xmldb:collection-available("/db/system/config/db/apps/discept-sync")))
    then xmldb:create-collection("/db/system/config/db/apps", "discept-sync")
    else (),

    if (not(xmldb:collection-available("/db/system/config/db/apps/discept-sync/data")))
    then xmldb:create-collection("/db/system/config/db/apps/discept-sync", "data")
    else (),

    if (not(xmldb:collection-available($cfg-root)))
    then xmldb:create-collection("/db/system/config/db/apps/discept-sync/data", "alignments")
    else (),

    if (doc-available($target || "/collection.xconf"))
    then xmldb:store($cfg-root, "collection.xconf", doc($target || "/collection.xconf"))
    else (),

    (: Collection permissions :)
    sm:chmod($align,    "rwxrwxrwx"),
    sm:chmod($versions, "rwxrwxrwx"),
    sm:chmod($euporia,  "rwxrwxrwx"),

    (: After installing the package, if Klee is available I automatically convert to XML/TEI for the first time :)
    if (doc-available($klee-src))
    then
        let $tei    := discept:convert(doc($klee-src))
        let $stored := xmldb:store($euporia, "discept.xml", $tei)
        return sm:chmod(xs:anyURI($euporia || "/discept.xml"), "rw-rw-rw-")
    else ()
)

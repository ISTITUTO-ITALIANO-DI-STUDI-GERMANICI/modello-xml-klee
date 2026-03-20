xquery version "3.1";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace sm    = "http://exist-db.org/xquery/securitymanager";

declare variable $target external;

let $align    := xs:anyURI($target || "/data/alignments")
let $versions := xs:anyURI($target || "/data/versions")
let $cfg-root := "/db/system/config/db/apps/klee-sync/data/alignments"

return (
    if (not(xmldb:collection-available("/db/system/config/db/apps/klee-sync")))
    then xmldb:create-collection("/db/system/config/db/apps", "klee-sync")
    else (),

    if (not(xmldb:collection-available("/db/system/config/db/apps/klee-sync/data")))
    then xmldb:create-collection("/db/system/config/db/apps/klee-sync", "data")
    else (),

    if (not(xmldb:collection-available($cfg-root)))
    then xmldb:create-collection("/db/system/config/db/apps/klee-sync/data", "alignments")
    else (),

    if (doc-available($target || "/collection.xconf"))
    then xmldb:store($cfg-root, "collection.xconf", doc($target || "/collection.xconf"))
    else (),

    sm:chmod($align,    "rwxrwxrwx"),
    sm:chmod($versions, "rwxrwxrwx")
)

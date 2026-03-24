xquery version "3.1";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare variable $target external;

(
    if (not(xmldb:collection-available($target)))
    then xmldb:create-collection("/db/apps", "discept-sync")
    else (),

    if (not(xmldb:collection-available($target || "/data")))
    then xmldb:create-collection($target, "data")
    else (),

    if (not(xmldb:collection-available($target || "/data/alignments")))
    then xmldb:create-collection($target || "/data", "alignments")
    else (),

    if (not(xmldb:collection-available($target || "/data/versions")))
    then xmldb:create-collection($target || "/data", "versions")
    else ()
)

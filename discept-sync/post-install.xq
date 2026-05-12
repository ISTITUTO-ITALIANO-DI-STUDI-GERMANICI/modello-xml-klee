xquery version "3.1";

import module namespace xmldb     = "http://exist-db.org/xquery/xmldb";
import module namespace sm        = "http://exist-db.org/xquery/securitymanager";
import module namespace scheduler = "http://exist-db.org/xquery/scheduler";
import module namespace discept   = "http://example.org/discept-sync/transform"
    at "/db/apps/discept-sync/src/modules/transform.xqm";

declare variable $target external;

let $align      := xs:anyURI($target || "/data/alignments")
let $versions   := xs:anyURI($target || "/data/versions")
let $euporia    := xs:anyURI($target || "/data/euporia")
let $cfg-sync   := "/db/system/config/db/apps/discept-sync/data/alignments"
let $cfg-klee   := "/db/system/config/db/apps/klee/data"
let $klee-src   := "/db/apps/klee/data/annoParsed.xml"
let $job-path   := "/db/apps/discept-sync/src/jobs/euporia-sync.xql"
let $job-name   := "discept-sync-euporia"

return (
    (: collection.xconf for alignments :)
    if (not(xmldb:collection-available("/db/system/config/db/apps/discept-sync")))
    then xmldb:create-collection("/db/system/config/db/apps", "discept-sync")
    else (),

    if (not(xmldb:collection-available("/db/system/config/db/apps/discept-sync/data")))
    then xmldb:create-collection("/db/system/config/db/apps/discept-sync", "data")
    else (),

    if (not(xmldb:collection-available($cfg-sync)))
    then xmldb:create-collection("/db/system/config/db/apps/discept-sync/data", "alignments")
    else (),

    if (doc-available($target || "/collection.xconf"))
    then xmldb:store($cfg-sync, "collection.xconf", doc($target || "/collection.xconf"))
    else (),

    (: collection.xconf for klee/data (trigger on annoParsed.xml) :)
    if (not(xmldb:collection-available("/db/system/config/db/apps/klee")))
    then xmldb:create-collection("/db/system/config/db/apps", "klee")
    else (),

    if (not(xmldb:collection-available($cfg-klee)))
    then xmldb:create-collection("/db/system/config/db/apps/klee", "data")
    else (),

    if (doc-available($target || "/klee-collection.xconf"))
    then (
        xmldb:store($cfg-klee, "collection.xconf", doc($target || "/klee-collection.xconf")),
        xmldb:reindex("/db/apps/klee/data")
    )
    else (),

    (: Collections permissions :)
    sm:chmod($align,    "rwxrwxrwx"),
    sm:chmod($versions, "rwxrwxrwx"),
    sm:chmod($euporia,  "rwxrwxrwx"),

    (: Trigger and dependency file permissions :)
    sm:chmod(xs:anyURI("/db/apps/discept-sync/src/trigger/euporia.xqm"),  "rwxrwxrwx"),
    sm:chmod(xs:anyURI("/db/apps/discept-sync/src/modules/transform.xqm"), "rwxrwxrwx"),
    sm:chmod(xs:anyURI("/db/apps/discept-sync/src/xslt/parsedToTEI.xsl"),  "rwxrwxrwx"),
    sm:chmod(xs:anyURI($job-path), "rwxrwxrwx"),

    (: Register cron job — every 10 seconds, replaces any existing job with the same name :)
    scheduler:delete-scheduled-job($job-name),
    scheduler:schedule-xquery-cron-job($job-path, "0/10 * * * * ?", $job-name, (), true()),

    (: First conversion to XML/TEI :)
    if (doc-available($klee-src))
    then
        let $tei    := discept:convert(doc($klee-src))
        let $stored := xmldb:store($euporia, "discept.xml", $tei)
        return sm:chmod(xs:anyURI($euporia || "/discept.xml"), "rwxrwxrwx")
    else ()
)

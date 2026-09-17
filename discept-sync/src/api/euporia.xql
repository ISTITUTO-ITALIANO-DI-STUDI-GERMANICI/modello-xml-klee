xquery version "3.1";

(:~
 : DIScEPT Sync – Euporia endpoint
 :
 : Returns the pre-converted TEI document (discept.xml) kept in sync
 : by the XQuery trigger on /db/apps/klee/data/.
 : The trigger fires whenever Euporia updates annoParsed.xml,
 : so this endpoint just serves the cached result.
 :)

import module namespace response = "http://exist-db.org/xquery/response";

declare variable $SYNC-DOC := "/db/apps/discept-sync/data/euporia/discept.xml";

if (not(doc-available($SYNC-DOC))) then (
    response:set-status-code(404),
    response:set-header("Content-Type", "application/xml; charset=UTF-8"),
    <error>
        <message>Converted TEI not available yet</message>
        <path>{$SYNC-DOC}</path>
        <hint>The document is produced by the Sync trigger when Euporia updates annoParsed.xml</hint>
    </error>
)
else (
    response:set-header("Content-Type", "application/xml; charset=UTF-8"),
    doc($SYNC-DOC)
)

xquery version "3.1";

(:~
 : DIScEPT Sync – Euporia endpoint
 :
 : Reads annoParsed.xml from Klee, applies the XML-D → TEI transform
 : and updates data/euporia/discept.xml in the Sync DB.
 :)

import module namespace response = "http://exist-db.org/xquery/response";
import module namespace xmldb    = "http://exist-db.org/xquery/xmldb";
import module namespace sm       = "http://exist-db.org/xquery/securitymanager";
import module namespace discept  = "http://example.org/discept-sync/transform"
    at "../modules/transform.xqm";

declare variable $KLEE-SRC  := "/db/apps/klee/data/annoParsed.xml";
declare variable $SYNC-COL  := "/db/apps/discept-sync/data/euporia";
declare variable $SYNC-FILE := "discept.xml";

if (not(doc-available($KLEE-SRC))) then (
    response:set-status-code(404),
    response:set-header("Content-Type", "application/xml; charset=UTF-8"),
    <error>
        <message>Euporia source not found</message>
        <path>{$KLEE-SRC}</path>
    </error>
)
else
    let $tei    := try { discept:convert(doc($KLEE-SRC)) } catch * { () }
    return
        if (empty($tei)) then (
            response:set-status-code(500),
            response:set-header("Content-Type", "application/xml; charset=UTF-8"),
            <error>
                <message>Transform failed</message>
                <path>{$KLEE-SRC}</path>
            </error>
        )
        else
            let $stored := xmldb:store($SYNC-COL, $SYNC-FILE, $tei)
            let $_      := sm:chmod(xs:anyURI($SYNC-COL || "/" || $SYNC-FILE), "rw-rw-rw-")
            return (
                response:set-header("Content-Type", "application/xml; charset=UTF-8"),
                <ok>
                    <stored>{$stored}</stored>
                </ok>
            )

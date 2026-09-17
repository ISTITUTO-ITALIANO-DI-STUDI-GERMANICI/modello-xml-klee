xquery version "3.1";

(:~
 : Runs every 10 seconds. Compares the last-modified timestamp of
 : annoParsed.xml (Euporia/Klee) with that of discept.xml (Sync cache).
 : If annoParsed.xml is newer, reconverts and updates discept.xml.
 : Writes a debug report to data/euporia/job-log.xml after every run.
 :)

import module namespace xmldb   = "http://exist-db.org/xquery/xmldb";
import module namespace sm      = "http://exist-db.org/xquery/securitymanager";
import module namespace util    = "http://exist-db.org/xquery/util";
import module namespace discept = "http://example.org/discept-sync/transform"
    at "/db/apps/discept-sync/src/modules/transform.xqm";

declare variable $KLEE-COL  := "/db/apps/klee/data";
declare variable $KLEE-FILE := "annoParsed.xml";
declare variable $KLEE-SRC  := $KLEE-COL || "/" || $KLEE-FILE;
declare variable $SYNC-COL  := "/db/apps/discept-sync/data/euporia";
declare variable $SYNC-FILE := "discept.xml";
declare variable $SYNC-DOC  := $SYNC-COL || "/" || $SYNC-FILE;
declare variable $LOG-FILE  := "job-log.xml";

declare function local:write-log($status as xs:string, $message as xs:string) {
    let $report := <job-log>
        <timestamp>{current-dateTime()}</timestamp>
        <status>{$status}</status>
        <message>{$message}</message>
        <anno-available>{doc-available($KLEE-SRC)}</anno-available>
        <sync-available>{doc-available($SYNC-DOC)}</sync-available>
        <anno-ts>{
            if (doc-available($KLEE-SRC))
            then string(xmldb:last-modified($KLEE-COL, $KLEE-FILE))
            else "n/a"
        }</anno-ts>
        <sync-ts>{
            if (doc-available($SYNC-DOC))
            then string(xmldb:last-modified($SYNC-COL, $SYNC-FILE))
            else "n/a"
        }</sync-ts>
    </job-log>
    return (
        xmldb:store($SYNC-COL, $LOG-FILE, $report),
        sm:chmod(xs:anyURI($SYNC-COL || "/" || $LOG-FILE), "rwxrwxrwx")
    )
};

if (not(doc-available($KLEE-SRC))) then
    local:write-log("skip", "annoParsed.xml not found")
else
    let $anno-ts := xmldb:last-modified($KLEE-COL, $KLEE-FILE)
    let $sync-ts := if (doc-available($SYNC-DOC))
                    then xmldb:last-modified($SYNC-COL, $SYNC-FILE)
                    else xs:dateTime("1970-01-01T00:00:00Z")
    return
        if ($anno-ts gt $sync-ts) then
            try {
                let $tei    := discept:convert(doc($KLEE-SRC))
                let $stored := xmldb:store($SYNC-COL, $SYNC-FILE, $tei)
                let $_      := sm:chmod(xs:anyURI($SYNC-DOC), "rwxrwxrwx")
                return local:write-log("ok", "discept.xml updated (" || $anno-ts || ")")
            } catch * {
                local:write-log("error", $err:code || " — " || $err:description)
            }
        else
            local:write-log("skip", "discept.xml is up to date")

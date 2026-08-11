xquery version "3.1";

(:~
 : Trigger on /db/apps/klee/data/
 : When annoParsed.xml is created or updated,
 : reconverts the document and updates discept.xml in Sync.
 :)

module namespace trigger = "http://exist-db.org/xquery/trigger";

import module namespace xmldb   = "http://exist-db.org/xquery/xmldb";
import module namespace sm      = "http://exist-db.org/xquery/securitymanager";
import module namespace util    = "http://exist-db.org/xquery/util";
import module namespace discept = "http://example.org/discept-sync/transform"
    at "/db/apps/discept-sync/src/modules/transform.xqm";

declare variable $trigger:KLEE-FILE  := "annoParsed.xml";
declare variable $trigger:SYNC-COL   := "/db/apps/discept-sync/data/euporia";
declare variable $trigger:SYNC-FILE  := "discept.xml";

declare function trigger:after-create-document($uri as xs:anyURI) {
    trigger:convert-if-anno($uri)
};

declare function trigger:after-update-document($uri as xs:anyURI) {
    trigger:convert-if-anno($uri)
};

declare function trigger:convert-if-anno($uri as xs:anyURI) {
    if (ends-with(string($uri), $trigger:KLEE-FILE))
    then
        try {
            let $tei    := discept:convert(doc($uri))
            let $stored := xmldb:store($trigger:SYNC-COL, $trigger:SYNC-FILE, $tei)
            return sm:chmod(xs:anyURI($trigger:SYNC-COL || "/" || $trigger:SYNC-FILE), "rwxrwxrwx")
        } catch * {
            util:log("error", "DIScEPT Sync trigger: conversion failed for " || $uri || " — " || $err:description)
        }
    else ()
};

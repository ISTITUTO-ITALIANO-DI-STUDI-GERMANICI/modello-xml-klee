xquery version "3.1";

import module namespace http="http://expath.org/ns/http-client";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

let $url := "https://dsl.example.org/xml"

let $response :=
    http:send-request(
        <http:request method="get" href="{$url}"/>
    )

let $xml := $response[2]

return
    xmldb:store(
        "/db/apps/klee-sync/data/input",
        "dsl.xml",
        $xml
    )
xquery version "3.1";

import module namespace response = "http://exist-db.org/xquery/response";
import module namespace request  = "http://exist-db.org/xquery/request";

response:set-header("Content-Type", "application/json"),
'{"status":"ok","auth":"' || request:get-header("Authorization") || '"}'

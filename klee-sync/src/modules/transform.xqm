xquery version "3.1";

module namespace klee="http://example.org/klee-sync/transform";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

declare function klee:convert(
    $input as node()
) as node() {
    let $xsl := doc("/db/apps/klee-sync/src/xslt/parsedToTEI.xsl")
    return transform:transform($input, $xsl, ())
};

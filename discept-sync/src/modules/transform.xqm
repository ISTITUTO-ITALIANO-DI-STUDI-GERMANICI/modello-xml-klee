xquery version "3.1";

module namespace discept="http://example.org/discept-sync/transform";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

declare function discept:convert(
    $input as node()
) as node() {
    let $xsl := doc("/db/apps/discept-sync/src/xslt/parsedToTEI.xsl")
    return transform:transform($input, $xsl, ())
};
